/**
 * Plaid Routes — Thin Controller Layer
 *
 * Handles HTTP request/response for Plaid-related endpoints.
 * All business logic is delegated to plaidService.
 *
 * Endpoints:
 *   POST /api/plaid/create-link-token   — Generate a link_token for client
 *   POST /api/plaid/exchange-token      — Exchange public_token for connection
 *   GET  /api/plaid/connections         — List all connected accounts
 *   GET  /api/plaid/connections/:id/balances — Fetch balances for a connection
 */

const express = require("express");
const router = express.Router();
const plaidService = require("../services/plaidService");
const connectionStore = require("../services/connectionStore");

/**
 * POST /api/plaid/create-link-token
 *
 * Creates a Plaid Link token for the client to initialize
 * the Link flow. The token is short-lived and single-use.
 *
 * Body: { userId: string }
 * Response: { linkToken: string }
 */
router.post("/create-link-token", async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: "userId is required",
      });
    }

    const linkToken = await plaidService.createLinkToken(userId);

    res.json({
      success: true,
      linkToken,
    });
  } catch (error) {
    console.error("[Plaid] Link token creation failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to create link token",
    });
  }
});

/**
 * POST /api/plaid/exchange-token
 *
 * Exchanges a public_token from Plaid Link for a permanent access_token.
 * The access_token is encrypted and stored — never returned to the client.
 *
 * Body: { publicToken: string }
 * Response: {
 *   success: true,
 *   connection: {
 *     id, itemId, institutionName, accounts, connectedAt, status
 *   }
 * }
 */
router.post("/exchange-token", async (req, res) => {
  try {
    const { publicToken } = req.body;

    if (!publicToken) {
      return res.status(400).json({
        success: false,
        error: "publicToken is required",
      });
    }

    const connection = await plaidService.exchangePublicToken(publicToken);

    res.json({
      success: true,
      connection,
    });
  } catch (error) {
    console.error("[Plaid] Token exchange failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to connect bank account",
    });
  }
});

/**
 * GET /api/plaid/connections
 *
 * Returns all connected bank accounts (sanitized — no access_tokens).
 *
 * Response: { success: true, connections: [...] }
 */
router.get("/connections", async (req, res) => {
  try {
    const connections = connectionStore.getAllConnections();

    res.json({
      success: true,
      connections,
    });
  } catch (error) {
    console.error("[Plaid] Connections fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to fetch connections",
    });
  }
});

/**
 * GET /api/plaid/connections/:id/balances
 *
 * Fetches real-time account balances for a specific connection.
 * The access_token is decrypted internally — never exposed.
 *
 * Response: { success: true, accounts: [...] }
 */
router.get("/connections/:id/balances", async (req, res) => {
  try {
    const accounts = await plaidService.getAccountBalances(req.params.id);

    res.json({
      success: true,
      accounts,
    });
  } catch (error) {
    console.error("[Plaid] Balance fetch failed:", error.message);

    if (error.message.includes("not found")) {
      return res.status(404).json({
        success: false,
        error: "Connection not found",
      });
    }

    res.status(500).json({
      success: false,
      error: "Failed to fetch balances",
    });
  }
});

/**
 * DELETE /api/plaid/connections/:id
 *
 * Revokes a bank connection and destroys the stored access_token.
 *
 * Response: { success: true }
 */
router.delete("/connections/:id", async (req, res) => {
  try {
    const revoked = connectionStore.revokeConnection(req.params.id);

    if (!revoked) {
      return res.status(404).json({
        success: false,
        error: "Connection not found",
      });
    }

    res.json({ success: true });
  } catch (error) {
    console.error("[Plaid] Connection revoke failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to revoke connection",
    });
  }
});

module.exports = router;
