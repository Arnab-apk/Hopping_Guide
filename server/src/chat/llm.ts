import dotenv from 'dotenv';
import { SYSTEM_PROMPT, buildUserPrompt } from './prompt';
import { ChatFacts } from './facts';
import { recordLlmCall } from './limits';

// Ensure environment variables are loaded
dotenv.config();

/**
 * Invokes NVIDIA Nemotron 3 Ultra (or specified NVIDIA NIM model).
 */
async function callNvidiaNemotron(
  prompt: string,
  apiKey: string,
  modelName: string
): Promise<string | null> {
  const delays = [0, 1000, 2000];

  for (const delay of delays) {
    if (delay > 0) {
      await new Promise((resolve) => setTimeout(resolve, delay));
    }

    try {
      const response = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: modelName,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user', content: prompt },
          ],
          temperature: 0.2,
          top_p: 0.7,
          max_tokens: 180,
          stream: false,
        }),
      });

      if (response.status === 429) {
        console.warn('[NemotronLLM] 429 Quota exhausted on NVIDIA NIM API.');
        return null;
      }

      if (response.ok) {
        const data = (await response.json()) as any;
        const choice = data.choices?.[0];
        let content = choice?.message?.content;

        // If reasoning model put output in reasoning_content instead of content
        if (!content && choice?.message?.reasoning_content) {
          content = choice.message.reasoning_content;
        }

        if (content && typeof content === 'string') {
          // Clean up any internal thinking tags if present
          const cleaned = content.replace(/<think>[\s\S]*?<\/think>/gi, '').trim();
          if (cleaned.length > 0) {
            recordLlmCall();
            return cleaned;
          }
        }
      } else {
        const errorText = await response.text();
        console.warn(`[NemotronLLM] API returned ${response.status}: ${errorText}`);
      }
    } catch (err) {
      console.warn('[NemotronLLM] Network or execution error:', err);
    }
  }

  return null;
}

/**
 * Invokes Google Gemini API as secondary fallback.
 */
async function callGemini(
  prompt: string,
  apiKey: string,
  modelName: string
): Promise<string | null> {
  const delays = [0, 1000, 2000];

  for (const delay of delays) {
    if (delay > 0) {
      await new Promise((resolve) => setTimeout(resolve, delay));
    }

    try {
      const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${encodeURIComponent(apiKey)}`;
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
          maxOutputTokens: 600,
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
        console.warn('[GeminiLLM] 429 Quota exhausted on Gemini API.');
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

/**
 * Invokes online LLM with multi-tier resilience:
 * 1. Primary: NVIDIA Nemotron 3 Ultra (nvidia/nemotron-3-ultra-550b-a55b)
 * 2. Secondary: Google Gemini (gemini-1.5-flash)
 * 3. Fallback: null (initiates deterministic ground-truth template fallback)
 */
export async function askLLM(
  question: string,
  facts: ChatFacts,
  lang: 'en' | 'bn' | 'auto'
): Promise<string | null> {
  const nvidiaKey = process.env.NVIDIA_API_KEY || '';
  const nvidiaModel = process.env.NVIDIA_MODEL || 'nvidia/nemotron-3-ultra-550b-a55b';
  const geminiKey = process.env.GEMINI_API_KEY || '';
  const geminiModel = process.env.GEMINI_MODEL || 'gemini-1.5-flash';

  const prompt = buildUserPrompt(question, facts, lang);

  // 1. Try NVIDIA Nemotron 3 Ultra if API key is configured
  if (nvidiaKey) {
    const answer = await callNvidiaNemotron(prompt, nvidiaKey, nvidiaModel);
    if (answer) {
      return answer;
    }
  }

  // 2. Try Google Gemini if configured
  if (geminiKey) {
    const answer = await callGemini(prompt, geminiKey, geminiModel);
    if (answer) {
      return answer;
    }
  }

  // 3. If no LLM available or both failed/rate-limited, return null for template fallback
  return null;
}
