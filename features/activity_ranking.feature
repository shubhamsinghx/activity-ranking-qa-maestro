@activity-ranking @mobile
Feature: 7-Day Activity Ranking Results
  As a mobile app user
  I want to see a ranked list of activities for the next 7 days after selecting a city
  So that I can plan my trip based on weather-appropriate activities

  Background:
    Given the app is installed and launched fresh on a mobile device
    And the user is on the Activity Ranking home screen
    And the device has an active internet connection

  # ─── Core Ranking Behaviour ──────────────────────────────────────────────────

  @smoke @TC-AR-01
  Scenario: Loading indicator appears then results are displayed after city selection
    When the user searches for and selects "Zurich, Switzerland"
    Then a loading indicator should be displayed
    And the loading indicator should disappear once results are loaded
    And the activity ranking results container should be visible
    And at least one day card should be rendered

  @smoke @TC-AR-02
  Scenario: Each daily result contains all four required fields
    When the user searches for and selects "Barcelona, Spain"
    And the activity ranking results are displayed
    Then each day card should contain a date label in a human-readable format
    And each day card should contain an activity name
    And each day card should contain a rank value
    And each day card should contain a reasoning string referencing weather

  @smoke @TC-AR-03
  Scenario: All four supported activities are present for every day
    When the user searches for and selects "Tokyo, Japan"
    And the activity ranking results are displayed
    Then each day should include a ranking entry for "Skiing"
    And each day should include a ranking entry for "Surfing"
    And each day should include a ranking entry for "Outdoor Sightseeing"
    And each day should include a ranking entry for "Indoor Sightseeing"

  @TC-AR-04
  Scenario: All rank values fall within the valid range of 1 to 10
    When the user searches for and selects "Denver, USA"
    And the activity ranking results are displayed
    Then every visible rank value should be a number between 1 and 10 inclusive

  @TC-AR-05
  Scenario: Results cover exactly the next 7 consecutive calendar days
    When the user searches for and selects "Cape Town, South Africa"
    And the activity ranking results are displayed
    Then the results should begin from tomorrow's date
    And exactly 7 day cards should be visible across the results list
    And the dates should be in sequential chronological order with no gaps

  # ─── Weather–Activity Correlation ──────────────────────────────────────────────────────────
  # AUTOMATION STATUS: @manual-only (all three WC scenarios)
  #
  # Reason: These scenarios assert that specific rank THRESHOLDS are met based
  # on live weather data ("Given the weather shows snow and -5°C"). Because the
  # real Open-Meteo forecast changes daily, an automated assertion like
  # "Skiing rank >= 8" is non-deterministic — it may be true today and false
  # tomorrow with no code change.
  #
  # Proper automation path (future work):
  #   1. Build a mock weather API that returns controlled forecast payloads.
  #   2. Point the app at the mock server during test runs.
  #   3. Remove @manual-only and implement as Maestro flows using mock data.
  #
  # Until then, execute manually per TC-04 in manual_test_script.md,
  # checking actual forecast data at test execution time.

  @manual-only @TC-AR-WC-01
  Scenario: Clear warm weather elevates Outdoor Sightseeing and Surfing ranks
    Given the weather forecast for "Lisbon, Portugal" shows clear skies and above 20°C
    When the user searches for and selects "Lisbon, Portugal"
    And the activity ranking results are displayed for a clear warm day
    Then "Outdoor Sightseeing" rank should be 7 or higher on that day
    And "Surfing" rank should be 6 or higher on that day
    And "Indoor Sightseeing" should have a lower rank than "Outdoor Sightseeing"

  @manual-only @TC-AR-WC-02
  Scenario: Snowy sub-zero conditions push Skiing to the top rank
    Given the weather forecast for "Innsbruck, Austria" shows heavy snow and below 0°C
    When the user searches for and selects "Innsbruck, Austria"
    And the activity ranking results are displayed for a snowy cold day
    Then "Skiing" rank should be 8 or higher on that day
    And "Surfing" rank should be 3 or lower on that day

  @manual-only @TC-AR-WC-03
  Scenario: Rainy conditions push Indoor Sightseeing to the top
    Given the weather forecast for "London, United Kingdom" shows rain and around 10°C
    When the user searches for and selects "London, United Kingdom"
    And the activity ranking results are displayed for a rainy day
    Then "Indoor Sightseeing" rank should be 7 or higher on that day
    And "Outdoor Sightseeing" rank should be lower than "Indoor Sightseeing" on that day

  # ─── UI Interaction ───────────────────────────────────────────────────────────

  @TC-AR-06
  Scenario: User can scroll vertically through all 7 day cards
    When the user searches for and selects "Mumbai, India"
    And the activity ranking results are displayed
    Then the user should be able to scroll down through the results list
    And all 7 day cards should be reachable via scrolling

  @TC-AR-07
  Scenario: Searching for a new city replaces all previous ranking results
    When the user searches for and selects "Rome, Italy"
    And the activity ranking results are displayed
    When the user taps the city search input field and clears it
    And the user searches for and selects "Oslo, Norway"
    Then the activity ranking results should update and show data for "Oslo, Norway"
    And no content from "Rome, Italy" should remain visible on screen

  # ─── Data Source Integrity ────────────────────────────────────────────────────

  @TC-AR-API
  Scenario: Reasoning text references real weather indicators
    When the user searches for and selects "Berlin, Germany"
    And the activity ranking results are displayed
    Then at least one reasoning string should mention a weather term
    Such as "temperature", "rain", "snow", "wind", "cloud", "clear", or a degree symbol
