# Manual Test Script – Activity Ranking API (Mobile)

**Feature:** Activity Ranking API – City-Based Weather Forecast with Autocomplete  
**Prepared by:** Shubham Singh  
**Date:** 2026-03-15  
**Platforms:** Android 13+, iOS 16+  
**Automation counterpart:** Maestro flows in `/flows/`

---

## General Preconditions (apply to all test cases)

1. The Activity Ranking app is installed on a **real device** (preferred over emulator/simulator for realistic keyboard, network, and lifecycle behaviour).
2. The device has a **stable Wi-Fi** or 4G/5G connection unless the test explicitly requires offline.
3. OS version is at or above minimum supported: **Android 13 / iOS 16**.
4. App is launched via a **cold start** — not restored from background — unless the test specifies otherwise.
5. Device is in **portrait orientation** unless the test states otherwise.
6. Device language is set to **English**.
7. No VPN is active that could affect API routing.
8. Location permission is granted if the app requests it.

---

## TC-01 – Autocomplete Suggestions Appear Dynamically While Typing

**Objective:** Verify that autocomplete suggestions display and refine as the user types.  
**Gherkin ref:** TC-AC-01, TC-AC-02  
**Automation:** `flows/autocomplete/TC-AC-01_dynamic_suggestions.yaml`, `TC-AC-02_progressive_refinement.yaml`

**Preconditions:** General preconditions met.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Launch the app. Confirm the home screen loads. | Home screen visible. City search input field is present and empty. |
| 2 | Tap the city search input field. | Field gains focus. Soft keyboard appears. |
| 3 | Type a single character: **"L"** | No autocomplete dropdown appears. (Threshold check.) |
| 4 | Type a second character to form **"Lo"** | Autocomplete dropdown appears with multiple city suggestions. Each suggestion shows a city name and country. |
| 5 | Continue typing to form **"Lon"** | Suggestions narrow down. "London, United Kingdom" should be prominently listed. |
| 6 | Continue typing to form **"Londo"** | Suggestions narrow further. "London, United Kingdom" should be the top result. |
| 7 | Delete all characters using the backspace key. | Autocomplete dropdown disappears. No activity results are shown. |

**Platform-specific notes:**
- **Android:** Verify the autocomplete dropdown renders above the soft keyboard without being obscured. Scroll the dropdown if needed.
- **iOS:** Verify the keyboard toolbar "Done" button is visible and does not interfere with the dropdown.

**Edge cases to check within this test:**
- Type extremely quickly — suggestions should stabilise to the final query (no stale intermediate results).
- Type gibberish (e.g. "zzxqw") — "No results found" should appear; no crash.

---

## TC-02 – Selecting an Autocomplete Suggestion Triggers the 7-Day Ranking

**Objective:** Verify that tapping a suggestion populates the input and fires the ranking API request.  
**Gherkin ref:** TC-AC-03  
**Automation:** `flows/autocomplete/TC-AC-03_select_suggestion.yaml`

**Preconditions:** General preconditions met.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Tap the search input and type **"Par"**. | Autocomplete dropdown appears with suggestions including "Paris, France". |
| 2 | Tap on **"Paris, France"** in the dropdown. | The input field now shows "Paris, France". The dropdown closes. |
| 3 | Observe the screen immediately after the tap. | A loading indicator (spinner or skeleton) appears, confirming the ranking API call was triggered. |
| 4 | Wait up to 10 seconds for results to load on a good connection. | Loading indicator disappears. A list of activity rankings is displayed. |

**Platform-specific notes:**
- **Android:** Soft keyboard may remain open after suggestion tap. The loading indicator and results should still be visible.
- **iOS:** Keyboard typically auto-dismisses after suggestion selection.

---

## TC-03 – 7-Day Activity Ranking Results – Content Validation

**Objective:** Verify all required fields are present and correctly formatted for all 7 days.  
**Gherkin ref:** TC-AR-02, TC-AR-03, TC-AR-04, TC-AR-05  
**Automation:** `flows/activity_ranking/TC-AR-02_required_fields.yaml` through `TC-AR-05_seven_days_coverage.yaml`

**Preconditions:** TC-02 completed; results for "Paris, France" are on screen.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Observe the first visible day card at the top of the results. | A date label is shown in a human-readable format (e.g. "Mon, 16 Mar 2026"). |
| 2 | For the first day, count the activity entries. | Exactly **4 activities** listed: Skiing, Surfing, Outdoor Sightseeing, Indoor Sightseeing. |
| 3 | For each activity on Day 1, check the **Rank** value. | A numeric value between **1 and 10** inclusive (not 0, not 11, not a dash or blank). |
| 4 | For each activity on Day 1, check the **Reasoning** text. | A non-empty string referencing weather (e.g. "Clear skies & 22°C", "Heavy rain expected"). |
| 5 | Scroll down through the results. | All 7 days are reachable. The list ends after Day 7 — no Day 8. |
| 6 | Verify the 7-day date sequence. | Dates start from **tomorrow** and are consecutive with no gaps or duplicates. |
| 7 | Check any day mid-list (e.g. Day 4). | Same structure: 4 activities, rank, reasoning for each. |

**Edge cases to check within this test:**
- A rank showing as "0" or a value > 10 is a bug.
- A blank reasoning field is a bug.
- Days showing the same date twice, or a date being skipped, is a bug.

---

## TC-04 – Weather–Activity Correlation Sanity Check

**Objective:** Verify that activity rankings logically correlate with the weather forecast.  
**Gherkin ref:** TC-AR-WC-01, TC-AR-WC-02, TC-AR-WC-03

**Preconditions:** General preconditions met. Check real-world weather forecast for each test city before running.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Search for **"Lisbon, Portugal"** (during a sunny warm period). | Results load for 7 days. |
| 2 | On a day with clear skies and high temperature, check "Outdoor Sightseeing" rank. | Rank should be **7 or higher**. |
| 3 | On the same day, check "Indoor Sightseeing" rank. | Rank should be **lower** than Outdoor Sightseeing. |
| 4 | Search for **"Innsbruck, Austria"** (during snow season, e.g. December–February). | Results load. |
| 5 | On a snowy, sub-zero day, check "Skiing" rank. | Rank should be **8 or higher**. |
| 6 | On the same day, check "Surfing" rank. | Rank should be **3 or lower**. |
| 7 | Search for **"London, United Kingdom"** during a rainy period. | Results load. |
| 8 | On a rainy day, check "Indoor Sightseeing" rank. | Rank should be **7 or higher**. |
| 9 | Cross-reference reasoning text with rank values. | Reasoning should explain the rank (e.g. snow → Skiing 9/10, "Heavy snowfall & -5°C"). |

**Note:** This test is inherently dynamic — real weather changes. Document the actual forecast at the time of testing in your test report.

---

## TC-05 – Minimum Character Threshold

**Objective:** Confirm autocomplete does not trigger on a single character.  
**Gherkin ref:** TC-AC-05  
**Automation:** `flows/autocomplete/TC-AC-05_min_char_threshold.yaml`

**Preconditions:** General preconditions met.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Tap the search input and type **"L"**. | No autocomplete dropdown appears. Wait 2 seconds — it should still not appear. |
| 2 | Type one more character: **"o"** (total: "Lo"). | Autocomplete dropdown appears with suggestions. |
| 3 | Delete one character (back to **"L"**). | Autocomplete dropdown disappears immediately. |

---

## TC-06 – No Suggestions for Unrecognised Input

**Objective:** Verify graceful empty state for invalid city names.  
**Gherkin ref:** TC-AC-06  
**Automation:** `flows/autocomplete/TC-AC-06_no_results.yaml`

**Preconditions:** General preconditions met.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Type **"xzqwk"** in the search input. | A "No results found" (or equivalent empty state) message appears. No suggestion rows are shown. |
| 2 | Clear the input and type **"!!@@##"**. | Same empty state. App remains stable. |

---

## TC-07 – New City Replaces Previous Results

**Objective:** Confirm results are fully reset when a different city is searched.  
**Gherkin ref:** TC-AR-07  
**Automation:** `flows/activity_ranking/TC-AR-07_replace_city.yaml`

**Preconditions:** General preconditions met.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Search for and select **"Rome, Italy"**. Wait for results. | 7-day rankings for Rome are displayed. |
| 2 | Tap the search input field. | Input gains focus. |
| 3 | Clear the input field completely. | Dropdown dismisses. Previous results may still show momentarily. |
| 4 | Type **"Osl"** and select **"Oslo, Norway"**. | Loading indicator appears. |
| 5 | Wait for results to load. | Oslo, Norway results are displayed. **No trace of Rome, Italy** data remains on screen. |

---

## TC-08 – No Internet Connection

**Objective:** Verify the app handles offline state gracefully for autocomplete.  
**Gherkin ref:** TC-EC-01  
**Automation:** `flows/edge_cases/TC-EC-01_no_internet.yaml` (requires Airplane Mode access)

**Preconditions:** General preconditions met. Then **enable Airplane Mode** before starting.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Enable **Airplane Mode** on the device. | Device is offline. |
| 2 | Launch the app (cold start). | App opens. Home screen is visible. |
| 3 | Tap the search input and type **"London"**. | An error message is displayed (e.g. "No internet connection" or "You are offline"). No autocomplete dropdown appears. |
| 4 | Attempt to type more characters. | Behaviour remains the same — no suggestions, error stays visible. |
| 5 | **Disable Airplane Mode** (restore internet). | |
| 6 | Clear the search input and type **"Lon"** again. | Autocomplete dropdown now appears normally with suggestions. |

---

## TC-09 – Network Loss During Results Loading

**Objective:** Verify error recovery when the network drops mid-request.  
**Gherkin ref:** TC-EC-02  
**Automation:** `flows/edge_cases/TC-EC-02_network_loss_retry.yaml`

**Preconditions:** General preconditions met.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Search for and select **"Berlin, Germany"**. | Loading indicator appears. |
| 2 | **Immediately** enable Airplane Mode while the loading indicator is visible. | The loading indicator disappears after a short time. A network error message appears (e.g. "Unable to load results" or "Network error"). A **Retry** button is visible. |
| 3 | **Disable Airplane Mode** (restore internet). | |
| 4 | Tap the **Retry** button. | Loading indicator reappears briefly. Results load successfully. |

**Tip:** Step 2 requires quick action. Have Airplane Mode one swipe away before tapping the city suggestion.

---

## TC-10 – API Server Error (5xx)

**Objective:** Verify the app shows a user-friendly message (not a raw stack trace) when the API fails.  
**Gherkin ref:** TC-EC-10  
**Automation:** `flows/edge_cases/TC-EC-07_api_error.yaml` (requires mock server setup)

**Preconditions:** A test build or staging environment configured to return HTTP 500 from the Open-Meteo ranking endpoint.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Search for and select any city (e.g. **"Vienna, Austria"**). | Loading indicator appears. |
| 2 | Wait for the response. | Loading indicator disappears. A user-friendly error message is shown (e.g. "Something went wrong. Please try again."). |
| 3 | Check the error message carefully. | The message does **NOT** contain: raw HTTP status codes ("500"), "Internal Server Error", stack traces, or JSON error bodies. |
| 4 | A **Retry** button should be visible. | Tapping Retry re-fires the request. |

---

## TC-11 – Screen Rotation

**Objective:** Verify orientation change does not lose or corrupt ranking data.  
**Gherkin ref:** TC-EC-12  
**Automation:** `flows/edge_cases/TC-EC-05_screen_rotation.yaml`

**Preconditions:** TC-02 completed; results for a city are visible. Auto-rotate is enabled on the device.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | With results displayed in **portrait**, rotate the device to **landscape**. | Layout reflows. All 7-day ranking content remains visible and correctly laid out. No blank areas or clipped text. |
| 2 | Scroll through results in landscape mode. | All 7 days are accessible. Scrolling works correctly. |
| 3 | Rotate back to **portrait**. | Layout returns to portrait. All data is still present. |
| 4 | Verify no loading indicator appeared during either rotation. | The app should NOT re-fetch data on rotation (use the cached/rendered state). |

---

## TC-12 – App Background and Resume

**Objective:** Verify the app recovers cleanly from being backgrounded.  
**Gherkin ref:** TC-EC-13, TC-EC-14  
**Automation:** `flows/edge_cases/TC-EC-06_app_background.yaml`

**Preconditions:** TC-02 completed; ranking results are visible on screen.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Press the **Home** button to send the app to background. | App is minimised. |
| 2 | Wait **10 seconds**, then reopen via the task switcher. | App resumes. Ranking results are still displayed (no blank screen, no crash). |
| 3 | Press Home again. Wait **5 minutes or more**. Reopen. | App either shows previously loaded results (cached) OR prompts the user to refresh. The app does NOT crash. |

---

## TC-13 – Special Characters and Non-Latin Input

**Objective:** Verify input handling for accented and Unicode city names.  
**Gherkin ref:** TC-EC-05, TC-EC-06  
**Automation:** `flows/edge_cases/TC-EC-03_special_characters.yaml`

**Preconditions:** General preconditions met.

| # | Step | Expected Result |
|---|------|-----------------|
| 1 | Type **"São Paulo"** (with the accented ã). | Autocomplete handles the input; suggestions for "São Paulo, Brazil" appear if available. No crash or garbled text. |
| 2 | Clear the input. Type **"東京"** (Japanese characters for Tokyo). | App remains stable. Either suggestions appear or a "No results found" message shows. App does NOT crash or freeze. |
| 3 | Clear the input. Type **"'; DROP TABLE cities; --"** | "No results found" or empty state. App does NOT crash, show DB errors, or expose internal error details. |

---

## Edge Cases Summary (Additional Checks)

| Edge Case | Expected Behaviour | Priority |
|-----------|-------------------|----------|
| Airplane Mode enabled before opening app | Full offline experience; graceful error on first use | High |
| Very slow connection (throttled to 2G) | Loading spinners shown; eventual timeout with Retry option | High |
| City near International Date Line (Auckland, NZ) | 7 correct dates shown; no duplicate or skipped dates | Medium |
| Selecting city immediately after previous results | Previous results cleared atomically; no flicker of old data | High |
| Typing in the search field while results are already showing | Results remain until a new city is selected | Medium |
| Screen reader (TalkBack / VoiceOver) enabled | All autocomplete suggestions and result fields are announced | Medium |
| Device with very small screen (< 5") | No content clipped; horizontal scrolling not required | Low |
| Dark mode enabled | All text, icons, and rank values remain readable | Low |
