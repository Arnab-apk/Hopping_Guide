/**
 * Rate limiters, budget monitors, and in-memory response caching
 * to strictly ensure $0 operating cost on Google Gemini Free Tier.
 */

interface DeviceLimitEntry {
  count: number;
  resetAt: number;
}

interface CacheEntry {
  answer: string;
  factsAsOf: string;
  usedLlm: boolean;
  expiresAt: number;
}

// Per-device window: 10 requests per hour
const DEVICE_WINDOW_MS = 60 * 60 * 1000;
const MAX_REQUESTS_PER_DEVICE_PER_HOUR = 10;

// Daily free tier guard: 800 requests/day (~80% of Google AI Studio free tier)
const MAX_GLOBAL_DAILY_CALLS = 800;
let globalDailyCount = 0;
let globalDayResetAt = Date.now() + 24 * 60 * 60 * 1000;

const deviceLimits = new Map<string, DeviceLimitEntry>();
const responseCache = new Map<string, CacheEntry>();

/**
 * Checks if a device has exceeded its hourly question quota.
 */
export function checkDeviceLimit(deviceId: string): { allowed: boolean; remaining: number } {
  const now = Date.now();
  let entry = deviceLimits.get(deviceId);

  if (!entry || now > entry.resetAt) {
    entry = { count: 1, resetAt: now + DEVICE_WINDOW_MS };
    deviceLimits.set(deviceId, entry);
    return { allowed: true, remaining: MAX_REQUESTS_PER_DEVICE_PER_HOUR - 1 };
  }

  if (entry.count >= MAX_REQUESTS_PER_DEVICE_PER_HOUR) {
    return { allowed: false, remaining: 0 };
  }

  entry.count++;
  return { allowed: true, remaining: MAX_REQUESTS_PER_DEVICE_PER_HOUR - entry.count };
}

/**
 * Checks if the global daily LLM budget is safe.
 * Once threshold is reached, server falls back to instant templates to prevent 429 errors.
 */
export function isGlobalLlmBudgetAvailable(): boolean {
  const now = Date.now();
  if (now > globalDayResetAt) {
    globalDailyCount = 0;
    globalDayResetAt = now + 24 * 60 * 60 * 1000;
  }

  return globalDailyCount < MAX_GLOBAL_DAILY_CALLS;
}

export function recordLlmCall(): void {
  globalDailyCount++;
}

/**
 * Cache popular questions for 60 seconds (identical intent + places).
 */
export function getCachedAnswer(cacheKey: string): { answer: string; factsAsOf: string; usedLlm: boolean } | null {
  const entry = responseCache.get(cacheKey);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    responseCache.delete(cacheKey);
    return null;
  }
  return {
    answer: entry.answer,
    factsAsOf: entry.factsAsOf,
    usedLlm: entry.usedLlm,
  };
}

export function setCachedAnswer(
  cacheKey: string,
  answer: string,
  factsAsOf: string,
  usedLlm: boolean,
  ttlSeconds = 60
): void {
  responseCache.set(cacheKey, {
    answer,
    factsAsOf,
    usedLlm,
    expiresAt: Date.now() + ttlSeconds * 1000,
  });
}
