@autocomplete @mobile
Feature: City Autocomplete Suggestions
  As a mobile app user
  I want to see autocomplete suggestions as I type a city name
  So that I can quickly find and select my desired city

  Background:
    Given the app is installed and launched fresh on a mobile device
    And the user is on the Activity Ranking home screen
    And the device has an active internet connection

  # ─── Core Autocomplete Behaviour ────────────────────────────────────────────

  @smoke @TC-AC-01
  Scenario: Autocomplete suggestions appear dynamically after minimum characters
    When the user taps the city search input field
    And the user types "Lon"
    Then the autocomplete dropdown should be visible within 3 seconds
    And the suggestions list should contain "London, United Kingdom"
    And each suggestion should display a city name and country code

  @smoke @TC-AC-02
  Scenario: Suggestions refine progressively with additional characters
    When the user taps the city search input field
    And the user types "Lo"
    Then the autocomplete dropdown should display multiple suggestions
    When the user continues typing "ndo"
    Then the suggestions list should narrow down to fewer results
    And the top suggestion should be "London, United Kingdom"

  @smoke @TC-AC-03
  Scenario: Selecting a suggestion populates the input and triggers ranking
    When the user taps the city search input field
    And the user types "Par"
    Then the autocomplete dropdown displays suggestions including "Paris, France"
    When the user taps on the suggestion "Paris, France"
    Then the city search input should display "Paris, France"
    And the autocomplete dropdown should be dismissed
    And a loading indicator should appear confirming the 7-day ranking request was triggered

  @TC-AC-04
  Scenario: Suggestions disappear when the search input is cleared
    When the user taps the city search input field
    And the user types "Ber"
    Then the autocomplete dropdown is visible with suggestions
    When the user clears the search input field
    Then the autocomplete dropdown should not be visible
    And no activity ranking results should be displayed

  @TC-AC-05
  Scenario: Minimum 2-character threshold before suggestions appear
    When the user taps the city search input field
    And the user types "L"
    Then the autocomplete dropdown should NOT be visible
    When the user types one more character making the input "Lo"
    Then the autocomplete dropdown should become visible with suggestions

  @TC-AC-06
  Scenario: No suggestions shown for unrecognised gibberish input
    When the user taps the city search input field
    And the user types "xzqwk"
    Then the autocomplete dropdown should display a "No results found" message
    And no suggestion items should be listed

  @TC-AC-11
  Scenario: Rapid typing does not produce stale or duplicate suggestions
    When the user taps the city search input field
    And the user rapidly types "San Francisco"
    Then the autocomplete dropdown should display suggestions matching "San Francisco"
    And no duplicate suggestions should appear in the list
    And no stale suggestions from intermediate keystrokes should be visible

  # ─── Performance ─────────────────────────────────────────────────────────────

  @performance @TC-AC-PERF
  Scenario: Autocomplete suggestions appear within 500ms of the last keystroke
    When the user taps the city search input field
    And the user types "New"
    Then autocomplete suggestions should appear within 500 milliseconds of the last keystroke

  # ─── Platform-Specific: Android ──────────────────────────────────────────────

  @android @TC-AC-07
  Scenario: Android – soft keyboard does not obscure autocomplete suggestions
    When the user taps the city search input field
    Then the Android soft keyboard should be visible
    And the autocomplete dropdown should remain fully visible above the keyboard
    When the user types "Tok"
    Then the suggestions should be scrollable if they exceed the visible area

  @android @TC-AC-08
  Scenario: Android – hardware Back button dismisses autocomplete and keyboard
    When the user taps the city search input field
    And the user types "Syd"
    And the autocomplete dropdown is visible with suggestions
    When the user presses the Android hardware Back button
    Then the autocomplete dropdown should be dismissed
    And the soft keyboard should be dismissed
    And the user should remain on the Activity Ranking home screen

  # ─── Platform-Specific: iOS ──────────────────────────────────────────────────

  @ios @TC-AC-09
  Scenario: iOS – keyboard Done button dismisses keyboard but retains typed input
    When the user taps the city search input field
    And the user types "Dub"
    And the autocomplete dropdown is visible with suggestions
    When the user taps the "Done" button on the iOS keyboard toolbar
    Then the iOS keyboard should be dismissed
    And the search input should still contain "Dub"
    And the autocomplete dropdown should remain visible with the previous suggestions

  @ios @TC-AC-10
  Scenario: iOS – tapping outside the input field dismisses the keyboard
    When the user taps the city search input field
    And the user types "Mu"
    When the user taps outside the search input area
    Then the iOS keyboard should be dismissed
    And the autocomplete dropdown should also be dismissed
