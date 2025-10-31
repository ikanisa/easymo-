import { constantTimeCompare } from "./security.ts";

const TRUE_VALUES = new Set(["1", "true", "yes", "on"]);
const FALSE_VALUES = new Set(["0", "false", "no", "off"]);
const TOKEN_HEADERS = ["x-agent-jwt", "x-internal-token", "x-api-key"];

function parseBooleanFlag(value: string | null | undefined, defaultValue = false): boolean {
  if (!value) return defaultValue;
  const normalized = value.toLowerCase().trim();
  if (TRUE_VALUES.has(normalized)) return true;
  if (FALSE_VALUES.has(normalized)) return false;
  return defaultValue;
}

function getConfiguredAgentToken(): string | null {
  const candidates = [
    Deno.env.get("AGENT_TOOL_TOKEN"),
    Deno.env.get("AGENT_CORE_INTERNAL_TOKEN"),
    Deno.env.get("AGENT_INTERNAL_TOKEN"),
    Deno.env.get("EASYMO_ADMIN_TOKEN"),
    Deno.env.get("ADMIN_TOKEN"),
  ];

  for (const token of candidates) {
    if (token && token.trim()) return token.trim();
  }

  return null;
}

function extractToken(req: Request): string | null {
  for (const header of TOKEN_HEADERS) {
    const value = req.headers.get(header);
    if (value && value.trim()) return value.trim();
  }

  const authorization = req.headers.get("authorization");
  if (!authorization) return null;

  const bearerMatch = authorization.match(/^Bearer\s+(.+)$/i);
  if (bearerMatch) {
    return bearerMatch[1].trim();
  }

  return authorization.trim() || null;
}

function maskToken(token: string): string {
  if (token.length <= 4) return "***";
  if (token.length <= 8) {
    return `${token.slice(0, 2)}***${token.slice(-2)}`;
  }
  return `${token.slice(0, 4)}***${token.slice(-4)}`;
}

export function verifyAgentToolAuth(
  req: Request,
  correlationId?: string,
): boolean {
  const expectedToken = getConfiguredAgentToken();

  if (!expectedToken) {
    console.error(
      JSON.stringify({
        event: "ai.agent.auth.misconfigured",
        correlation_id: correlationId,
        timestamp: new Date().toISOString(),
      }),
    );
    return false;
  }

  const providedToken = extractToken(req);
  if (!providedToken) {
    console.warn(
      JSON.stringify({
        event: "ai.agent.auth.missing_token",
        correlation_id: correlationId,
        timestamp: new Date().toISOString(),
      }),
    );
    return false;
  }

  const authorized = constantTimeCompare(providedToken, expectedToken);
  if (!authorized) {
    console.warn(
      JSON.stringify({
        event: "ai.agent.auth.invalid_token",
        correlation_id: correlationId,
        provided_length: providedToken.length,
        expected_length: expectedToken.length,
        timestamp: new Date().toISOString(),
      }),
    );
  }

  return authorized;
}

export function isAgentVoucherFeatureEnabled(): boolean {
  return parseBooleanFlag(Deno.env.get("FEATURE_AGENT_VOUCHERS"));
}

export function isAgentCustomerLookupEnabled(): boolean {
  const explicit = Deno.env.get("FEATURE_AGENT_CUSTOMER_LOOKUP");
  if (explicit && explicit.trim().length > 0) {
    return parseBooleanFlag(explicit);
  }
  return isAgentVoucherFeatureEnabled();
}

export function maskAgentTokenForLog(token: string | null): string | null {
  if (!token) return null;
  return maskToken(token);
}
