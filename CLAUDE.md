# Rounds — Claude Context

Rounds is an **iOS game for medical students** (USMLE Step 1 prep). It's a Wordle-style clinical case diagnosis game: progressive hints reveal details about a patient case, players guess the diagnosis.

## Quick Facts

- **Platform:** iOS 18+, SwiftUI, SwiftData, Swift 6
- **Monetization:** RevenueCat — entitlement `"Rounds Pro"` (monthly/yearly/lifetime)
- **Analytics:** PostHog via `AnalyticsManager.swift`
- **Version:** 1.3.0

## Gameplay

- 5 hints per case (each wrong guess reveals next hint)
- 5 guesses max
- Score: 500 − 100/guess − 50/extra hint (first hint free)
- **Daily Case** (date-seeded, same for all), **Random Case**, **Browse Cases**

## Key Files

| File | Role |
|------|------|
| `Rounds/CaseLibrary.swift` | ALL cases — hard-coded, 308KB, source of truth |
| `Rounds/GameModels.swift` | MedicalCase, GameSession, PlayerStats SwiftData models |
| `Rounds/DiagnosisRegistry.swift` | Alternative diagnosis name matching via slugs |
| `Rounds/ContentView.swift` | Home screen (Play / Progress / More tabs) |
| `Rounds/GameView.swift` | Core gameplay |
| `Rounds/SubscriptionManager.swift` | RevenueCat singleton |
| `Rounds/RoundsApp.swift` | App entry, seeding, schema migration |

## Critical Nuances

1. **Cases are hard-coded in CaseLibrary.swift** — not fetched from a server. Add/edit there only.
2. **MedicalCase UUIDs are deterministic** (SHA256 of diagnosis name) — stable across reinstalls.
3. **`gameStateRaw` is a String** on GameSession (not an enum) — required for CloudKit compat. Use the `gameState` computed property.
4. **TestFlight + DEBUG builds auto-grant Pro** — no sandbox purchase needed for beta.
5. **Streak freeze** only works if the user missed exactly 1 day (gap of 2 calendar days).
6. **DiagnosisRegistry** (slug-based) is the modern matching system; `alternativeNames` array is legacy fallback.
7. **Schema migration** is manual in `migrateIfNeeded()` — increment the migration key when changing SwiftData models.
8. **Store has a 3-step fallback** at launch: persistent → delete+retry → in-memory.

## Pro Features

- Streak Freeze (1/week, resets Monday)
- Global Leaderboard (school-based rankings)
- Gated via `SubscriptionManager.shared.hasProAccess()` or `ProFeatureGate`

## Deep Links

`rounds://case/{caseID}` — share specific cases with friends (handled in `DeepLinkManager`).
