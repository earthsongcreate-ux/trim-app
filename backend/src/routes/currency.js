/**
 * Currency Routes — Thin Controller Layer
 *
 * Handles HTTP request/response for currency preferences and rates.
 *
 * Endpoints:
 *   GET  /api/currency/supported           — List all supported currencies
 *   GET  /api/currency/rate?from=X&to=Y    — Get current exchange rate
 *   GET  /api/currency/user/:userId        — Get user's base currency
 *   PUT  /api/currency/user/:userId        — Set user's base currency
 */

const express = require("express");
const router = express.Router();
const {
  getSupportedCurrencies,
  getExchangeRate,
  getUserBaseCurrency,
  setUserBaseCurrency,
  SUPPORTED_CURRENCIES,
} = require("../services/currencyService");

/**
 * GET /api/currency/supported
 *
 * Returns all supported currencies with metadata.
 *
 * Response: { success, currencies: [{ code, symbol, name, flag }] }
 */
router.get("/supported", (req, res) => {
  res.json({
    success: true,
    currencies: getSupportedCurrencies(),
  });
});

/**
 * GET /api/currency/rate
 *
 * Fetches the current exchange rate between two currencies.
 *
 * Query params: from (ISO code), to (ISO code)
 * Response: { success, from, to, rate }
 */
router.get("/rate", async (req, res) => {
  try {
    const { from, to } = req.query;

    if (!from || !to) {
      return res.status(400).json({
        success: false,
        error: "Both 'from' and 'to' query params are required",
      });
    }

    const fromUpper = from.toUpperCase();
    const toUpper = to.toUpperCase();

    if (!SUPPORTED_CURRENCIES[fromUpper] || !SUPPORTED_CURRENCIES[toUpper]) {
      return res.status(400).json({
        success: false,
        error: "Unsupported currency code",
      });
    }

    const rate = await getExchangeRate(fromUpper, toUpper);

    res.json({
      success: true,
      from: fromUpper,
      to: toUpper,
      rate,
    });
  } catch (error) {
    console.error("[Currency] Rate fetch failed:", error.message);
    res.status(500).json({
      success: false,
      error: "Failed to fetch exchange rate",
    });
  }
});

/**
 * GET /api/currency/user/:userId
 *
 * Returns the user's base currency setting.
 *
 * Response: { success, userId, baseCurrency, currencyInfo }
 */
router.get("/user/:userId", (req, res) => {
  const { userId } = req.params;
  const baseCurrency = getUserBaseCurrency(userId);
  const currencyInfo = SUPPORTED_CURRENCIES[baseCurrency];

  res.json({
    success: true,
    userId,
    baseCurrency,
    currencyInfo: {
      code: baseCurrency,
      ...currencyInfo,
    },
  });
});

/**
 * PUT /api/currency/user/:userId
 *
 * Sets the user's base currency. Called during onboarding
 * or from settings.
 *
 * Body: { currencyCode: "EUR" }
 * Response: { success, baseCurrency, currencyInfo }
 */
router.put("/user/:userId", (req, res) => {
  try {
    const { userId } = req.params;
    const { currencyCode } = req.body;

    if (!currencyCode) {
      return res.status(400).json({
        success: false,
        error: "currencyCode is required",
      });
    }

    setUserBaseCurrency(userId, currencyCode);
    const baseCurrency = getUserBaseCurrency(userId);
    const currencyInfo = SUPPORTED_CURRENCIES[baseCurrency];

    res.json({
      success: true,
      baseCurrency,
      currencyInfo: {
        code: baseCurrency,
        ...currencyInfo,
      },
    });
  } catch (error) {
    console.error("[Currency] Set base currency failed:", error.message);

    if (error.message.includes("Unsupported")) {
      return res.status(400).json({
        success: false,
        error: error.message,
      });
    }

    res.status(500).json({
      success: false,
      error: "Failed to set base currency",
    });
  }
});

module.exports = router;
