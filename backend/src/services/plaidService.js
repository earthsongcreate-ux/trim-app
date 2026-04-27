/**
 * Plaid Service
 *
 * Business logic layer for Plaid API interactions.
 * Wraps the Plaid SDK client and provides clean interfaces for:
 * - Creating link_tokens for client-side Link sessions
 * - Exchanging public_tokens for access_tokens
 * - Fetching account metadata
 *
 * This service is the ONLY layer that handles plaintext access_tokens.
 * Tokens are encrypted before reaching the storage layer.
 */

const { createPlaidClient } = require("../config/plaid");
const {
  storeConnection,
  getAccessToken,
} = require("./connectionStore");
const { Products, CountryCode } = require("plaid");

const plaidClient = createPlaidClient();

/**
 * Creates a link_token for a client-side Plaid Link session.
 *
 * The link_token is short-lived and single-use. It configures which
 * Plaid products and countries are available in the Link flow.
 *
 * @param {string} userId - The app's internal user identifier
 * @returns {Promise<string>} The link_token for the client
 */
async function createLinkToken(userId) {
  const response = await plaidClient.linkTokenCreate({
    user: { client_user_id: userId },
    client_name: "Trim",
    products: [Products.Transactions],
    country_codes: [CountryCode.Us],
    language: "en",
  });

  return response.data.link_token;
}

/**
 * Exchanges a public_token for an access_token and stores the connection.
 *
 * Flow:
 * 1. Exchange public_token → access_token + item_id (Plaid API)
 * 2. Fetch account metadata for the connected item
 * 3. Fetch institution details for display
 * 4. Encrypt and store the access_token
 * 5. Return sanitized connection (no access_token)
 *
 * @param {string} publicToken - The single-use public_token from Plaid Link
 * @returns {Promise<object>} The stored connection metadata (sanitized)
 */
async function exchangePublicToken(publicToken) {
  // Step 1: Exchange public_token for access_token
  const exchangeResponse = await plaidClient.itemPublicTokenExchange({
    public_token: publicToken,
  });

  const accessToken = exchangeResponse.data.access_token;
  const itemId = exchangeResponse.data.item_id;

  // Step 2: Fetch linked accounts
  const accountsResponse = await plaidClient.accountsGet({
    access_token: accessToken,
  });

  const accounts = accountsResponse.data.accounts;
  const item = accountsResponse.data.item;

  // Step 3: Fetch institution details
  let institutionName = "Connected Bank";
  let institutionId = item.institution_id;

  if (institutionId) {
    try {
      const instResponse = await plaidClient.institutionsGetById({
        institution_id: institutionId,
        country_codes: [CountryCode.Us],
      });
      institutionName = instResponse.data.institution.name;
    } catch {
      // Non-critical — proceed with default name
    }
  }

  // Step 4: Store connection with encrypted access_token
  const connection = storeConnection({
    accessToken,
    itemId,
    institutionId,
    institutionName,
    accounts,
  });

  // Step 5: Trigger initial transaction sync (fire-and-forget)
  // Plaid may need a few seconds to prepare transactions for new items.
  // The sync will be retried on next daily sync if this initial attempt
  // returns empty results.
  const { syncConnection } = require("./transactionSyncService");
  syncConnection(connection.id).catch((err) => {
    console.error(
      `[Plaid] Initial sync for ${connection.id} deferred:`,
      err.message
    );
  });

  return connection;
}

/**
 * Fetches account balances for an existing connection.
 *
 * @param {string} connectionId - The stored connection ID
 * @returns {Promise<Array>} Array of account objects with balances
 */
async function getAccountBalances(connectionId) {
  const accessToken = getAccessToken(connectionId);
  if (!accessToken) {
    throw new Error("Connection not found or access revoked");
  }

  const response = await plaidClient.accountsBalanceGet({
    access_token: accessToken,
  });

  return response.data.accounts.map((account) => ({
    id: account.account_id,
    name: account.name,
    type: account.type,
    subtype: account.subtype,
    mask: account.mask,
    balances: {
      available: account.balances.available,
      current: account.balances.current,
      currency: account.balances.iso_currency_code,
    },
  }));
}

module.exports = {
  createLinkToken,
  exchangePublicToken,
  getAccountBalances,
};
