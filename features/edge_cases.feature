@edge-cases @mobile
Feature: Edge Cases and Error Handling
  As a mobile app user
  I want the app to handle unexpected situations gracefully
  So that I have a reliable experience even under adverse conditions

  Background:
    Given the app is installed and launched fresh on a mobile device
    And the user is on the Activity Ranking home screen

  # ─── Network Errors ───────────────────────────────────────────────────────────

  @TC-EC-01
  Scenario: No internet connection – autocomplete shows offline error
    Given the device has no internet connection (Airplane Mode ON)
    When the user taps the city search input field
    And the user types "London"
    Then an error message indicating no internet connection should be visible
    And the autocomplete dropdown should not display any suggestions

  @TC-EC-02
  Scenario: Network lost mid-load shows error with a Retry button that recovers
    Given the device has an active internet connection
    When the user searches for and selects "Paris, France"
    And the device loses internet connection before the results finish loading
    Then the loading indicator should disappear
    And a network error message should be displayed
    And a "Retry" button should be visible
    When the device internet connection is restored
    And the user taps the "Retry" button
    Then the activity ranking results should load successfully

  @TC-EC-03
  Scenario: Timeout on autocomplete request shows a user-friendly message
    Given the device is on an extremely slow or throttled network
    When the user taps the city search input field
    And the user types "Tok"
    Then either a loading spinner should appear inside the autocomplete area
    Or a "Request timed out. Please try again." message should be displayed

  @TC-EC-04
  Scenario: Timeout on ranking results request shows error with Retry
    Given the device is on an extremely slow or throttled network
    When the user searches for and selects "Berlin, Germany"
    Then a loading indicator should be displayed
    And after a reasonable timeout period a timeout error message should appear
    And a "Retry" button should be visible

  # ─── Input Edge Cases ─────────────────────────────────────────────────────────

  @TC-EC-05
  Scenario: Accented and special characters are handled correctly
    When the user taps the city search input field
    And the user types "São Paulo"
    Then the autocomplete dropdown should display suggestions for "São Paulo"
    And the app should not crash or display a rendering error

  @TC-EC-06
  Scenario: Non-Latin (Unicode) characters do not crash the app
    When the user taps the city search input field
    And the user types "東京"
    Then the app should remain stable and not crash
    And the autocomplete area should either show suggestions or a "No results found" message

  @TC-EC-07
  Scenario: Extremely long input is truncated gracefully
    When the user taps the city search input field
    And the user pastes or types a string of 200 characters
    Then the input field should truncate or cap the entry without crashing
    And the app should remain fully responsive

  @TC-EC-08
  Scenario: SQL injection string is handled safely with no crash or data exposure
    When the user taps the city search input field
    And the user types "'; DROP TABLE cities; --"
    Then the autocomplete dropdown should display "No results found"
    And the app should not crash or expose any raw error or database detail

  @TC-EC-09
  Scenario: XSS script injection string is rendered as plain text only
    When the user taps the city search input field
    And the user types "<script>alert('xss')</script>"
    Then the autocomplete dropdown should display "No results found"
    And no JavaScript alert should be triggered
    And no HTML should be rendered from the input string

  # ─── API Error States ─────────────────────────────────────────────────────────

  @TC-EC-10
  Scenario: Open-Meteo API 5xx error shows a friendly error message
    Given the Open-Meteo API is returning a 500 Internal Server Error
    When the user searches for and selects "Vienna, Austria"
    Then the app should display a user-friendly error message
    And a "Retry" button should be visible
    And no raw API error details or stack trace should be shown to the user

  @TC-EC-11
  Scenario: Incomplete API response shows partial results with fallback text
    Given the Open-Meteo API returns weather data with some missing fields
    When the user searches for and selects that city
    Then activities with sufficient data should display valid rankings
    And activities with missing data should show "Data unavailable" as the reasoning
    And the app should not crash

  # ─── Device and Orientation ───────────────────────────────────────────────────

  @TC-EC-12
  Scenario: Screen rotation from portrait to landscape preserves ranking results
    When the user searches for and selects "Sydney, Australia"
    And the activity ranking results are displayed
    When the device is rotated from portrait to landscape orientation
    Then the activity ranking results should remain fully visible
    And the layout should adapt correctly to landscape
    And no data should be lost or reset during the rotation

  # ─── App Lifecycle ────────────────────────────────────────────────────────────

  @TC-EC-13
  Scenario: App backgrounded briefly and resumed shows cached results intact
    When the user searches for and selects "Nairobi, Kenya"
    And the activity ranking results are displayed
    When the user sends the app to the background by pressing the Home button
    And the user returns to the app within 30 seconds
    Then the activity ranking results should still be visible
    And the app should not show a blank screen or crash

  @TC-EC-14
  Scenario: App backgrounded for 5+ minutes prompts a refresh or shows cached results
    When the user searches for and selects "Lagos, Nigeria"
    And the activity ranking results are displayed
    When the user sends the app to the background for more than 5 minutes
    And the user returns to the app
    Then the app should either display the previously cached results
    Or display a prompt asking the user to refresh the data
    And the app should not crash

  # ─── Accessibility ────────────────────────────────────────────────────────────

  @accessibility @TC-EC-15
  Scenario: Screen reader announces autocomplete suggestions correctly
    Given the device accessibility screen reader is enabled
    When the user taps the city search input field
    And the user types "New"
    Then each autocomplete suggestion should be focusable and announceable by the screen reader
    And the user should be able to navigate and select a suggestion using accessibility gestures

  @accessibility @TC-EC-16
  Scenario: Screen reader can traverse all ranking result fields
    Given the device accessibility screen reader is enabled
    When the user searches for and selects "Rome, Italy"
    And the activity ranking results are displayed
    Then the screen reader should be able to announce the date, activity name, rank, and reasoning for each day card

  # ─── Boundary Conditions ─────────────────────────────────────────────────────

  @TC-EC-17
  Scenario: City near International Date Line shows correct non-duplicated dates
    When the user searches for and selects "Auckland, New Zealand"
    And the activity ranking results are displayed
    Then exactly 7 day cards should be displayed
    And no date should appear more than once in the results list
    And no date should be skipped in the 7-day sequence
