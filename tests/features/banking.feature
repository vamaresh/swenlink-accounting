Feature: Smart banking workspace
  As a user importing bank statements
  I want banking to skip duplicates, support search and reconcile transactions
  So that the bank tab becomes a helpful accounting workbench

  Scenario: Bank import skips duplicates and supports search
    Given I am in the demo workspace
    When I import a bank statement containing "BDD BANK FEE"
    And I import the same bank statement again
    Then the app should report duplicate bank transactions were skipped
    When I search banking transactions for "BDD BANK"
    Then the bank transaction "BDD BANK FEE" should be visible

  Scenario: Bank transaction detail remains readable in dark mode
    Given I am in the demo workspace
    When I open the "Banking" page
    And I open the transaction detail panel for "CURRYS BUSINESS"
    Then the transaction detail panel should be readable in dark mode

  Scenario: Suggested banking transaction can be reconciled
    Given I am in the demo workspace
    When I open the "Banking" page
    And I reconcile the suggested banking transaction
    Then the banking transaction should move to reconciled status
