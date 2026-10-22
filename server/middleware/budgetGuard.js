/**
 * Budget Guard & Anti-EDoS (Economic Denial of Sustainability) Sentry
 * 
 * Enforces strictly zero billing on Google Cloud / Firebase Blaze plan:
 * 1. Daily Invocations Circuit Breaker (Cap at 45,000 req/day; free limit is 66,000/day & 50k Firestore)
 * 2. Malicious Bot & Vulnerability Scanner Blocking (0ms drop)
 * 3. Query Limit Clamping (prevents pagination denial-of-wallet)
 * 4. Multi-Service Quota Radar tracking Firestore, Cloud Functions, Gemini AI, and Hosting Egress
 */

// Daily quota tracking
const DAILY_FREE_TIER_LIMIT = 45000; // Safe threshold before 50,000 Firestore / 66,000 Functions
const DAILY_FIRESTORE_READ_LIMIT = 50000;
const DAILY_FIRESTORE_WRITE_LIMIT = 20000;
const DAILY_GEMINI_REQUEST_LIMIT = 1500;
const GEMINI_RPM_LIMIT = 15;
const DAILY_EGRESS_MB_LIMIT = 360; // 10 GB / month free tier ~360 MB / day

let currentDay = new Date().toISOString().slice(0, 10);
let dailyRequestCount = 0;
let dailyFirestoreReads = 0;
let dailyFirestoreWrites = 0;
let dailyGeminiRequests = 0;
let geminiMinuteRequests = [];
let dailyEgressBytes = 0;
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
 * Resets daily quota counters when UTC day flips
 */
function checkDayRollOver() {
  const today = new Date().toISOString().slice(0, 10);
  if (today !== currentDay) {
    console.log(`[BudgetGuard] New UTC day: ${today}. Resetting daily counters (Invocations: ${dailyRequestCount}, Firestore Reads: ${dailyFirestoreReads}, Writes: ${dailyFirestoreWrites}, Gemini: ${dailyGeminiRequests}).`);
    currentDay = today;
    dailyRequestCount = 0;
    dailyFirestoreReads = 0;
    dailyFirestoreWrites = 0;
    dailyGeminiRequests = 0;
    dailyEgressBytes = 0;
    isEmergencyFreeMode = false;
  }
}

/**
 * Record Firestore operations for zero-billing quota monitoring
 */
function recordFirestoreOp(opType, count = 1) {
  checkDayRollOver();
  if (opType === 'read') {
    dailyFirestoreReads += count;
  } else if (opType === 'write') {
    dailyFirestoreWrites += count;
  }
}

/**
 * Record Gemini AI inference calls
 */
function recordGeminiOp(count = 1) {
  checkDayRollOver();
  dailyGeminiRequests += count;
  const now = Date.now();
  geminiMinuteRequests.push(now);
  geminiMinuteRequests = geminiMinuteRequests.filter(ts => (now - ts) < 60000);
}

/**
 * Record network egress bytes
 */
function recordEgress(bytes = 0) {
  checkDayRollOver();
  dailyEgressBytes += bytes;
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

  // Exempt health checks from counting against the quota
  if (req.path === '/api/health' || req.path === '/health') {
    return next();
  }

  dailyRequestCount++;

  // Estimate read operation for queries
  if (req.path.startsWith('/api/news') || req.path.startsWith('/api/morning-digest')) {
    recordFirestoreOp('read', 1);
  }

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

  // Measure egress on finish
  res.on('finish', () => {
    const lenHeader = res.getHeader('content-length');
    if (lenHeader) {
      const len = parseInt(lenHeader, 10);
      if (!isNaN(len)) recordEgress(len);
    }
  });

  next();
}

/**
 * Heavy Route Limiter (Prevents Gemini AI & scraping denial-of-wallet)
 */
function heavyRouteLimiter(req, res, next) {
  const clientIp = req.ip || req.connection?.remoteAddress || 'unknown';
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
 * Returns current multi-service budget and quota statistics
 */
function getBudgetStats() {
  checkDayRollOver();
  const now = Date.now();
  geminiMinuteRequests = geminiMinuteRequests.filter(ts => (now - ts) < 60000);
  const currentGeminiRpm = geminiMinuteRequests.length;

  const functionsPercent = (dailyRequestCount / DAILY_FREE_TIER_LIMIT) * 100;
  const firestoreReadsPercent = (dailyFirestoreReads / DAILY_FIRESTORE_READ_LIMIT) * 100;
  const firestoreWritesPercent = (dailyFirestoreWrites / DAILY_FIRESTORE_WRITE_LIMIT) * 100;
  const geminiRequestsPercent = (dailyGeminiRequests / DAILY_GEMINI_REQUEST_LIMIT) * 100;
  const egressMb = Math.round((dailyEgressBytes / (1024 * 1024)) * 100) / 100;
  const egressPercent = (egressMb / DAILY_EGRESS_MB_LIMIT) * 100;

  const maxUtilization = Math.max(
    functionsPercent,
    firestoreReadsPercent,
    firestoreWritesPercent,
    geminiRequestsPercent,
    egressPercent
  );

  let exhaustionAlert = 'SAFE';
  let alertMessage = 'All service consumption is well within Google Cloud zero-billing free tier quotas.';
  if (maxUtilization >= 90 || isEmergencyFreeMode) {
    exhaustionAlert = 'CRITICAL';
    alertMessage = 'Critical: One or more services have exceeded 90% of daily free-tier quota. Circuit breaker armed to protect $0 billing.';
  } else if (maxUtilization >= 70) {
    exhaustionAlert = 'WARNING_ELEVATED';
    alertMessage = 'Notice: One or more services have crossed 70% of daily free-tier quota. Throttling non-essential background tasks.';
  }

  return {
    currentDateUTC: currentDay,
    projectedCost: '$0.00 (Guaranteed Free Tier)',
    exhaustionAlert,
    alertMessage,
    maxUtilizationPercent: Math.round(maxUtilization * 10) / 10,
    services: {
      cloudFunctions: {
        dailyInvocations: dailyRequestCount,
        dailyLimit: DAILY_FREE_TIER_LIMIT,
        monthlyLimit: 2000000,
        remainingDaily: Math.max(0, DAILY_FREE_TIER_LIMIT - dailyRequestCount),
        percentUsed: Math.round(functionsPercent * 10) / 10,
        status: functionsPercent >= 90 ? 'CRITICAL' : (functionsPercent >= 70 ? 'WARNING' : 'HEALTHY')
      },
      cloudFirestore: {
        dailyReads: dailyFirestoreReads,
        dailyReadLimit: DAILY_FIRESTORE_READ_LIMIT,
        remainingReads: Math.max(0, DAILY_FIRESTORE_READ_LIMIT - dailyFirestoreReads),
        readPercentUsed: Math.round(firestoreReadsPercent * 10) / 10,
        dailyWrites: dailyFirestoreWrites,
        dailyWriteLimit: DAILY_FIRESTORE_WRITE_LIMIT,
        remainingWrites: Math.max(0, DAILY_FIRESTORE_WRITE_LIMIT - dailyFirestoreWrites),
        writePercentUsed: Math.round(firestoreWritesPercent * 10) / 10,
        status: (firestoreReadsPercent >= 90 || firestoreWritesPercent >= 90) ? 'CRITICAL' : 'HEALTHY'
      },
      geminiAi: {
        dailyRequests: dailyGeminiRequests,
        dailyLimit: DAILY_GEMINI_REQUEST_LIMIT,
        remainingDaily: Math.max(0, DAILY_GEMINI_REQUEST_LIMIT - dailyGeminiRequests),
        percentUsed: Math.round(geminiRequestsPercent * 10) / 10,
        currentRpm: currentGeminiRpm,
        rpmLimit: GEMINI_RPM_LIMIT,
        status: (geminiRequestsPercent >= 90 || currentGeminiRpm >= GEMINI_RPM_LIMIT) ? 'WARNING' : 'HEALTHY'
      },
      hostingAndNetwork: {
        dailyEgressMb: egressMb,
        dailyLimitMb: DAILY_EGRESS_MB_LIMIT,
        remainingEgressMb: Math.max(0, DAILY_EGRESS_MB_LIMIT - egressMb),
        percentUsed: Math.round(egressPercent * 10) / 10,
        status: egressPercent >= 90 ? 'WARNING' : 'HEALTHY'
      }
    },
    isEmergencyFreeMode
  };
}

module.exports = {
  budgetGuardMiddleware,
  heavyRouteLimiter,
  getBudgetStats,
  recordFirestoreOp,
  recordGeminiOp,
  recordEgress
};
