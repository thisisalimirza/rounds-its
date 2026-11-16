# Server-driven announcements, config, and What's New

This iOS branch does **not** create these tables. The web migration owns the
schema. The names below are the contract the app was built against. If a
column moves, change `AnnouncementContract`, `AppConfigParser`, or
`ChangelogContract` — those are the only mappings.

Do not apply a competing migration from this repo.

## `player_announcements`

| Column | Type |
| --- | --- |
| title, body | text |
| cta_label, cta_url | text, nullable |
| starts_at, ends_at | timestamptz |
| priority | int |
| min_app_version, max_app_version | text |
| kind | `banner` \| `in_app` \| `modal` |
| surfaces | text[] (`landing`, `player_web`, `ios`, `android`) |
| pages | text[] (web only) |
| dismissible | bool |
| status | `draft` \| `scheduled` \| `live` \| `ended` |
| audience | jsonb `{ segment: all\|signed_out\|free\|pro\|school, school_ids, roles }` |

Clients do not select this table. They call:

```sql
get_active_announcements(p_surface text, p_platform text, p_app_version text)
```

The server resolves the audience from `auth.uid()`. `anon` and `authenticated`
can execute it. iOS passes `p_surface = 'ios'`, `p_platform = 'ios'`,
`p_app_version = CFBundleShortVersionString`.

Dismissals are remembered on the device and inserted into
`player_announcement_events` (`announcement_id`, `event` = view | click | dismiss,
`platform`).

## `app_config`

`key text primary key`, `value jsonb`. `anon` and `authenticated` can select.

Keys the app reads:

- `maintenance_mode` — boolean. An object `{ "enabled", "message" }` is still accepted.
- `maintenance_message` — string, shown with the boolean. A non-empty string wins over a message inside the object.
- `signups_paused` — bool
- `ios_purchases_enabled` — bool. Missing means App Store purchases stay on.
- `paywall_enabled` and `checkout_enabled` are web-only. iOS does not read them. `checkout_enabled = false` is how the web sends players to the iOS app.
- `min_supported_version` — `{ "ios": "1.5", "android": "..." }` or a bare string
- `recommended_version` — same shape
- `enable_*` / `flag_*` — bool feature flags

iOS flags wired to cards that are still "coming soon" until the mode exists:

- `enable_rapid_fire`
- `enable_lab_values`
- `enable_image_rounds`
- `enable_high_yield_playbooks`

The account-gate keys (`account_gate_enabled`, `anon_free_cases`,
`grandfathered_gate_enabled`) are parsed by the same file so the sync PR and
this PR share one parser. The gate UI itself is in the sync PR.

Missing table: the app keeps compiled defaults and the last disk cache.

## `changelog_entries`

`version` is `text not null default ''`, plus `title`, `body`, and
`published_at`. Public read exists only after web PR 200. A failed select
falls back to the disk cache, then the compiled `AppChangelog`. Empty
versions are skipped. The query is `order by published_at desc`.
