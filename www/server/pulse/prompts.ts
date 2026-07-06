import type {
  DailyPulseRequest,
  FollowUpRequest,
  MoriLocale,
  PulseSource,
} from './types.js'

type DailyPulsePromptOptions = {
  liveSearchAvailable?: boolean
}

export function dailyPulseMessages(
  request: DailyPulseRequest,
  sources: PulseSource[],
  options: DailyPulsePromptOptions = {},
) {
  const topics = safeTopics(request.topics, request.locale)
  const language = outputLanguage(request.locale)
  const sourceDigest = sources.map(formatSource).join('\n')
  const liveSearchAvailable = options.liveSearchAvailable ?? sources.length > 0
  const inputMode = liveSearchAvailable
    ? 'Build a daily Clarity Pulse from live search sources and aggregate app context.'
    : 'Build a daily Clarity Pulse from the selected topics and aggregate app context. No live search sources are available in this request.'
  const recencyGuidance = liveSearchAvailable
    ? 'Prioritize concrete, named developments from the last 7 days that match the selected topics. Avoid generic trend summaries unless no credible current signal is available.'
    : 'Do not invent current events, citations, URLs, or source-backed claims. Prefer durable, practical attention guidance tied to the selected topics and app context.'
  const sourceGuidance = liveSearchAvailable
    ? 'Every worthKnowing, worthIgnoring, and attentionTrap card must cite sources that match that exact topic. Do not reuse a source from the first topic for later topics unless the source clearly names that later topic too. Cite sources by sourceIndexes only when the numbered source clearly belongs to the card topic; otherwise include a non-empty sources array with real URLs from the web pages used.'
    : 'Use empty sourceIndexes arrays and omit sources arrays unless actual sources are listed below.'
  const topicCoverage = topics.length > 1
    ? `Topic coverage: create exactly ${topics.length} topicPulses, one for each active topic, in this exact order: ${topics.join(' | ')}. topicPulses.length must be ${topics.length}. Each listed topic must appear once and only once. Do not combine topics or let the first topic crowd out later topics.`
    : `Topic coverage: create exactly 1 topicPulse for "${topics[0]}".`

  return [
    {
      role: 'system' as const,
      content:
        'You are Mori, a calm life clarity assistant. Protect attention while still being concrete. Avoid urgency, sensationalism, medical advice, trading advice, doom framing, and infinite-scroll language. For wellness or health topics, describe information signals and attention choices; do not diagnose, treat, or prescribe.',
    },
    {
      role: 'user' as const,
      content: `
MORI_DAILY_PULSE_V2_JSON
${inputMode}
Each topic pulse should answer three jobs for that exact topic: what matters, what to ignore, and what trap to avoid.
Output language: ${language}.
${recencyGuidance}
${topicCoverage}
Use calm language. Each body must be 35-70 words in 2-3 compact sentences; bodies shorter than 35 words are invalid.
${sourceGuidance}
Do not include markdown links or raw URLs inside body text. Put source URLs only in sourceIndexes or sources arrays.
For live search, each topicPulse must have at least one source-backed signal card tied to that exact topic. If a listed topic has no matching live source, do not fill it with generic advice.
Create exactly one shared resetAction card and exactly one shared reclaimedTime card in sharedCards. Do not put resetAction or reclaimedTime inside topicPulses.
The resetAction card should fit today's app context and give one small attention practice, not general advice. Do not recommend using a health/medical/financial product as the reset action.
The reclaimedTime card should use reclaimedMinutesToday from context and should not introduce a new news topic, product, or health instruction.
The result should feel like useful topic briefs the user chose, not a feed. Do not add topics that are not listed.

Date key: ${request.dateKey ?? ''}
Timezone: ${request.timezone ?? ''}
Topics: ${topics.join(', ')}
Context: clarityScore=${request.userContext.clarityScore}, seedsToday=${request.userContext.seedsToday}, quietMinutesToday=${request.userContext.quietMinutesToday}, reclaimedMinutesToday=${request.userContext.reclaimedMinutesToday}, screenTimeAttemptsToday=${request.userContext.screenTimeAttemptsToday ?? 0}, screenTimeSavedMinutesToday=${request.userContext.screenTimeSavedMinutesToday ?? 0}.
Recent local summaries: ${(request.recentInputs ?? []).slice(0, 4).join(' | ')}

Sources:
${sourceDigest}

Return only valid JSON with this shape:
{
  "reclaimedMinutes": 25,
  "topicPulses": [
    {
      "topic": "${topics[0]}",
      "cards": [
        {"kind":"worthKnowing","headline":"...","body":"...","actionLabel":"Mark useful","sourceIndexes":[1],"sources":[{"title":"...","url":"https://...","site":"...","publishedAt":"...","snippet":"..."}],"followUpPrompts":["Why does this matter?", "What should I do with this?"]},
        {"kind":"worthIgnoring","headline":"...","body":"...","actionLabel":"Let it pass","sourceIndexes":[2],"sources":[{"title":"...","url":"https://...","site":"...","publishedAt":"...","snippet":"..."}],"followUpPrompts":["Why ignore this?", "What is the real signal?"]},
        {"kind":"attentionTrap","headline":"...","body":"...","actionLabel":"Name the trap","sourceIndexes":[3],"sources":[{"title":"...","url":"https://...","site":"...","publishedAt":"...","snippet":"..."}],"followUpPrompts":["What makes this sticky?", "How do I avoid the loop?"]}
      ]
    }
  ],
  "sharedCards": [
    {"kind":"resetAction","headline":"...","body":"...","actionLabel":"Choose practice","sourceIndexes":[],"followUpPrompts":["Which practice fits now?", "Make this smaller"]},
    {"kind":"reclaimedTime","headline":"...","body":"...","minutes":25,"sourceIndexes":[],"followUpPrompts":["Where did this time come from?", "How do I protect it?"]}
  ]
}
      `.trim(),
    },
  ]
}

export function topicPulseMessages(
  request: DailyPulseRequest,
  topic: string,
  sources: PulseSource[],
  options: DailyPulsePromptOptions = {},
) {
  const sourceDigest = sources.map(formatSource).join('\n')
  const language = outputLanguage(request.locale)
  const liveSearchAvailable = options.liveSearchAvailable ?? sources.length > 0
  const sourceGuidance = liveSearchAvailable
    ? 'Use only the numbered sources below. Every card must cite sourceIndexes from this topic source list. Do not invent URLs, publishers, dates, or source-backed claims.'
    : 'No live sources are available. Use empty sourceIndexes arrays and do not invent current events, citations, URLs, article titles, or publishers.'

  return [
    {
      role: 'system' as const,
      content:
        'You are Mori, a calm life clarity assistant. Build one topic pulse only. Protect attention while being concrete. Avoid urgency, sensationalism, medical advice, trading advice, doom framing, and infinite-scroll language.',
    },
    {
      role: 'user' as const,
      content: `
MORI_TOPIC_PULSE_JSON
Build exactly one Clarity Pulse topic section for this topic: ${topic}
Output language: ${language}.
Each card should answer one job for this exact topic: what matters, what to ignore, and what trap to avoid.
${sourceGuidance}
Do not discuss other selected topics. Do not use generic placeholder guidance such as "one useful signal is enough", "repeated commentary can wait", or "the sticky part is the refresh".
Use calm language. Each body must be 35-70 words in 2-3 compact sentences.
Do not include markdown links or raw URLs inside body text. Put source references only in sourceIndexes or sources arrays.

Date key: ${request.dateKey ?? ''}
Timezone: ${request.timezone ?? ''}
Context: clarityScore=${request.userContext.clarityScore}, seedsToday=${request.userContext.seedsToday}, quietMinutesToday=${request.userContext.quietMinutesToday}, reclaimedMinutesToday=${request.userContext.reclaimedMinutesToday}, screenTimeAttemptsToday=${request.userContext.screenTimeAttemptsToday ?? 0}, screenTimeSavedMinutesToday=${request.userContext.screenTimeSavedMinutesToday ?? 0}.
Recent local summaries: ${(request.recentInputs ?? []).slice(0, 4).join(' | ')}

Sources for ${topic}:
${sourceDigest}

Return only valid JSON with this shape:
{
  "topic": "${topic}",
  "cards": [
    {"kind":"worthKnowing","headline":"...","body":"...","actionLabel":"Mark useful","sourceIndexes":[1],"followUpPrompts":["Why does this matter?", "What should I do with this?"]},
    {"kind":"worthIgnoring","headline":"...","body":"...","actionLabel":"Let it pass","sourceIndexes":[1],"followUpPrompts":["Why ignore this?", "What is the real signal?"]},
    {"kind":"attentionTrap","headline":"...","body":"...","actionLabel":"Name the trap","sourceIndexes":[1],"followUpPrompts":["What makes this sticky?", "How do I avoid the loop?"]}
  ]
}
      `.trim(),
    },
  ]
}

export function followUpMessages(request: FollowUpRequest, sources: PulseSource[]) {
  const sourceDigest = sources.map(formatSource).join('\n')
  const language = outputLanguage(request.locale)
  const thread = (request.messages ?? [])
    .slice(-6)
    .map((message) => `${message.role}: ${message.content}`)
    .join('\n')

  return [
    {
      role: 'system' as const,
      content:
        'You are Mori. Answer follow-up questions clearly and calmly. Do not turn the answer into a feed. Avoid medical, legal, trading, or crisis advice. Mention uncertainty when sources are thin.',
    },
    {
      role: 'user' as const,
      content: `
MORI_PULSE_FOLLOW_UP_JSON
Card kind: ${request.card.kind}
Card headline: ${request.card.headline}
Card body: ${request.card.body}
Topics: ${(request.topics ?? []).join(', ')}
Question: ${request.question}
Output language: ${language}.

Recent thread:
${thread}

Sources:
${sourceDigest}

Return only valid JSON:
{
  "answer": "A concise answer in 3-5 short sentences. Start with the direct answer, include the useful context, and close with one bounded practice or reset. Include source references like [1] only when useful.",
  "sourceIndexes": [1],
  "followUpPrompts": ["One useful next question", "One practical next step"]
}
      `.trim(),
    },
  ]
}

export function searchQueries(request: DailyPulseRequest): string[] {
  return safeTopics(request.topics, request.locale)
    .slice(0, 5)
    .map((topic) => `${topic} latest news practical update past week what matters`)
}

export function searchQueryText(request: DailyPulseRequest): string {
  return safeTopics(request.topics, request.locale)
    .slice(0, 5)
    .map((topic) => `${topic} latest news practical update past week`)
    .join('; ')
}

export function followUpSearchQuery(request: FollowUpRequest): string {
  return `${request.card.headline} ${request.question} latest context`
}

function safeTopics(topics: string[] | undefined, locale: MoriLocale | undefined): string[] {
  const cleaned = (topics ?? [])
    .map((topic) => topic.trim())
    .filter((topic) => topic.length > 0)
    .slice(0, 5)
  if (cleaned.length > 0) {
    return cleaned
  }

  switch (locale) {
    case 'zh-Hans':
      return ['心智', '健康', '学习']
    case 'zh-Hant':
      return ['心智', '健康', '學習']
    default:
      return ['Mind', 'Wellness', 'Learning']
  }
}

function outputLanguage(locale: MoriLocale | undefined): string {
  switch (locale) {
    case 'zh-Hans':
      return 'Simplified Chinese'
    case 'zh-Hant':
      return 'Traditional Chinese'
    default:
      return 'English'
  }
}

function formatSource(source: PulseSource, index: number): string {
  const date = source.publishedAt ? ` (${source.publishedAt})` : ''
  const site = source.site ? `${source.site}: ` : ''
  const snippet = source.snippet ? ` - ${source.snippet.slice(0, 520)}` : ''
  return `[${index + 1}] ${site}${source.title}${date} ${source.url}${snippet}`
}
