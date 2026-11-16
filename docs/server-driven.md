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

- `maintenance_mode` — bool, or `{ "enabled": true, "message": "..." }`
- `signups_paused` — bool
- `paywall_enabled` — bool
- `checkout_enabled` — bool
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

Not found in this repo. The adapter assumes `version`, `title`, `body`,
`published_at`. Confirm against the web `/whats-new` query and edit
`RemoteChangelog.swift` only. Offline with no cache uses the compiled
`AppChangelog`.
