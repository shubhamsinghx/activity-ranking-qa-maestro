/**
 * validate_rank_range.js
 *
 * Maestro runScript helper used by TC-AR-04.
 *
 * Purpose:
 *   Reads the text content of all elements with accessibility ID "activity-rank"
 *   currently visible on screen and asserts that every value is an integer
 *   in the range [1, 10] inclusive.
 *
 * How it works in Maestro:
 *   When Maestro executes a runScript file, it provides a `maestro` object
 *   that can interact with the running app's element tree.
 *   - maestro.elementByIdList("activity-rank") returns an array of element
 *     descriptor objects, each with a `.text` property.
 *   - Setting output.assertions lets Maestro surface pass/fail per item
 *     in the test report.
 *
 * Expected element format:
 *   The rank label is expected to display the numeric value only, e.g. "7"
 *   OR in a labelled format such as "Rank: 7".
 *   The regex below handles both.
 */

const rankElements = maestro.elementByIdList('activity-rank');

const assertions = [];
let allPassed = true;

rankElements.forEach(function (el, index) {
  const rawText = (el.text || '').trim();

  // Extract the numeric part – handles "7", "Rank: 7", "7/10", etc.
  const match = rawText.match(/\d+/);
  if (!match) {
    assertions.push({
      status: 'FAILED',
      message: 'Element ' + index + ' has no numeric rank value. Raw text: "' + rawText + '"',
    });
    allPassed = false;
    return;
  }

  const rankValue = parseInt(match[0], 10);

  if (rankValue >= 1 && rankValue <= 10) {
    assertions.push({
      status: 'PASSED',
      message: 'Element ' + index + ' rank = ' + rankValue + ' (valid 1–10)',
    });
  } else {
    assertions.push({
      status: 'FAILED',
      message:
        'Element ' + index + ' rank = ' + rankValue + ' is OUTSIDE valid range [1, 10]. Raw text: "' + rawText + '"',
    });
    allPassed = false;
  }
});

// If no rank elements were found at all, fail the script
if (rankElements.length === 0) {
  assertions.push({
    status: 'FAILED',
    message: 'No elements with id "activity-rank" were found on screen.',
  });
  allPassed = false;
}

// Surface results in Maestro test report
output.assertions = assertions;
output.allPassed = allPassed;
output.totalChecked = rankElements.length;
