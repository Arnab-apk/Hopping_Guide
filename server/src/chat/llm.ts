import { SYSTEM_PROMPT, buildUserPrompt } from './prompt';
import { ChatFacts } from './facts';
import { recordLlmCall } from './limits';

const MODEL = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
const KEY = process.env.GEMINI_API_KEY || '';

/**
 * Invokes Google Gemini API with exponential backoff and automatic quota fallback.
 * Returns null if key is missing, network fails, or 429 rate limit is encountered.
 */
export async function askLLM(
  question: string,
  facts: ChatFacts,
  lang: 'en' | 'bn' | 'auto'
): Promise<string | null> {
  if (!KEY) {
    // If no key provided, gracefully fall back to zero-cost template
    return null;
  }

  const prompt = buildUserPrompt(question, facts, lang);
  const delays = [0, 1000, 2000];

  for (const delay of delays) {
    if (delay > 0) {
      await new Promise((resolve) => setTimeout(resolve, delay));
    }

    try {
      const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${encodeURIComponent(KEY)}`;
      const payload = {
        systemInstruction: {
          parts: [{ text: SYSTEM_PROMPT }],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text: prompt }],
          },
        ],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 300,
        },
      };

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (response.status === 429) {
        console.warn('[GeminiLLM] 429 Quota exhausted. Triggering instant template fallback.');
        return null;
      }

      if (response.ok) {
        const data = (await response.json()) as any;
        const answer = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (answer && typeof answer === 'string') {
          recordLlmCall();
          return answer.trim();
        }
      } else {
        const errorText = await response.text();
        console.warn(`[GeminiLLM] API returned ${response.status}: ${errorText}`);
      }
    } catch (err) {
      console.warn('[GeminiLLM] Network or execution error:', err);
    }
  }

  return null;
}
