import {
  completeChat,
  completeOpenAIChatWithWebSearch,
  completeOpenAIResponsesWithWebSearch,
  searchOpenAI,
} from './providers.js'
import {
  followUpMessages,
  topicPulseMessages,
} from './prompts.js'
import { env, providerID } from './env.js'
import type {
  DailyPulseRequest,
  DailyPulseResponse,
  FollowUpRequest,
  FollowUpResponse,
  MoriLocale,
  PulseCard,
  PulseCardKind,
  PulseSource,
  TopicPulse,
} from './types.js'

type RawPulseCard = PulseCard & { sourceIndexes?: number[] }
type RawTopicPulse = {
  topic?: string
  symbolName?: string
  cards?: RawPulseCard[]
}
type TopicSourceGroup = {
  topic: string
  sources: PulseSource[]
}

const topicCardKinds: PulseCardKind[] = [
  'worthKnowing',
  'worthIgnoring',
  'attentionTrap',
]

const sharedCardKinds: PulseCardKind[] = [
  'resetAction',
  'reclaimedTime',
]

const topicPulseRepairSchema = `{
  "topic": string,
  "symbolName": string,
  "cards": [
    {
      "kind": "worthKnowing" | "worthIgnoring" | "attentionTrap",
      "headline": string,
      "body": string,
      "actionLabel": string,
      "minutes": number,
      "sourceIndexes": number[],
      "sources": [{"title": string, "url": string, "site": string, "publishedAt": string, "snippet": string}],
      "followUpPrompts": string[]
    }
  ]
}`

const followUpRepairSchema = `{
  "answer": string,
  "sourceIndexes": number[],
  "followUpPrompts": string[]
}`

export async function buildDailyPulse(request: DailyPulseRequest): Promise<DailyPulseResponse> {
  assertDailyRequest(request)
  const locale = resolveLocale(request.locale)
  const topics = sanitizeTopics(request.topics, locale)
  let topicSourceGroups: TopicSourceGroup[] = []
  const provider = providerID()
  const liveSearchRequired = provider === 'openai' || Boolean(env('OPENAI_API_KEY'))

  if (provider === 'openai') {
    topicSourceGroups = await searchSourcesByTopic(
      topics,
      async (topic) => searchOpenAISourcesForTopic(topic, topicSearchQuery(topic), 3),
    )
  } else {
    topicSourceGroups = await searchSourcesWithAvailableWebProvider(topics)
  }

  if (liveSearchRequired) {
    assertTopicSourceCoverage(topics, topicSourceGroups)
  }

  const contextReclaimedMinutes = clampInt(request.userContext.reclaimedMinutesToday, 0, 90, 0)
  const reclaimedMinutes = contextReclaimedMinutes > 0
    ? contextReclaimedMinutes
    : 25

  const topicPulses = await Promise.all(
    topics.map((topic) =>
      buildTopicPulse(
        { ...request, topics },
        topic,
        sourcesForTopic(topicSourceGroups, topic),
        reclaimedMinutes,
        locale,
      ),
    ),
  )
  if (liveSearchRequired) {
    assertTopicPulseLiveSources(topicPulses, topicSourceGroups)
  }

  const sharedCards = normalizeSharedCards([], [], reclaimedMinutes, locale)
  const normalizedCards = [...topicPulses.flatMap((topicPulse) => topicPulse.cards), ...sharedCards]

  return {
    dateKey: request.dateKey || dateKey(),
    generatedAt: new Date().toISOString(),
    topics,
    topicPulses,
    sharedCards,
    cards: normalizedCards,
    reclaimedMinutes,
    isMock: false,
  }
}

async function buildTopicPulse(
  request: DailyPulseRequest,
  topic: string,
  topicSources: PulseSource[],
  reclaimedMinutes: number,
  locale: MoriLocale,
): Promise<TopicPulse> {
  const liveSearchAvailable = topicSources.length > 0
  const text = await completeChat({
    messages: topicPulseMessages(request, topic, topicSources, { liveSearchAvailable }),
    temperature: 0.3,
    maxTokens: 1400,
    json: true,
  })
  const payload = await parseJSONWithRepair(text, topicPulseRepairSchema, 1800) as RawTopicPulse
  const rawCards = Array.isArray(payload.cards) ? payload.cards : []

  return {
    topic,
    symbolName: clean(payload.symbolName) || undefined,
    cards: normalizeCardsForKinds(topicCardKinds, rawCards, topicSources, reclaimedMinutes, locale, topic, topicSources),
  }
}

export async function buildFollowUp(request: FollowUpRequest): Promise<FollowUpResponse> {
  assertFollowUpRequest(request)
  const cardSources = request.card.sources ?? []
  let text: string
  let sources: PulseSource[] = cardSources
  const provider = providerID()

  if (provider === 'openai') {
    try {
      const chatWithSearch = await completeOpenAIResponsesWithWebSearch({
        messages: followUpMessages(request, cardSources),
        temperature: 0.25,
        maxTokens: 720,
        json: true,
      })
      text = chatWithSearch.text
      sources = dedupeSources([...cardSources, ...chatWithSearch.sources]).slice(0, 6)
    } catch (responsesError) {
      console.warn(`[pulse] OpenAI Responses follow-up web search failed: ${errorSummary(responsesError)}`)
      try {
        const chatWithSearch = await completeOpenAIChatWithWebSearch({
          messages: followUpMessages(request, cardSources),
          temperature: 0.25,
          maxTokens: 720,
          json: true,
        })
        text = chatWithSearch.text
        sources = dedupeSources([...cardSources, ...chatWithSearch.sources]).slice(0, 6)
      } catch (chatSearchError) {
        console.warn(`[pulse] OpenAI chat follow-up web search failed: ${errorSummary(chatSearchError)}`)
        text = await completeChat({
          messages: followUpMessages(request, cardSources),
          temperature: 0.25,
          maxTokens: 720,
          json: true,
        })
      }
    }
  } else {
    text = await completeChat({
      messages: followUpMessages(request, cardSources),
      temperature: 0.25,
      maxTokens: 720,
      json: true,
    })
  }

  const payload = await parseJSONWithRepair(text, followUpRepairSchema, 1000) as {
    answer?: string
    sourceIndexes?: number[]
    followUpPrompts?: string[]
  }
  const answer = clean(payload.answer)
  if (!answer) {
    throw new Error('Follow-up answer was empty.')
  }

  return {
    answer,
    sources: sourcesForIndexes(sources, payload.sourceIndexes).slice(0, 4),
    followUpPrompts: followUpPromptFallback(sanitizePrompts(payload.followUpPrompts), resolveLocale(request.locale)),
  }
}

function normalizeSharedCards(
  cards: RawPulseCard[],
  sources: PulseSource[],
  reclaimedMinutes: number,
  locale: MoriLocale,
): PulseCard[] {
  return normalizeCardsForKinds(sharedCardKinds, cards, sources, reclaimedMinutes, locale)
}

function normalizeCardsForKinds(
  kinds: PulseCardKind[],
  cards: RawPulseCard[],
  sources: PulseSource[],
  reclaimedMinutes: number,
  locale: MoriLocale,
  topic?: string,
  topicSources: PulseSource[] = [],
): PulseCard[] {
  return kinds.map((kind) => {
    const candidate = cards.find((card) => card.kind === kind)
    const raw = isGenericPlaceholderCard(kind, candidate) ? undefined : candidate
    const fallback = fallbackCard(kind, reclaimedMinutes, locale, topic, topicSources)
    const body = bodyForCard(kind, raw, fallback)
    const cardSources = dedupeSources([
      ...sourcesForCard(kind, raw, sources, topicSources),
      ...sanitizeSources(fallback.sources),
      ...sourcesFromMarkdownLinks(body),
    ]).slice(0, 3)

    return {
      kind,
      headline: kind === 'reclaimedTime' ? fallback.headline : clean(raw?.headline) || fallback.headline,
      body: stripMarkdownLinks(body),
      actionLabel: clean(raw?.actionLabel) || fallback.actionLabel,
      minutes: kind === 'reclaimedTime' ? reclaimedMinutes : raw?.minutes,
      sources: cardSources,
      followUpPrompts: sanitizePrompts(raw?.followUpPrompts ?? fallback.followUpPrompts),
      followUpMessages: [],
    }
  })
}

function isGenericPlaceholderCard(
  kind: PulseCardKind,
  card: RawPulseCard | undefined,
): boolean {
  if (!card || kind === 'resetAction' || kind === 'reclaimedTime') {
    return false
  }

  const text = `${clean(card.headline)} ${clean(card.body)}`.toLowerCase()
  return text.includes('one useful signal is enough') ||
    text.includes('repeated commentary can wait') ||
    text.includes('the sticky part is the refresh') ||
    text.includes('choose the update that changes a real decision')
}

function fallbackCard(
  kind: PulseCardKind,
  reclaimedMinutes: number,
  locale: MoriLocale,
  topic?: string,
  topicSources: PulseSource[] = [],
): PulseCard {
  const copy = fallbackCopy(locale)
  const prefix = topic ? `${topic}: ` : ''
  const sourceBacked = topic ? sourceBackedFallbackCard(kind, topic, topicSources, locale) : undefined
  if (sourceBacked) {
    return sourceBacked
  }

  switch (kind) {
    case 'worthKnowing':
      return {
        kind,
        headline: topic ? copy.topicWorthKnowingHeadline(topic) : `${prefix}${copy.worthKnowingHeadline}`,
        body: topic
          ? copy.topicWorthKnowingBody(topic)
          : copy.worthKnowingBody,
        actionLabel: copy.markUseful,
        followUpPrompts: copy.worthKnowingPrompts,
      }
    case 'worthIgnoring':
      return {
        kind,
        headline: topic ? copy.topicWorthIgnoringHeadline(topic) : `${prefix}${copy.worthIgnoringHeadline}`,
        body: topic
          ? copy.topicWorthIgnoringBody(topic)
          : copy.worthIgnoringBody,
        actionLabel: copy.letItPass,
        followUpPrompts: copy.worthIgnoringPrompts,
      }
    case 'attentionTrap':
      return {
        kind,
        headline: topic ? copy.topicAttentionTrapHeadline(topic) : `${prefix}${copy.attentionTrapHeadline}`,
        body: topic
          ? copy.topicAttentionTrapBody(topic)
          : copy.attentionTrapBody,
        actionLabel: copy.nameTrap,
        followUpPrompts: copy.attentionTrapPrompts,
      }
    case 'resetAction':
      return {
        kind,
        headline: copy.resetHeadline,
        body: copy.resetBody,
        actionLabel: copy.choosePractice,
        followUpPrompts: copy.resetPrompts,
      }
    case 'reclaimedTime':
      return {
        kind,
        headline: copy.reclaimedHeadline(reclaimedMinutes),
        body: copy.reclaimedBody(reclaimedMinutes),
        minutes: reclaimedMinutes,
        followUpPrompts: copy.reclaimedPrompts,
      }
  }
}

function bodyForCard(
  kind: PulseCardKind,
  raw: (PulseCard & { sourceIndexes?: number[] }) | undefined,
  fallback: PulseCard,
): string {
  if (kind === 'reclaimedTime') {
    return fallback.body
  }

  const body = clean(raw?.body) || fallback.body
  if (kind === 'resetAction' && body.split(/\s+/).filter(Boolean).length < 45) {
    return fallback.body
  }

  return body
}

function sourceBackedFallbackCard(
  kind: PulseCardKind,
  topic: string,
  sources: PulseSource[],
  locale: MoriLocale,
): PulseCard | undefined {
  if (kind !== 'worthKnowing' && kind !== 'worthIgnoring' && kind !== 'attentionTrap') {
    return undefined
  }

  const source = sourceForFallback(kind, sources)
  if (!source) {
    return undefined
  }

  const summary = sourceSummary(source)
  const site = clean(source.site) || hostname(source.url) || 'a current source'
  const sourceList = dedupeSources([source, ...sources]).slice(0, 2)
  const copy = fallbackCopy(locale)

  switch (kind) {
    case 'worthKnowing':
      return {
        kind,
        headline: `${topic}: ${sourceHeadline(source)}`,
        body: copy.sourceWorthKnowingBody(site, summary, topic),
        actionLabel: copy.markUseful,
        sources: sourceList,
        followUpPrompts: copy.sourceWorthKnowingPrompts,
      }
    case 'worthIgnoring':
      return {
        kind,
        headline: copy.sourceWorthIgnoringHeadline(topic),
        body: copy.sourceWorthIgnoringBody(summary),
        actionLabel: copy.letItPass,
        sources: sourceList,
        followUpPrompts: copy.sourceWorthIgnoringPrompts,
      }
    case 'attentionTrap':
      return {
        kind,
        headline: copy.sourceAttentionTrapHeadline(topic),
        body: copy.sourceAttentionTrapBody(topic),
        actionLabel: copy.nameTrap,
        sources: sourceList,
        followUpPrompts: copy.sourceAttentionTrapPrompts,
      }
  }
}

function sourceForFallback(kind: PulseCardKind, sources: PulseSource[]): PulseSource | undefined {
  const cleanSources = sanitizeSources(sources)
  if (kind === 'worthIgnoring') {
    return cleanSources[1] ?? cleanSources[0]
  }

  return cleanSources[0]
}

function sourcesForIndexes(sources: PulseSource[], indexes: number[] | undefined): PulseSource[] {
  if (indexes && indexes.length === 0) {
    return []
  }

  const selected = (indexes ?? [])
    .map((index) => sources[index - 1])
    .filter((source): source is PulseSource => Boolean(source))
  return selected.length > 0 ? selected : sources.slice(0, 2)
}

function sourcesForCard(
  kind: PulseCardKind,
  raw: (PulseCard & { sourceIndexes?: number[] }) | undefined,
  sources: PulseSource[],
  topicSources: PulseSource[] = [],
): PulseSource[] {
  if (raw?.sourceIndexes && raw.sourceIndexes.length > 0) {
    const indexedSources = sourcesForIndexes(sources, raw.sourceIndexes)
    if (indexedSources.length > 0) {
      return indexedSources
    }
  }

  const explicitSources = sanitizeSources(raw?.sources)
  if (explicitSources.length > 0) {
    return explicitSources
  }

  if (raw?.sourceIndexes && raw.sourceIndexes.length === 0) {
    return []
  }

  if (kind === 'worthKnowing' || kind === 'worthIgnoring' || kind === 'attentionTrap') {
    if (topicSources.length > 0) {
      return topicSources.slice(0, 2)
    }

    return []
  }

  return []
}

function dedupeSources(sources: PulseSource[]): PulseSource[] {
  const seen = new Set<string>()
  const deduped: PulseSource[] = []
  for (const source of sources) {
    const url = normalizeURL(clean(source.url))
    const key = url || source.title
    if (!key || seen.has(key)) {
      continue
    }
    seen.add(key)
    deduped.push({
      ...source,
      title: clean(source.title) || hostname(url) || 'Untitled source',
      url,
      site: clean(source.site) || hostname(url),
      publishedAt: clean(source.publishedAt),
      snippet: clean(source.snippet),
    })
  }
  return deduped
}

async function searchSourcesByTopic(
  topics: string[],
  search: (topic: string, index: number) => Promise<PulseSource[]>,
): Promise<TopicSourceGroup[]> {
  return Promise.all(
    topics.slice(0, 5).map(async (topic, index) => {
      try {
        const sources = await search(topic, index)
        return {
          topic,
          sources: sanitizeSources(sources).slice(0, 3),
        }
      } catch (error) {
        console.warn(`[pulse] ${topic} source search failed: ${errorSummary(error)}`)
        return { topic, sources: [] }
      }
    }),
  )
}

async function searchSourcesWithAvailableWebProvider(topics: string[]): Promise<TopicSourceGroup[]> {
  if (env('OPENAI_API_KEY')) {
    const queries = topics.slice(0, 5).map(topicSearchQuery)
    return searchSourcesByTopic(
      topics.slice(0, queries.length),
      async (topic, index) => searchOpenAISourcesForTopic(topic, queries[index], 3),
    )
  }

  return []
}

function sourcesForTopic(groups: TopicSourceGroup[], topic: string): PulseSource[] {
  const normalizedTopic = topic.toLowerCase()
  return groups.find((group) => group.topic.toLowerCase() === normalizedTopic)?.sources ?? []
}

function topicSearchQuery(topic: string): string {
  return `${topic} latest news practical update past week what matters`
}

async function searchOpenAISourcesForTopic(topic: string, query: string, count: number): Promise<PulseSource[]> {
  const primary = await searchOpenAI(query, count)
  if (primary.length > 0) {
    return primary
  }

  return searchOpenAI(`${topic} recent credible sources current developments background practical context`, count)
}

function resolveLocale(locale: MoriLocale | undefined): MoriLocale {
  if (locale === 'zh-Hans' || locale === 'zh-Hant') {
    return locale
  }
  return 'en'
}

function defaultTopics(locale: MoriLocale): string[] {
  switch (locale) {
    case 'zh-Hans':
      return ['心智', '健康', '学习']
    case 'zh-Hant':
      return ['心智', '健康', '學習']
    default:
      return ['Mind', 'Wellness', 'Learning']
  }
}

function sanitizeTopics(topics: string[] | undefined, locale: MoriLocale): string[] {
  const cleaned = (topics ?? [])
    .map((topic) => topic.trim())
    .filter((topic) => topic.length > 0)
    .slice(0, 5)
  return cleaned.length > 0 ? cleaned : defaultTopics(locale)
}

function fallbackCopy(locale: MoriLocale) {
  if (locale === 'zh-Hans') {
    return {
      worthKnowingHeadline: '一个有用信号就够了',
      topicWorthKnowingHeadline: (topic: string) => `${topic}: 一个有用信号就够了`,
      worthKnowingBody: '选择真正会改变决定的更新，其余内容先留在今天之外。',
      topicWorthKnowingBody: (topic: string) => `关于${topic}，选择会改变真实决定的更新，其余内容先留在今天之外。重点是把宽泛主题收束成一个有边界的信号，然后在搜索变成循环前停下。`,
      worthIgnoringHeadline: '重复评论可以等一等',
      topicWorthIgnoringHeadline: (topic: string) => `${topic}: 重复评论可以等一等`,
      worthIgnoringBody: '如果它不会改变你的健康、工作、关系或时间安排，就可以不再多看一次。',
      topicWorthIgnoringBody: (topic: string) => `关于${topic}，当重复评论不会改变你的下一步时，就可以等一等。保留有用背景，让反应、排行和猜测先经过，不必再查一次。`,
      attentionTrapHeadline: '黏住你的常常是刷新',
      topicAttentionTrapHeadline: (topic: string) => `${topic}: 黏住你的常常是刷新`,
      attentionTrapBody: '打开另一个信息流前，先说出冲动是什么；无聊、紧张和回避需要不同照顾。',
      topicAttentionTrapBody: (topic: string) => `关于${topic}，黏住你的常常是刷新，而不是信号本身。再打开一个来源前，先分辨这股拉力是好奇、紧张、无聊，还是回避。`,
      resetHeadline: '用一次练习收尾',
      resetBody: '打开另一个来源前，先做一个小重置。慢慢呼吸一分钟，把真正的下一步写成一句话，然后放下手机五分钟。重点不是优化，而是给注意力一个干净的落点。',
      reclaimedHeadline: (minutes: number) => `大约收回 ${minutes} 分钟`,
      reclaimedBody: (minutes: number) => `这个 Pulse 把开放式浏览变成短暂的信号检查，为有开始也有结束的事情保护大约 ${minutes} 分钟。把这段时间用于一个具体下一步、短走一段、写一条安静笔记，或只是不要把空隙填满。`,
      sourceWorthKnowingBody: (site: string, summary: string, topic: string) => `来自 ${site} 的当前来源指向 ${summary}。把它当作有边界的${topic}信号：只检查它是否改变今天的选择、期限、预算或计划。若只是背景，记一次就停止扫描。`,
      sourceWorthIgnoringHeadline: (topic: string) => `${topic}: 跳过重复解读`,
      sourceWorthIgnoringBody: (summary: string) => `当你已经看到关于 ${summary} 的来源更新，重复评论就可以等一等。跳过那些没有新日期、新数字、新决策者或直接后果的重复包装。`,
      sourceAttentionTrapHeadline: (topic: string) => `${topic}: 不追下一个角度`,
      sourceAttentionTrapBody: (topic: string) => `${topic}里的陷阱，是在有用事实已经清楚后继续刷新，追更“新”的角度。打开引用来源一次，记下它影响的决定，然后把预测串和反应排行留在这次会话之外。`,
      markUseful: '标记有用',
      letItPass: '让它经过',
      nameTrap: '说出陷阱',
      choosePractice: '选择练习',
      worthKnowingPrompts: ['真实信号是什么？', '下一步该做什么？'],
      worthIgnoringPrompts: ['为什么可以忽略？', '今天可以跳过什么？'],
      attentionTrapPrompts: ['它为什么黏人？', '怎样退出来？'],
      resetPrompts: ['现在适合哪种练习？', '把它变小一点'],
      reclaimedPrompts: ['怎样保护这段时间？', '这些时间从哪里来？'],
      sourceWorthKnowingPrompts: ['为什么重要？', '我该怎么处理？'],
      sourceWorthIgnoringPrompts: ['为什么忽略？', '真实信号是什么？'],
      sourceAttentionTrapPrompts: ['它为什么黏人？', '怎样避免循环？'],
      followUpFallback: ['让它更实际', '我可以忽略什么？'],
    }
  }

  if (locale === 'zh-Hant') {
    return {
      worthKnowingHeadline: '一個有用信號就夠了',
      topicWorthKnowingHeadline: (topic: string) => `${topic}: 一個有用信號就夠了`,
      worthKnowingBody: '選擇真正會改變決定的更新，其餘內容先留在今天之外。',
      topicWorthKnowingBody: (topic: string) => `關於${topic}，選擇會改變真實決定的更新，其餘內容先留在今天之外。重點是把寬泛主題收束成一個有邊界的信號，然後在搜尋變成循環前停下。`,
      worthIgnoringHeadline: '重複評論可以等一等',
      topicWorthIgnoringHeadline: (topic: string) => `${topic}: 重複評論可以等一等`,
      worthIgnoringBody: '如果它不會改變你的健康、工作、關係或時間安排，就可以不再多看一次。',
      topicWorthIgnoringBody: (topic: string) => `關於${topic}，當重複評論不會改變你的下一步時，就可以等一等。保留有用背景，讓反應、排行和猜測先經過，不必再查一次。`,
      attentionTrapHeadline: '黏住你的常常是刷新',
      topicAttentionTrapHeadline: (topic: string) => `${topic}: 黏住你的常常是刷新`,
      attentionTrapBody: '打開另一個資訊流前，先說出衝動是甚麼；無聊、緊張和迴避需要不同照顧。',
      topicAttentionTrapBody: (topic: string) => `關於${topic}，黏住你的常常是刷新，而不是信號本身。再打開一個來源前，先分辨這股拉力是好奇、緊張、無聊，還是迴避。`,
      resetHeadline: '用一次練習收尾',
      resetBody: '打開另一個來源前，先做一個小重置。慢慢呼吸一分鐘，把真正的下一步寫成一句話，然後放下手機五分鐘。重點不是優化，而是給注意力一個乾淨的落點。',
      reclaimedHeadline: (minutes: number) => `大約收回 ${minutes} 分鐘`,
      reclaimedBody: (minutes: number) => `這個 Pulse 把開放式瀏覽變成短暫的信號檢查，為有開始也有結束的事情保護大約 ${minutes} 分鐘。把這段時間用於一個具體下一步、短走一段、寫一條安靜筆記，或只是不要把空隙填滿。`,
      sourceWorthKnowingBody: (site: string, summary: string, topic: string) => `來自 ${site} 的目前來源指向 ${summary}。把它當作有邊界的${topic}信號：只檢查它是否改變今天的選擇、期限、預算或計劃。若只是背景，記一次就停止掃描。`,
      sourceWorthIgnoringHeadline: (topic: string) => `${topic}: 跳過重複解讀`,
      sourceWorthIgnoringBody: (summary: string) => `當你已經看到關於 ${summary} 的來源更新，重複評論就可以等一等。跳過那些沒有新日期、新數字、新決策者或直接後果的重複包裝。`,
      sourceAttentionTrapHeadline: (topic: string) => `${topic}: 不追下一個角度`,
      sourceAttentionTrapBody: (topic: string) => `${topic}裡的陷阱，是在有用事實已經清楚後繼續刷新，追更「新」的角度。打開引用來源一次，記下它影響的決定，然後把預測串和反應排行留在這次會話之外。`,
      markUseful: '標記有用',
      letItPass: '讓它經過',
      nameTrap: '說出陷阱',
      choosePractice: '選擇練習',
      worthKnowingPrompts: ['真實信號是甚麼？', '下一步該做甚麼？'],
      worthIgnoringPrompts: ['為甚麼可以忽略？', '今天可以略過甚麼？'],
      attentionTrapPrompts: ['它為甚麼黏人？', '怎樣退出來？'],
      resetPrompts: ['現在適合哪種練習？', '把它變小一點'],
      reclaimedPrompts: ['怎樣保護這段時間？', '這些時間從哪裡來？'],
      sourceWorthKnowingPrompts: ['為甚麼重要？', '我該怎樣處理？'],
      sourceWorthIgnoringPrompts: ['為甚麼忽略？', '真實信號是甚麼？'],
      sourceAttentionTrapPrompts: ['它為甚麼黏人？', '怎樣避免循環？'],
      followUpFallback: ['讓它更實際', '我可以忽略甚麼？'],
    }
  }

  return {
    worthKnowingHeadline: 'one useful signal is enough',
    topicWorthKnowingHeadline: (topic: string) => `${topic}: one useful signal is enough`,
    worthKnowingBody: 'Choose the update that changes a real decision and let the rest stay outside your day.',
    topicWorthKnowingBody: (topic: string) => `For ${topic}, choose the update that changes a real decision and let the rest stay outside your day. The point is to turn a broad topic into one bounded signal, then stop before the search becomes a loop.`,
    worthIgnoringHeadline: 'repeated commentary can wait',
    topicWorthIgnoringHeadline: (topic: string) => `${topic}: repeated commentary can wait`,
    worthIgnoringBody: 'If it does not change your health, work, relationships, or timing, it can pass without another check.',
    topicWorthIgnoringBody: (topic: string) => `For ${topic}, repeated commentary can wait when it does not change your next step. Keep the useful context and let reactions, rankings, and speculative takes pass without another check.`,
    attentionTrapHeadline: 'the sticky part is the refresh',
    topicAttentionTrapHeadline: (topic: string) => `${topic}: the sticky part is the refresh`,
    attentionTrapBody: 'Name the urge before opening another feed; boredom, tension, and avoidance need different care.',
    topicAttentionTrapBody: (topic: string) => `For ${topic}, the sticky part is often the refresh, not the signal itself. Name whether the pull is curiosity, tension, boredom, or avoidance before opening another source.`,
    resetHeadline: 'Close with one practice',
    resetBody: 'Choose one small reset before opening another source. Breathe slowly for one minute, write the next real action in a single sentence, then put the phone down for five minutes. The point is not optimization; it is giving your attention a clean place to land.',
    reclaimedHeadline: (minutes: number) => `About ${minutes} minutes reclaimed`,
    reclaimedBody: (minutes: number) => `This Pulse is meant to turn an open-ended scan into a short signal check, protecting about ${minutes} minutes for something with a beginning and an end. Use that time for one concrete next step, a short walk, a quiet note, or simply not filling the gap.`,
    sourceWorthKnowingBody: (site: string, summary: string, topic: string) => `A current source from ${site} points to ${summary}. Use that as the bounded ${topic} signal: check whether it changes a real choice, deadline, budget, or plan today. If it only adds background, note it once and stop scanning.`,
    sourceWorthIgnoringHeadline: (topic: string) => `${topic}: skip repeat takes`,
    sourceWorthIgnoringBody: (summary: string) => `Once you have the source-backed update on ${summary}, repeated commentary can wait. Skip posts that repackage the same claim without a new date, number, decision maker, or direct consequence for your next step.`,
    sourceAttentionTrapHeadline: (topic: string) => `${topic}: do not chase the next angle`,
    sourceAttentionTrapBody: (topic: string) => `The trap in ${topic} is refreshing for a newer angle after the useful fact is already clear. Open the cited source once, capture the decision it affects, then leave prediction threads and reaction rankings outside the session.`,
    markUseful: 'Mark useful',
    letItPass: 'Let it pass',
    nameTrap: 'Name the trap',
    choosePractice: 'Choose practice',
    worthKnowingPrompts: ['What is the real signal?', 'What should I do next?'],
    worthIgnoringPrompts: ['Why ignore this?', 'What can I skip today?'],
    attentionTrapPrompts: ['What makes this sticky?', 'How do I step away?'],
    resetPrompts: ['Which practice fits now?', 'Make this smaller'],
    reclaimedPrompts: ['How do I protect this time?', 'Where did this time come from?'],
    sourceWorthKnowingPrompts: ['Why does this matter?', 'What should I do with this?'],
    sourceWorthIgnoringPrompts: ['Why ignore this?', 'What is the real signal?'],
    sourceAttentionTrapPrompts: ['What makes this sticky?', 'How do I avoid the loop?'],
    followUpFallback: ['Make this practical', 'What can I ignore?'],
  }
}

function assertTopicSourceCoverage(topics: string[], groups: TopicSourceGroup[]): void {
  const missing = topics.filter((topic) => sourcesForTopic(groups, topic).length === 0)
  if (missing.length > 0) {
    throw new Error(`Live web search returned no sources for: ${missing.join(', ')}.`)
  }
}

function assertTopicPulseLiveSources(topicPulses: TopicPulse[], groups: TopicSourceGroup[]): void {
  const missing = topicPulses
    .filter((topicPulse) => !topicPulseHasOwnLiveSource(topicPulse, sourcesForTopic(groups, topicPulse.topic)))
    .map((topicPulse) => topicPulse.topic)

  if (missing.length > 0) {
    throw new Error(`Clarity Pulse could not attach live sources for: ${missing.join(', ')}.`)
  }
}

function topicPulseHasOwnLiveSource(topicPulse: TopicPulse, topicSources: PulseSource[]): boolean {
  const topicSourceURLs = new Set(sanitizeSources(topicSources).map((source) => source.url))
  if (topicSourceURLs.size === 0) {
    return false
  }

  return topicPulse.cards
    .filter((card) => topicCardKinds.includes(card.kind))
    .some((card) => {
      const text = `${clean(card.headline)} ${clean(card.body)}`.toLowerCase()
      const hasGenericText = text.includes('one useful signal is enough') ||
        text.includes('repeated commentary can wait') ||
        text.includes('the sticky part is the refresh') ||
        text.includes('choose the update that changes a real decision')
      if (hasGenericText) {
        return false
      }

      return sanitizeSources(card.sources).some((source) => topicSourceURLs.has(source.url))
    })
}

function sanitizePrompts(prompts: string[] | undefined): string[] {
  return (prompts ?? [])
    .map((prompt) => prompt.trim())
    .filter((prompt) => prompt.length > 0)
    .slice(0, 3)
}

function followUpPromptFallback(prompts: string[], locale: MoriLocale): string[] {
  return prompts.length > 0 ? prompts : fallbackCopy(locale).followUpFallback
}

function sanitizeSources(sources: PulseSource[] | undefined): PulseSource[] {
  return dedupeSources(
    (sources ?? [])
      .map((source) => ({
        title: clean(source.title) || 'Untitled source',
        url: normalizeURL(clean(source.url)),
        site: clean(source.site),
        publishedAt: clean(source.publishedAt),
        snippet: clean(source.snippet),
      }))
      .filter((source) => source.url.length > 0),
  )
}

function sourceSummary(source: PulseSource): string {
  const summary = clean(source.snippet) || clean(source.title) || 'a current development'
  return trimSentence(summary, 150)
}

function sourceHeadline(source: PulseSource): string {
  const title = clean(source.title) || sourceSummary(source)
  return trimSentence(title, 70)
}

function trimSentence(text: string, maxLength: number): string {
  const cleaned = text.replace(/\s+/g, ' ').trim()
  if (cleaned.length <= maxLength) {
    return cleaned
  }

  const truncated = cleaned.slice(0, maxLength - 1).trimEnd()
  const lastSpace = truncated.lastIndexOf(' ')
  return `${truncated.slice(0, lastSpace > 30 ? lastSpace : truncated.length).trimEnd()}...`
}

function sourcesFromMarkdownLinks(text: string): PulseSource[] {
  const sources: PulseSource[] = []
  const linkPattern = /\[([^\]]{1,180})\]\((https?:\/\/[^)\s]+)\)/g
  let match = linkPattern.exec(text)

  while (match) {
    const url = normalizeURL(match[2])
    sources.push({
      title: clean(match[1]) || hostname(url),
      url,
      site: hostname(url),
    })
    match = linkPattern.exec(text)
  }

  return sources
}

function stripMarkdownLinks(text: string): string {
  return text
    .replace(/\s*\(\[([^\]]+)\]\((https?:\/\/[^)]+)\)\)/g, '')
    .replace(/\[([^\]]+)\]\((https?:\/\/[^)]+)\)/g, '$1')
    .replace(/\s{2,}/g, ' ')
    .trim()
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

function hostname(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, '')
  } catch {
    return ''
  }
}

function assertDailyRequest(request: DailyPulseRequest): void {
  if (!request.userContext || typeof request.userContext.clarityScore !== 'number') {
    throw new Error('userContext.clarityScore is required.')
  }
}

function assertFollowUpRequest(request: FollowUpRequest): void {
  if (!request.card?.headline || !request.card?.body) {
    throw new Error('card is required.')
  }
  if (!request.question?.trim()) {
    throw new Error('question is required.')
  }
}

function parseJSON(text: string): unknown {
  const start = text.indexOf('{')
  const end = text.lastIndexOf('}')
  const candidate = start >= 0 && end >= start ? text.slice(start, end + 1) : text
  return JSON.parse(candidate)
}

async function parseJSONWithRepair(text: string, schema: string, maxTokens: number): Promise<unknown> {
  try {
    return parseJSON(text)
  } catch (error) {
    console.warn(`[pulse] JSON parse failed; attempting repair: ${errorSummary(error)}`)
  }

  const repaired = await completeChat({
    messages: [
      {
        role: 'system',
        content:
          'You repair malformed model output into strict JSON. Preserve the original meaning. Fix escaping, trailing commas, markdown fences, and missing commas. Return only valid JSON.',
      },
      {
        role: 'user',
        content: `
Repair this output into valid JSON matching this shape:
${schema}

Malformed output:
${text.slice(0, 12000)}
        `.trim(),
      },
    ],
    temperature: 0,
    maxTokens,
    json: true,
  })

  return parseJSON(repaired)
}

function clean(value: string | undefined): string {
  return value?.trim() ?? ''
}

function clampInt(value: number | undefined, min: number, max: number, fallback: number): number {
  if (typeof value !== 'number' || Number.isNaN(value)) {
    return fallback
  }
  return Math.max(min, Math.min(max, Math.round(value)))
}

function errorSummary(error: unknown): string {
  if (error instanceof Error) {
    return error.message.slice(0, 700)
  }

  return String(error).slice(0, 700)
}

function dateKey(date = new Date()): string {
  return date.toISOString().slice(0, 10)
}
