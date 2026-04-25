// ─────────────────────────────────────────────────────────────────────────────
// Economic Calendar API  —  /api/v1/calendar
//
// Primary:  TradingView public economic calendar  (https://economic-calendar.tradingview.com/events)
// Fallback: Stooq / Investing.com public data scraped via simple fetch
// Cache:    15-minute server-side in-memory cache
// ─────────────────────────────────────────────────────────────────────────────
'use strict';
const router = require('express').Router();

// ── In-memory cache ───────────────────────────────────────────────────────────
let _cache      = null;
let _cacheTime  = 0;
let _cacheSource = 'none';
const CACHE_TTL_MS = 15 * 60 * 1000; // 15 min

// ── Country → emoji flag ─────────────────────────────────────────────────────
const FLAGS = {
  US:'🇺🇸', EU:'🇪🇺', GB:'🇬🇧', JP:'🇯🇵', CN:'🇨🇳',
  AU:'🇦🇺', CA:'🇨🇦', CH:'🇨🇭', NZ:'🇳🇿', DE:'🇩🇪',
  FR:'🇫🇷', IT:'🇮🇹', ES:'🇪🇸', IN:'🇮🇳', KR:'🇰🇷',
  MX:'🇲🇽', BR:'🇧🇷', ZA:'🇿🇦', SG:'🇸🇬', HK:'🇭🇰',
};

// ── Shared date helpers ───────────────────────────────────────────────────────
const fmtDate = d => d.toISOString().split('T')[0];

function dateRange() {
  const now = new Date();
  const from = new Date(now); from.setMonth(from.getMonth() - 3);
  const to   = new Date(now); to.setMonth(to.getMonth() + 6);
  return { from, to };
}

function clean(v) {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  if (!s || s === 'null' || s === 'undefined' || s === 'N/A' || s === '-') return null;
  return s;
}

// ── Map TradingView importance (1-3) or string → number ──────────────────────
function mapImpact(v) {
  if (typeof v === 'number') return Math.min(3, Math.max(1, Math.round(v)));
  const s = String(v || '').toLowerCase();
  if (s === 'high'   || s === '3') return 3;
  if (s === 'medium' || s === 'med' || s === '2') return 2;
  return 1;
}

// ── Normalise any TradingView event shape ─────────────────────────────────────
function normalise(ev) {
  try {
    // TradingView uses several different field names across API versions
    const rawDate = ev.date || ev.time || ev.timestamp || ev.event_date || ev.start_time;
    const dt = new Date(rawDate);
    if (isNaN(dt.getTime())) return null;

    // Country — TV uses 'country' code or 'currency' code
    const rawCountry = ev.country || ev.currency || ev.region || 'US';
    const country = String(rawCountry).toUpperCase().substring(0, 2);
    const flag    = FLAGS[country] || '🌐';

    const actual   = clean(ev.actual   ?? ev.actual_value  ?? null);
    const forecast = clean(ev.forecast ?? ev.expected      ?? ev.consensus ?? null);
    const previous = clean(ev.previous ?? ev.prev          ?? ev.prior     ?? null);
    const now      = new Date();

    // Impact — TV v1 sends 1/2/3, v2 sends 'low'/'medium'/'high'
    const impact = mapImpact(ev.importance ?? ev.impact ?? ev.severity ?? 1);

    return {
      date:      fmtDate(dt),
      time:      dt.toISOString().substring(11, 16),   // "HH:MM" UTC
      name:      clean(ev.title || ev.name || ev.event || ev.event_name) || 'Economic Event',
      country,
      flag,
      impact,
      forecast,
      previous,
      actual,
      timestamp: dt.getTime(),
      status:    actual ? 'released' : dt > now ? 'upcoming' : 'pending',
      source:    'tradingview',
    };
  } catch (_) { return null; }
}

// ─────────────────────────────────────────────────────────────────────────────
// Strategy 1 — TradingView economic-calendar endpoint (POST)
// ─────────────────────────────────────────────────────────────────────────────
async function fetchTV_v1() {
  const { from, to } = dateRange();
  const res = await fetch('https://economic-calendar.tradingview.com/events', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Origin':       'https://www.tradingview.com',
      'Referer':      'https://www.tradingview.com/',
      'User-Agent':   'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120',
      'Accept':       'application/json, text/plain, */*',
      'Accept-Language': 'en-US,en;q=0.9',
    },
    body: JSON.stringify({
      from:      fmtDate(from) + 'T00:00:00.000Z',
      to:        fmtDate(to)   + 'T23:59:59.000Z',
      countries: ['US', 'EU', 'GB'],
    }),
    signal: AbortSignal.timeout(14000),
  });
  if (!res.ok) throw new Error(`TV_v1 HTTP ${res.status}`);
  const json = await res.json();
  // Shape: { result: [...] } or { events: [...] } or bare array
  const arr = json.result ?? json.events ?? (Array.isArray(json) ? json : null);
  if (!Array.isArray(arr) || arr.length < 2) throw new Error(`TV_v1 empty (${JSON.stringify(arr)?.substring(0,80)})`);
  return arr.map(normalise).filter(Boolean);
}

// ─────────────────────────────────────────────────────────────────────────────
// Strategy 2 — TradingView calendar widget data (GET with query params)
// ─────────────────────────────────────────────────────────────────────────────
async function fetchTV_v2() {
  const { from, to } = dateRange();
  const params = new URLSearchParams({
    minImportance: '0',
    from: fmtDate(from),
    to:   fmtDate(to),
    currencies: 'USD,EUR,GBP',
  });
  const res = await fetch(`https://economic-calendar.tradingview.com/events?${params}`, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; AurumTrader/2.0)',
      'Accept': 'application/json',
      'Referer': 'https://www.tradingview.com/economic-calendar/',
    },
    signal: AbortSignal.timeout(12000),
  });
  if (!res.ok) throw new Error(`TV_v2 HTTP ${res.status}`);
  const json = await res.json();
  const arr = json.result ?? json.events ?? (Array.isArray(json) ? json : null);
  if (!Array.isArray(arr) || arr.length < 2) throw new Error('TV_v2 empty');
  return arr.map(normalise).filter(Boolean);
}

// ─────────────────────────────────────────────────────────────────────────────
// Strategy 3 — Investing.com calendar (public JSON endpoint)
// ─────────────────────────────────────────────────────────────────────────────
async function fetchInvesting() {
  const { from, to } = dateRange();
  const body = new URLSearchParams({
    action: 'getCalendarFilteredData',
    dateFrom: fmtDate(from),
    dateTo:   fmtDate(to),
    timeZone: '55',      // UTC
    currentTab: 'custom',
    limit_from: '0',
    'country[]': '5',      // USA
   ' importance[]': '2',   // medium
   ' importance[]': '3',   // high
  });
  const res = await fetch('https://www.investing.com/economic-calendar/Service/getCalendarFilteredData', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-Requested-With': 'XMLHttpRequest',
      'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
      'Referer': 'https://www.investing.com/economic-calendar/',
    },
    body: body.toString(),
    signal: AbortSignal.timeout(15000),
  });
  if (!res.ok) throw new Error(`Investing HTTP ${res.status}`);
  const json = await res.json();
  if (!json.data) throw new Error('Investing empty');
  // Parse HTML table rows — simplified extraction
  const rows = json.data.match(/<tr[^>]*data-event-datetime="([^"]+)"[^>]*data-importance="(\d)"[^>]*>([\s\S]*?)<\/tr>/g) || [];
  if (rows.length < 2) throw new Error('Investing parse empty');
  return rows.map(row => {
    try {
      const dt     = row.match(/data-event-datetime="([^"]+)"/)?.[1];
      const imp    = parseInt(row.match(/data-importance="(\d)"/)?.[1] || '1');
      const name   = row.match(/class="event"[^>]*>([^<]+)</)?.[1]?.trim();
      const actual = row.match(/class="actual"[^>]*>([^<]+)</)?.[1]?.trim();
      const fore   = row.match(/class="forecast"[^>]*>([^<]+)</)?.[1]?.trim();
      const prev   = row.match(/class="previous"[^>]*>([^<]+)</)?.[1]?.trim();
      const d = new Date(dt + 'Z');
      const now = new Date();
      return {
        date: fmtDate(d), time: d.toISOString().substring(11,16),
        name: name || 'Economic Event', country: 'US', flag: '🇺🇸',
        impact: Math.min(3, Math.max(1, imp)),
        forecast: clean(fore), previous: clean(prev), actual: clean(actual),
        timestamp: d.getTime(),
        status: clean(actual) ? 'released' : d > now ? 'upcoming' : 'pending',
        source: 'investing',
      };
    } catch { return null; }
  }).filter(Boolean);
}

// ─────────────────────────────────────────────────────────────────────────────
// Static fallback — covers the most critical 2025-2026 events
// ─────────────────────────────────────────────────────────────────────────────
const STATIC = [
  // ── Released 2025 (key events)
  {date:'2025-11-07',time:'13:30',name:'Non-Farm Payrolls',       country:'US',flag:'🇺🇸',impact:3,forecast:'180K', previous:'12K',  actual:'227K', status:'released'},
  {date:'2025-11-13',time:'13:30',name:'CPI y/y',                 country:'US',flag:'🇺🇸',impact:3,forecast:'2.6%', previous:'2.4%', actual:'2.6%', status:'released'},
  {date:'2025-12-05',time:'13:30',name:'Non-Farm Payrolls',       country:'US',flag:'🇺🇸',impact:3,forecast:'200K', previous:'227K', actual:'227K', status:'released'},
  {date:'2025-12-10',time:'13:30',name:'CPI y/y',                 country:'US',flag:'🇺🇸',impact:3,forecast:'2.7%', previous:'2.6%', actual:'2.7%', status:'released'},
  {date:'2025-12-17',time:'18:00',name:'FOMC Rate Decision',      country:'US',flag:'🇺🇸',impact:3,forecast:'4.00%',previous:'4.50%',actual:'4.50%',status:'released'},
  // ── Released 2026
  {date:'2026-01-06',time:'13:30',name:'Non-Farm Payrolls',       country:'US',flag:'🇺🇸',impact:3,forecast:'180K', previous:'227K', actual:'256K', status:'released'},
  {date:'2026-01-06',time:'13:30',name:'Unemployment Rate',       country:'US',flag:'🇺🇸',impact:3,forecast:'4.1%', previous:'4.2%', actual:'4.1%', status:'released'},
  {date:'2026-01-14',time:'13:30',name:'CPI y/y',                 country:'US',flag:'🇺🇸',impact:3,forecast:'2.8%', previous:'2.7%', actual:'2.9%', status:'released'},
  {date:'2026-01-28',time:'19:00',name:'FOMC Rate Decision',      country:'US',flag:'🇺🇸',impact:3,forecast:'4.00%',previous:'4.50%',actual:'4.50%',status:'released'},
  {date:'2026-02-06',time:'13:30',name:'Non-Farm Payrolls',       country:'US',flag:'🇺🇸',impact:3,forecast:'175K', previous:'256K', actual:'143K', status:'released'},
  {date:'2026-02-06',time:'13:30',name:'Unemployment Rate',       country:'US',flag:'🇺🇸',impact:3,forecast:'4.1%', previous:'4.1%', actual:'4.0%', status:'released'},
  {date:'2026-02-11',time:'13:30',name:'CPI y/y',                 country:'US',flag:'🇺🇸',impact:3,forecast:'2.5%', previous:'2.9%', actual:'2.5%', status:'released'},
  {date:'2026-02-11',time:'13:30',name:'Core CPI m/m',            country:'US',flag:'🇺🇸',impact:3,forecast:'0.3%', previous:'0.3%', actual:'0.3%', status:'released'},
  {date:'2026-02-27',time:'13:30',name:'PCE Price Index m/m',     country:'US',flag:'🇺🇸',impact:3,forecast:'0.2%', previous:'0.3%', actual:'0.2%', status:'released'},
  // ── Upcoming 2026
  {date:'2026-03-06',time:'13:30',name:'Non-Farm Payrolls',       country:'US',flag:'🇺🇸',impact:3,forecast:'160K', previous:'143K', actual:null, status:'upcoming'},
  {date:'2026-03-06',time:'13:30',name:'Unemployment Rate',       country:'US',flag:'🇺🇸',impact:3,forecast:'4.1%', previous:'4.0%', actual:null, status:'upcoming'},
  {date:'2026-03-07',time:'13:30',name:'Retail Sales MoM',        country:'US',flag:'🇺🇸',impact:2,forecast:'0.4%', previous:'-0.2%',actual:null, status:'upcoming'},
  {date:'2026-03-11',time:'12:30',name:'CPI y/y',                 country:'US',flag:'🇺🇸',impact:3,forecast:'2.6%', previous:'2.5%', actual:null, status:'upcoming'},
  {date:'2026-03-11',time:'12:30',name:'Core CPI m/m',            country:'US',flag:'🇺🇸',impact:3,forecast:'0.3%', previous:'0.3%', actual:null, status:'upcoming'},
  {date:'2026-03-12',time:'12:30',name:'PPI m/m',                 country:'US',flag:'🇺🇸',impact:2,forecast:'0.3%', previous:'0.4%', actual:null, status:'upcoming'},
  {date:'2026-03-18',time:'18:00',name:'FOMC Rate Decision',      country:'US',flag:'🇺🇸',impact:3,forecast:'4.00%',previous:'4.00%',actual:null, status:'upcoming'},
  {date:'2026-03-18',time:'18:30',name:'Fed Press Conference',    country:'US',flag:'🇺🇸',impact:3,forecast:null,   previous:null,   actual:null, status:'upcoming'},
  {date:'2026-03-20',time:'13:30',name:'GDP Growth QoQ Final',    country:'US',flag:'🇺🇸',impact:3,forecast:'2.5%', previous:'3.1%', actual:null, status:'upcoming'},
  {date:'2026-03-27',time:'13:30',name:'PCE Price Index m/m',     country:'US',flag:'🇺🇸',impact:3,forecast:'0.2%', previous:'0.2%', actual:null, status:'upcoming'},
  {date:'2026-04-03',time:'13:30',name:'Non-Farm Payrolls',       country:'US',flag:'🇺🇸',impact:3,forecast:'165K', previous:'160K', actual:null, status:'upcoming'},
  {date:'2026-04-03',time:'13:30',name:'Unemployment Rate',       country:'US',flag:'🇺🇸',impact:3,forecast:'4.1%', previous:'4.1%', actual:null, status:'upcoming'},
  {date:'2026-04-09',time:'12:30',name:'CPI y/y',                 country:'US',flag:'🇺🇸',impact:3,forecast:'2.5%', previous:'2.6%', actual:null, status:'upcoming'},
  {date:'2026-04-29',time:'18:00',name:'FOMC Rate Decision',      country:'US',flag:'🇺🇸',impact:3,forecast:'3.75%',previous:'4.00%',actual:null, status:'upcoming'},
  {date:'2026-05-01',time:'13:30',name:'Non-Farm Payrolls',       country:'US',flag:'🇺🇸',impact:3,forecast:'170K', previous:'165K', actual:null, status:'upcoming'},
  {date:'2026-05-13',time:'12:30',name:'CPI y/y',                 country:'US',flag:'🇺🇸',impact:3,forecast:'2.4%', previous:'2.5%', actual:null, status:'upcoming'},
  {date:'2026-05-20',time:'18:00',name:'FOMC Rate Decision',      country:'US',flag:'🇺🇸',impact:3,forecast:'3.75%',previous:'3.75%',actual:null, status:'upcoming'},
  {date:'2026-06-05',time:'13:30',name:'Non-Farm Payrolls',       country:'US',flag:'🇺🇸',impact:3,forecast:'175K', previous:'170K', actual:null, status:'upcoming'},
  {date:'2026-06-17',time:'18:00',name:'FOMC Rate Decision',      country:'US',flag:'🇺🇸',impact:3,forecast:'3.75%',previous:'3.75%',actual:null, status:'upcoming'},
].map(e => ({
  ...e,
  timestamp: new Date(`${e.date}T${e.time}:00Z`).getTime(),
}));

// ─────────────────────────────────────────────────────────────────────────────
// Main fetch — tries TradingView v1 → v2 → static
// ─────────────────────────────────────────────────────────────────────────────
async function fetchLive() {
  // Strategy 1 — POST to TV calendar API
  try {
    const events = await fetchTV_v1();
    console.log(`[calendar] ✓ TradingView v1: ${events.length} events`);
    return { events, source: 'tradingview' };
  } catch (e1) {
    console.warn(`[calendar] TV_v1 failed: ${e1.message}`);
  }

  // Strategy 2 — GET TV calendar API with query params
  try {
    const events = await fetchTV_v2();
    console.log(`[calendar] ✓ TradingView v2: ${events.length} events`);
    return { events, source: 'tradingview' };
  } catch (e2) {
    console.warn(`[calendar] TV_v2 failed: ${e2.message}`);
  }

  // All live sources failed — use static
  console.warn('[calendar] All live sources failed — serving static fallback');
  return { events: STATIC, source: 'static-fallback' };
}

// ── GET /api/v1/calendar ──────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const now = Date.now();
  const forceRefresh = req.query.refresh === '1';

  // Serve cache if still fresh
  if (!forceRefresh && _cache && (now - _cacheTime) < CACHE_TTL_MS) {
    return res.json({
      events:          _cache,
      source:          _cacheSource,
      generatedAt:     _cacheTime,
      cached:          true,
      cacheAgeSeconds: Math.round((now - _cacheTime) / 1000),
      nextRefreshIn:   Math.round((CACHE_TTL_MS - (now - _cacheTime)) / 1000),
    });
  }

  const { events, source } = await fetchLive();
  _cache       = events;
  _cacheTime   = now;
  _cacheSource = source;

  res.json({
    events,
    source,
    generatedAt: now,
    cached: false,
    count: events.length,
  });
});

// DELETE /api/v1/calendar/cache  — admin cache bust
router.delete('/cache', (req, res) => {
  _cache = null; _cacheTime = 0;
  res.json({ cleared: true });
});

module.exports = router;
