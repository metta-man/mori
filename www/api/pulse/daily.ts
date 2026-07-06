import { buildDailyPulse } from '../../server/pulse/service.js'
import { providerID } from '../../server/pulse/env.js'
import type { DailyPulseRequest } from '../../server/pulse/types.js'

type VercelRequest = {
  method?: string
  body?: unknown
}

type VercelResponse = {
  setHeader(name: string, value: string): void
  status(code: number): VercelResponse
  json(body: unknown): void
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  setResponseHeaders(res)

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed.' })
  }

  try {
    const payload = await buildDailyPulse(parseBody(req.body) as DailyPulseRequest)
    return res.status(200).json(payload)
  } catch (error) {
    return res.status(503).json({
      error: error instanceof Error ? error.message : 'Unable to build Clarity Pulse.',
    })
  }
}

function parseBody(body: unknown): unknown {
  if (typeof body === 'string') {
    return JSON.parse(body)
  }
  return body
}

function setResponseHeaders(res: VercelResponse): void {
  res.setHeader('Cache-Control', 'no-store')
  res.setHeader('X-Mori-LLM-Provider', providerID())
}
