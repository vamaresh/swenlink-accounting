Feature: Global theme, typography and controls
  As a user
  I want the whole app to share one consistent visual system
  So that dark mode, fonts and standard buttons remain readable everywhere

  Scenario: Settings saves global dark theme and font preference
    Given I am in the demo workspace
    When I save settings with dark theme and Space Grotesk font
    Then a settings success toast should appear
    And the UI should use the selected global font

  Scenario: Standard visible buttons have readable contrast
    Given I am in the demo workspace
    When I open the "Banking" page
    And I reconcile the suggested banking transaction
    Then standard buttons should have readable contrast
