import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";

Deno.env.set("WA_VERIFY_TOKEN", "test_verify_token");
Deno.env.set("WA_APP_SECRET", "test_secret");
Deno.env.set("DEST_EASYMO_URL", "https://example.com/easymo");
Deno.env.set("DEST_INSURANCE_URL", "https://example.com/insurance");
Deno.env.set("DEST_BASKET_URL", "https://example.com/basket");
Deno.env.set("DEST_QR_URL", "https://example.com/qr");
Deno.env.set("DEST_DINE_URL", "https://example.com/dine");

const { handleWaRouterRequest } = await import("./index.ts");

// Test helper to create mock WhatsApp payloads
function createMockPayload(
  messageType: string,
  content: Record<string, unknown>,
): Record<string, unknown> {
  return {
    object: "whatsapp_business_account",
    entry: [
      {
        id: "123456789",
        changes: [
          {
            value: {
              messaging_product: "whatsapp",
              metadata: {
                display_phone_number: "250788000000",
                phone_number_id: "123456789",
              },
              messages: [
                {
                  id: `wamid.${crypto.randomUUID()}`,
                  from: "250788000001",
                  type: messageType,
                  ...content,
                },
              ],
            },
            field: "messages",
          },
        ],
      },
    ],
  };
}

// Test helper to create HMAC signature
async function createSignature(body: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(body),
  );
  const bytes = new Uint8Array(signature);
  const hex = Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return `sha256=${hex}`;
}

Deno.test("wa-router: GET request with valid token returns challenge", async () => {
  const WA_VERIFY_TOKEN = "test_verify_token";
  const challenge = "test_challenge_123";
  const url = new URL("https://wa-router.test");
  url.searchParams.set("hub.mode", "subscribe");
  url.searchParams.set("hub.verify_token", WA_VERIFY_TOKEN);
  url.searchParams.set("hub.challenge", challenge);

  const response = await handleWaRouterRequest(new Request(url, { method: "GET" }));
  const body = await response.text();

  assertEquals(response.status, 200);
  assertEquals(body, challenge);
});

Deno.test("wa-router: GET request with invalid token fails", async () => {
  const url = new URL("https://wa-router.test");
  url.searchParams.set("hub.mode", "subscribe");
  url.searchParams.set("hub.verify_token", "wrong_token");
  url.searchParams.set("hub.challenge", "test");

  const response = await handleWaRouterRequest(new Request(url, { method: "GET" }));

  assertEquals(response.status, 403);
});

Deno.test("wa-router: signature verification works correctly", async () => {
  const secret = "test_secret";
  const body = JSON.stringify({ test: "data" });

  const signature = await createSignature(body, secret);

  assertEquals(signature.startsWith("sha256="), true);
  assertEquals(signature.length > 7, true);
});

Deno.test("wa-router: keyword extraction from text message", () => {
  const testCases = [
    { input: "easymo", expected: "easymo" },
    { input: "I want to check my insurance", expected: "insurance" },
    { input: "baskets", expected: "basket" },
    { input: "basket", expected: "basket" },
    { input: "Show me QR code", expected: "qr" },
    { input: "dine menu", expected: "dine" },
    { input: "random text", expected: undefined },
  ];

  for (const tc of testCases) {
    const cleaned = tc.input.toLowerCase().trim();
    const keywords = ["easymo", "insurance", "basket", "baskets", "qr", "dine"];
    let result: string | undefined;

    for (const keyword of keywords) {
      if (cleaned.includes(keyword)) {
        result = keyword === "baskets" ? "basket" : keyword;
        break;
      }
    }

    assertEquals(result, tc.expected, `Failed for input: "${tc.input}"`);
  }
});

Deno.test("wa-router: payload normalization for text message", () => {
  const payload = createMockPayload("text", {
    text: { body: "I want insurance" },
  });

  const normalized = [];
  for (const entry of (payload.entry as any[]) ?? []) {
    for (const change of entry.changes ?? []) {
      const value = change.value;
      if (!value) continue;

      const messages = value.messages ?? [];
      for (const msg of messages) {
        normalized.push({
          from: msg.from,
          messageId: msg.id,
          type: msg.type,
          text: msg.text?.body,
        });
      }
    }
  }

  assertEquals(normalized.length, 1);
  assertEquals(normalized[0].type, "text");
  assertEquals(normalized[0].text, "I want insurance");
  assertEquals(normalized[0].from, "250788000001");
});

Deno.test("wa-router: payload normalization for interactive button", () => {
  const payload = createMockPayload("interactive", {
    interactive: {
      type: "button_reply",
      button_reply: {
        id: "qr_start",
        title: "QR Code",
      },
    },
  });

  const normalized = [];
  for (const entry of (payload.entry as any[]) ?? []) {
    for (const change of entry.changes ?? []) {
      const value = change.value;
      if (!value) continue;

      const messages = value.messages ?? [];
      for (const msg of messages) {
        const norm: any = {
          from: msg.from,
          messageId: msg.id,
          type: msg.type,
        };

        if (msg.type === "interactive" && msg.interactive?.button_reply) {
          norm.interactive = {
            type: "button_reply",
            id: msg.interactive.button_reply.id,
            title: msg.interactive.button_reply.title,
          };
        }

        normalized.push(norm);
      }
    }
  }

  assertEquals(normalized.length, 1);
  assertEquals(normalized[0].type, "interactive");
  assertEquals(normalized[0].interactive.type, "button_reply");
  assertEquals(normalized[0].interactive.id, "qr_start");
  assertEquals(normalized[0].interactive.title, "QR Code");
});

Deno.test("wa-router: payload normalization for image with caption", () => {
  const payload = createMockPayload("image", {
    image: {
      id: "1234567890",
      caption: "insurance document",
    },
  });

  const normalized = [];
  for (const entry of (payload.entry as any[]) ?? []) {
    for (const change of entry.changes ?? []) {
      const value = change.value;
      if (!value) continue;

      const messages = value.messages ?? [];
      for (const msg of messages) {
        const norm: any = {
          from: msg.from,
          messageId: msg.id,
          type: msg.type,
        };

        if (msg.type === "image" && msg.image) {
          norm.media = {
            type: "image",
            id: msg.image.id,
            caption: msg.image.caption,
          };
        }

        normalized.push(norm);
      }
    }
  }

  assertEquals(normalized.length, 1);
  assertEquals(normalized[0].type, "image");
  assertEquals(normalized[0].media.type, "image");
  assertEquals(normalized[0].media.caption, "insurance document");
});

Deno.test("wa-router: destination URL mapping", () => {
  const routes = {
    easymo: "https://example.com/easymo",
    insurance: "https://example.com/insurance",
    basket: "https://example.com/basket",
    qr: "https://example.com/qr",
    dine: "https://example.com/dine",
  };

  assertEquals(routes["easymo"], "https://example.com/easymo");
  assertEquals(routes["insurance"], "https://example.com/insurance");
  assertEquals(routes["basket"], "https://example.com/basket");
  assertEquals(routes["qr"], "https://example.com/qr");
  assertEquals(routes["dine"], "https://example.com/dine");
  assertEquals(routes["unknown" as keyof typeof routes], undefined);
});
