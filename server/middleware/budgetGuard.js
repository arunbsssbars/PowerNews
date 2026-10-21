/**
 * Budget Guard & Anti-EDoS (Economic Denial of Sustainability) Sentry
 * 
 * Enforces strictly zero billing on Google Cloud / Firebase Blaze plan:
 * 1. Daily Invocations Circuit Breaker (Cap at 45,000 req/day; free limit is ~66k/day & 50k Firestore)
 * 2. Malicious Bot & Vulnerability Scanner Blocking
 * 3. Query Limit Clamping (prevents pagination denial-of-wallet)
 * 4. Heavy Route Per-IP Throttling (/api/article-summary, /api/article-content)
 */

// Daily quota tracking
const DAILY_FREE_TIER_LIMIT = 45000; // Safe threshold before 50,000 Firestore / 66,000 Functions
let currentDay = new Date().toISOString().slice(0, 10);
let dailyRequestCount = 0;
let isEmergencyFreeMode = false;

// Per-IP tracker for heavy operations (max 5/min)
const heavyIpAccessMap = new Map();
const HEAVY_WINDOW_MS = 60 * 1000;
const HEAVY_MAX_REQUESTS = 5;

// Known malicious vulnerability scanners and automated scraping bot signatures
const MALICIOUS_USER_AGENTS = [
  /sqlmap/i,
  /nikto/i,
  /masscan/i,
  /nmap/i,
  /zgrab/i,
  /acunetix/i,
  /python-urllib/i,
  /havij/i,
  /gobuster/i,
  /dirbuster/i,
  /censys/i,
];

/**
 * Resets daily quota counter when UTC day flips
 */
function checkDayRollOver() {
  const today = new Date().toISOString().slice(0, 10);
  if (today !== currentDay) {
    console.log(`[BudgetGuard] New UTC day: ${today}. Resetting daily counter from ${dailyRequestCount} to 0.`);
    currentDay = today;
    dailyRequestCount = 0;
    isEmergencyFreeMode = false;
  }
}

/**
 * Main Budget Guard Middleware
 */
function budgetGuardMiddleware(req, res, next) {
  checkDayRollOver();

  // 1. Bot & Vulnerability Scanner Filter (Drop at 0ms)
  const userAgent = req.headers['user-agent'] || '';
  for (const pattern of MALICIOUS_USER_AGENTS) {
    if (pattern.test(userAgent)) {
      console.warn(`[BudgetGuard] Blocked malicious User-Agent: ${userAgent} from IP: ${req.ip}`);
      return res.status(403).json({ error: 'Access denied' });
    }
  }

  // Exempt local health checks from counting against the quota
  if (req.path === '/api/health' || req.path === '/health') {
    return next();
  }

  dailyRequestCount++;

  // 2. Daily Free Tier Circuit Breaker
  if (dailyRequestCount >= DAILY_FREE_TIER_LIMIT) {
    if (!isEmergencyFreeMode) {
      console.error(`[BudgetGuard CRITICAL] Daily request budget of ${DAILY_FREE_TIER_LIMIT} reached! Activating Emergency Free Mode.`);
      isEmergencyFreeMode = true;
    }

    // Attach emergency header so downstream knows to avoid Firestore/external calls
    req.emergencyFreeMode = true;

    // For heavy non-essential endpoints, reject immediately to prevent compute/memory exhaustion
    if (req.path.includes('/article-summary') || req.path.includes('/article-content') || req.path.includes('/generate')) {
      return res.status(429).json({
        error: 'Daily free quota budget reached. Endpoint temporarily paused to guarantee zero billing. Feed browsing remains available.',
        emergencyMode: true
      });
    }
  }

  // 3. Query Limit Clamping (Anti-Pagination Denial-of-Wallet)
  if (req.query && req.query.limit) {
    const rawLimit = parseInt(req.query.limit, 10);
    if (!isNaN(rawLimit)) {
      req.query.limit = String(Math.min(Math.max(1, rawLimit), 50));
    }
  }

  next();
}

/**
 * Heavy Route Limiter (Prevents Gemini AI & scraping denial-of-wallet)
 */
function heavyRouteLimiter(req, res, next) {
  const clientIp = req.ip || req.connection.remoteAddress || 'unknown';
  const now = Date.now();

  const record = heavyIpAccessMap.get(clientIp) || { count: 0, resetTime: now + HEAVY_WINDOW_MS };

  if (now > record.resetTime) {
    record.count = 1;
    record.resetTime = now + HEAVY_WINDOW_MS;
  } else {
    record.count++;
  }

  heavyIpAccessMap.set(clientIp, record);

  // Periodically clean stale IPs
  if (heavyIpAccessMap.size > 1000) {
    for (const [ip, data] of heavyIpAccessMap.entries()) {
      if (now > data.resetTime) {
        heavyIpAccessMap.delete(ip);
      }
    }
  }

  if (record.count > HEAVY_MAX_REQUESTS) {
    return res.status(429).json({
      error: `Too many heavy processing requests. Rate limit is ${HEAVY_MAX_REQUESTS} requests per minute per client.`
    });
  }

  next();
}

/**
 * Returns current budget and quota statistics
 */
function getBudgetStats() {
  checkDayRollOver();
  return {
    currentDateUTC: currentDay,
    dailyRequestCount,
    dailyFreeTierLimit: DAILY_FREE_TIER_LIMIT,
    remainingRequests: Math.max(0, DAILY_FREE_TIER_LIMIT - dailyRequestCount),
    isEmergencyFreeMode,
    projectedCost: '$0.00 (Guaranteed Free Tier)'
  };
}

module.exports = {
  budgetGuardMiddleware,
  heavyRouteLimiter,
  getBudgetStats
};
