Feature: Application navigation
  As a business user
  I want every page and section link to open correctly
  So that I can move around the accounting workspace with confidence

  Scenario: First-time visitor can preview the product
    Given I open the SwenBooks app
    Then I should see "SwenBooks"
    When I preview the logged-in workspace
    Then the "Swenlink Limited" heading should be visible
    And I should see "Swenlink Limited overview"

  Scenario: Primary navigation links open their pages
    Given I am in the demo workspace
    Then all primary navigation links should be usable

  Scenario: People page groups customers and suppliers as tabs
    Given I am in the demo workspace
    When I open the "People" page
    Then the "People" heading should be visible
    When I select the "Customers" section tab
    Then the "Customers" heading should be visible
    When I select the "Suppliers" section tab
    Then the "Suppliers" heading should be visible

  Scenario: Compliance page groups compliance tasks as tabs
    Given I am in the demo workspace
    When I open the "Compliance" page
    Then the "Compliance" heading should be visible
    When I select the "Key Dates" section tab
    Then I should see "Key Dates & Compliance"
    When I select the "Alerts" section tab
    Then I should see "S455 Tax Alerts"
    When I select the "VAT Returns" section tab
    Then the "VAT Returns" heading should be visible
    When I select the "DLA" section tab
    Then I should see "Director's Loan Account (DLA)"

  Scenario: Banking tabs open their functional sections
    Given I am in the demo workspace
    When I open the "Banking" page
    Then the "Bank Transactions" heading should be visible
    When I select the "Rules" section tab
    Then I should see "Categorization Rules"
    When I select the "Bank Accounts" section tab
    Then the "Bank Accounts" heading should be visible
    When I select the "Chart of Accounts" section tab
    Then the "Chart of Accounts" heading should be visible
