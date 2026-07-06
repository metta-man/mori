export type PulseCardKind =
  | 'worthKnowing'
  | 'worthIgnoring'
  | 'attentionTrap'
  | 'resetAction'
  | 'reclaimedTime'

export type PulseSource = {
  title: string
  url: string
  site?: string
  publishedAt?: string
  snippet?: string
}

export type MoriLocale = 'en' | 'zh-Hans' | 'zh-Hant'

export type PulseCard = {
  id?: string
  kind: PulseCardKind
  headline: string
  body: string
  actionLabel?: string
  minutes?: number
  sources?: PulseSource[]
  followUpPrompts?: string[]
  followUpMessages?: PulseFollowUpMessage[]
}

export type TopicPulse = {
  id?: string
  topic: string
  symbolName?: string
  cards: PulseCard[]
}

export type PulseFollowUpRole = 'user' | 'assistant'

export type PulseFollowUpMessage = {
  id?: string
  role: PulseFollowUpRole
  content: string
  createdAt?: string
  sources?: PulseSource[]
}

export type PulseUserContext = {
  clarityScore: number
  seedsToday: number
  quietMinutesToday: number
  reclaimedMinutesToday: number
  screenTimeAttemptsToday?: number
  screenTimeSavedMinutesToday?: number
  weeklyProofCompleted?: boolean
}

export type DailyPulseRequest = {
  dateKey?: string
  timezone?: string
  locale?: MoriLocale
  topics?: string[]
  userContext: PulseUserContext
  recentInputs?: string[]
}

export type DailyPulseResponse = {
  dateKey: string
  generatedAt: string
  topics: string[]
  topicPulses: TopicPulse[]
  sharedCards: PulseCard[]
  cards: PulseCard[]
  reclaimedMinutes: number
  isMock: boolean
}

export type FollowUpRequest = {
  dateKey?: string
  timezone?: string
  locale?: MoriLocale
  topics?: string[]
  card: PulseCard
  question: string
  messages?: PulseFollowUpMessage[]
  userContext?: PulseUserContext
}

export type FollowUpResponse = {
  answer: string
  sources: PulseSource[]
  followUpPrompts: string[]
}

export type ChatMessage = {
  role: 'system' | 'user' | 'assistant'
  content: string
}

export type ChatCompletionRequest = {
  messages: ChatMessage[]
  temperature: number
  maxTokens: number
  json: boolean
}

export type ChatCompletionWithSources = {
  text: string
  sources: PulseSource[]
}
