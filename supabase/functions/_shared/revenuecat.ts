// Shared RevenueCat v2 reads and the profile mirror.
//
// The webhook and refresh-pro both recompute subscription_* from the live
// customer instead of trusting a single event. A refunded lifetime has no
// active entitlement, so the mirror becomes expired even if expires_at was null.

export const ENTITLEMENT_LOOKUP_DEFAULT = "Rounds Pro";

export type SubscriptionMirror = {
  subscription_status: string;
  subscription_will_renew: boolean;
  subscription_product_id: string | null;
  subscription_store: string | null;
  subscription_period_type: string | null;
  subscription_expires_at: string | null;
  has_pro: boolean;
};

export type RCConfig = {
  key: string;
  project: string;
  lookup: string;
  base: string;
  headers: Record<string, string>;
};

export function rcConfig(): RCConfig {
  const key = Deno.env.get("RC_SECRET_KEY");
  const project = Deno.env.get("RC_PROJECT_ID");
  if (!key || !project) {
    throw new Error("RC_SECRET_KEY or RC_PROJECT_ID is not set");
  }
  return {
    key,
    project,
    lookup: Deno.env.get("RC_ENTITLEMENT_ID") ?? ENTITLEMENT_LOOKUP_DEFAULT,
    base: `https://api.revenuecat.com/v2/projects/${project}`,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
  };
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuid(value: string): boolean {
  return UUID_RE.test(value);
}

async function rcGet(config: RCConfig, path: string): Promise<any> {
  const res = await fetch(`${config.base}${path}`, { headers: config.headers });
  if (res.status === 404) return null;
  if (!res.ok) {
    throw new Error(`rc ${path} ${res.status}: ${await res.text()}`);
  }
  return await res.json();
}

let entitlementIdCache: { lookup: string; id: string } | null = null;

export async function roundsProEntitlementId(config: RCConfig): Promise<string> {
  if (entitlementIdCache?.lookup === config.lookup) return entitlementIdCache.id;
  const list = await rcGet(config, "/entitlements");
  const found = (list?.items ?? []).find(
    (item: { lookup_key?: string; id?: string }) => item.lookup_key === config.lookup,
  );
  if (!found?.id) {
    throw new Error(`no entitlement with lookup_key ${config.lookup}`);
  }
  entitlementIdCache = { lookup: config.lookup, id: found.id };
  return found.id;
}

type ActiveEntitlement = { entitlement_id?: string; expires_at?: number | null };
type RCSubscription = {
  id?: string;
  product_id?: string | null;
  store?: string | null;
  status?: string | null;
  gives_access?: boolean;
  auto_renewal_status?: string | null;
  current_period_ends_at?: number | null;
  entitlement_ids?: string[] | null;
};
type RCPurchase = {
  product_id?: string | null;
  store?: string | null;
  status?: string | null;
  purchased_at?: number | null;
};

function pickPurchase(items: RCPurchase[]): RCPurchase | null {
  const open = items.filter((item) => (item.status ?? "owned").toLowerCase() !== "refunded");
  open.sort((a, b) => (b.purchased_at ?? 0) - (a.purchased_at ?? 0));
  return open.find((item) => (item.store ?? "").toLowerCase() !== "promotional") ?? open[0] ?? null;
}

export async function customerAccess(config: RCConfig, appUserId: string): Promise<{
  active: ActiveEntitlement | null;
  subscription: RCSubscription | null;
  purchase: RCPurchase | null;
  promotional: boolean;
}> {
  const entitlementId = await roundsProEntitlementId(config);
  const encoded = encodeURIComponent(appUserId);
  const [activeList, subscriptionList] = await Promise.all([
    rcGet(config, `/customers/${encoded}/active_entitlements`),
    rcGet(config, `/customers/${encoded}/subscriptions`),
  ]);
  const active = ((activeList?.items ?? []) as ActiveEntitlement[]).find(
    (item) => item.entitlement_id === entitlementId,
  ) ?? null;
  const subscriptions = (subscriptionList?.items ?? []) as RCSubscription[];
  const matching = subscriptions.find((item) =>
    (item.entitlement_ids ?? []).includes(entitlementId) && item.gives_access !== false
  ) ?? subscriptions.find((item) => item.gives_access) ?? null;
  let purchase: RCPurchase | null = null;
  if (!matching) {
    const purchaseList = await rcGet(config, `/customers/${encoded}/purchases`);
    purchase = pickPurchase((purchaseList?.items ?? []) as RCPurchase[]);
  }
  const store = (matching?.store ?? purchase?.store ?? "").toLowerCase();
  // A lifetime App Store purchase has no subscription. That is not a grant.
  // Promotional is only a purchase whose store is promotional, or an active
  // entitlement with neither a subscription nor a purchase.
  const promotional = active != null && (
    store === "promotional" || (matching == null && purchase == null)
  );
  return { active, subscription: matching, purchase, promotional };
}

function isoFromMillis(value: number | null | undefined): string | null {
  if (value == null) return null;
  return new Date(value).toISOString();
}

function storeName(
  active: ActiveEntitlement | null,
  subscription: RCSubscription | null,
  purchase: RCPurchase | null,
): string | null {
  const named = subscription?.store ?? purchase?.store ?? null;
  if (named) return named.toLowerCase();
  if (active && !subscription && !purchase) return "promotional";
  return null;
}

export function mirrorFromAccess(
  active: ActiveEntitlement | null,
  subscription: RCSubscription | null,
  purchase: RCPurchase | null = null,
  periodType: string | null = null,
): SubscriptionMirror {
  const period = periodType && periodType.trim() !== "" ? periodType : null;
  const productId = subscription?.product_id ?? purchase?.product_id ?? null;
  if (!active) {
    return {
      subscription_status: "expired",
      subscription_will_renew: false,
      subscription_product_id: productId,
      subscription_store: storeName(null, subscription, purchase),
      subscription_period_type: period,
      // A null expiry used to keep a refunded lifetime inside profile_has_pro.
      subscription_expires_at: new Date().toISOString(),
      has_pro: false,
    };
  }

  const statusRaw = (subscription?.status ?? "active").toLowerCase();
  let status = "active";
  if (statusRaw.includes("trial")) status = "trialing";
  else if (statusRaw.includes("grace")) status = "grace_period";
  else if (statusRaw.includes("billing") || statusRaw.includes("past_due")) status = "billing_issue";
  else if (statusRaw.includes("pause")) status = "paused";
  else if (statusRaw.includes("expir")) status = "expired";

  const willRenew = (subscription?.auto_renewal_status ?? "").toLowerCase() === "will_renew";
  const expires = isoFromMillis(active.expires_at ?? subscription?.current_period_ends_at);
  const live = status === "active" || status === "trialing" || status === "grace_period";
  return {
    subscription_status: status,
    subscription_will_renew: willRenew,
    subscription_product_id: productId,
    subscription_store: storeName(active, subscription, purchase),
    subscription_period_type: period,
    subscription_expires_at: expires,
    has_pro: live && (expires == null || new Date(expires).getTime() > Date.now()),
  };
}

export async function recomputeCustomer(
  config: RCConfig,
  appUserId: string,
  periodType: string | null = null,
): Promise<SubscriptionMirror> {
  const access = await customerAccess(config, appUserId);
  return mirrorFromAccess(access.active, access.subscription, access.purchase, periodType);
}

/// Read-only. Confirms RC_SECRET_KEY can GET active_entitlements and
/// subscriptions. Returns status codes and item counts, never the secret
/// and never a profile write.
export async function probeSecretReads(config: RCConfig, appUserId: string): Promise<{
  active_entitlements: { status: number; count: number | null };
  subscriptions: { status: number; count: number | null };
}> {
  async function hit(path: string): Promise<{ status: number; count: number | null }> {
    const res = await fetch(`${config.base}${path}`, { headers: config.headers });
    const text = await res.text();
    let count: number | null = null;
    if (res.ok) {
      try {
        const body = JSON.parse(text);
        count = Array.isArray(body.items) ? body.items.length : null;
      } catch {
        count = null;
      }
    }
    return { status: res.status, count };
  }
  const encoded = encodeURIComponent(appUserId);
  const [active_entitlements, subscriptions] = await Promise.all([
    hit(`/customers/${encoded}/active_entitlements`),
    hit(`/customers/${encoded}/subscriptions`),
  ]);
  return { active_entitlements, subscriptions };
}

export async function grantPromotional(
  config: RCConfig,
  appUserId: string,
  expiresAtMs: number,
): Promise<void> {
  const entitlementId = await roundsProEntitlementId(config);
  await fetch(`${config.base}/customers`, {
    method: "POST",
    headers: config.headers,
    body: JSON.stringify({ id: appUserId }),
  });
  const res = await fetch(
    `${config.base}/customers/${encodeURIComponent(appUserId)}/actions/grant_entitlement`,
    {
      method: "POST",
      headers: config.headers,
      body: JSON.stringify({ entitlement_id: entitlementId, expires_at: expiresAtMs }),
    },
  );
  if (!res.ok) throw new Error(`grant ${res.status}: ${await res.text()}`);
}

export async function revokePromotional(config: RCConfig, appUserId: string): Promise<void> {
  const entitlementId = await roundsProEntitlementId(config);
  const res = await fetch(
    `${config.base}/customers/${encodeURIComponent(appUserId)}/actions/revoke_granted_entitlement`,
    {
      method: "POST",
      headers: config.headers,
      body: JSON.stringify({ entitlement_id: entitlementId }),
    },
  );
  if (!res.ok && res.status !== 404) {
    throw new Error(`revoke ${res.status}: ${await res.text()}`);
  }
}

/// One page of customers. `cursor` is either a next_page URL or a customer id.
export async function listCustomers(config: RCConfig, cursor: string | null): Promise<{
  ids: string[];
  next: string | null;
}> {
  const url = cursor?.startsWith("http")
    ? cursor
    : `${config.base}/customers?limit=25${cursor ? `&starting_after=${encodeURIComponent(cursor)}` : ""}`;
  const res = await fetch(url, { headers: config.headers });
  if (!res.ok) throw new Error(`list customers ${res.status}: ${await res.text()}`);
  const body = await res.json();
  const items = (body.items ?? []) as { id?: string }[];
  const ids = items.map((item) => item.id).filter((id): id is string => typeof id === "string");
  const next = typeof body.next_page === "string"
    ? body.next_page
    : (ids.length === 25 ? ids[ids.length - 1] : null);
  return { ids, next };
}
