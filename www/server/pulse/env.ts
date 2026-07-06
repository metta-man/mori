declare const process: {
  env: Record<string, string | undefined>
}

export type LLMProvider = 'openai' | 'gemini' | 'deepseek'

export function env(name: string): string | undefined {
  const value = process.env[name]?.trim()
  return value && value.length > 0 ? value : undefined
}

export function providerID(): LLMProvider {
  const provider = env('MORI_LLM_PROVIDER')?.toLowerCase()
  if (provider === 'openai' || provider === 'gemini' || provider === 'deepseek') {
    return provider
  }

  return 'deepseek'
}
