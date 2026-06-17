const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests/e2e/playwright',
  timeout: 30000,
  fullyParallel: false,
  reporter: [['list']],
  use: {
    baseURL: 'http://127.0.0.1:18180',
    trace: 'retain-on-failure'
  },
  webServer: {
    command: 'node tests/e2e/playwright/mock-e2e-server.js',
    url: 'http://127.0.0.1:18180/__health',
    reuseExistingServer: false,
    timeout: 10000
  }
});
