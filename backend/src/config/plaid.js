/**
 * Plaid Client Configuration
 *
 * Initializes the Plaid SDK with environment-specific settings.
 * All credentials are read from environment variables — never hardcoded.
 *
 * Environment mapping:
 *   PLAID_ENV=sandbox   → PlaidEnvironments.sandbox
 *   PLAID_ENV=production → PlaidEnvironments.production
 */

const { Configuration, PlaidApi, PlaidEnvironments } = require("plaid");

const PLAID_ENV_MAP = {
  sandbox: PlaidEnvironments.sandbox,
  development: PlaidEnvironments.development,
  production: PlaidEnvironments.production,
};

function createPlaidClient() {
  const clientId = process.env.PLAID_CLIENT_ID;
  const secret = process.env.PLAID_SECRET;
  const env = process.env.PLAID_ENV || "sandbox";

  if (!clientId || !secret) {
    throw new Error(
      "Missing PLAID_CLIENT_ID or PLAID_SECRET environment variables"
    );
  }

  const configuration = new Configuration({
    basePath: PLAID_ENV_MAP[env] || PlaidEnvironments.sandbox,
    baseOptions: {
      headers: {
        "PLAID-CLIENT-ID": clientId,
        "PLAID-SECRET": secret,
      },
    },
  });

  return new PlaidApi(configuration);
}

module.exports = { createPlaidClient };
