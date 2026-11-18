import { assertEquals } from "jsr:@std/assert@1";
import { currentState } from "./state.ts";

const ENT = "entl3e2294d9c1";
function mock(routes: Record<string, unknown>) {
  globalThis.fetch = ((url: string) => {
    const path = new URL(url).pathname.replace(/^\/v2\/projects\/[^/]+/, "");
    const body = routes[path];
    return Promise.resolve(body === undefined
      ? new Response("{}", { status: 404 })
      : new Response(JSON.stringify(body), { status: 200 }));
  }) as typeof fetch;
}
const U = "3e9a9e6a-b65e-4c49-90b7-e475c9d41ab7";
const C = `/customers/${U}`;

Deno.test("lifetime purchase → active, no expiry, app_store", async () => {
  mock({
    [C]: { active_entitlements: { items: [{ entitlement_id: ENT, expires_at: null }] } },
    [`${C}/subscriptions`]: { items: [] },
    [`${C}/purchases`]: { items: [{ status: "owned", environment: "production", store: "app_store", product_id: "prod3850592397" }] },
    ["/products/prod3850592397"]: { store_identifier: "03" },
  });
  const s = await currentState(U, "k");
  assertEquals(s?.subscription_status, "active");
  assertEquals(s?.subscription_store, "app_store");
  assertEquals(s?.subscription_product_id, "03");
  assertEquals(s?.subscription_expires_at, null);
});

Deno.test("no active entitlement → expired", async () => {
  mock({ [C]: { active_entitlements: { items: [] } } });
  assertEquals((await currentState(U, "k"))?.subscription_status, "expired");
});

Deno.test("unknown customer → null (no write)", async () => {
  mock({});
  assertEquals(await currentState(U, "k"), null);
});

Deno.test("trialing subscription", async () => {
  mock({
    [C]: { active_entitlements: { items: [{ entitlement_id: ENT, expires_at: "2026-12-01T00:00:00Z" }] } },
    [`${C}/subscriptions`]: { items: [{ gives_access: true, status: "trialing", environment: "production", store: "app_store", auto_renewal_status: "will_renew", product_id: "p" }] },
  });
  const s = await currentState(U, "k");
  assertEquals(s?.subscription_status, "trialing");
  assertEquals(s?.subscription_will_renew, true);
});

Deno.test("grant with no purchase → promotional", async () => {
  mock({
    [C]: { active_entitlements: { items: [{ entitlement_id: ENT, expires_at: "2076-01-01T00:00:00Z" }] } },
    [`${C}/subscriptions`]: { items: [] },
    [`${C}/purchases`]: { items: [] },
  });
  assertEquals((await currentState(U, "k"))?.subscription_store, "promotional");
});

Deno.test("sandbox-only purchase → store sandbox", async () => {
  mock({
    [C]: { active_entitlements: { items: [{ entitlement_id: ENT, expires_at: null }] } },
    [`${C}/subscriptions`]: { items: [] },
    [`${C}/purchases`]: { items: [{ status: "owned", environment: "sandbox", store: "app_store" }] },
  });
  assertEquals((await currentState(U, "k"))?.subscription_store, "sandbox");
});
