const { defineConfig } = require('@playwright/test');

process.env.TZ = 'Europe/Berlin'; // same zone as the server in tests/serve.sh, so "local midnight" means the same on both sides

module.exports = defineConfig({
  testDir: 'tests',
  workers: 1, // one shared dashboard server and one demo database
  timeout: 60_000,
  use: { baseURL: 'http://127.0.0.1:8792', channel: 'chrome' }, // installed Chrome, no browser download
  webServer: { command: 'sh tests/serve.sh', url: 'http://127.0.0.1:8792/api/data', reuseExistingServer: false, timeout: 30_000 },
});
