import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  isAgentCustomerLookupEnabled,
  isAgentVoucherFeatureEnabled,
  verifyAgentToolAuth,
} from "./agent-auth.ts";

function createRequest(headers: HeadersInit = {}): Request {
  return new Request("https://example.com", { headers });
}

Deno.test("verifyAgentToolAuth returns true for matching x-agent-jwt", () => {
  Deno.env.set("AGENT_TOOL_TOKEN", "super-secret-token");
  const req = createRequest({ "x-agent-jwt": "super-secret-token" });
  assertEquals(verifyAgentToolAuth(req), true);
  Deno.env.delete("AGENT_TOOL_TOKEN");
});

Deno.test("verifyAgentToolAuth checks authorization bearer header", () => {
  Deno.env.set("AGENT_CORE_INTERNAL_TOKEN", "bearer-secret");
  const req = createRequest({ Authorization: "Bearer bearer-secret" });
  assertEquals(verifyAgentToolAuth(req), true);
  Deno.env.delete("AGENT_CORE_INTERNAL_TOKEN");
});

Deno.test("verifyAgentToolAuth fails when token missing", () => {
  Deno.env.set("AGENT_TOOL_TOKEN", "missing-secret");
  const req = createRequest();
  assertEquals(verifyAgentToolAuth(req), false);
  Deno.env.delete("AGENT_TOOL_TOKEN");
});

Deno.test("verifyAgentToolAuth fails when misconfigured", () => {
  const req = createRequest({ "x-agent-jwt": "any" });
  assertEquals(verifyAgentToolAuth(req), false);
});

Deno.test("isAgentVoucherFeatureEnabled parses truthy values", () => {
  Deno.env.set("FEATURE_AGENT_VOUCHERS", "true");
  assertEquals(isAgentVoucherFeatureEnabled(), true);
  Deno.env.set("FEATURE_AGENT_VOUCHERS", "0");
  assertEquals(isAgentVoucherFeatureEnabled(), false);
  Deno.env.delete("FEATURE_AGENT_VOUCHERS");
});

Deno.test("isAgentCustomerLookupEnabled falls back to vouchers flag", () => {
  Deno.env.set("FEATURE_AGENT_VOUCHERS", "1");
  assertEquals(isAgentCustomerLookupEnabled(), true);
  Deno.env.set("FEATURE_AGENT_CUSTOMER_LOOKUP", "false");
  assertEquals(isAgentCustomerLookupEnabled(), false);
  Deno.env.delete("FEATURE_AGENT_CUSTOMER_LOOKUP");
  Deno.env.delete("FEATURE_AGENT_VOUCHERS");
});
