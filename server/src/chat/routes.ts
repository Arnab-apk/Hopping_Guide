import { detectIntent } from './intent';
import { resolvePlace, ResolvedPlace } from './resolve';
import {
  gatherRouteFacts,
  RouteClientSummary,
  FactBlock,
  buildFactBlocks,
  buildFactActions,
  getActiveAlertsSummary,
} from './facts';
import { askLLM } from './llm';
import {
  templateRouteAnswer,
  templateBlockageAnswer,
  templateCrowdAnswer,
  templateStationAnswer,
  templateHelplineAnswer,
  templateSuggestionsAnswer,
} from './templates';
import {
  checkDeviceLimit,
  isGlobalLlmBudgetAvailable,
  getCachedAnswer,
  setCachedAnswer,
} from './limits';

export interface ChatRequestBody {
  deviceId?: string;
  message?: string;
  route?: RouteClientSummary;
  lang?: 'en' | 'bn' | 'auto';
}

export interface ChatResponseBody {
  answer: string;
  facts_as_of: string;
  used_llm: boolean;
  intent: string;
  blocks?: FactBlock[];
  actions?: string[];
  detected_places?: {
    from?: string;
    to?: string;
    place?: string;
  };
  suggestions?: string[];
}

export function handleStatusRequest(): { status: number; data: any } {
  return {
    status: 200,
    data: getActiveAlertsSummary(),
  };
}

export async function handleChatRequest(body: ChatRequestBody): Promise<{ status: number; data: any }> {
  const deviceId = body.deviceId || 'anon-guest-device';
  const rawMessage = (body.message || '').trim();
  const clientRoute = body.route;
  const requestedLang = body.lang || 'auto';

  if (!rawMessage) {
    return {
      status: 400,
      data: { error: { code: 'EMPTY_MESSAGE', message: 'Chat message cannot be empty' } },
    };
  }

  // 1. Device Rate Limiting (10 questions/hour per device)
  const rateLimit = checkDeviceLimit(deviceId);
  if (!rateLimit.allowed) {
    return {
      status: 429,
      data: {
        error: {
          code: 'RATE_LIMITED',
          message: 'You have asked 10 questions this hour. Please wait a short while or browse the map directly.',
        },
      },
    };
  }

  // 2. Intent Detection
  const { intent, entities, language } = detectIntent(rawMessage);
  const effectiveLang: 'en' | 'bn' = requestedLang === 'bn' || language === 'bn' ? 'bn' : 'en';

  // 3. Fast-path: Emergency Helpline
  if (intent === 'helpline') {
    return {
      status: 200,
      data: {
        answer: templateHelplineAnswer(effectiveLang),
        facts_as_of: new Date().toISOString(),
        used_llm: false,
        intent,
      },
    };
  }

  // 4. Place Resolution
  let fromPlace: ResolvedPlace | null = null;
  let toPlace: ResolvedPlace | null = null;
  let targetPlace: ResolvedPlace | null = null;
  const suggestions: ResolvedPlace[] = [];

  if (entities.fromText) {
    const res = resolvePlace(entities.fromText);
    fromPlace = res.match;
    if (!res.match && res.suggestions.length > 0) suggestions.push(...res.suggestions);
  }

  if (entities.toText) {
    const res = resolvePlace(entities.toText);
    toPlace = res.match;
    if (!res.match && res.suggestions.length > 0) suggestions.push(...res.suggestions);
  }

  if (entities.placeText) {
    const res = resolvePlace(entities.placeText);
    targetPlace = res.match;
    if (!res.match && res.suggestions.length > 0) suggestions.push(...res.suggestions);
    if (!toPlace) toPlace = targetPlace;
  }

  // If a specific place was asked for but couldn't be resolved with confidence
  if ((entities.toText || entities.placeText) && !toPlace && suggestions.length > 0) {
    return {
      status: 200,
      data: {
        answer: templateSuggestionsAnswer(suggestions, effectiveLang),
        facts_as_of: new Date().toISOString(),
        used_llm: false,
        intent,
        suggestions: suggestions.map((s) => s.name),
      },
    };
  }

  // 5. Response Cache Check (60s TTL)
  const cacheKey = `${intent}_${fromPlace?.id || 'none'}_${toPlace?.id || 'none'}_${effectiveLang}`;
  const cached = getCachedAnswer(cacheKey);
  if (cached) {
    return {
      status: 200,
      data: {
        answer: cached.answer,
        facts_as_of: cached.factsAsOf,
        used_llm: cached.usedLlm,
        intent,
        detected_places: {
          from: fromPlace?.name,
          to: toPlace?.name,
        },
      },
    };
  }

  // 6. Gather Ground-Truth Facts
  const facts = await gatherRouteFacts(fromPlace, toPlace, clientRoute);

  // 7. Generation (LLM vs Deterministic Template)
  let answer: string | null = null;
  let usedLlm = false;

  if (isGlobalLlmBudgetAvailable()) {
    answer = await askLLM(rawMessage, facts, effectiveLang);
    if (answer) {
      usedLlm = true;
    }
  }

  // If LLM returned null or daily budget reached: apply deterministic template
  if (!answer) {
    usedLlm = false;
    switch (intent) {
      case 'blockage_check':
        answer = templateBlockageAnswer(facts, effectiveLang);
        break;
      case 'crowd':
        answer = templateCrowdAnswer(facts, effectiveLang);
        break;
      case 'nearest_station':
        answer = templateStationAnswer(facts, effectiveLang);
        break;
      case 'route':
      default:
        answer = templateRouteAnswer(facts, effectiveLang);
        break;
    }
  }

  // Cache response for 60 seconds
  setCachedAnswer(cacheKey, answer, facts.generated_at, usedLlm, 60);

  const blocks = buildFactBlocks(facts);
  const actions = buildFactActions(facts);

  return {
    status: 200,
    data: {
      answer,
      facts_as_of: facts.generated_at,
      used_llm: usedLlm,
      intent,
      blocks,
      actions,
      detected_places: {
        from: fromPlace?.name,
        to: toPlace?.name,
      },
    },
  };
}
