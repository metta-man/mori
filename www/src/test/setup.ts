import { cleanup } from '@testing-library/react'
import { afterEach, vi } from 'vitest'

const storage = new Map<string, string>()
Object.defineProperty(window, 'localStorage', {
  configurable: true,
  value: {
    clear: () => storage.clear(),
    getItem: (key: string) => storage.get(key) ?? null,
    key: (index: number) => Array.from(storage.keys())[index] ?? null,
    get length() { return storage.size },
    removeItem: (key: string) => storage.delete(key),
    setItem: (key: string, value: string) => storage.set(key, String(value)),
  },
})

Element.prototype.getClientRects = () => ([{ width: 44, height: 44 }] as unknown as DOMRectList)

if (!window.requestAnimationFrame) {
  window.requestAnimationFrame = (callback) => window.setTimeout(() => callback(Date.now()), 0)
  window.cancelAnimationFrame = (handle) => window.clearTimeout(handle)
}

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
  vi.useRealTimers()
  window.localStorage.clear()
  window.history.replaceState({}, '', '/mori-v2')
})
