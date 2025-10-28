/**
 * Security utilities for Supabase Edge Functions
 * 
 * Provides signature verification, secret management helpers,
 * and security best practices enforcement.
 * 
 * @see docs/GROUND_RULES.md for security guidelines
 */

import { logError } from "./observability.ts";

/**
 * Verify WhatsApp webhook signature using HMAC SHA-256
 * 
 * @param signature - Signature from x-hub-signature-256 header
 * @param rawBody - Raw request body (as string or Uint8Array)
 * @param secret - WhatsApp app secret
 * @returns true if signature is valid
 * @throws Error if signature is invalid or missing
 * 
 * @example
 * const signature = req.headers.get("x-hub-signature-256");
 * const rawBody = await req.text();
 * const isValid = await verifyWhatsAppSignature(
 *   signature,
 *   rawBody,
 *   Deno.env.get("WA_APP_SECRET")
 * );
 */
export async function verifyWhatsAppSignature(
  signature: string | null,
  rawBody: string | Uint8Array,
  secret: string,
): Promise<boolean> {
  if (!signature) {
    logError("signature_verification", "Missing x-hub-signature-256 header");
    throw new Error("missing_signature");
  }

  if (!secret) {
    logError("signature_verification", "WA_APP_SECRET not configured");
    throw new Error("secret_not_configured");
  }

  // Remove 'sha256=' prefix if present and normalize casing/whitespace
  const signatureValue = signature.replace(/^sha256=/, "").trim();
  const normalizedSignature = signatureValue.toLowerCase();

  // Convert body to Uint8Array if string
  const bodyBytes = typeof rawBody === "string"
    ? new TextEncoder().encode(rawBody)
    : rawBody;

  // Import secret as CryptoKey
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const key = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  // Compute HMAC
  const signatureBytes = await crypto.subtle.sign("HMAC", key, bodyBytes);
  const expectedSignature = Array.from(new Uint8Array(signatureBytes))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Constant-time comparison
  if (!constantTimeCompare(expectedSignature, normalizedSignature)) {
    logError("signature_verification", "Invalid signature", {
      providedLength: normalizedSignature.length,
      expectedLength: expectedSignature.length,
    });
    throw new Error("invalid_signature");
  }

  return true;
}

/**
 * Verify generic webhook HMAC signature
 * 
 * @param signature - Signature from header
 * @param rawBody - Raw request body
 * @param secret - Signing secret
 * @param algorithm - HMAC algorithm (default: SHA-256)
 * @returns true if signature is valid
 * 
 * @example
 * const signature = req.headers.get("x-signature");
 * await verifyHmacSignature(signature, rawBody, secret);
 */
export async function verifyHmacSignature(
  signature: string | null,
  rawBody: string | Uint8Array,
  secret: string,
  algorithm: "SHA-1" | "SHA-256" | "SHA-512" = "SHA-256",
): Promise<boolean> {
  if (!signature || !secret) {
    throw new Error("missing_signature_or_secret");
  }

  const bodyBytes = typeof rawBody === "string"
    ? new TextEncoder().encode(rawBody)
    : rawBody;

  const keyData = new TextEncoder().encode(secret);
  const key = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: algorithm },
    false,
    ["sign"],
  );

  const signatureBytes = await crypto.subtle.sign("HMAC", key, bodyBytes);
  const expectedSignature = Array.from(new Uint8Array(signatureBytes))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return constantTimeCompare(signature, expectedSignature);
}

/**
 * Constant-time string comparison to prevent timing attacks
 * 
 * @param a - First string
 * @param b - Second string
 * @returns true if strings are equal
 */
export function constantTimeCompare(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }

  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }

  return result === 0;
}

/**
 * Validate that required environment variables are set
 * 
 * @param vars - Array of environment variable names
 * @throws Error if any variable is missing
 * 
 * @example
 * validateRequiredEnvVars([
 *   "SUPABASE_SERVICE_ROLE_KEY",
 *   "WA_APP_SECRET",
 *   "ADMIN_TOKEN"
 * ]);
 */
export function validateRequiredEnvVars(vars: string[]): void {
  const missing: string[] = [];

  for (const varName of vars) {
    const value = Deno.env.get(varName);
    if (!value || value.trim().length === 0) {
      missing.push(varName);
    }
  }

  if (missing.length > 0) {
    const error = `Missing required environment variables: ${missing.join(", ")}`;
    logError("env_validation", error);
    throw new Error(error);
  }
}

/**
 * Check if an environment variable contains a placeholder value
 * 
 * @param varName - Environment variable name
 * @returns true if value is a placeholder
 * 
 * @example
 * if (isPlaceholderValue("ADMIN_TOKEN")) {
 *   console.warn("ADMIN_TOKEN is not configured");
 * }
 */
export function isPlaceholderValue(varName: string): boolean {
  const value = Deno.env.get(varName);
  if (!value) return true;

  const placeholderPatterns = [
    /^CHANGEME/i,
    /^TODO/i,
    /^REPLACE/i,
    /^PLACEHOLDER/i,
    /^YOUR_/i,
  ];

  return placeholderPatterns.some((pattern) => pattern.test(value));
}

/**
 * Sanitize error messages to prevent information leakage
 * 
 * @param error - Error object or message
 * @param genericMessage - Generic message to return (default: "internal_error")
 * @returns Sanitized error message safe for client
 * 
 * @example
 * try {
 *   await riskyOperation();
 * } catch (error) {
 *   const safeMessage = sanitizeErrorMessage(error);
 *   return json({ error: safeMessage }, 500);
 * }
 */
export function sanitizeErrorMessage(
  error: unknown,
  genericMessage = "internal_error",
): string {
  // In development, return full error
  if (Deno.env.get("APP_ENV") === "development") {
    return error instanceof Error ? error.message : String(error);
  }

  // In production, return generic message
  return genericMessage;
}

/**
 * Rate limiting helper using simple in-memory store
 * For production, use Redis or similar distributed store
 * 
 * @param key - Rate limit key (e.g., IP address, user ID)
 * @param maxRequests - Maximum requests allowed
 * @param windowMs - Time window in milliseconds
 * @returns true if rate limit exceeded
 */
const rateLimitStore = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(
  key: string,
  maxRequests: number,
  windowMs: number,
): boolean {
  const now = Date.now();
  const entry = rateLimitStore.get(key);

  if (!entry || entry.resetAt < now) {
    // New window
    rateLimitStore.set(key, { count: 1, resetAt: now + windowMs });
    return false;
  }

  if (entry.count >= maxRequests) {
    // Rate limit exceeded
    return true;
  }

  // Increment count
  entry.count++;
  return false;
}

/**
 * Clean up expired rate limit entries
 * Call periodically to prevent memory leaks
 */
export function cleanupRateLimitStore(): void {
  const now = Date.now();
  for (const [key, entry] of rateLimitStore.entries()) {
    if (entry.resetAt < now) {
      rateLimitStore.delete(key);
    }
  }
}

/**
 * Validate JWT token structure (without verification)
 * Useful for basic validation before costly verification
 * 
 * @param token - JWT token string
 * @returns true if token has valid structure
 */
export function isValidJwtStructure(token: string | null): boolean {
  if (!token) return false;
  const parts = token.split(".");
  return parts.length === 3;
}
