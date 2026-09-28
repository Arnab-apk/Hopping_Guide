/**
 * Rule-based intent detection and entity extraction (0ms latency, $0 cost).
 * Works across English, Bengali script, and transliterated Banglish.
 */

export type Intent =
  | 'route'
  | 'blockage_check'
  | 'crowd'
  | 'nearest_station'
  | 'timing'
  | 'helpline'
  | 'other';

export interface DetectedEntities {
  fromText?: string;
  toText?: string;
  placeText?: string;
}

export interface IntentResult {
  intent: Intent;
  entities: DetectedEntities;
  language: 'en' | 'bn' | 'auto';
}

export function detectLanguage(text: string): 'bn' | 'en' {
  // Check for Bengali Unicode script range (\u0980-\u09FF)
  const bengaliRegex = /[\u0980-\u09FF]/;
  return bengaliRegex.test(text) ? 'bn' : 'en';
}

export function detectIntent(msg: string): IntentResult {
  const raw = msg.trim();
  const lower = raw.toLowerCase();
  const lang = detectLanguage(raw);

  // 1. Emergency & Helpline Intent (Top priority for safety)
  if (
    /(emergency|police|helpline|ambulance|doctor|hospital|lost child|bipod|danger|thana|phari|100|112|1090)/i.test(
      lower
    ) ||
    /(জরুরি|পুলিশ|হেল্পলাইন|অ্যাম্বুলেন্স|হাসপাতাল|বিপদ)/.test(raw)
  ) {
    return { intent: 'helpline', entities: {}, language: lang };
  }

  // 2. Road Blockage & Barricade Intent
  if (
    /(block|closed|closure|barricade|open|jam|traffic|road bondho|rasta bondho|barricaded|police diversion)/i.test(
      lower
    ) ||
    /(বন্ধ|ব্যারিকেড|জ্যাম|রাস্তা বন্ধ|ট্রাফিক|খোলা)/.test(raw)
  ) {
    const place = extractPlaceName(raw);
    return {
      intent: 'blockage_check',
      entities: { placeText: place },
      language: lang,
    };
  }

  // 3. Crowd Level Intent
  if (
    /(crowd|busy|rush|bhir|empty|least crowded|kom bhir|line kemon|waiting time|bheer)/i.test(
      lower
    ) ||
    /(ভিড়|কম ভিড়|ফাঁকা|লাইন কেমন|ভিড়)/.test(raw)
  ) {
    const place = extractPlaceName(raw);
    return {
      intent: 'crowd',
      entities: { placeText: place },
      language: lang,
    };
  }

  // 4. Nearest Station & Transit Intent
  if (
    /(nearest metro|metro station|railway station|train station|nearest train|subway|kono station|kache metro)/i.test(
      lower
    ) ||
    /(মেট্রো|কাছের স্টেশন|ট্রেন|কাছের মেট্রো)/.test(raw)
  ) {
    const place = extractPlaceName(raw);
    return {
      intent: 'nearest_station',
      entities: { placeText: place },
      language: lang,
    };
  }

  // 5. Timing & Best Hour Intent
  if (
    /(should i go now|when to visit|best time|after 11|night|kokhon jabo|timing|time to go)/i.test(
      lower
    ) ||
    /(কখন যাব|কখন ভিড় কম|এখন যাওয়া যাবে|সময়)/.test(raw)
  ) {
    const place = extractPlaceName(raw);
    return {
      intent: 'timing',
      entities: { placeText: place },
      language: lang,
    };
  }

  // 6. Route Intent (Default navigation query)
  if (
    /(route|way|how to get|how to go|kibhabe jabo|kothay theke|to |theke|directions|walk to)/i.test(
      lower
    ) ||
    /(কীভাবে যাব|কিভাবে যাব|যেতে হবে|থেকে|রাস্তা|পথ)/.test(raw)
  ) {
    const entities = extractRouteEndpoints(raw);
    return {
      intent: 'route',
      entities,
      language: lang,
    };
  }

  // 7. General / Other query
  const fallbackPlace = extractPlaceName(raw);
  return {
    intent: fallbackPlace ? 'route' : 'other',
    entities: fallbackPlace ? { toText: fallbackPlace } : {},
    language: lang,
  };
}

/**
 * Extracts origin (from) and destination (to) candidates using regex patterns.
 */
function extractRouteEndpoints(query: string): DetectedEntities {
  // Pattern A: "from X to Y" or "from X -> Y"
  const fromToMatch = query.match(/from\s+([^,]+?)\s+(?:to|->|towards)\s+([^?.,]+)/i);
  if (fromToMatch) {
    return {
      fromText: cleanPlaceString(fromToMatch[1]),
      toText: cleanPlaceString(fromToMatch[2]),
    };
  }

  // Pattern B: Bengali Banglish "X theke Y [te / e / jabo]"
  const thekeMatch = query.match(/([^,]+?)\s+(?:theke|hote|thika)\s+([^?.,\s]+(?:\s+[^?.,\s]+)*)/i);
  if (thekeMatch) {
    return {
      fromText: cleanPlaceString(thekeMatch[1]),
      toText: cleanPlaceString(thekeMatch[2].replace(/(?:jabo|jaowar|e|te|jaoa).*$/i, '')),
    };
  }

  // Pattern C: Bengali script "X থেকে Y [যাব/যাওয়ার]"
  const bnFromToMatch = query.match(/([^,]+?)\s+থেকে\s+([^?.,\s]+(?:\s+[^?.,\s]+)*)/);
  if (bnFromToMatch) {
    return {
      fromText: cleanPlaceString(bnFromToMatch[1]),
      toText: cleanPlaceString(bnFromToMatch[2].replace(/(?:যাব|যাওয়ার|তে|এ).*$/, '')),
    };
  }

  // Pattern D: "how to get to Y" / "way to Y"
  const toMatch = query.match(/(?:how to get to|way to|route to|to|kibhabe jabo|directions to)\s+([^?.,]+)/i);
  if (toMatch) {
    return {
      toText: cleanPlaceString(toMatch[1]),
    };
  }

  return {};
}

/**
 * Extracts single candidate place name for blockage or crowd checks.
 */
function extractPlaceName(query: string): string | undefined {
  const cleaned = query
    .replace(/(is|are|the|road|open|closed|blocked|barricaded|crowded|busy|now|today|right now|currently)/gi, '')
    .replace(/(কি|কী|খোলা|বন্ধ|ভিড়|আছে|কেমন|এখন)/g, '')
    .replace(/(nearest metro to|nearest station to|crowd at|crowd near)/gi, '')
    .trim();

  return cleanPlaceString(cleaned);
}

function cleanPlaceString(str?: string): string | undefined {
  if (!str) return undefined;
  const s = str
    .replace(/^(the|a|an)\s+/i, '')
    .replace(/[?!.,;]/g, '')
    .trim();
  return s.length >= 2 ? s : undefined;
}
