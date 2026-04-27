/**
 * Trim Backend — Server Entry Point
 *
 * Configures Express with security middleware and mounts API routes.
 *
 * Security layers:
 * 1. Helmet — sets security headers (CSP, HSTS, etc.)
 * 2. CORS — restricts origins to allowed list
 * 3. Rate limiting — prevents abuse on sensitive endpoints
 * 4. JSON body parsing with size limit
 */

require("dotenv").config();

const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const plaidRoutes = require("./routes/plaid");
const transactionRoutes = require("./routes/transactions");
const currencyRoutes = require("./routes/currency");
const insightRoutes = require("./routes/insights");
const feedbackRoutes = require("./routes/feedback");
const healthScoreRoutes = require("./routes/healthScore");
const coachingRoutes = require("./routes/coaching");
const savingsRoutes = require("./routes/savings");
const engagementRoutes = require("./routes/engagement");
const paywallRoutes = require("./routes/paywall");

const app = express();
const PORT = process.env.PORT || 3001;

// --- Security Middleware ---

// Security headers
app.use(helmet());

// CORS — restrict to allowed origins
const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: allowedOrigins.length > 0 ? allowedOrigins : false,
    methods: ["GET", "POST", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Body parsing with size limit
app.use(express.json({ limit: "1mb" }));

// Rate limiting on Plaid endpoints (prevent token abuse)
const plaidLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // 30 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: "Too many requests. Please try again later.",
  },
});

// Transaction sync rate limiting (more generous — reads are cheaper)
const transactionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: "Too many requests. Please try again later.",
  },
});

// Currency rate limiting (moderate — external API calls)
const currencyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: "Too many requests. Please try again later.",
  },
});

// --- Routes ---

app.use("/api/plaid", plaidLimiter, plaidRoutes);
app.use("/api/transactions", transactionLimiter, transactionRoutes);
app.use("/api/currency", currencyLimiter, currencyRoutes);
app.use("/api/insights", currencyLimiter, insightRoutes);
app.use("/api/feedback", transactionLimiter, feedbackRoutes);
app.use("/api/health-score", transactionLimiter, healthScoreRoutes);
app.use("/api/coaching", transactionLimiter, coachingRoutes);
app.use("/api/savings", transactionLimiter, savingsRoutes);
app.use("/api/engagement", transactionLimiter, engagementRoutes);
app.use("/api/paywall", transactionLimiter, paywallRoutes);

// Health check
app.get("/api/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// --- Error Handling ---

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: "Endpoint not found",
  });
});

// Global error handler — never expose stack traces
app.use((err, req, res, _next) => {
  console.error("[Server] Unhandled error:", err.message);
  res.status(500).json({
    success: false,
    error: "Internal server error",
  });
});

// --- Start ---

app.listen(PORT, () => {
  console.log(`[Trim] Backend running on port ${PORT}`);
  console.log(`[Trim] Plaid environment: ${process.env.PLAID_ENV || "sandbox"}`);
});
