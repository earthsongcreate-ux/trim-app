/**
 * Encryption Service
 *
 * Provides AES-256 encryption for sensitive data at rest.
 * Used exclusively for encrypting Plaid access_tokens before storage.
 *
 * Security model:
 * - Uses AES-256 via crypto-js (symmetric encryption)
 * - Encryption key is read from ENCRYPTION_KEY env var
 * - Key must be a 256-bit hex string (64 hex chars)
 * - Never log or expose encrypted/decrypted values
 */

const CryptoJS = require("crypto-js");

function getEncryptionKey() {
  const key = process.env.ENCRYPTION_KEY;
  if (!key || key === "replace_with_a_secure_256_bit_hex_key") {
    throw new Error(
      "ENCRYPTION_KEY is not set or is using the default placeholder. " +
        "Generate a secure key: openssl rand -hex 32"
    );
  }
  return key;
}

/**
 * Encrypts a plaintext string using AES-256.
 *
 * @param {string} plaintext - The value to encrypt (e.g., access_token)
 * @returns {string} The encrypted ciphertext string
 */
function encrypt(plaintext) {
  const key = getEncryptionKey();
  return CryptoJS.AES.encrypt(plaintext, key).toString();
}

/**
 * Decrypts an AES-256 encrypted string back to plaintext.
 *
 * @param {string} ciphertext - The encrypted value to decrypt
 * @returns {string} The original plaintext value
 */
function decrypt(ciphertext) {
  const key = getEncryptionKey();
  const bytes = CryptoJS.AES.decrypt(ciphertext, key);
  return bytes.toString(CryptoJS.enc.Utf8);
}

module.exports = { encrypt, decrypt };
