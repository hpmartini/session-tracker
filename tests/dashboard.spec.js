const { test, expect } = require('@playwright/test');

// Expected values are computed from the raw /api/data blocks, independently of the page code under test.
const dayOf = ts => new Date(ts * 1000).toLocaleDateString('sv-SE', { timeZone: 'Europe/Berlin' }); // YYYY-MM-DD
const minutes = text => { const m = text.match(/(?:(\d+) h )?(\d+) min/); return (+m[1] || 0) * 60 + +m[2]; };
const inRange = ([lo, hi]) => b => b[0] >= lo && b[0] < hi;

let api;
test.beforeAll(async ({ request }) => {
  api = await (await request.get('/api/data?derived=1&kurz=0&gap=5')).json();
});

// Opens the dashboard with derived data on and the given "Tage unter X h" threshold, waits for the reload.
async function open(page, kurz) {
  await page.goto('/');
  await Promise.all([page.waitForResponse(r => r.url().includes('derived=1')), page.check('#der')]);
  await Promise.all([page.waitForResponse(r => r.url().includes(`kurz=${kurz}`)), page.evaluate(v => {
    const k = document.querySelector('#kurz'); k.value = v; k.dispatchEvent(new Event('change', { bubbles: true }));
  }, kurz)]);
}

const kpi = (page, i) => page.locator('#kpis .kpi:not(.heute) b').nth(i);

test('blocks never cross local midnight', () => {
  expect(api.blocks.length).toBeGreaterThan(100);
  for (const [a, b] of api.blocks) {
    expect(b).toBeGreaterThan(a);
    expect(dayOf(b - 1), `block ${a}-${b}`).toBe(dayOf(a));
  }
});

test('period filter: days, blocks and total match the raw blocks for all 13 periods', async ({ page }) => {
  await open(page, 0);
  for (const [key, range] of Object.entries(api.ranges)) {
    const bl = api.blocks.filter(inRange(range));
    await page.click(`[data-p=${key}]`);
    await expect(kpi(page, 0), key).toHaveText(String(new Set(bl.map(b => dayOf(b[0]))).size));
    await expect(kpi(page, 1), key).toHaveText(String(bl.length));
    const total = bl.reduce((s, b) => s + Math.round((b[1] - b[0]) / 60), 0);
    expect(minutes(await kpi(page, 2).innerText()), key).toBe(total);
  }
});

test('year table follows the selected period', async ({ page }) => {
  await open(page, 0);
  for (const [key, range] of Object.entries(api.ranges)) {
    const days = {};
    for (const b of api.blocks.filter(inRange(range))) (days[dayOf(b[0]).slice(0, 4)] ??= new Set()).add(dayOf(b[0]));
    const want = Object.entries(days).sort().map(([y, s]) => [y, String(s.size)]);
    await page.click(`[data-p=${key}]`);
    await expect.poll(async () => {
      const rows = await page.locator('#years tr:has(td)').evaluateAll(trs => trs.map(tr => [...tr.cells].slice(0, 2).map(c => c.textContent)));
      return JSON.stringify(rows);
    }, { message: key }).toBe(JSON.stringify(want));
  }
});

test('threshold field hides short days and drives the year table', async ({ page }) => {
  const total = async () => +(await page.locator('#pager').innerText()).match(/von (\d+)/)[1];
  await open(page, 0);
  await page.click('[data-p=gesamt]');
  const all = await total();

  await Promise.all([page.waitForResponse(r => r.url().includes('kurz=8')), page.evaluate(() => {
    const k = document.querySelector('#kurz'); k.value = 8; k.dispatchEvent(new Event('change', { bubbles: true }));
  })]);
  await expect.poll(total).toBeLessThan(all);

  await page.selectOption('#ps', '250');
  const seps = await page.locator('#body tr.d').allInnerTexts();
  expect(seps.length).toBeGreaterThan(5);
  for (const s of seps) expect(minutes(s.match(/Gesamt.*$/)[0]), s).toBeGreaterThanOrEqual(480);

  const perDay = {};
  for (const b of api.blocks) perDay[dayOf(b[0])] = (perDay[dayOf(b[0])] || 0) + (b[1] - b[0]);
  const short = Object.values(perDay).filter(s => s / 3600 < 8).length;
  expect(short, "demo data must contain short days, else the test proves nothing").toBeGreaterThan(0);
  await expect(page.locator('#years th').nth(3)).toHaveText('Tage unter 8 h');
  await expect.poll(async () => (await page.locator('#years tr:has(td)').evaluateAll(trs => trs.reduce((s, tr) => s + +tr.cells[3].textContent, 0)))).toBe(short);
});
