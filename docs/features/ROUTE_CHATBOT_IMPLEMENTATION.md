# 🤖 UMA Route Assistant: Chatbot Implementation Guide

> Location: `docs/features/ROUTE_CHATBOT_IMPLEMENTATION.md`
> Goal: an in-app chatbot that answers "what's the best way to get from X to Y?" using the **latest road blockages and crowd levels**, at **$0 cost**.

---

## 1. Core Design Principle: Ground the Bot, Don't Let It Guess

A language model has no knowledge of tonight's barricades in Kolkata. If you let it answer from its own knowledge, it will confidently invent routes and closures. So:

> **Your code computes the facts. The model only turns facts into a friendly answer.**

```
User question
   │
   ▼
1. Intent + place detection (deterministic rules, no LLM)
   │
   ▼
2. Fact gathering (on-device & backend data)
   ├─ Route (GemKit / device routing)
   ├─ Active blockages (Redis / Postgres / Police notices)
   ├─ Crowd levels (aggregated reports, min. 3 contributors)
   └─ Nearest stations, pandal info (bundled offline JSON)
   │
   ▼
3. Facts JSON  ──►  4. LLM writes the answer (facts only)
   │                       │
   └── quota exhausted ──► 4b. Template fallback (deterministic, no LLM)
```

Benefits:
- One LLM call per question (preserves Google AI Studio free-tier quotas).
- Zero hallucinated road closures, barricades, or metro timings.
- The chatbot operates gracefully even when offline or when external AI quotas are depleted.

---

## 2. Cost Model ($0)

| Component | Free option | Notes |
|:---|:---|:---|
| **LLM** | Google Gemini API free tier (Google AI Studio) | Flash-class models (`gemini-2.5-flash` / `gemini-1.5-flash`). Conservative request budgets: ~10-15 req/min and ~1,000 req/day. |
| **Place resolution** | Bundled pandal (`pandals.json`) and station (`stations.geojson`) data | 100% offline-ready, no paid geocoding APIs. |
| **Routing** | On-device GemKit pedestrian routing | Zero cloud routing overhead. |
| **Blockage and crowd data** | In-memory / Redis + Neon Postgres | Reuses existing squad and telemetry stack. |
| **Server** | Existing Node.js WebSocket & REST API server | Single lightweight `POST /chat` endpoint with local in-app fallback. |

> ⚠️ **Privacy tradeoff:** Google's terms indicate that free-tier API inputs and outputs may be processed for service improvement. Therefore, **never transmit user identifiers, names, phone numbers, or high-precision live GPS coordinates to the LLM**. Only pass fuzzy place names and sanitized fact summaries.

---

## 3. What the Bot Can Answer

| Question Type | Facts Needed | Example Output |
|:---|:---|:---|
| **Route advice** | Route distance + duration + blockages on path + crowd at destination | "Howrah to Kumartuli is ~5.2 km (~65 min walk). Note: barricades reported near Rabindra Sarani 15 min ago. Destination crowd is moderate." |
| **Blockage check** | Active police closures & crowd barricades near queried landmark | "Central Ave crossing near MG Road has police pedestrian barricades reported 8 min ago." |
| **Crowd intelligence** | Pandal crowd levels sorted ascending | "Currently lowest crowd in North: Baghbazar Sarbojanin and Kumartuli Park." |
| **Nearest stations** | Precomputed `nearest_stations` from station integration | "Baghbazar Sarbojanin is 450 m from Shyambazar Metro (Gate 1)." |
| **Visit timing** | Baseline hourly crowd pattern + live squad density | "Historically, crowd triples after 9 PM. Visiting before 7:30 PM is strongly recommended." |
| **Multilingual** | Bengali, English, and Transliterated Bengali ("Banglish") | The bot responds in the user's selected language. |

**Out of scope:**
- Medical / policing emergencies: Bot immediately serves verified helplines (Kolkata Police `100/112`, Women Helpline `1090/1091`, Ambulance `102/108`).
- Live train tracking: Bot deep-links out to official NTES / IRCTC portal.

---

## 4. Server Architecture (`server/src/chat/`)

```
server/src/chat/
  ├── intent.ts        # Intent classification & origin/destination extraction
  ├── resolve.ts       # Fuzzy matching names -> pandal/station identifiers
  ├── facts.ts         # Gathers blockages, crowd status, route metrics
  ├── prompt.ts        # Strict grounding system prompt + injection defenses
  ├── llm.ts           # Gemini API call with retries and 429 quota handling
  ├── templates.ts     # Deterministic zero-LLM template generator (fallback)
  ├── limits.ts        # Per-device rate limiter & global daily budget keeper
  └── routes.ts        # Express / HTTP request dispatcher for POST /chat
```

### 4.1 Request & Response Contract

```jsonc
// POST /chat or POST /api/chat
{
  "deviceId": "anon-uuid-41a2",
  "message": "Howrah theke Kumartuli jaowar best route ki?",
  "route": {
    "distance_m": 5200,
    "duration_s": 3900,
    "polyline": "encoded...",
    "mode": "pedestrian"
  },
  "lang": "auto"
}
```

```jsonc
// 200 OK Response
{
  "answer": "হাওড়া স্টেশন থেকে কুমারটুলি প্রায় ৫.২ কিমি (৬৫ মিনিট হাঁটা পথ)...",
  "facts_as_of": "2026-10-19T21:42:00.000Z",
  "used_llm": true,
  "intent": "route",
  "detected_places": {
    "from": "Howrah Junction",
    "to": "Kumartuli Park"
  }
}
```

---

## 5. Staying Within Free-Tier Limits ($0 Operating Cost)

1. **Per-Device Rate Limiting**: Max 10 queries per device per hour.
2. **Global Daily Quota Protection**: When daily Gemini API requests exceed 80% of quota (~800 requests), system seamlessly switches all queries to deterministic template fallback.
3. **Response Caching (60s TTL)**: Repeated common queries (e.g., "Howrah to College Square") serve cached responses without hitting the LLM.
4. **Quick-Reply Template Shortcuts**: Frequently tapped chips ("Emergency Helplines", "Nearest Metro") skip the LLM and render instant grounded templates.
5. **Token Cap**: Output tokens capped at 300 tokens to ensure rapid generation and minimal consumption.

---

## 6. Privacy, Security & Anti-Injection Rules

- **No Personal Identifiers**: User IDs, phone numbers, companion names, and raw GPS logs are stripped before facts are passed to the model.
- **Strict Data Sanitization**: Blockage reports are mapped strictly to enumeration values (`road_blocked`, `barricade`, `crowd_diverted`), never raw user text notes.
- **System Instructions Enforcement**: System prompt treats user text and facts as untrusted data strings. Any injection attempts (e.g. "Ignore previous instructions") are neutralized.

---

## 7. Verification Checklist

- [x] Intent detection handles English, Bengali script, and transliterated Banglish
- [x] Fuzzy resolution correctly maps pandals, circular railway, and metro stations
- [x] Stale facts (> 45 min) flagged with unconfirmed warnings
- [x] Template fallback automatically responds when LLM is unavailable or rate-limited
- [x] Per-device and global budget limiters prevent quota exhaustion
- [x] Zero external geocoding or routing fees ($0 spend)
- [x] In-app disclaimer and emergency helpline integration
