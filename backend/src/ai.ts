import OpenAI from 'openai';

export class AiNotConfiguredError extends Error {
  constructor() {
    // Shown to students; the setup detail goes to the server log instead.
    super("The AI tutor isn't available right now. Please try again later.");
    console.warn('AI request refused: OPENAI_API_KEY is not set');
  }
}

const key = process.env.OPENAI_API_KEY;
export const aiConfigured = !!key && !key.includes('your_') && !key.includes('dummy');
const client = aiConfigured ? new OpenAI({ apiKey: key }) : null;

export const TUTOR_PROMPT =
  "You are AutoLearn's tutor. Help students understand whatever subject they are studying. " +
  'Explain with intuition first, then the formal idea; use a worked example or a diagram described in words when it helps; ' +
  'use real-world examples; end with one short question that checks understanding. Be concise and encouraging.';

type Msg = { role: 'system' | 'user' | 'assistant'; content: string };

/** One chat completion. Throws AiNotConfiguredError when no key is set. */
export async function complete(messages: Msg[], opts: { json?: boolean; maxTokens?: number } = {}): Promise<string> {
  if (!client) throw new AiNotConfiguredError();
  const res = await client.chat.completions.create({
    model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
    messages,
    temperature: 0.4,
    max_tokens: opts.maxTokens ?? 800,
    ...(opts.json && { response_format: { type: 'json_object' as const } }),
  });
  const content = res.choices[0]?.message?.content;
  if (!content) throw new Error('AI returned an empty response');
  return content;
}

/** Maps AI errors to HTTP responses so every controller reports them the same way. */
export function aiErrorStatus(e: unknown): { status: number; error: string } {
  if (e instanceof AiNotConfiguredError) return { status: 503, error: e.message };
  return { status: 502, error: 'The AI service failed to respond. Please try again.' };
}
