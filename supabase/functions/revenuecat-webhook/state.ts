// RevenueCat v2 lookup of a customer's current Pro state, as profile columns.
// Kept apart from index.ts so it can be tested without starting the server.

export type Status =
  | "free" | "active" | "trialing" | "grace_period"
  | "billing_issue" | "expired" | "paused";

const RC_API = "https://api.revenuecat.com/v2";
const RC_PROJECT = Deno.env.get("RC_PROJECT_ID") ?? "projcd18207a";
const RC_ENTITLEMENT_V2_ID = Deno.env.get("RC_ENTITLEMENT_V2_ID") ?? "entl3e2294d9c1";

export type MirrorPatch = {
  subscription_status: Status;
  subscription_will_renew: boolean | null;
  subscription_product_id: string | null;
  subscription_store: string | null;
  subscription_period_type: string | null;
  subscription_expires_at: string | null;
};

async function rcGet(path: string, key: string): Promise<any> {
  const res = await fetch(`${RC_API}/projects/${RC_PROJECT}${path}`, {
    headers: { Authorization: `Bearer ${key}` },
    signal: AbortSignal.timeout(8_000),
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`RevenueCat ${res.status} on ${path.split("?")[0]}`);
  return res.json();
}

/** The store's product identifier (e.g. "03"), which the web uses to spot lifetime. */
async function storeProductId(productId: string | null | undefined, key: string): Promise<string | null> {
  if (!productId) return null;
  try {
    const p = await rcGet(`/products/${encodeURIComponent(productId)}`, key);
    return p?.store_identifier ?? productId;
  } catch {
    return productId;
  }
}

/** What RevenueCat says this customer has right now, as profile columns. */
export async function currentState(userId: string, key: string): Promise<MirrorPatch | null> {
  const id = encodeURIComponent(userId);
  const customer = await rcGet(`/customers/${id}`, key);
  if (!customer) return null; // RevenueCat has never seen this user.

  const ent = (customer.active_entitlements?.items ?? [])
    .find((e: any) => e.entitlement_id === RC_ENTITLEMENT_V2_ID);

  if (!ent) {
    return {
      subscription_status: "expired",
      subscription_will_renew: false,
      subscription_product_id: null,
      subscription_store: null,
      subscription_period_type: null,
      subscription_expires_at: null,
    };
  }

  const expiresAt = ent.expires_at ? new Date(ent.expires_at).toISOString() : null;

  // Which purchase gives access: a live subscription first, then a one-time buy.
  // Production first; a TestFlight (sandbox) purchase is mirrored with store
  // "sandbox" so it grants Pro but never counts as paying.
  const live = (items: any[], ok: (x: any) => boolean) =>
    items.find((x) => ok(x) && x.environment === "production") ?? items.find(ok);
  const storeOf = (x: any) => (x.environment === "sandbox" ? "sandbox" : x.store ?? null);

  const subs = await rcGet(`/customers/${id}/subscriptions?limit=50`, key);
  const sub = live(subs?.items ?? [], (s: any) => s.gives_access);
  if (sub) {
    const status: Status = sub.status === "trialing"
      ? "trialing"
      // The entitlement is active, so billing retry still gives access.
      : sub.status === "in_grace_period" || sub.status === "in_billing_retry"
      ? "grace_period"
      : "active";
    return {
      subscription_status: status,
      subscription_will_renew: sub.auto_renewal_status === "will_renew",
      subscription_product_id: await storeProductId(sub.product_id, key),
      subscription_store: storeOf(sub),
      subscription_period_type: status === "trialing" ? "trial" : "normal",
      subscription_expires_at: expiresAt ?? sub.current_period_ends_at ?? null,
    };
  }

  const buys = await rcGet(`/customers/${id}/purchases?limit=50`, key);
  const buy = live(buys?.items ?? [], (p: any) => p.status === "owned");
  if (buy) {
    return {
      subscription_status: "active",
      subscription_will_renew: false,
      subscription_product_id: await storeProductId(buy.product_id, key),
      subscription_store: storeOf(buy),
      subscription_period_type: "normal",
      subscription_expires_at: null,
    };
  }

  // Active with no store purchase behind it: a grant made in RevenueCat.
  return {
    subscription_status: "active",
    subscription_will_renew: false,
    subscription_product_id: null,
    subscription_store: "promotional",
    subscription_period_type: "promotional",
    subscription_expires_at: expiresAt,
  };
}

