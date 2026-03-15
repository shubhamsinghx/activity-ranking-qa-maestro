# Activity Ranking API – QA Test Suite (Maestro)

QA test suite for the **Activity Ranking** mobile feature. Users type a city name, pick from autocomplete suggestions, and receive a ranked list of 4 activities (Skiing, Surfing, Outdoor Sightseeing, Indoor Sightseeing) for the next 7 days, each with a 1–10 rank and weather-based reasoning powered by the [Open-Meteo API](https://open-meteo.com/).

---

## Why Maestro?

| Concern | Maestro approach |
|---------|-----------------|
| Cross-platform | Same YAML flows run on Android and iOS — no separate test suites |
| No server required | `maestro test` runs directly; no Appium server or `wdio.conf.js` to manage |
| Async UI | `extendedWaitUntil` polls instead of sleeping — no `sleep(3000)` hacks |
| Platform splits | `tags: [android]` / `tags: [ios]` + `--include-tags` to run selectively |
| Reuse | `runFlow` with `env:` variables lets subflows act as parameterised helpers |
| Screenshots | `takeScreenshot` baked into every flow for instant visual evidence |

---

## Repository Structure

```
activity-ranking-qa-maestro/
├── features/                          # BDD test criteria (Gherkin)
│   ├── autocomplete.feature           # 11 autocomplete scenarios
│   ├── activity_ranking.feature       # 10 ranking scenarios
│   └── edge_cases.feature             # 17 edge-case and error scenarios
│
├── flows/
│   ├── subflows/                      # Reusable helper flows
│   │   ├── 00_launch_app.yaml         # Cold-start + wait for home screen
│   │   ├── 00_search_and_select_city.yaml  # Parameterised search + select
│   │   └── 00_wait_for_results.yaml   # Wait for results container
│   │
│   ├── autocomplete/                  # 11 test flows  (TC-AC-01 … TC-AC-11)
│   ├── activity_ranking/              # 7  test flows  (TC-AR-01 … TC-AR-07)
│   └── edge_cases/                    # 7  test flows  (TC-EC-01 … TC-EC-07)
│
├── scripts/
│   ├── run_tests.sh                   # Convenience runner with suite selection
│   └── validate_rank_range.js         # JS helper: validates rank values 1–10
│
└── manual/
    └── manual_test_script.md          # 13-case manual test script
```

---

## Accessibility ID Map

Every Maestro locator maps to an accessibility ID your app must expose:

| Accessibility ID | Element |
|-----------------|---------|
| `city-search-input` | The city name text input field |
| `autocomplete-dropdown` | The dropdown container |
| `autocomplete-suggestion` | Shared ID on each suggestion row |
| `no-results-message` | "No results found" empty state |
| `error-message` | Any error banner/inline message |
| `retry-button` | The retry CTA on error states |
| `loading-indicator` | Spinner / progress bar during API fetch |
| `results-container` | The scrollable 7-day results list |
| `day-card` | Shared ID on each day row |
| `day-1-card` … `day-7-card` | Positional IDs for each of the 7 days |
| `day-date` | The date label within a day card |
| `activity-name` | Activity name label |
| `activity-rank` | Rank value label |
| `activity-reasoning` | Reasoning text label |

On **Android** these map to `contentDescription`.  
On **iOS** these map to `accessibilityIdentifier`.

---

## Test Flow Summary

### Autocomplete (`flows/autocomplete/`)

| ID | Test | Tags |
|----|------|------|
| TC-AC-01 | Suggestions appear after 2+ characters typed | smoke |
| TC-AC-02 | Suggestions refine progressively | smoke |
| TC-AC-03 | Tapping a suggestion populates input + triggers ranking | smoke |
| TC-AC-04 | Clearing input dismisses dropdown | — |
| TC-AC-05 | 1-character input does NOT show dropdown | — |
| TC-AC-06 | Gibberish → "No results found" empty state | — |
| TC-AC-07 | Android: keyboard does not obscure dropdown | android |
| TC-AC-08 | Android: Back button dismisses keyboard + dropdown | android |
| TC-AC-09 | iOS: Done button dismisses keyboard, retains input | ios |
| TC-AC-10 | iOS: Tap outside dismisses keyboard + dropdown | ios |
| TC-AC-11 | Rapid typing shows correct final suggestions only | — |

### Activity Ranking (`flows/activity_ranking/`)

| ID | Test | Tags |
|----|------|------|
| TC-AR-01 | Loading indicator then results visible | smoke |
| TC-AR-02 | All 4 required fields present per day card | smoke |
| TC-AR-03 | All 4 activities present on each day | smoke |
| TC-AR-04 | All rank values are 1–10 inclusive | — |
| TC-AR-05 | Exactly 7 consecutive day cards | — |
| TC-AR-06 | Full vertical scroll to Day 7 | — |
| TC-AR-07 | New city replaces old results completely | — |

### Edge Cases (`flows/edge_cases/`)

| ID | Test | Tags |
|----|------|------|
| TC-EC-01 | Airplane Mode → offline error shown | — |
| TC-EC-02 | Network cut mid-load → error + Retry → recovers | — |
| TC-EC-03 | Accented chars + Unicode handled without crash | — |
| TC-EC-04 | Long input + SQL injection + XSS all handled safely | — |
| TC-EC-05 | Screen rotation preserves results | — |
| TC-EC-06 | App backgrounded 10 s → resume shows results | — |
| TC-EC-07 | API 5xx → friendly error, no raw trace, Retry shown | — |

---

## Prerequisites

### 1. Install Maestro CLI

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

Verify:

```bash
maestro --version
```

### 2. Connect a device or start an emulator/simulator

**Android** – connect via ADB:
```bash
adb devices
```

**iOS** – start a simulator:
```bash
open -a Simulator
```

### 3. Install the app on the device

```bash
# Android
adb install path/to/activity-ranking.apk

# iOS (simulator)
xcrun simctl install booted path/to/ActivityRanking.app
```

---

## Running Tests

### Run everything

```bash
MAESTRO_APP_ID=com.example.activityranking ./scripts/run_tests.sh all
```

### Run smoke tests only (fast CI check)

```bash
MAESTRO_APP_ID=com.example.activityranking ./scripts/run_tests.sh smoke
```

### Run a specific suite

```bash
# Autocomplete flows
./scripts/run_tests.sh autocomplete

# Activity ranking flows
./scripts/run_tests.sh ranking

# Edge case flows
./scripts/run_tests.sh edge
```

### Run platform-specific tests

```bash
# Android-only flows (TC-AC-07, TC-AC-08)
./scripts/run_tests.sh android

# iOS-only flows (TC-AC-09, TC-AC-10)
MAESTRO_APP_ID=com.example.ActivityRanking ./scripts/run_tests.sh ios
```

### Run a single flow directly

```bash
maestro test flows/autocomplete/TC-AC-01_dynamic_suggestions.yaml
```

---

## Environment Variable Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `MAESTRO_APP_ID` | Android package name or iOS bundle ID | `com.example.activityranking` |

---

## Locator Strategy – Rationale

1. **Accessibility ID first** (`id:` in Maestro) — maps to `contentDescription` on Android and `accessibilityIdentifier` on iOS. Works on both platforms without forking.
2. **Text match second** (`text:`) — used for suggestion items and labels whose exact content is known (e.g. city names, activity names).
3. **Coordinate tap** (`point: "x%, y%"`) — only for the iOS "tap outside to dismiss" scenario where no interactive element exists at that location.
4. **XPath — never used** — brittle, slow, and platform-specific.

---

## Async Handling Strategy

| Situation | Maestro approach |
|-----------|-----------------|
| Autocomplete dropdown appearing | `extendedWaitUntil visible id:"autocomplete-dropdown" timeout:3000` |
| Results loading | `extendedWaitUntil notVisible id:"loading-indicator" timeout:15000` then `assertVisible id:"results-container"` |
| Keyboard animation | `waitForAnimationToEnd timeout:600-800` after every `tapOn` on a text field |
| Network cut + error state | `extendedWaitUntil notVisible id:"loading-indicator" timeout:20000` |
| Dropdown dismiss | `waitForAnimationToEnd timeout:500` after tapping a suggestion |

---

## Manual Tests

See [`manual/manual_test_script.md`](manual/manual_test_script.md) for 13 step-by-step test cases covering all scenarios including edge cases that require manual network manipulation (TC-08, TC-09) or a mock API server (TC-10).

---

## Tech Stack

| Component | Choice |
|-----------|--------|
| BDD Syntax | Gherkin (plain `.feature` files) |
| Automation Framework | **Maestro** |
| Locator strategy | Accessibility IDs + Text match |
| Platforms | Android (API 33+) and iOS (16+) |
| CI integration | `maestro test` is a single CLI command |
| Screenshots | Built-in `takeScreenshot` per flow |
