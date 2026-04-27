/**
 * Connection Storage
 *
 * Handles secure persistence of Plaid bank connections.
 *
 * Current implementation: In-memory store (development/prototype).
 * Production: Replace with database (PostgreSQL recommended per project rules).
 *
 * Storage schema per connection:
 * {
 *   id:                 string   — Unique connection ID
 *   itemId:             string   — Plaid item_id (safe to store plaintext)
 *   accessToken:        string   — Encrypted access_token (AES-256)
 *   institutionId:      string   — Plaid institution_id
 *   institutionName:    string   — Human-readable institution name
 *   accounts:           array    — Linked account metadata
 *   connectedAt:        string   — ISO 8601 timestamp
 *   status:             string   — 'active' | 'error' | 'revoked'
 * }
 *
 * SECURITY:
 * - access_token is ALWAYS encrypted before storage
 * - access_token is NEVER returned to the client
 * - Only itemId + account metadata are exposed via API
 */

const { encrypt, decrypt } = require("./encryption");
const crypto = require("crypto");

// In-memory store — replace with database in production
const connections = new Map();

/**
 * Stores a new bank connection with encrypted access_token.
 *
 * @param {object} params
 * @param {string} params.accessToken - Plaintext access_token from Plaid
 * @param {string} params.itemId - Plaid item_id
 * @param {string} params.institutionId - Plaid institution_id
 * @param {string} params.institutionName - Institution display name
 * @param {Array}  params.accounts - Account metadata from Plaid
 * @returns {object} The stored connection (without access_token)
 */
function storeConnection({
  accessToken,
  itemId,
  institutionId,
  institutionName,
  accounts,
}) {
  const id = crypto.randomUUID();
  const encryptedToken = encrypt(accessToken);

  const connection = {
    id,
    itemId,
    accessToken: encryptedToken,
    institutionId: institutionId || null,
    institutionName: institutionName || "Unknown Institution",
    accounts: accounts.map((account) => ({
      id: account.id,
      name: account.name,
      mask: account.mask,
      type: account.type,
      subtype: account.subtype,
    })),
    connectedAt: new Date().toISOString(),
    status: "active",
  };

  connections.set(id, connection);

  // Return sanitized version — never expose access_token
  return sanitizeConnection(connection);
}

/**
 * Retrieves the decrypted access_token for a connection.
 * Used ONLY by internal services that need to call Plaid APIs.
 *
 * @param {string} connectionId - The connection ID
 * @returns {string|null} The decrypted access_token, or null if not found
 */
function getAccessToken(connectionId) {
  const connection = connections.get(connectionId);
  if (!connection) return null;
  return decrypt(connection.accessToken);
}

/**
 * Retrieves all connections for display (sanitized — no access_tokens).
 *
 * @returns {Array} Array of sanitized connection objects
 */
function getAllConnections() {
  return Array.from(connections.values()).map(sanitizeConnection);
}

/**
 * Retrieves a single connection by ID (sanitized).
 *
 * @param {string} connectionId
 * @returns {object|null}
 */
function getConnection(connectionId) {
  const connection = connections.get(connectionId);
  if (!connection) return null;
  return sanitizeConnection(connection);
}

/**
 * Marks a connection as revoked (e.g., user disconnected).
 *
 * @param {string} connectionId
 * @returns {boolean} Whether the connection was found and updated
 */
function revokeConnection(connectionId) {
  const connection = connections.get(connectionId);
  if (!connection) return false;

  connection.status = "revoked";
  connection.accessToken = null; // Destroy encrypted token
  return true;
}

/**
 * Strips the access_token from a connection before returning to clients.
 * This is the ONLY format that should ever leave the backend.
 */
function sanitizeConnection(connection) {
  const { accessToken, ...safe } = connection;
  return safe;
}

module.exports = {
  storeConnection,
  getAccessToken,
  getAllConnections,
  getConnection,
  revokeConnection,
};
