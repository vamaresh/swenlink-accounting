# Automated Testing

The app now has a BDD end-to-end suite powered by Cucumber and Playwright.

## Run Locally

```bash
npm install
npm test
```

Use headed browser mode when debugging:

```bash
npm run test:e2e:headed
```

Reports are generated in `reports/`:

- `reports/cucumber-report.html`
- `reports/cucumber-report.json`
- `reports/cucumber-junit.xml`

## Coverage

The BDD features cover:

- First-time landing page and preview login flow.
- Every primary navigation link.
- People, Compliance and Banking tab groups.
- CRUD-style create/delete workflows for customers, suppliers, sales invoices, purchase bills, expenses, chart of accounts and bank accounts in demo mode.
- Banking CSV import, duplicate detection, search, detail view readability and reconciliation.
- Global theme, font and standard button contrast checks.

## CI / Merge Gate

GitHub Actions runs `.github/workflows/bdd-e2e.yml` on pushes and pull requests. The job name is `bdd-e2e`.

To block merges when tests fail, enable branch protection in GitHub:

1. Go to `Settings` -> `Branches`.
2. Add or edit the rule for `main` or `master`.
3. Enable `Require status checks to pass before merging`.
4. Select the required check named `bdd-e2e`.
5. Enable `Require branches to be up to date before merging`.
