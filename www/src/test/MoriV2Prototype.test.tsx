import React from 'react'
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, test, vi } from 'vitest'
import App from '../App'
import MoriV2Prototype from '../MoriV2Prototype'

vi.mock('framer-motion', async () => {
  const ReactModule = await import('react')
  const makeMotion = (tag: string) => ReactModule.forwardRef<any, any>((props, ref) => {
    const cleanProps = { ...props }
    for (const key of ['initial', 'animate', 'exit', 'transition', 'layout']) delete cleanProps[key]
    return ReactModule.createElement(tag, { ...cleanProps, ref }, props.children)
  })

  return {
    AnimatePresence: ({ children }: { children: React.ReactNode }) => children,
    motion: {
      article: makeMotion('article'),
      button: makeMotion('button'),
      div: makeMotion('div'),
      img: makeMotion('img'),
      section: makeMotion('section'),
    },
    useReducedMotion: () => true,
  }
})

afterEach(() => {
  vi.useRealTimers()
  vi.restoreAllMocks()
})

describe('Mori v2 core flow', () => {
  test('routes every reason into the configured pause before continuing', async () => {
    const user = userEvent.setup()
    render(<MoriV2Prototype />)

    await user.click(screen.getByRole('button', { name: 'Begin a quiet pause' }))
    const beforeFeed = screen.getByRole('region', { name: 'Before Feed' })
    await waitFor(() => expect(document.activeElement).toBe(beforeFeed))
    expect(screen.getByRole('button', { name: 'Choose a reason' }).hasAttribute('disabled')).toBe(true)

    const reasons = ['Reply to someone', 'Learn', 'Relax', 'Habit', 'Other']
    for (const [index, reason] of reasons.entries()) {
      await user.click(screen.getByRole('radio', { name: reason }))
      await user.click(screen.getByRole('button', { name: 'Continue' }))
      expect(screen.getByRole('timer').getAttribute('aria-label')).toBe('60 seconds remaining')
      expect(screen.queryByRole('button', { name: 'Continue to Instagram' })).toBe(null)
      await user.click(screen.getByRole('button', { name: 'Close Instagram' }))

      if (index < reasons.length - 1) {
        await user.click(screen.getByRole('button', { name: 'Begin a quiet pause' }))
      }
    }
  })

  test('preserves a mood-only Log draft and updates Intent Count after a chosen feed', async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-07-16T00:00:00Z'))
    const anchorClick = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => undefined)
    render(<MoriV2Prototype />)

    fireEvent.click(screen.getByRole('button', { name: 'Begin a quiet pause' }))
    fireEvent.click(screen.getByRole('radio', { name: 'Learn' }))
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }))
    expect(anchorClick).not.toHaveBeenCalled()

    vi.setSystemTime(new Date('2026-07-16T00:01:01Z'))
    act(() => document.dispatchEvent(new Event('visibilitychange')))
    fireEvent.click(screen.getByRole('button', { name: 'Continue to Instagram' }))
    expect(anchorClick).toHaveBeenCalledOnce()
    vi.useRealTimers()

    const user = userEvent.setup()

    await user.click(screen.getByRole('button', { name: 'Log' }))
    const photoInput = document.querySelector<HTMLInputElement>('input[type="file"]')
    expect(photoInput).toBeTruthy()
    await user.upload(photoInput!, new File(['quiet'], 'quiet.jpg', { type: 'image/jpeg' }))
    expect(screen.getByRole('button', { name: 'Remove' })).toBeTruthy()
    await user.click(screen.getByRole('button', { name: 'Remove' }))
    expect(screen.queryByRole('button', { name: 'Remove' })).toBe(null)
    await user.click(screen.getByRole('button', { name: 'Calm' }))
    expect(screen.getByRole('button', { name: 'Done' }).hasAttribute('disabled')).toBe(false)

    await user.click(screen.getByRole('button', { name: 'Today' }))
    await user.click(screen.getByRole('button', { name: 'Log' }))
    expect(screen.getByRole('button', { name: 'Calm' }).getAttribute('aria-pressed')).toBe('true')

    await user.click(screen.getByRole('button', { name: 'Done' }))
    expect(screen.getByRole('heading', { name: 'Kept for today.' })).toBeTruthy()
    await user.click(screen.getByRole('button', { name: 'View quiet notes' }))
    expect(screen.getByText('4 / 5 feeds today')).toBeTruthy()
    expect(screen.getByText(/132 hours lifetime/)).toBeTruthy()
  })

  test('traps Settings focus, restores it on Escape, and preserves switch choices', async () => {
    const user = userEvent.setup()
    render(<MoriV2Prototype />)

    const settingsButton = screen.getByRole('button', { name: 'Open settings' })
    await user.click(settingsButton)
    const close = screen.getByRole('button', { name: 'Close' })
    expect(document.activeElement).toBe(close)

    await user.keyboard('{Shift>}{Tab}{/Shift}')
    expect(document.activeElement).toBe(screen.getByRole('combobox', { name: 'Before Feed reset length' }))
    await user.selectOptions(screen.getByRole('combobox', { name: 'Before Feed reset length' }), '30')
    await user.click(screen.getByRole('switch', { name: 'Quiet bell' }))
    expect(screen.getByRole('switch', { name: 'Quiet bell' }).getAttribute('aria-checked')).toBe('false')

    await user.keyboard('{Escape}')
    await waitFor(() => expect(screen.queryByRole('dialog', { name: 'Settings' })).toBe(null))
    await waitFor(() => expect(document.activeElement).toBe(settingsButton))

    await user.click(settingsButton)
    expect(screen.getByRole('switch', { name: 'Quiet bell' }).getAttribute('aria-checked')).toBe('false')
    expect((screen.getByRole('combobox', { name: 'Before Feed reset length' }) as HTMLSelectElement).value).toBe('30')

    await user.click(screen.getByRole('button', { name: 'Close' }))
    await user.click(screen.getByRole('button', { name: 'Begin a quiet pause' }))
    await user.click(screen.getByRole('radio', { name: 'Other' }))
    await user.click(screen.getByRole('button', { name: 'Continue' }))
    expect(screen.getByRole('timer').getAttribute('aria-label')).toBe('30 seconds remaining')
  })

  test('uses a truthful deadline across pause, resume, and early end', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-07-16T00:00:00Z'))
    render(<MoriV2Prototype />)

    fireEvent.click(screen.getByRole('button', { name: 'Focus' }))
    act(() => vi.advanceTimersByTime(61_000))
    expect(screen.getByLabelText('23:59 remaining')).toBeTruthy()

    fireEvent.click(screen.getByRole('button', { name: 'Pause' }))
    act(() => vi.advanceTimersByTime(10_000))
    expect(screen.getByLabelText('23:59 remaining')).toBeTruthy()

    fireEvent.click(screen.getByRole('button', { name: 'Continue' }))
    act(() => vi.advanceTimersByTime(1_000))
    fireEvent.click(screen.getByRole('button', { name: 'Pause' }))
    fireEvent.click(screen.getByRole('button', { name: 'End quietly' }))

    expect(screen.getByRole('region', { name: 'Session ended quietly' })).toBeTruthy()
    expect(screen.getByRole('heading', { name: 'A quiet moment protected.' })).toBeTruthy()
    expect(screen.getByText('1 quiet minute.')).toBeTruthy()
  })

  test('recalculates breathing on visibility and keeps completion focus behind Settings', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-07-16T00:00:00Z'))
    render(<MoriV2Prototype />)

    fireEvent.click(screen.getByRole('button', { name: 'Begin a quiet pause' }))
    fireEvent.click(screen.getByRole('radio', { name: 'Habit' }))
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }))
    expect(screen.getByRole('timer').getAttribute('aria-label')).toBe('60 seconds remaining')
    expect(screen.queryByRole('button', { name: 'Continue to Instagram' })).toBe(null)

    vi.setSystemTime(new Date('2026-07-16T00:01:01Z'))
    act(() => document.dispatchEvent(new Event('visibilitychange')))
    expect(screen.getByRole('heading', { name: 'Whenever you’re ready' })).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Continue to Instagram' })).toBeTruthy()

    fireEvent.click(screen.getByRole('button', { name: 'Close Instagram' }))
    fireEvent.click(screen.getByRole('button', { name: 'Focus' }))
    fireEvent.click(screen.getByRole('button', { name: 'Open settings' }))
    const close = screen.getByRole('button', { name: 'Close' })
    expect(document.activeElement).toBe(close)

    act(() => vi.advanceTimersByTime(25 * 60 * 1000))
    expect(screen.getByRole('dialog', { name: 'Settings' })).toBeTruthy()
    expect(document.activeElement).toBe(close)

    fireEvent.keyDown(document, { key: 'Escape' })
    act(() => vi.runOnlyPendingTimers())
    act(() => vi.runOnlyPendingTimers())
    const complete = screen.getByRole('region', { name: 'Session complete' })
    expect(document.activeElement).toBe(complete)
    expect(screen.getByText('25 quiet minutes.')).toBeTruthy()
  })

  test('dispatches nested Mori routes without swallowing similar marketing paths', () => {
    window.history.replaceState({}, '', '/mori-v2/deep')
    const nested = render(<App />)
    expect(screen.getByRole('region', { name: 'Today' })).toBeTruthy()
    nested.unmount()

    window.history.replaceState({}, '', '/mori-v2foo')
    render(<App />)
    expect(document.querySelector('.mori-web-hero')).toBeTruthy()
    expect(screen.queryByRole('region', { name: 'Today' })).toBe(null)
  })
})
