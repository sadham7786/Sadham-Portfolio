'use strict';
// ─────────────────────────────────────────────────────────────────────────────
// News API  —  /api/v1/news
// Proxies financial news from multiple RSS feeds, cached 10 minutes
// ─────────────────────────────────────────────────────────────────────────────
const router = require('express').Router();

let _cache = null;
let _cacheTime = 0;
const CACHE_TTL = 10 * 60 * 1000; // 10 min

// RSS feeds for financial news
const FEEDS = [
  { name: 'Reuters Markets', url: 'https://feeds.reuters.com/reuters/businessNews', cat: 'markets' },
  { name: 'FX Street',       url: 'https://www.fxstreet.com/rss/news',             cat: 'forex'   },
  { name: 'Investing.com',   url: 'https://www.investing.com/rss/news.rss',         cat: 'all'     },
  { name: 'MarketWatch',     url: 'https://feeds.marketwatch.com/marketwatch/realtimeheadlines/', cat: 'markets' },
];

async function fetchFeed(feed) {
  try {
    const res = await fetch(feed.url, {
      headers: { 'Accept': 'application/rss+xml, application/xml, text/xml', 'User-Agent': 'AurumTrader/1.0' },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return [];
    const xml = await res.text();
    return parseRss(xml, feed);
  } catch { return []; }
}

function parseRss(xml, feed) {
  const items = [];
  const itemMatches = xml.matchAll(/<item>([\s\S]*?)<\/item>/g);
  for (const m of itemMatches) {
    const block = m[1];
    const title   = stripCdata(block.match(/<title[^>]*>([\s\S]*?)<\/title>/)?.[1] || '');
    const link    = strip(block.match(/<link[^>]*>([\s\S]*?)<\/link>/)?.[1] || '');
    const pubDate = strip(block.match(/<pubDate[^>]*>([\s\S]*?)<\/pubDate>/)?.[1] || '');
    const desc    = stripCdata(block.match(/<description[^>]*>([\s\S]*?)<\/description>/)?.[1] || '');
    if (!title) continue;
    const category = detectCategory(title + ' ' + desc);
    const ts = pubDate ? new Date(pubDate).getTime() : Date.now();
    items.push({
      id:          Buffer.from(link || title).toString('base64').substring(0, 20),
      title:       title.substring(0, 200),
      description: stripHtml(desc).substring(0, 300),
      url:         link,
      source:      feed.name,
      category,
      publishedAt: isNaN(ts) ? Date.now() : ts,
      isUnread:    true,
    });
  }
  return items.slice(0, 15); // max 15 per feed
}

function detectCategory(text) {
  const t = text.toLowerCase();
  if (/gold|xau|precious|silver|metal/.test(t))     return 'gold';
  if (/bitcoin|crypto|btc|ethereum|defi/.test(t))   return 'crypto';
  if (/forex|currency|dollar|euro|yen|pound/.test(t)) return 'forex';
  if (/fed|fomc|inflation|cpi|nfp|gdp|rate/.test(t)) return 'economy';
  return 'markets';
}

function stripCdata(s) { return (s || '').replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1').trim(); }
function strip(s)      { return (s || '').trim(); }
function stripHtml(s)  { return (s || '').replace(/<[^>]+>/g, '').replace(/&[a-z]+;/gi, ' ').trim(); }

// Static fallback articles when all feeds fail
const STATIC_ARTICLES = [
  { id:'s1', title:'Gold Prices Hold Near Record Highs Amid Fed Rate Uncertainty', source:'Reuters', category:'gold',    publishedAt: Date.now() - 3600000,  url:'#', description:'Gold traded near all-time highs as traders awaited clarity on Federal Reserve rate policy.', isUnread:true },
  { id:'s2', title:'FOMC Minutes: Fed Officials Signal Caution on Rate Cuts',      source:'Reuters', category:'economy', publishedAt: Date.now() - 7200000,  url:'#', description:'Federal Reserve minutes showed officials remain cautious about cutting rates too quickly.', isUnread:true },
  { id:'s3', title:'Dollar Weakens as Non-Farm Payrolls Miss Expectations',        source:'FX Street',category:'forex',   publishedAt: Date.now() - 10800000, url:'#', description:'The US Dollar weakened after Non-Farm Payroll data missed analyst forecasts.', isUnread:true },
  { id:'s4', title:'XAU/USD Technical Analysis: Bulls Eye $2,400 Level',           source:'FX Street',category:'gold',    publishedAt: Date.now() - 14400000, url:'#', description:'Gold technicals suggest bullish momentum with resistance at $2,400.', isUnread:true },
  { id:'s5', title:'Bitcoin Surges Past $67,000 on ETF Inflow Data',               source:'MarketWatch',category:'crypto', publishedAt: Date.now() - 18000000, url:'#', description:'Bitcoin rose sharply as spot ETF inflows hit weekly records.', isUnread:true },
  { id:'s6', title:'EUR/USD Dips Below 1.08 on ECB Dovish Signals',                source:'Reuters', category:'forex',   publishedAt: Date.now() - 21600000, url:'#', description:'Euro fell below key support as ECB officials signalled readiness to cut rates.', isUnread:true },
  { id:'s7', title:'US CPI Data: Inflation Cools to 2.6%, Below Forecast',        source:'Reuters', category:'economy', publishedAt: Date.now() - 25200000, url:'#', description:'US consumer prices rose less than expected in the latest reading.', isUnread:true },
  { id:'s8', title:'Silver Lags Gold Rally Despite Bullish Metals Sentiment',      source:'MarketWatch',category:'gold',   publishedAt: Date.now() - 28800000, url:'#', description:'Silver underperformed gold despite the broader precious metals rally.', isUnread:true },
];

// ── GET /api/v1/news ──────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const category = req.query.category || 'all';
  const limit    = Math.min(parseInt(req.query.limit) || 30, 60);
  const now      = Date.now();

  // Serve from cache
  if (_cache && (now - _cacheTime) < CACHE_TTL) {
    let articles = _cache;
    if (category !== 'all') articles = articles.filter(a => a.category === category);
    return res.json({ articles: articles.slice(0, limit), total: articles.length, source: 'cache' });
  }

  // Fetch all feeds in parallel
  const results = await Promise.allSettled(FEEDS.map(fetchFeed));
  const allArticles = results.flatMap(r => r.status === 'fulfilled' ? r.value : []);

  let articles = allArticles.length > 5 ? allArticles : STATIC_ARTICLES;
  // Deduplicate by id
  const seen = new Set();
  articles = articles.filter(a => { if (seen.has(a.id)) return false; seen.add(a.id); return true; });
  // Sort newest first
  articles.sort((a, b) => b.publishedAt - a.publishedAt);

  _cache = articles;
  _cacheTime = now;

  const source = allArticles.length > 5 ? 'live' : 'static';
  if (category !== 'all') articles = articles.filter(a => a.category === category);
  res.json({ articles: articles.slice(0, limit), total: articles.length, source });
});

module.exports = router;
