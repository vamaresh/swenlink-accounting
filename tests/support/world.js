const { setWorldConstructor, BeforeAll, AfterAll, Before, After, Status, setDefaultTimeout } = require('@cucumber/cucumber');
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const repoRoot = path.resolve(__dirname, '..', '..');
let server;
let browser;
let baseUrl = process.env.TEST_BASE_URL;

setDefaultTimeout(90_000);

function contentTypeFor(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  return {
    '.css': 'text/css',
    '.csv': 'text/csv',
    '.html': 'text/html',
    '.ico': 'image/x-icon',
    '.js': 'text/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.txt': 'text/plain',
    '.webmanifest': 'application/manifest+json'
  }[ext] || 'application/octet-stream';
}

function startStaticServer() {
  return new Promise((resolve, reject) => {
    const app = http.createServer((req, res) => {
      const urlPath = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
      const requested = urlPath === '/' ? '/app.html' : urlPath;
      const filePath = path.normalize(path.join(repoRoot, requested));

      if (!filePath.startsWith(repoRoot)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
      }

      fs.readFile(filePath, (error, body) => {
        if (error) {
          res.writeHead(404);
          res.end('Not found');
          return;
        }
        res.writeHead(200, {
          'Content-Type': contentTypeFor(filePath),
          'Cache-Control': 'no-store'
        });
        res.end(body);
      });
    });

    app.once('error', reject);
    app.listen(0, '127.0.0.1', () => {
      const { port } = app.address();
      resolve({ app, url: `http://127.0.0.1:${port}` });
    });
  });
}

class AccountingWorld {
  constructor({ attach }) {
    this.attach = attach;
    this.baseUrl = baseUrl;
    this.page = null;
    this.context = null;
  }

  async openApp() {
    await this.page.goto(`${this.baseUrl}/app.html`, { waitUntil: 'domcontentloaded' });
    await this.page.getByRole('button', { name: 'Preview logged-in workspace' }).waitFor();
  }

  async enterDemoWorkspace() {
    const preview = this.page.getByRole('button', { name: 'Preview logged-in workspace' });
    await preview.click();
    await this.page.getByRole('heading', { name: 'Swenlink Limited', exact: true }).waitFor();
  }

  async openPage(pageName) {
    const button = this.page.getByRole('button', { name: pageName, exact: true });
    await expectSingle(button, `${pageName} navigation button`);
    await button.click();
  }

  async openSectionTab(tabName) {
    let button = this.page.getByRole('button', { name: tabName, exact: true });
    if (await button.count() !== 1) {
      button = this.page.locator('button.section-tab').filter({ hasText: tabName });
    }
    await expectSingle(button, `${tabName} tab`);
    await button.click();
  }
}

async function expectSingle(locator, label) {
  const count = await locator.count();
  assert.strictEqual(count, 1, `Expected one ${label}, found ${count}`);
}

BeforeAll(async function () {
  if (!baseUrl) {
    const started = await startStaticServer();
    server = started.app;
    baseUrl = started.url;
  }

  browser = await chromium.launch({
    headless: process.env.HEADLESS !== 'false'
  });
});

Before(async function () {
  this.baseUrl = baseUrl;
  this.context = await browser.newContext({
    viewport: { width: 1440, height: 960 },
    ignoreHTTPSErrors: true
  });
  this.page = await this.context.newPage();
  this.page.setDefaultTimeout(15_000);
});

After(async function (scenario) {
  if (scenario.result?.status === Status.FAILED && this.page) {
    const screenshot = await this.page.screenshot({ fullPage: true });
    await this.attach(screenshot, 'image/png');
  }
  if (this.context) {
    await this.context.close();
  }
});

AfterAll(async function () {
  if (browser) {
    await browser.close();
  }
  if (server) {
    await new Promise(resolve => server.close(resolve));
  }
});

setWorldConstructor(AccountingWorld);
module.exports = { expectSingle };
