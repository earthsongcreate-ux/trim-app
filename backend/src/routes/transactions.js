/**
 * Transaction Routes — Thin Controller Layer
 *
 * Handles HTTP request/response for transaction sync and retrieval.
 * All business logic delegated to transactionSyncService.
 *
 * Endpoints:
 *   POST /api/transactions/sync/:connectionId  — Trigger sync for a connection
 *   POST /api/transactions/sync-all            — Trigger sync for all connections
 *   GET  /api/transactions                     — Get all transactions
 *   GET  /api/transactions/:connectionId       — Get transactions for a connection
 */

const express = require("express");
const router = express.Router();
const {
  syncConnection,
  syncAllConnections,
  getClientTransactions,
  getSubscriptionAnalysis,
} = require("../services/transactionSyncService");
const { getAllConnections } = require("../services/connectionStore");
const { getDictionaryStats } = require("../services/merchantMappingSystem");
const { getCategories } = require("../services/categoryClassificationEngine");

/**
 * POST /api/transactions/sync/:connectionId
 *
 * Triggers an incremental transaction sync for a specific connection.
 * On first call (no cursor), performs a full initial sync.
 *
 * Response: { success, sync: { addedCount, modifiedCount, removedCount, totalStored } }
 */
router.post("/sync/:connectionId", async (req, res) => {
  try {
    const { connectionId } = req.params;

    if (!connectionId) {
      return res.status(400).json({
        success: false,
        error: "connectionId is required",
      });
    }

    const result = await syncConnection(connectionId);

    res.json({
      success: true,
      sync: result,
    });
  } catch (error) {
    console.error("[Transactions] Sync failed:", error.message);

    if (error.message.includes("not found")) {
      return res.status(404).json({
        success: false,
        error: "Connection not found",
      });
    }

    res.status(500).json({
      success: false,
      error: "Transaction sync failed",
    });
  }
});

/**
 * POST /api/transactions/sync-all
 *
 * Triggers sync for all active connections.
 * Used by the daily background job or manual full-sync.
 *
 * Response: { success, results: { synced, failed, results, errors } }
 */
router.post("/sync-all", async (req, res) => {
  try {
    const connections = getAllConnections();
    const activeIds = connections
      .filter((c) => c.status === "active")
      .map((c) => c.id);

    if (activeIds.length === 0) {
      return res.json({
        success: true,
        results: { synced: 0, failed: 0, results: [], errors: [] },
      });
    }

    const results = await syncAllConnections(activeIds);

    res.json({
      success: true,
      results,
    });
  } catch (error) {
    console.error("[Transactions] Sync-all failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Batch sync failed",
    });
  }
});

/**
 * GET /api/transactions
 *
 * Returns all synced transactions across all connections.
 * Formatted for the iOS client's Transaction model.
 *
 * Response: { success, transactions: [...], count }
 */
router.get("/", async (req, res) => {
  try {
    const transactions = getClientTransactions(null);

    res.json({
      success: true,
      transactions,
      count: transactions.length,
    });
  } catch (error) {
    console.error("[Transactions] Fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to fetch transactions",
    });
  }
});

/**
 * GET /api/transactions/:connectionId
 *
 * Returns transactions for a specific connection.
 *
 * Response: { success, transactions: [...], count }
 */
router.get("/:connectionId", async (req, res) => {
  try {
    const transactions = getClientTransactions(req.params.connectionId);

    res.json({
      success: true,
      transactions,
      count: transactions.length,
    });
  } catch (error) {
    console.error("[Transactions] Fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to fetch transactions",
    });
  }
});

/**
 * GET /api/transactions/subscriptions/analysis
 *
 * Returns the current recurring / subscription detection analysis.
 * Powers the Savings Dashboard and subscription management UI.
 *
 * Response: { success, subscriptions: [...], count }
 */
router.get("/subscriptions/analysis", async (req, res) => {
  try {
    const subscriptions = getSubscriptionAnalysis();

    res.json({
      success: true,
      subscriptions,
      count: subscriptions.length,
    });
  } catch (error) {
    console.error("[Transactions] Subscription analysis failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve subscription analysis",
    });
  }
});

/**
 * GET /api/transactions/meta/categories
 *
 * Returns all valid Trim transaction categories.
 * Used by the client for filter/sort UI.
 *
 * Response: { success, categories: [...] }
 */
router.get("/meta/categories", async (req, res) => {
  res.json({
    success: true,
    categories: getCategories(),
  });
});

/**
 * GET /api/transactions/meta/normalization-stats
 *
 * Returns normalization system health stats.
 * Useful for monitoring and debugging.
 *
 * Response: { success, stats: { merchants, aliases } }
 */
router.get("/meta/normalization-stats", async (req, res) => {
  res.json({
    success: true,
    stats: getDictionaryStats(),
  });
});

module.exports = router;
