/**
 * validate_rank_range.js
 *
 * Maestro runScript helper — DATA LAYER rank validation for TC-AR-04.
 *
 * -------------------------------------------------------------------------
 * WHY THIS EXISTS
 * -------------------------------------------------------------------------
 * The UI-layer assertions in TC-AR-04.yaml catch rank values that are
 * rendered out of range on screen. This script provides a SECOND,
 * independent validation layer by calling the ranking API directly and
 * checking every rank value in the raw JSON response — including values
 * for days that are scrolled off screen or truncated in the UI.
 *
 * -------------------------------------------------------------------------
 * MAESTRO JS RUNTIME — WHAT IS ACTUALLY AVAILABLE
 * -------------------------------------------------------------------------
 * Maestro’s runScript environment exposes:
 *   output   — set key/value pairs visible in the test report
 *   http     — http.get(url, headers?) / http.post(url, body, headers?)
 *   json     — json.parse(str) / json.stringify(obj)
 *   files    — file read/write helpers
 *   crypto   — hashing utilities
 *
 * It does NOT expose any element-querying API (no maestro.elementByIdList,
 * no DOM access). All element-level assertions must be done in YAML.
 *
 * -------------------------------------------------------------------------
 * CONFIGURATION
 * -------------------------------------------------------------------------
 * Set RANKING_API_URL and TEST_CITY via the env block in the calling flow:
 *
 *   - runScript:
 *       file: "../../scripts/validate_rank_range.js"
 *       env:
 *         RANKING_API_URL: ${RANKING_API_URL}
 *         TEST_CITY: "Denver"
 *
 * If RANKING_API_URL is not set the script logs a warning and exits cleanly
 * so that CI does not break while the API URL is being onboarded.
 *
 * -------------------------------------------------------------------------
 * EXPECTED API RESPONSE SHAPE
 * -------------------------------------------------------------------------
 * {
 *   "city": "Denver",
 *   "days": [
 *     {
 *       "date": "2026-03-16",
 *       "activities": [
 *         { "name": "Skiing",              "rank": 8, "reasoning": "..." },
 *         { "name": "Surfing",             "rank": 2, "reasoning": "..." },
 *         { "name": "Outdoor Sightseeing", "rank": 6, "reasoning": "..." },
 *         { "name": "Indoor Sightseeing",  "rank": 4, "reasoning": "..." }
 *       ]
 *     },
 *     ... (7 days total)
 *   ]
 * }
 */

var apiUrl    = output.RANKING_API_URL || '';
var testCity  = output.TEST_CITY       || 'Denver';

// ────────────────────────────────────────────────────────────────────────────
if (!apiUrl) {
  // Graceful skip — do not fail CI when the URL is not yet configured.
  // Replace this block with a hard failure once the API is always available.
  output.skipped = true;
  output.skipReason = 'RANKING_API_URL env var not set — skipping API layer validation';
  output.allPassed = true;   // non-blocking skip
  return;
}

// ────────────────────────────────────────────────────────────────────────────
// Call the ranking API
var fullUrl  = apiUrl + '?city=' + encodeURIComponent(testCity);
var response = http.get(fullUrl, { 'Accept': 'application/json' });

if (response.statusCode !== 200) {
  output.allPassed  = false;
  output.error      = 'API returned HTTP ' + response.statusCode + ' for city: ' + testCity;
  return;
}

var payload;
try {
  payload = json.parse(response.body);
} catch (e) {
  output.allPassed = false;
  output.error     = 'Failed to parse API response as JSON: ' + e.message;
  return;
}

if (!payload.days || !Array.isArray(payload.days)) {
  output.allPassed = false;
  output.error     = 'API response missing "days" array. Got: ' + json.stringify(payload);
  return;
}

// ────────────────────────────────────────────────────────────────────────────
// Validate every rank value in the full 7-day payload
var assertions   = [];
var allPassed    = true;
var totalChecked = 0;

var SUPPORTED_ACTIVITIES = ['Skiing', 'Surfing', 'Outdoor Sightseeing', 'Indoor Sightseeing'];

payload.days.forEach(function (day, dayIdx) {
  var dayLabel = 'Day ' + (dayIdx + 1) + ' (' + (day.date || 'unknown date') + ')';

  if (!day.activities || !Array.isArray(day.activities)) {
    assertions.push({
      status:  'FAILED',
      message: dayLabel + ': missing activities array',
    });
    allPassed = false;
    return;
  }

  // Check that all 4 supported activities are present
  var activityNames = day.activities.map(function (a) { return a.name; });
  SUPPORTED_ACTIVITIES.forEach(function (expected) {
    if (activityNames.indexOf(expected) === -1) {
      assertions.push({
        status:  'FAILED',
        message: dayLabel + ': missing activity "' + expected + '"',
      });
      allPassed = false;
    }
  });

  // Validate each rank value
  day.activities.forEach(function (activity) {
    totalChecked++;
    var rank = activity.rank;
    var label = dayLabel + ' / ' + activity.name;

    if (rank === null || rank === undefined) {
      assertions.push({ status: 'FAILED', message: label + ': rank is null/undefined' });
      allPassed = false;
      return;
    }

    if (typeof rank !== 'number' || !isFinite(rank)) {
      assertions.push({ status: 'FAILED', message: label + ': rank is not a finite number, got: ' + rank });
      allPassed = false;
      return;
    }

    if (rank !== Math.floor(rank)) {
      assertions.push({ status: 'FAILED', message: label + ': rank must be an integer, got: ' + rank });
      allPassed = false;
      return;
    }

    if (rank >= 1 && rank <= 10) {
      assertions.push({ status: 'PASSED', message: label + ': rank = ' + rank + ' ✓' });
    } else {
      assertions.push({
        status:  'FAILED',
        message: label + ': rank = ' + rank + ' is OUTSIDE [1, 10]',
      });
      allPassed = false;
    }
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Validate 7-day count
if (payload.days.length !== 7) {
  assertions.push({
    status:  'FAILED',
    message: 'Expected 7 days in response, got ' + payload.days.length,
  });
  allPassed = false;
}

// Surface all results
output.assertions    = assertions;
output.allPassed     = allPassed;
output.totalChecked  = totalChecked;
output.daysValidated = payload.days.length;
