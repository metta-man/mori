type VercelRequest = { method?: string; body?: unknown }
type VercelResponse = {
  setHeader(name: string, value: string): void
  status(code: number): VercelResponse
  json(body: unknown): void
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Cache-Control', 'no-store')
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed.' })

  const distinctId = parseDistinctId(req.body)
  if (!distinctId || !/^user_[0-9A-F-]{36}$/i.test(distinctId)) {
    return res.status(400).json({ error: 'Invalid analytics identifier.' })
  }

  const apiKey = env('POSTHOG_PERSONAL_API_KEY')
  const projectId = env('POSTHOG_PROJECT_ID')
  const host = (env('POSTHOG_HOST') ?? 'https://eu.posthog.com').replace(/\/$/, '')
  if (!apiKey || !projectId) return res.status(503).json({ error: 'Deletion service unavailable.' })

  const headers = { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' }
  const deletion = await fetch(`${host}/api/projects/${projectId}/persons/bulk_delete/`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      distinct_ids: [distinctId],
      delete_events: true,
      delete_recordings: true,
      keep_person: false,
    }),
  })

  // PostHog processes person, event, and recording deletion asynchronously.
  if (deletion.status !== 202) {
    return res.status(502).json({ error: 'Unable to queue analytics data deletion.' })
  }
  return res.status(202).json({ accepted: true })
}

function parseDistinctId(body: unknown): string | undefined {
  let parsed: unknown
  try {
    parsed = typeof body === 'string' ? JSON.parse(body) : body
  } catch {
    return undefined
  }
  if (!parsed || typeof parsed !== 'object') return undefined
  const value = (parsed as { distinctId?: unknown }).distinctId
  return typeof value === 'string' ? value : undefined
}
import { env } from '../../server/pulse/env.js'
