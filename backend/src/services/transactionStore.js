/**
 * @module transactionStore
 *
 * Transaction Store
 *
 * Handles normalized transaction storage with built-in deduplication.
 * Transactions flow through the full normalization pipeline before storage:
 *
 *   Raw Plaid Data → Merchant Cleaning → Merchant Mapping →
 *   Category Classification → Recurring Detection → Currency Conversion → Store
 *
 * Current implementation: In-memory (development/prototype).
 * Production: Replace with PostgreSQL.
 *
 * Deduplication strategy:
 * - Each transaction has a unique `plaidTransactionId` from Plaid
 * - On sync, removed transactions are deleted, modified are updated
 * - Plaid's /transactions/sync handles cursor-based pagination,
 *   and this store tracks the cursor per connection
 *
 * Enriched schema:
 * {
 *   id:                    string   — Internal UUID
 *   plaidTransactionId:    string   — Plaid's transaction_id (dedup key)
 *   connectionId:          string   — FK to connection store
 *   accountId:             string   — Plaid account_id
 *   date:                  string   — Transaction date (YYYY-MM-DD)
 *   merchantRaw:           string   — Original raw bank description (never mutated)
 *   merchantClean:         string   — Cleaned merchant name (noise stripped)
 *   merchantName:          string   — Canonical merchant identity (mapped)
 *   amountOriginal:        number   — Amount in original currency
 *   currencyOriginal:      string   — Original ISO currency code from Plaid
 *   amountConverted:       number   — Amount converted to user's base currency
 *   currencyBase:          string   — User's base currency code
 *   exchangeRateAtTime:    number   — Exchange rate locked at transaction ingest
 *   amount:                number   — Legacy alias → amountConverted
 *   currency:              string   — Legacy alias → currencyBase
 *   category:              string   — Classified category (subscriptions, food, etc.)
 *   isRecurring:           boolean  — Recurring transaction flag
 *   recurringInterval:     string   — Detected interval (monthly, annual, etc.)
 *   confidenceScores:      object   — { merchant, category, recurring }
 *   pending:               boolean  — Whether the transaction is pending
 *   createdAt:             string   — When we first ingested this
 * }
 */
 */

const crypto = require("crypto");
const {
  getHistoricalRate,
  convert,
  getUserBaseCurrency,
} = require("./currencyService");
const {
  normalizeTransaction: enrichTransaction,
  refreshRecurringCache,
} = require("./transactionNormalizationService");

// In-memory stores — replace with database in production
const transactions = new Map();
const syncCursors = new Map(); // connectionId → cursor string

/**
 * Normalizes a raw Plaid transaction into Trim's enriched internal format.
 *
 * Pipeline:
 * 1. Merchant cleaning (strip noise, normalize casing)
 * 2. Merchant mapping (resolve canonical identity)
 * 3. Category classification (layered keyword + Plaid + heuristic)
 * 4. Recurring detection (via cached analysis)
 *
 * Currency conversion is applied separately via applyCurrencyConversion().
 *
 * @param {object} plaidTx - Raw transaction from Plaid API
 * @param {string} connectionId - The parent connection ID
 * @param {string} baseCurrency - User's base currency code
 * @returns {object} Enriched, normalized transaction
 */
function normalizePlaidTransaction(plaidTx, connectionId, baseCurrency = "USD") {
  // Run through the full normalization pipeline
  const enriched = enrichTransaction(plaidTx, { connectionId, baseCurrency });

  // Assign a unique internal ID
  enriched.id = crypto.randomUUID();

  return enriched;
}

/**
 * Applies currency conversion to a normalized transaction.
 * Fetches the historical rate for the transaction date and locks it.
 *
 * @param {object} normalizedTx - Output of normalizePlaidTransaction
 * @returns {Promise<object>} Transaction with converted amounts
 */
async function applyCurrencyConversion(normalizedTx) {
  const { amountOriginal, currencyOriginal, currencyBase, date } = normalizedTx;

  if (currencyOriginal === currencyBase) {
    normalizedTx.amountConverted = amountOriginal;
    normalizedTx.exchangeRateAtTime = 1.0;
    normalizedTx.amount = amountOriginal;
    return normalizedTx;
  }

  try {
    const rate = await getHistoricalRate(currencyOriginal, currencyBase, date);
    const { amount: converted } = await convert(
      amountOriginal,
      currencyOriginal,
      currencyBase,
      rate
    );

    normalizedTx.amountConverted = converted;
    normalizedTx.exchangeRateAtTime = rate;
    normalizedTx.amount = converted; // Legacy alias
  } catch (error) {
    console.error(
      `[TransactionStore] Currency conversion failed for ${currencyOriginal} → ${currencyBase}:`,
      error.message
    );
    // Fail safe: keep original amount with rate=1 flagged
    normalizedTx.amountConverted = amountOriginal;
    normalizedTx.exchangeRateAtTime = 1.0;
    normalizedTx.amount = amountOriginal;
  }

  return normalizedTx;
}

/**
 * Ingests new transactions from a sync response.
 * Handles added, modified, and removed transactions.
 * Currency conversion is applied at ingest time and locked permanently.
 *
 * @param {string} connectionId - The connection these transactions belong to
 * @param {object} syncData - { added: [], modified: [], removed: [] }
 * @param {string} baseCurrency - User's base currency for conversion
 * @returns {Promise<object>} Summary of changes
 */
async function ingestSyncResults(connectionId, syncData, baseCurrency = "USD") {
  let addedCount = 0;
  let modifiedCount = 0;
  let removedCount = 0;

  // Process added transactions
  for (const plaidTx of syncData.added || []) {
    // Dedup check — skip if we already have this transaction
    const existing = findByPlaidId(plaidTx.transaction_id);
    if (existing) continue;

    const normalized = normalizePlaidTransaction(plaidTx, connectionId, baseCurrency);
    const converted = await applyCurrencyConversion(normalized);
    transactions.set(converted.id, converted);
    addedCount++;
  }

  // Process modified transactions (price adjustments, category changes)
  // NOTE: Modified transactions preserve the original exchange rate
  for (const plaidTx of syncData.modified || []) {
    const existing = findByPlaidId(plaidTx.transaction_id);
    if (existing) {
      const updated = normalizePlaidTransaction(plaidTx, connectionId, baseCurrency);
      updated.id = existing.id;
      updated.createdAt = existing.createdAt;
      // Preserve original locked exchange rate — never recalculate
      updated.exchangeRateAtTime = existing.exchangeRateAtTime;
      updated.amountConverted = Math.round(updated.amountOriginal * existing.exchangeRateAtTime * 100) / 100;
      updated.amount = updated.amountConverted;
      transactions.set(existing.id, updated);
      modifiedCount++;
    }
  }

  // Process removed transactions (reversed, returned, etc.)
  for (const removal of syncData.removed || []) {
    const existing = findByPlaidId(removal.transaction_id);
    if (existing) {
      transactions.delete(existing.id);
      removedCount++;
    }
  }

  // Refresh the recurring detection cache with all stored transactions
  refreshRecurringCache(Array.from(transactions.values()));

  return { addedCount, modifiedCount, removedCount };
}

/**
 * Finds a stored transaction by its Plaid transaction_id.
 *
 * @param {string} plaidTransactionId
 * @returns {object|null}
 */
function findByPlaidId(plaidTransactionId) {
  for (const tx of transactions.values()) {
    if (tx.plaidTransactionId === plaidTransactionId) {
      return tx;
    }
  }
  return null;
}

/**
 * Gets all transactions for a specific connection.
 *
 * @param {string} connectionId
 * @returns {Array} Transactions sorted by date descending
 */
function getTransactionsByConnection(connectionId) {
  return Array.from(transactions.values())
    .filter((tx) => tx.connectionId === connectionId)
    .sort((a, b) => new Date(b.date) - new Date(a.date));
}

/**
 * Gets all transactions across all connections.
 *
 * @returns {Array} All transactions sorted by date descending
 */
function getAllTransactions() {
  return Array.from(transactions.values()).sort(
    (a, b) => new Date(b.date) - new Date(a.date)
  );
}

/**
 * Gets/sets the sync cursor for a connection.
 * The cursor tracks the last sync position for incremental updates.
 */
function getSyncCursor(connectionId) {
  return syncCursors.get(connectionId) || null;
}

function setSyncCursor(connectionId, cursor) {
  syncCursors.set(connectionId, cursor);
}

module.exports = {
  normalizePlaidTransaction,
  applyCurrencyConversion,
  ingestSyncResults,
  getTransactionsByConnection,
  getAllTransactions,
  getSyncCursor,
  setSyncCursor,
};
