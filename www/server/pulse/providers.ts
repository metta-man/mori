import { env, providerID } from './env.js'
import type { ChatCompletionRequest, ChatCompletionWithSources, PulseSource } from './types.js'

type OpenAICompatibleResponse = {
  choices?: Array<{
    message?: OpenAICompatibleMessage
  }>
}

type OpenAICompatibleMessage = {
  content?: string | Array<{
    type?: string
    text?: string
  }> | null
  annotations?: OpenAIChatAnnotation[]
}

type OpenAIChatAnnotation = {
  type?: string
  url_citation?: {
    title?: string
    url?: string
  }
}

type GeminiResponse = {
  candidates?: Array<{
    content?: {
      parts?: Array<{
        text?: string
      }>
    }
  }>
}

type OpenAIResponseAnnotation = {
  type?: string
  title?: string
  url?: string
}

type OpenAIResponseSource = {
  title?: string
  url?: string
  snippet?: string
  source?: {
    title?: string
    url?: string
  }
}

type OpenAIResponsesResponse = {
  output_text?: string
  output?: Array<{
    type?: string
    content?: Array<{
      type?: string
      text?: string
      annotations?: OpenAIResponseAnnotation[]
    }>
    action?: {
      sources?: OpenAIResponseSource[]
    }
  }>
}

export async function completeChat(request: ChatCompletionRequest): Promise<string> {
  const provider = providerID()

  switch (provider) {
    case 'openai':
      return completeOpenAICompatible({
        apiKeyName: 'OPENAI_API_KEY',
        baseURL: env('MORI_OPENAI_BASE_URL') ?? 'https://api.openai.com/v1/chat/completions',
        model: env('MORI_OPENAI_MODEL') ?? 'gpt-4o-mini',
        request,
      })
    case 'gemini':
      return completeGemini(request)
    case 'deepseek':
      return completeOpenAICompatible({
        apiKeyName: 'DEEPSEEK_API_KEY',
        baseURL: env('MORI_DEEPSEEK_BASE_URL') ?? 'https://api.deepseek.com/chat/completions',
        model: env('MORI_DEEPSEEK_MODEL') ?? 'deepseek-v4-flash',
        request,
      })
  }
}

export async function completeOpenAIChatWithWebSearch(
  request: ChatCompletionRequest,
): Promise<ChatCompletionWithSources> {
  const apiKey = env('OPENAI_API_KEY')
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not configured.')
  }

  const response = await fetch(env('MORI_OPENAI_BASE_URL') ?? 'https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: env('MORI_OPENAI_SEARCH_MODEL') ?? 'gpt-4o-mini-search-preview',
      messages: request.messages,
      max_tokens: request.maxTokens,
      stream: false,
      web_search_options: {
        search_context_size: 'medium',
      },
    }),
  })

  const bodyText = await response.text()
  if (!response.ok) {
    throw new Error(`OpenAI chat web search returned ${response.status}: ${bodyText}`)
  }

  const payload = JSON.parse(bodyText) as OpenAICompatibleResponse
  const message = payload.choices?.[0]?.message
  const text = textFromOpenAICompatibleMessage(message)
  if (!text) {
    throw new Error(`OpenAI chat web search returned an empty response: ${bodyText.slice(0, 700)}`)
  }

  return {
    text,
    sources: sourcesFromOpenAIChatAnnotations(message?.annotations ?? []),
  }
}

export async function searchOpenAI(query: string, count = 2): Promise<PulseSource[]> {
  const apiKey = env('OPENAI_API_KEY')
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not configured.')
  }

  const response = await fetch(env('MORI_OPENAI_BASE_URL') ?? 'https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: env('MORI_OPENAI_SEARCH_MODEL') ?? 'gpt-4o-mini-search-preview',
      messages: [
        {
          role: 'system',
          content:
            'You find current web sources for a calm daily briefing. Return only valid JSON. Do not invent URLs, dates, article titles, or publishers.',
        },
        {
          role: 'user',
          content: `
Find ${count} credible, recent web sources for this query:
${query}

Prefer sources from the last 7 days. Avoid sensational sources. Return only this JSON shape:
{
  "sources": [
    {"title": "Article title", "url": "https://...", "site": "publisher.com", "publishedAt": "YYYY-MM-DD if known", "snippet": "One sentence summary of the useful signal"}
  ]
}
          `.trim(),
        },
      ],
      max_tokens: 900,
      stream: false,
      web_search_options: {
        search_context_size: 'medium',
      },
    }),
  })

  const bodyText = await response.text()
  if (!response.ok) {
    throw new Error(`OpenAI source search returned ${response.status}: ${bodyText}`)
  }

  const payload = JSON.parse(bodyText) as OpenAICompatibleResponse
  const message = payload.choices?.[0]?.message
  const text = textFromOpenAICompatibleMessage(message)
  const textSources = sourcesFromOpenAISearchText(text)
  const annotationSources = sourcesFromOpenAIChatAnnotations(message?.annotations ?? [])
  return dedupeSources([...textSources, ...annotationSources]).slice(0, count)
}

export async function completeOpenAIResponsesWithWebSearch(
  request: ChatCompletionRequest,
): Promise<ChatCompletionWithSources> {
  const apiKey = env('OPENAI_API_KEY')
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not configured.')
  }

  const body = {
    model: env('MORI_OPENAI_MODEL') ?? 'gpt-4o-mini',
    input: request.messages.map((message) => ({
      role: message.role,
      content: [
        {
          type: 'input_text',
          text: message.content,
        },
      ],
    })),
    temperature: request.temperature,
    max_output_tokens: request.maxTokens,
    tools: [
      {
        type: 'web_search',
        external_web_access: true,
      },
    ],
    tool_choice: 'required',
    include: ['web_search_call.action.sources'],
  }

  const response = await fetch(env('MORI_OPENAI_RESPONSES_URL') ?? 'https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  })

  const bodyText = await response.text()
  if (!response.ok) {
    throw new Error(`OpenAI Responses web search returned ${response.status}: ${bodyText}`)
  }

  const payload = JSON.parse(bodyText) as OpenAIResponsesResponse
  const text = textFromOpenAIResponses(payload)
  if (!text) {
    throw new Error('OpenAI Responses web search returned an empty response.')
  }

  return {
    text,
    sources: sourcesFromOpenAIResponses(payload),
  }
}

async function completeOpenAICompatible(args: {
  apiKeyName: string
  baseURL: string
  model: string
  request: ChatCompletionRequest
}): Promise<string> {
  const apiKey = env(args.apiKeyName)
  if (!apiKey) {
    throw new Error(`${args.apiKeyName} is not configured.`)
  }

  const response = await fetch(args.baseURL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: args.model,
      messages: args.request.messages,
      temperature: args.request.temperature,
      max_tokens: args.request.maxTokens,
      stream: false,
      response_format: args.request.json ? { type: 'json_object' } : undefined,
    }),
  })

  const bodyText = await response.text()
  if (!response.ok) {
    throw new Error(`LLM provider returned ${response.status}: ${bodyText}`)
  }

  const payload = JSON.parse(bodyText) as OpenAICompatibleResponse
  const content = textFromOpenAICompatibleMessage(payload.choices?.[0]?.message)
  if (!content) {
    throw new Error(`LLM provider returned an empty response: ${bodyText.slice(0, 700)}`)
  }

  return content
}

async function completeGemini(request: ChatCompletionRequest): Promise<string> {
  const apiKey = env('GEMINI_API_KEY')
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured.')
  }

  const model = env('MORI_GEMINI_MODEL') ?? 'gemini-2.5-flash'
  const modelPath = model.startsWith('models/') ? model : `models/${model}`
  const prompt = request.messages
    .map((message) => `${message.role.toUpperCase()}: ${message.content}`)
    .join('\n\n')

  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/${modelPath}:generateContent`, {
    method: 'POST',
    headers: {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: {
        temperature: request.temperature,
        maxOutputTokens: request.maxTokens,
        responseMimeType: request.json ? 'application/json' : 'text/plain',
      },
    }),
  })

  const bodyText = await response.text()
  if (!response.ok) {
    throw new Error(`Gemini returned ${response.status}: ${bodyText}`)
  }

  const payload = JSON.parse(bodyText) as GeminiResponse
  const content = payload.candidates?.[0]?.content?.parts
    ?.map((part) => part.text)
    .filter(Boolean)
    .join('\n')
    .trim()
  if (!content) {
    throw new Error('Gemini returned an empty response.')
  }

  return content
}

function clean(value: string | undefined): string {
  return value?.trim() ?? ''
}

function textFromOpenAICompatibleMessage(message: OpenAICompatibleMessage | undefined): string {
  const content = message?.content
  if (typeof content === 'string') {
    return content.trim()
  }

  if (Array.isArray(content)) {
    return content
      .map((part) => clean(part.text))
      .filter((text) => text.length > 0)
      .join('\n')
      .trim()
  }

  return ''
}

function textFromOpenAIResponses(payload: OpenAIResponsesResponse): string {
  const directText = clean(payload.output_text)
  if (directText) {
    return directText
  }

  return (payload.output ?? [])
    .flatMap((item) => item.content ?? [])
    .map((content) => clean(content.text))
    .filter((text) => text.length > 0)
    .join('\n')
    .trim()
}

function sourcesFromOpenAIResponses(payload: OpenAIResponsesResponse): PulseSource[] {
  const sources: PulseSource[] = []

  for (const item of payload.output ?? []) {
    for (const source of item.action?.sources ?? []) {
      const nested = source.source
      const url = clean(source.url) || clean(nested?.url)
      if (!url) {
        continue
      }

      sources.push({
        title: clean(source.title) || clean(nested?.title) || hostname(url),
        url,
        site: hostname(url),
        snippet: clean(source.snippet),
      })
    }

    for (const content of item.content ?? []) {
      for (const annotation of content.annotations ?? []) {
        const url = clean(annotation.url)
        if (!url) {
          continue
        }

        sources.push({
          title: clean(annotation.title) || hostname(url),
          url,
          site: hostname(url),
        })
      }
    }
  }

  return dedupeSources(sources).slice(0, 8)
}

function sourcesFromOpenAIChatAnnotations(annotations: OpenAIChatAnnotation[]): PulseSource[] {
  return dedupeSources(
    annotations
      .map((annotation) => {
        const citation = annotation.url_citation
        const url = normalizeURL(clean(citation?.url))
        return {
          title: clean(citation?.title) || hostname(url),
          url,
          site: hostname(url),
        }
      })
      .filter((source) => source.url.length > 0),
  ).slice(0, 8)
}

function sourcesFromOpenAISearchText(text: string): PulseSource[] {
  const parsed = parseJSONCandidate(text) as { sources?: PulseSource[] }
  return dedupeSources(
    (parsed.sources ?? [])
      .map((source) => {
        const url = normalizeURL(clean(source.url))
        return {
          title: clean(source.title) || hostname(url),
          url,
          site: clean(source.site) || hostname(url),
          publishedAt: clean(source.publishedAt),
          snippet: clean(source.snippet),
        }
      })
      .filter((source) => source.url.length > 0),
  )
}

function dedupeSources(sources: PulseSource[]): PulseSource[] {
  const seen = new Set<string>()
  const deduped: PulseSource[] = []
  for (const source of sources) {
    const key = source.url || source.title
    if (!key || seen.has(key)) {
      continue
    }
    seen.add(key)
    deduped.push(source)
  }
  return deduped
}

function hostname(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, '')
  } catch {
    return ''
  }
}

function normalizeURL(url: string): string {
  if (!url) {
    return ''
  }

  try {
    const parsed = new URL(url)
    for (const key of [...parsed.searchParams.keys()]) {
      if (key.toLowerCase().startsWith('utm_')) {
        parsed.searchParams.delete(key)
      }
    }
    return parsed.toString()
  } catch {
    return url
  }
}

function parseJSONCandidate(text: string): unknown {
  const start = text.indexOf('{')
  const end = text.lastIndexOf('}')
  const candidate = start >= 0 && end >= start ? text.slice(start, end + 1) : text
  return JSON.parse(candidate)
}
