const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { expectSingle } = require('../support/world');

Given('I open the SwenBooks app', async function () {
  await this.openApp();
});

Given('I am in the demo workspace', async function () {
  await this.openApp();
  await this.enterDemoWorkspace();
});

When('I preview the logged-in workspace', async function () {
  await this.enterDemoWorkspace();
});

When('I open the {string} page', async function (pageName) {
  await this.openPage(pageName);
});

When('I select the {string} section tab', async function (tabName) {
  await this.openSectionTab(tabName);
});

Then('I should see {string}', async function (text) {
  await this.page.getByText(text, { exact: true }).waitFor();
});

Then('the {string} heading should be visible', async function (heading) {
  await this.page.getByRole('heading', { name: heading, exact: true }).waitFor();
});

Then('all primary navigation links should be usable', async function () {
  const navItems = [
    ['Dashboard', 'Swenlink Limited overview'],
    ['Reports', 'Reports'],
    ['Banking', 'Bank Transactions'],
    ['Sales Invoices', 'Sales Invoices'],
    ['Expenses', 'Expenses'],
    ['Purchase Bills', 'Purchase Bills'],
    ['People', 'People'],
    ['Compliance', 'Compliance'],
    ['Chart of Accounts', 'Chart of Accounts'],
    ['Settings', 'Profile & Compliance']
  ];

  for (const [buttonName, expectedText] of navItems) {
    await this.openPage(buttonName);
    const text = this.page.getByText(expectedText, { exact: false });
    const count = await text.count();
    assert.ok(count >= 1, `Expected to find "${expectedText}" after opening ${buttonName}`);
    await text.nth(0).waitFor();
  }
});

Then('the UI should use the selected global font', async function () {
  const family = await this.page.evaluate(() => getComputedStyle(document.body).fontFamily);
  assert.match(family.toLowerCase(), /inter|space grotesk|system-ui|apple-system|sans-serif/);
});

Then('standard buttons should have readable contrast', async function () {
  const buttonStyles = await this.page.evaluate(() => {
    const luminance = (rgb) => {
      const parts = rgb.match(/\d+/g)?.slice(0, 3).map(Number) || [0, 0, 0];
      const linear = parts.map(value => {
        const normalized = value / 255;
        return normalized <= 0.03928 ? normalized / 12.92 : Math.pow((normalized + 0.055) / 1.055, 2.4);
      });
      return (0.2126 * linear[0]) + (0.7152 * linear[1]) + (0.0722 * linear[2]);
    };
    const contrast = (foreground, background) => {
      const a = luminance(foreground);
      const b = luminance(background);
      const light = Math.max(a, b);
      const dark = Math.min(a, b);
      return (light + 0.05) / (dark + 0.05);
    };

    return [...document.querySelectorAll('button')]
      .filter(button => button.offsetParent !== null && button.textContent.trim())
      .slice(0, 30)
      .map(button => {
        const style = getComputedStyle(button);
        return {
          text: button.textContent.trim(),
          color: style.color,
          background: style.backgroundColor,
          ratio: contrast(style.color, style.backgroundColor)
        };
      });
  });

  const failures = buttonStyles.filter(button => button.background !== 'rgba(0, 0, 0, 0)' && button.ratio < 3);
  assert.deepStrictEqual(failures, [], `Low contrast buttons: ${JSON.stringify(failures, null, 2)}`);
});

async function fillByLabel(page, label, value) {
  let field = page.getByLabel(label, { exact: true });
  if (await field.count() !== 1 && label.endsWith(' *')) {
    field = page.getByLabel(label.replace(' *', ''), { exact: true });
  }
  if (await field.count() !== 1) {
    field = page.locator(`.modal-backdrop form [name="${fieldNameFor(label)}"]`);
  }
  if (await field.count() !== 1) {
    field = page.locator(`[name="${fieldNameFor(label)}"]`);
  }
  await expectSingle(field, `${label} field`);
  await field.fill(String(value));
}

async function selectByLabel(page, label, option) {
  let field = page.getByLabel(label, { exact: true });
  if (await field.count() !== 1 && label.endsWith(' *')) {
    field = page.getByLabel(label.replace(' *', ''), { exact: true });
  }
  if (await field.count() !== 1) {
    field = page.locator(`.modal-backdrop form [name="${fieldNameFor(label)}"]`);
  }
  if (await field.count() !== 1) {
    field = page.locator(`[name="${fieldNameFor(label)}"]`);
  }
  await expectSingle(field, `${label} select`);
  await field.selectOption(option);
}

function fieldNameFor(label) {
  const clean = label.replace(' *', '');
  return {
    'Account Code': 'code',
    'Account Name': 'name',
    'Bank Name': 'bank',
    'Bill Number': 'billNumber',
    'Category': 'category',
    'Currency': 'currency',
    'Current Balance (£)': 'balance',
    'Customer': 'customerId',
    'Customer Name': 'name',
    'Date': 'date',
    'Description': 'description',
    'Due Date': 'dueDate',
    'Email': 'email',
    'Font Style': 'fontFamily',
    'Gross amount paid (£)': 'amount',
    'Gross amount paid/owed (£)': 'subtotal',
    'Initial Balance (£)': 'balance',
    'Invoice Number': 'invoiceNumber',
    'Payment Method': 'paymentMethod',
    'Phone': 'phone',
    'Supplier': 'supplierId',
    'Supplier Name': 'name',
    'Type': 'type',
    'VAT Rate (0 if not VAT registered)': 'vatRate'
  }[clean] || clean.replace(/[^a-zA-Z0-9]+(.)/g, (_, chr) => chr.toUpperCase()).replace(/^[A-Z]/, chr => chr.toLowerCase());
}

async function clickButton(page, name) {
  let button = page.getByRole('button', { name, exact: true });
  if (await button.count() !== 1) {
    button = page.locator('button').filter({ hasText: name });
  }
  await expectSingle(button, `${name} button`);
  await button.click();
}

async function deleteRow(page, rowText, confirmText = 'Delete') {
  const row = page.locator('tr').filter({ hasText: rowText });
  const rowCount = await row.count();
  assert.ok(rowCount >= 1, `Expected row containing "${rowText}"`);
  const buttons = row.nth(0).locator('button');
  const buttonCount = await buttons.count();
  assert.ok(buttonCount >= 1, `Expected an action button for "${rowText}"`);
  await buttons.nth(buttonCount - 1).click();
  await clickButton(page, confirmText);
  await page.getByText(rowText, { exact: false }).waitFor({ state: 'detached' });
}

async function deleteCard(page, cardText, confirmText = 'Delete') {
  const card = page.locator('.metric-card').filter({ hasText: cardText });
  const cardCount = await card.count();
  assert.ok(cardCount >= 1, `Expected card containing "${cardText}"`);
  const buttons = card.nth(0).locator('button');
  const buttonCount = await buttons.count();
  assert.ok(buttonCount >= 1, `Expected an action button for "${cardText}"`);
  await buttons.nth(buttonCount - 1).click();
  await clickButton(page, confirmText);
  await page.getByText(cardText, { exact: false }).waitFor({ state: 'detached' });
}

When('I create and delete a customer named {string}', async function (name) {
  await this.openPage('People');
  await clickButton(this.page, 'Customers');
  await clickButton(this.page, 'Add Customer');
  await fillByLabel(this.page, 'Customer Name *', name);
  await fillByLabel(this.page, 'Email *', `${name.toLowerCase().replace(/\s+/g, '.')}@example.test`);
  await fillByLabel(this.page, 'Phone', '020 7000 0001');
  await clickButton(this.page, 'Create');
  await this.page.getByText(name, { exact: true }).waitFor();
  await deleteRow(this.page, name);
});

When('I create and delete a supplier named {string}', async function (name) {
  await this.openPage('People');
  await clickButton(this.page, 'Suppliers');
  await clickButton(this.page, 'Add Supplier');
  await fillByLabel(this.page, 'Supplier Name *', name);
  await fillByLabel(this.page, 'Email *', `${name.toLowerCase().replace(/\s+/g, '.')}@example.test`);
  await fillByLabel(this.page, 'Phone', '020 7000 0002');
  await clickButton(this.page, 'Create');
  await this.page.getByText(name, { exact: true }).waitFor();
  await deleteRow(this.page, name);
});

When('I create and delete an expense named {string}', async function (description) {
  await this.openPage('Expenses');
  await clickButton(this.page, 'Add Expense');
  await fillByLabel(this.page, 'Date *', '2026-06-07');
  await selectByLabel(this.page, 'Category *', { label: 'Office Supplies' });
  await fillByLabel(this.page, 'Description *', description);
  await fillByLabel(this.page, 'Gross amount paid (£) *', '24.50');
  await selectByLabel(this.page, 'Payment Method', { label: 'Card' });
  await clickButton(this.page, 'Create');
  await this.page.getByText(description, { exact: true }).waitFor();
  await deleteRow(this.page, description);
});

When('I create and delete a chart account named {string}', async function (name) {
  await this.openPage('Chart of Accounts');
  await clickButton(this.page, 'Add Account');
  await fillByLabel(this.page, 'Account Code *', '6999');
  await fillByLabel(this.page, 'Account Name *', name);
  await selectByLabel(this.page, 'Type *', { label: 'Expense' });
  await fillByLabel(this.page, 'Initial Balance (£) *', '0');
  await clickButton(this.page, 'Create');
  await this.page.getByText(name, { exact: true }).waitFor();
  await deleteRow(this.page, name);
});

When('I create and delete a bank account named {string}', async function (name) {
  await this.openPage('Banking');
  await clickButton(this.page, 'Bank Accounts');
  await clickButton(this.page, 'Add Bank Account');
  await fillByLabel(this.page, 'Account Name *', name);
  await fillByLabel(this.page, 'Bank Name *', 'Test Bank');
  await fillByLabel(this.page, 'Current Balance (£) *', '100');
  await selectByLabel(this.page, 'Currency *', { label: 'GBP (£)' });
  await clickButton(this.page, 'Create');
  await this.page.getByText(name, { exact: true }).waitFor();
  await deleteCard(this.page, name);
});

When('I create and delete a sales invoice numbered {string}', async function (invoiceNumber) {
  await this.openPage('Sales Invoices');
  await clickButton(this.page, 'Create Invoice');
  await selectByLabel(this.page, 'Customer *', { label: 'Northstar Digital Ltd' });
  await fillByLabel(this.page, 'Invoice Number *', invoiceNumber);
  await fillByLabel(this.page, 'Date *', '2026-06-07');
  await fillByLabel(this.page, 'Due Date *', '2026-06-21');
  await clickButton(this.page, 'Create');
  await this.page.getByText(invoiceNumber, { exact: true }).waitFor();
  await deleteRow(this.page, invoiceNumber);
});

When('I create and delete a purchase bill numbered {string}', async function (billNumber) {
  await this.openPage('Purchase Bills');
  await clickButton(this.page, 'Add Bill');
  await selectByLabel(this.page, 'Supplier *', { label: 'Amazon Business' });
  await fillByLabel(this.page, 'Bill Number *', billNumber);
  await fillByLabel(this.page, 'Date *', '2026-06-07');
  await fillByLabel(this.page, 'Due Date *', '2026-06-21');
  await fillByLabel(this.page, 'Description', 'BDD supplier invoice');
  await fillByLabel(this.page, 'Gross amount paid/owed (£) *', '42');
  await fillByLabel(this.page, 'VAT Rate (0 if not VAT registered) *', '0');
  await clickButton(this.page, 'Create');
  await this.page.getByText(billNumber, { exact: true }).waitFor();
  await deleteRow(this.page, billNumber);
});

When('I save settings with dark theme and Space Grotesk font', async function () {
  await this.openPage('Settings');
  const darkRadio = this.page.getByRole('radio', { name: 'Dark', exact: true });
  await expectSingle(darkRadio, 'Dark radio');
  await darkRadio.check();
  await selectByLabel(this.page, 'Font Style', { label: 'Space Grotesk' });
  await clickButton(this.page, 'Save Settings');
});

Then('a settings success toast should appear', async function () {
  await this.page.getByText('Settings updated successfully', { exact: true }).waitFor();
});

When('I import a bank statement containing {string}', async function (description) {
  await this.openPage('Banking');
  const csv = [
    'Date,Transaction ID,Transaction description,Reference,From,To,Paid in,Paid out,Category name,Transaction type,Status,Initiated by',
    `07/06/2026,BDD-TXN-001,${description},BDD REF,,${description},0,12.34,Bank fees,Card,Settled,BDD`
  ].join('\n');
  const filePath = path.join(os.tmpdir(), `swenbooks-bank-${Date.now()}.csv`);
  fs.writeFileSync(filePath, csv);
  await this.page.locator('input[type="file"][accept=".csv"]').setInputFiles(filePath);
  await this.page.getByText(description, { exact: false }).waitFor();
});

When('I import the same bank statement again', async function () {
  const fileInput = this.page.locator('input[type="file"][accept=".csv"]');
  const csv = [
    'Date,Transaction ID,Transaction description,Reference,From,To,Paid in,Paid out,Category name,Transaction type,Status,Initiated by',
    '07/06/2026,BDD-TXN-001,BDD BANK FEE,BDD REF,,BDD BANK FEE,0,12.34,Bank fees,Card,Settled,BDD'
  ].join('\n');
  const filePath = path.join(os.tmpdir(), `swenbooks-bank-duplicate-${Date.now()}.csv`);
  fs.writeFileSync(filePath, csv);
  await fileInput.setInputFiles(filePath);
});

Then('the app should report duplicate bank transactions were skipped', async function () {
  await this.page.getByText(/No new transactions imported|duplicate transaction/).waitFor();
});

When('I search banking transactions for {string}', async function (query) {
  await this.page.getByPlaceholder('Search description, reference, category or party...').fill(query);
});

Then('the bank transaction {string} should be visible', async function (description) {
  await this.page.getByText(description, { exact: false }).waitFor();
});

When('I open the transaction detail panel for {string}', async function (description) {
  const row = this.page.locator('tr').filter({ hasText: description });
  const rowCount = await row.count();
  assert.ok(rowCount >= 1, `Expected transaction row containing "${description}"`);
  const infoButton = row.nth(0).getByRole('button', { name: 'i', exact: true });
  await expectSingle(infoButton, 'transaction info button');
  await infoButton.click();
});

Then('the transaction detail panel should be readable in dark mode', async function () {
  const detail = this.page.getByText('Transaction detail', { exact: true });
  await detail.waitFor();
  const colors = await detail.evaluate(element => {
    const style = getComputedStyle(element);
    return {
      color: style.color,
      background: getComputedStyle(element.closest('tr')).backgroundColor
    };
  });
  assert.notStrictEqual(colors.color, colors.background);
});

When('I reconcile the suggested banking transaction', async function () {
  const reconcile = this.page.getByRole('button', { name: 'Reconcile', exact: true });
  const count = await reconcile.count();
  assert.ok(count >= 1, 'Expected at least one Reconcile action');
  await reconcile.nth(0).click();
  await clickButton(this.page, 'Mark as Reconciled');
});

Then('the banking transaction should move to reconciled status', async function () {
  const reconciledFilter = this.page.getByRole('button', { name: /Reconciled/ });
  const count = await reconciledFilter.count();
  assert.ok(count >= 1, 'Expected Reconciled filter button');
  await reconciledFilter.nth(0).click();
  const badges = this.page.getByText('Reconciled', { exact: true });
  const badgeCount = await badges.count();
  assert.ok(badgeCount >= 1, 'Expected at least one reconciled transaction badge');
  await badges.nth(0).waitFor();
});
