Feature: Core accounting workflows
  As a director-led SME
  I want every major workspace area to support basic actions
  So that invoices, bills, expenses, people and accounts can be maintained

  Scenario: Customer records can be created and deleted
    Given I am in the demo workspace
    When I create and delete a customer named "BDD Customer Ltd"
    Then I should see "Deleted item from demo workspace."

  Scenario: Supplier records can be created and deleted
    Given I am in the demo workspace
    When I create and delete a supplier named "BDD Supplier Ltd"
    Then I should see "Deleted item from demo workspace."

  Scenario: Expense records can be created and deleted
    Given I am in the demo workspace
    When I create and delete an expense named "BDD office purchase"
    Then I should see "Deleted item from demo workspace."

  Scenario: Sales invoices can be created and deleted
    Given I am in the demo workspace
    When I create and delete a sales invoice numbered "BDD-INV-001"
    Then I should see "Deleted item from demo workspace."

  Scenario: Purchase bills can be created and deleted
    Given I am in the demo workspace
    When I create and delete a purchase bill numbered "BDD-BILL-001"
    Then I should see "Deleted item from demo workspace."

  Scenario: Chart of accounts records can be created and deleted
    Given I am in the demo workspace
    When I create and delete a chart account named "BDD Test Expense"
    Then I should see "Deleted item from demo workspace."

  Scenario: Bank accounts can be created and deleted
    Given I am in the demo workspace
    When I create and delete a bank account named "BDD Test Bank"
    Then I should see "Deleted item from demo workspace."
