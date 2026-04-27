const { createPlaidClient } = require("../config/plaid");
const { getAccessToken } = require("./connectionStore");
const { getUserBaseCurrency } = require("./currencyService");
const {
  ingestSyncResults,
  getSyncCursor,
  setSyncCursor,
  getTransactionsByConnection,
  getAllTransactions,
} = require("./transactionStore");
const {
  formatForClient,
  getRecurringAnalysis,
} = require("./transactionNormalizationService");

const plaidClient = createPlaidClient();

/**
 * Syncs transactions for a specific connection.
 *
 * Fetches all new/modified/removed transactions since the last cursor,
 * normalizes them, and ingests into the store.
 *
 * @param {string} connectionId - The connection to sync
 * @returns {Promise<object>} Sync summary with counts
 */
async function syncConnection(connectionId) {
  const accessToken = getAccessToken(connectionId);
  if (!accessToken) {
    throw new Error(`Connection ${connectionId} not found or revoked`);
  }

  let cursor = getSyncCursor(connectionId);
  let allAdded = [];
  let allModified = [];
  let allRemoved = [];
  let hasMore = true;

  // Paginate through all available updates
  while (hasMore) {
    const request = {
      access_token: accessToken,
      options: {
        include_personal_finance_category: true,
      },
    };

    // Only include cursor if we have one (null = initial full sync)
    if (cursor) {
      request.cursor = cursor;
    }

    const response = await plaidClient.transactionsSync(request);
    const data = response.data;

    allAdded.push(...data.added);
    allModified.push(...data.modified);
    allRemoved.push(...data.removed);

    hasMore = data.has_more;
    cursor = data.next_cursor;
  }

  // Ingest all results into the store with currency conversion
  const baseCurrency = getUserBaseCurrency(connectionId);
  const summary = await ingestSyncResults(connectionId, {
    added: allAdded,
    modified: allModified,
    removed: allRemoved,
  }, baseCurrency);

  // Persist the cursor for next incremental sync
  setSyncCursor(connectionId, cursor);

  return {
    connectionId,
    ...summary,
    totalStored: getTransactionsByConnection(connectionId).length,
    syncedAt: new Date().toISOString(),
  };
}

/**
 * Syncs transactions for ALL active connections.
 *
 * Used by the daily background sync job. Processes each connection
 * independently so a failure in one doesn't block others.
 *
 * @param {Array<string>} connectionIds - IDs of active connections
 * @returns {Promise<object>} Aggregate sync results
 */
async function syncAllConnections(connectionIds) {
  const results = [];
  const errors = [];

  for (const connectionId of connectionIds) {
    try {
      const result = await syncConnection(connectionId);
      results.push(result);
    } catch (error) {
      console.error(
        `[Sync] Failed for connection ${connectionId}:`,
        error.message
      );
      errors.push({ connectionId, error: error.message });
    }
  }

  return {
    synced: results.length,
    failed: errors.length,
    results,
    errors,
    completedAt: new Date().toISOString(),
  };
}

/**
 * Formats stored transactions into the shape expected by
 * the iOS client's Transaction model.
 *
 * Uses the normalization service's formatForClient to ensure
 * enriched data (canonical merchant, confidence scores, recurring)
 * is properly exposed.
 *
 * @param {string|null} connectionId - Filter by connection, or null for all
 * @returns {Array} Client-ready transaction objects
 */
function getClientTransactions(connectionId) {
  const txs = connectionId
    ? getTransactionsByConnection(connectionId)
    : getAllTransactions();

  return txs
    .filter((tx) => !tx.pending) // Exclude pending transactions
    .map((tx) => formatForClient(tx));
}

/**
 * Returns the current recurring / subscription analysis.
 * Used by subscription dashboards and savings intelligence.
 *
 * @returns {Array} Recurring merchant analysis results
 */
function getSubscriptionAnalysis() {
  return getRecurringAnalysis();
}

module.exports = {
  syncConnection,
  syncAllConnections,
  getClientTransactions,
  getSubscriptionAnalysis,
};

