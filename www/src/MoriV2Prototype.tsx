import { AnimatePresence, motion, useReducedMotion } from 'framer-motion'
import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import appLimitPaper from './assets/v2/mori-before-feed-paper-v2.webp'
import practicePaper from './assets/v2/mori-breathing-paper-v2.webp'
import breathingRing from './assets/v2/mori-breathing-ring-v2.webp'
import forestPaper from './assets/v2/mori-deep-session-forest-v2.webp'
import todayPaper from './assets/v2/mori-log-paper-v2.webp'
import { MoriIcon } from './components/Icon'
import './styles/mori-v2.css'

type RootTab = 'today' | 'focus' | 'log'
type Flow = 'root' | 'beforeFeed' | 'breathing' | 'sessionComplete'
type FeedReason = 'reply' | 'learn' | 'relax' | 'habit' | 'other'
type Mood = 'Calm' | 'Clear' | 'Neutral' | 'Tired' | 'Drained'
type LogEntry = { mood: Mood | null; note: string; photo: File | null; saved: boolean }
type SettingsPreferences = {
  quietBell: boolean
  gentleHaptics: boolean
  beforeFeedDurationSeconds: number
}
type QuietMetrics = {
  intentCount: number
  intentBudget: number
  todayMinutes: number
  weekMinutes: number
  lifeMinutes: number
}

const feedReasons: Array<{ value: FeedReason; label: string }> = [
  { value: 'reply', label: 'Reply to someone' },
  { value: 'learn', label: 'Learn' },
  { value: 'relax', label: 'Relax' },
  { value: 'habit', label: 'Habit' },
  { value: 'other', label: 'Other' },
]

const moods: Mood[] = ['Calm', 'Clear', 'Neutral', 'Tired', 'Drained']
const beforeFeedDurationOptions = [30, 60, 2 * 60, 5 * 60, 10 * 60]

function formatTime(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}

function formatDuration(totalSeconds: number) {
  if (totalSeconds < 60) return `${totalSeconds} seconds`
  const minutes = totalSeconds / 60
  return minutes === 1 ? '1 minute' : `${minutes} minutes`
}

function formatLifeQuietTime(totalMinutes: number) {
  const hours = Math.floor(totalMinutes / 60)
  const minutes = totalMinutes % 60
  return minutes === 0 ? `${hours} hours lifetime` : `${hours}h ${minutes}m lifetime`
}

function Screen({
  screenKey,
  screenLabel,
  children,
  className = '',
}: {
  screenKey: string
  screenLabel: string
  children: React.ReactNode
  className?: string
}) {
  const shouldReduceMotion = useReducedMotion()
  const sectionRef = useRef<HTMLElement>(null)

  useEffect(() => {
    const frame = window.requestAnimationFrame(() => {
      if (sectionRef.current?.closest('[aria-hidden="true"]')) return
      sectionRef.current?.focus({ preventScroll: true })
    })
    return () => window.cancelAnimationFrame(frame)
  }, [screenKey])

  return (
    <motion.section
      ref={sectionRef}
      key={screenKey}
      className={`mori-v2-screen ${className}`}
      role="region"
      aria-label={screenLabel}
      tabIndex={-1}
      initial={shouldReduceMotion ? { opacity: 0 } : { opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={shouldReduceMotion ? { opacity: 0 } : { opacity: 0, y: -5 }}
      transition={{ duration: shouldReduceMotion ? 0.12 : 0.46, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.section>
  )
}

function WatercolorScene({ source, position = 'center' }: { source: string; position?: string }) {
  const shouldReduceMotion = useReducedMotion()

  return (
    <motion.img
      className="mori-v2-scene"
      src={source}
      alt=""
      aria-hidden="true"
      style={{ objectPosition: position }}
      animate={
        shouldReduceMotion
          ? { opacity: 1 }
          : { scale: [1.015, 1.028, 1.015], y: [0, -5, 0], opacity: [0.96, 1, 0.96] }
      }
      transition={
        shouldReduceMotion
          ? { duration: 0 }
          : { duration: 22, repeat: Number.POSITIVE_INFINITY, ease: 'easeInOut' }
      }
    />
  )
}

function SettingsButton({ onOpen }: { onOpen: () => void }) {
  return (
    <button type="button" className="mori-v2-icon-button" onClick={onOpen} aria-label="Open settings">
      <MoriIcon name="settings" size={24} />
    </button>
  )
}

function RootHeader({
  title,
  subtitle,
  onOpenSettings,
}: {
  title: string
  subtitle: string
  onOpenSettings: () => void
}) {
  return (
    <header className="mori-v2-header">
      <div>
        <h1>{title}</h1>
        <p>{subtitle}</p>
      </div>
      <SettingsButton onOpen={onOpenSettings} />
    </header>
  )
}

function TabBar({ tab, onChange }: { tab: RootTab; onChange: (tab: RootTab) => void }) {
  const items: Array<{ tab: RootTab; label: string; icon: 'home' | 'focus' | 'journal' }> = [
    { tab: 'today', label: 'Today', icon: 'home' },
    { tab: 'focus', label: 'Focus', icon: 'focus' },
    { tab: 'log', label: 'Log', icon: 'journal' },
  ]

  return (
    <nav className="mori-v2-tabbar" aria-label="Main navigation">
      {items.map((item) => (
        <button
          key={item.tab}
          type="button"
          className="mori-v2-tab"
          data-active={tab === item.tab}
          aria-current={tab === item.tab ? 'page' : undefined}
          onClick={() => onChange(item.tab)}
        >
          <MoriIcon name={item.icon} size={22} />
          <span>{item.label}</span>
        </button>
      ))}
    </nav>
  )
}

function TodayScreen({ onBegin, onOpenSettings }: { onBegin: () => void; onOpenSettings: () => void }) {
  return (
    <Screen screenKey="today" screenLabel="Today" className="mori-v2-today">
      <WatercolorScene source={forestPaper} position="center bottom" />
      <RootHeader
        title="Today"
        subtitle="One mindful choice at a time."
        onOpenSettings={onOpenSettings}
      />

      <div className="mori-v2-today-space" aria-hidden="true" />

      <motion.article
        className="mori-v2-next-card"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.1, duration: 0.7 }}
      >
        <div className="mori-v2-card-status">
          <MoriIcon name="lockShield" size={19} />
          <span>App Limit Active</span>
        </div>
        <h2>Before Feed Reset</h2>
        <p>Pause before Instagram opens.</p>
        <button type="button" className="mori-v2-primary" onClick={onBegin}>
          Begin a quiet pause
        </button>
        <small>Complete the pause, then choose.</small>
      </motion.article>
    </Screen>
  )
}

function BeforeFeedScreen({
  reason,
  onReasonChange,
  onBack,
  onContinue,
  onCloseInstagram,
}: {
  reason: FeedReason | null
  onReasonChange: (reason: FeedReason) => void
  onBack: () => void
  onContinue: () => void
  onCloseInstagram: () => void
}) {
  return (
    <Screen screenKey="before-feed" screenLabel="Before Feed" className="mori-v2-before-feed">
      <WatercolorScene source={appLimitPaper} position="center bottom" />
      <header className="mori-v2-flow-header">
        <button type="button" className="mori-v2-back" onClick={onBack} aria-label="Back to Today">
          <MoriIcon name="chevron" size={20} />
        </button>
        <p>You’re opening</p>
        <h1>Instagram</h1>
        <span>Take a breath. Why now?</span>
      </header>

      <fieldset className="mori-v2-reasons">
        <legend className="sr-only">Why are you opening Instagram?</legend>
        {feedReasons.map((item) => (
          <label key={item.value} className="mori-v2-reason" data-selected={reason === item.value}>
            <span>{item.label}</span>
            <input
              type="radio"
              name="feed-reason"
              value={item.value}
              checked={reason === item.value}
              onChange={() => onReasonChange(item.value)}
            />
          </label>
        ))}
      </fieldset>

      <div className="mori-v2-flow-actions">
        <button
          type="button"
          className="mori-v2-primary"
          onClick={onContinue}
          disabled={reason === null}
        >
          {reason === null ? 'Choose a reason' : 'Continue'}
        </button>
        <button type="button" className="mori-v2-text-button" onClick={onCloseInstagram}>
          Close Instagram
        </button>
      </div>
    </Screen>
  )
}

function BreathingScreen({
  seconds,
  durationSeconds,
  onContinue,
  onCloseInstagram,
}: {
  seconds: number
  durationSeconds: number
  onContinue: () => void
  onCloseInstagram: () => void
}) {
  const shouldReduceMotion = useReducedMotion()
  const phase = Math.floor((durationSeconds - seconds) / 4) % 2 === 0 ? 'Breathe in' : 'Breathe out'

  return (
    <Screen screenKey="breathing" screenLabel="Breathing pause" className="mori-v2-breathing">
      <WatercolorScene source={practicePaper} position="center" />
      <header className="mori-v2-centered-header">
        <p>A small pause</p>
        <h1>{seconds === 0 ? 'Whenever you’re ready' : phase}</h1>
      </header>

      <div
        className="mori-v2-breathing-visual"
        role="timer"
        aria-label={`${seconds} seconds remaining`}
      >
        <motion.img
          src={breathingRing}
          alt=""
          aria-hidden="true"
          animate={
            shouldReduceMotion || seconds === 0
              ? { scale: 1, opacity: 0.84 }
              : { scale: phase === 'Breathe in' ? 1.035 : 0.93, opacity: phase === 'Breathe in' ? 0.92 : 0.76 }
          }
          transition={{ duration: shouldReduceMotion ? 0 : 3.7, ease: 'easeInOut' }}
        />
        <strong>{seconds}</strong>
        <span>seconds</span>
      </div>
      <p className="sr-only" role="status" aria-live="polite" aria-atomic="true">
        {seconds === 0 ? 'The breathing pause is complete.' : phase}
      </p>

      <div className="mori-v2-flow-actions mori-v2-breathing-actions">
        {seconds === 0 ? (
          <button type="button" className="mori-v2-primary" onClick={onContinue}>
            Continue to Instagram
          </button>
        ) : (
          <p className="mori-v2-offer">Instagram stays closed until the {formatDuration(durationSeconds)} pause is complete.</p>
        )}
        <button type="button" className="mori-v2-text-button" onClick={onCloseInstagram}>
          Close Instagram
        </button>
      </div>
    </Screen>
  )
}

function FocusScreen({
  seconds,
  paused,
  onTogglePause,
  onEnd,
  onOpenSettings,
}: {
  seconds: number
  paused: boolean
  onTogglePause: () => void
  onEnd: () => void
  onOpenSettings: () => void
}) {
  return (
    <Screen screenKey="focus" screenLabel="Deep Session" className="mori-v2-focus">
      <WatercolorScene source={forestPaper} position="center bottom" />
      <SettingsButton onOpen={onOpenSettings} />

      <header className="mori-v2-focus-header">
        <h1>Deep Session</h1>
        <p>{paused ? 'Paused. Nothing is lost.' : 'A quiet boundary for this moment.'}</p>
      </header>

      <div className="mori-v2-timer" aria-live="off" aria-label={`${formatTime(seconds)} remaining`}>
        {formatTime(seconds)}
      </div>

      <div className="mori-v2-focus-controls">
        <div className="mori-v2-blocked-apps">
          <span>Blocked apps</span>
          <strong>Instagram · YouTube · Threads</strong>
        </div>
        <button type="button" className="mori-v2-pause" onClick={onTogglePause}>
          <MoriIcon name={paused ? 'play' : 'pause'} size={19} />
          <span>{paused ? 'Continue' : 'Pause'}</span>
        </button>
        <AnimatePresence initial={false}>
          {paused ? (
            <motion.button
              type="button"
              className="mori-v2-end-session"
              onClick={onEnd}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              End quietly
            </motion.button>
          ) : null}
        </AnimatePresence>
      </div>
    </Screen>
  )
}

function SessionCompleteScreen({
  quietMinutes,
  onContinue,
  onOpenInstagram,
}: {
  quietMinutes: number
  onContinue: () => void
  onOpenInstagram: () => void
}) {
  const completedFullSession = quietMinutes === 25

  return (
    <Screen
      screenKey="session-complete"
      screenLabel={completedFullSession ? 'Session complete' : 'Session ended quietly'}
      className="mori-v2-complete"
    >
      <WatercolorScene source={forestPaper} position="center bottom" />
      <div className="mori-v2-complete-copy">
        <p>{completedFullSession ? 'Session complete' : 'Session ended quietly'}</p>
        <h1>{completedFullSession ? 'One quiet session protected.' : 'A quiet moment protected.'}</h1>
        {quietMinutes > 0 ? (
          <strong>{quietMinutes} quiet {quietMinutes === 1 ? 'minute' : 'minutes'}.</strong>
        ) : null}
      </div>
      <div className="mori-v2-flow-actions mori-v2-complete-actions">
        <button type="button" className="mori-v2-primary" onClick={onContinue}>
          Continue
        </button>
        <button type="button" className="mori-v2-text-button" onClick={onOpenInstagram}>
          Open Instagram
        </button>
      </div>
    </Screen>
  )
}

function LogScreen({
  entry,
  quietMetrics,
  onEntryChange,
  onOpenSettings,
}: {
  entry: LogEntry
  quietMetrics: QuietMetrics
  onEntryChange: (entry: LogEntry) => void
  onOpenSettings: () => void
}) {
  const { mood, note, photo, saved } = entry
  const [quietSummaryOpen, setQuietSummaryOpen] = useState(false)
  const shouldReduceMotion = useReducedMotion()
  const photoInputRef = useRef<HTMLInputElement>(null)

  if (saved) {
    return (
      <Screen screenKey="log-saved" screenLabel="Log saved" className="mori-v2-log mori-v2-log-saved">
        <WatercolorScene source={todayPaper} position="center" />
        <RootHeader title="Log" subtitle="Only what you want to keep." onOpenSettings={onOpenSettings} />
        <div className="mori-v2-log-confirmation">
          <h2>Kept for today.</h2>
          <p>A small record, held lightly.</p>
          <button
            type="button"
            className="mori-v2-quiet-link"
            aria-expanded={quietSummaryOpen}
            onClick={() => setQuietSummaryOpen((value) => !value)}
          >
            {quietSummaryOpen ? 'Hide quiet notes' : 'View quiet notes'}
          </button>
          <AnimatePresence initial={false}>
            {quietSummaryOpen ? (
              <motion.div
                className="mori-v2-quiet-details"
                aria-label="Quiet notes"
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ duration: shouldReduceMotion ? 0 : 0.32, ease: [0.22, 1, 0.36, 1] }}
              >
                <div>
                  <span>Intent count</span>
                  <strong>{quietMetrics.intentCount} / {quietMetrics.intentBudget} feeds today</strong>
                </div>
                <div>
                  <span>Quiet minutes</span>
                  <strong>
                    {quietMetrics.todayMinutes} today · {quietMetrics.weekMinutes} this week · {formatLifeQuietTime(quietMetrics.lifeMinutes)}
                  </strong>
                </div>
              </motion.div>
            ) : null}
          </AnimatePresence>
        </div>
      </Screen>
    )
  }

  return (
    <Screen screenKey="log" screenLabel="Log" className="mori-v2-log">
      <WatercolorScene source={todayPaper} position="center" />
      <RootHeader title="Log" subtitle="Only what you want to keep." onOpenSettings={onOpenSettings} />

      <div className="mori-v2-log-scroll">
        <form
          className="mori-v2-log-form"
          onSubmit={(event) => {
            event.preventDefault()
            onEntryChange({ ...entry, saved: true })
          }}
        >
          <fieldset>
            <legend>How do you feel?</legend>
            <div className="mori-v2-moods">
              {moods.map((item) => (
                <button
                  key={item}
                  type="button"
                  data-selected={mood === item}
                  aria-pressed={mood === item}
                  onClick={() => onEntryChange({ ...entry, mood: item })}
                >
                  {item}
                </button>
              ))}
            </div>
          </fieldset>

          <label className="mori-v2-note">
            <span>One thing worth keeping</span>
            <textarea
              value={note}
              onChange={(event) => onEntryChange({ ...entry, note: event.target.value })}
              maxLength={140}
              rows={3}
              placeholder="One sentence…"
            />
          </label>

          <div className="mori-v2-photo-wrap">
            <label className="mori-v2-photo">
              <input
                ref={photoInputRef}
                type="file"
                accept="image/*"
                onChange={(event) => onEntryChange({ ...entry, photo: event.target.files?.[0] ?? null })}
              />
              <MoriIcon name="plus" size={18} />
              <span>{photo?.name || 'Add an optional photo'}</span>
            </label>
            {photo ? (
              <button
                type="button"
                className="mori-v2-remove-photo"
                onClick={() => {
                  onEntryChange({ ...entry, photo: null })
                  if (photoInputRef.current) photoInputRef.current.value = ''
                }}
              >
                Remove
              </button>
            ) : null}
          </div>

          <button
            type="submit"
            className="mori-v2-primary"
            disabled={mood === null && note.trim().length === 0 && photo === null}
          >
            Done
          </button>
        </form>
      </div>
    </Screen>
  )
}

function SettingsSheet({
  preferences,
  onPreferencesChange,
  onClose,
}: {
  preferences: SettingsPreferences
  onPreferencesChange: (preferences: SettingsPreferences) => void
  onClose: () => void
}) {
  const shouldReduceMotion = useReducedMotion()
  const { quietBell, gentleHaptics } = preferences
  const dialogRef = useRef<HTMLElement>(null)
  const closeButtonRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    const previouslyFocused = document.activeElement instanceof HTMLElement ? document.activeElement : null
    closeButtonRef.current?.focus()

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        event.preventDefault()
        onClose()
        return
      }

      if (event.key !== 'Tab' || !dialogRef.current) return

      const focusable = Array.from(
        dialogRef.current.querySelectorAll<HTMLElement>('button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled])'),
      ).filter((element) => element.getClientRects().length > 0)

      if (focusable.length === 0) return
      const first = focusable[0]
      const last = focusable[focusable.length - 1]

      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('keydown', handleKeyDown)
      window.setTimeout(() => {
        if (previouslyFocused?.isConnected) {
          previouslyFocused.focus()
        } else {
          document.querySelector<HTMLElement>('.mori-v2-screen')?.focus({ preventScroll: true })
        }
      }, 0)
    }
  }, [onClose])

  return (
    <motion.div
      className="mori-v2-sheet-backdrop"
      role="presentation"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onMouseDown={(event) => {
        if (event.currentTarget === event.target) onClose()
      }}
    >
      <motion.section
        ref={dialogRef}
        className="mori-v2-settings"
        role="dialog"
        aria-modal="true"
        aria-labelledby="mori-v2-settings-title"
        initial={shouldReduceMotion ? { opacity: 0 } : { opacity: 0, y: 28 }}
        animate={{ opacity: 1, y: 0 }}
        exit={shouldReduceMotion ? { opacity: 0 } : { opacity: 0, y: 20 }}
        transition={{ duration: shouldReduceMotion ? 0.12 : 0.36, ease: [0.22, 1, 0.36, 1] }}
      >
        <header>
          <div>
            <p>Keep only what helps</p>
            <h2 id="mori-v2-settings-title">Settings</h2>
          </div>
          <button ref={closeButtonRef} type="button" onClick={onClose}>Close</button>
        </header>

        <button
          type="button"
          className="mori-v2-setting-row"
          role="switch"
          aria-checked={quietBell}
          onClick={() => onPreferencesChange({ ...preferences, quietBell: !quietBell })}
        >
          <span>Quiet bell</span>
          <span className="mori-v2-switch" data-on={quietBell} aria-hidden="true"><span /></span>
        </button>
        <button
          type="button"
          className="mori-v2-setting-row"
          role="switch"
          aria-checked={gentleHaptics}
          onClick={() => onPreferencesChange({ ...preferences, gentleHaptics: !gentleHaptics })}
        >
          <span>Gentle haptics</span>
          <span className="mori-v2-switch" data-on={gentleHaptics} aria-hidden="true"><span /></span>
        </button>
        <label className="mori-v2-setting-row">
          <span>Before Feed reset length</span>
          <select
            aria-label="Before Feed reset length"
            value={preferences.beforeFeedDurationSeconds}
            onChange={(event) => onPreferencesChange({
              ...preferences,
              beforeFeedDurationSeconds: Number(event.target.value),
            })}
          >
            {beforeFeedDurationOptions.map((seconds) => (
              <option key={seconds} value={seconds}>{formatDuration(seconds)}</option>
            ))}
          </select>
        </label>
        <div className="mori-v2-setting-row mori-v2-setting-static">
          <span>Blocked apps</span>
          <strong>3 apps</strong>
        </div>
      </motion.section>
    </motion.div>
  )
}

export default function MoriV2Prototype() {
  const [tab, setTab] = useState<RootTab>('today')
  const [flow, setFlow] = useState<Flow>(() =>
    new URLSearchParams(window.location.search).get('screen') === 'complete' ? 'sessionComplete' : 'root',
  )
  const [reason, setReason] = useState<FeedReason | null>(null)
  const [breathingSeconds, setBreathingSeconds] = useState(60)
  const [breathingDeadline, setBreathingDeadline] = useState<number | null>(null)
  const [sessionSeconds, setSessionSeconds] = useState(25 * 60)
  const [sessionPaused, setSessionPaused] = useState(false)
  const [sessionDeadline, setSessionDeadline] = useState<number | null>(null)
  const [completionMinutes, setCompletionMinutes] = useState(25)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [settingsPreferences, setSettingsPreferences] = useState<SettingsPreferences>({
    quietBell: true,
    gentleHaptics: true,
    beforeFeedDurationSeconds: 60,
  })
  const [logEntry, setLogEntry] = useState<LogEntry>({ mood: null, note: '', photo: null, saved: false })
  const [intentCount, setIntentCount] = useState(3)
  const [quietTodayMinutes, setQuietTodayMinutes] = useState(28)
  const [quietWeekMinutes, setQuietWeekMinutes] = useState(112)
  const [quietLifeMinutes, setQuietLifeMinutes] = useState(132 * 60)
  const [toast, setToast] = useState('')
  const closeSettings = useCallback(() => setSettingsOpen(false), [])

  useEffect(() => {
    document.body.classList.add('mori-v2-body')
    document.documentElement.lang = 'en'
    document.title = 'Mori v2 — Pause. Notice. Choose.'
    return () => document.body.classList.remove('mori-v2-body')
  }, [])

  useEffect(() => {
    if (flow !== 'breathing' || breathingDeadline === null) return

    const updateRemaining = () => {
      const remaining = Math.max(0, Math.ceil((breathingDeadline - Date.now()) / 1000))
      setBreathingSeconds(remaining)
      if (remaining === 0) setBreathingDeadline(null)
    }

    updateRemaining()
    const timer = window.setInterval(updateRemaining, 250)
    document.addEventListener('visibilitychange', updateRemaining)
    return () => {
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', updateRemaining)
    }
  }, [breathingDeadline, flow])

  useEffect(() => {
    if (flow !== 'root' || tab !== 'focus' || sessionPaused || sessionDeadline === null) return

    const updateRemaining = () => {
      setSessionSeconds(Math.max(0, Math.ceil((sessionDeadline - Date.now()) / 1000)))
    }

    updateRemaining()
    const timer = window.setInterval(updateRemaining, 250)
    document.addEventListener('visibilitychange', updateRemaining)
    return () => {
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', updateRemaining)
    }
  }, [flow, sessionDeadline, sessionPaused, tab])

  useEffect(() => {
    if (sessionSeconds === 0) {
      setCompletionMinutes(25)
      setSessionDeadline(null)
      setQuietTodayMinutes((value) => value + 25)
      setQuietWeekMinutes((value) => value + 25)
      setQuietLifeMinutes((value) => value + 25)
      setFlow('sessionComplete')
    }
  }, [sessionSeconds])

  useEffect(() => {
    if (!toast) return
    const timer = window.setTimeout(() => setToast(''), 2600)
    return () => window.clearTimeout(timer)
  }, [toast])

  const rootScreen = useMemo(() => {
    if (tab === 'today') {
      return <TodayScreen key="today" onBegin={() => setFlow('beforeFeed')} onOpenSettings={() => setSettingsOpen(true)} />
    }
    if (tab === 'focus') {
      return (
        <FocusScreen
          key="focus"
          seconds={sessionSeconds}
          paused={sessionPaused}
          onTogglePause={() => {
            if (sessionPaused) {
              setSessionDeadline(Date.now() + sessionSeconds * 1000)
              setSessionPaused(false)
              return
            }

            const remaining = sessionDeadline === null
              ? sessionSeconds
              : Math.max(0, Math.ceil((sessionDeadline - Date.now()) / 1000))
            setSessionSeconds(remaining)
            setSessionDeadline(null)
            setSessionPaused(true)
          }}
          onEnd={() => {
            const elapsedMinutes = Math.max(0, Math.floor((25 * 60 - sessionSeconds) / 60))
            setCompletionMinutes(elapsedMinutes)
            if (elapsedMinutes > 0) {
              setQuietTodayMinutes((value) => value + elapsedMinutes)
              setQuietWeekMinutes((value) => value + elapsedMinutes)
              setQuietLifeMinutes((value) => value + elapsedMinutes)
            }
            setSessionDeadline(null)
            setFlow('sessionComplete')
          }}
          onOpenSettings={() => setSettingsOpen(true)}
        />
      )
    }
    return (
      <LogScreen
        key="log"
        entry={logEntry}
        quietMetrics={{
          intentCount,
          intentBudget: 5,
          todayMinutes: quietTodayMinutes,
          weekMinutes: quietWeekMinutes,
          lifeMinutes: quietLifeMinutes,
        }}
        onEntryChange={setLogEntry}
        onOpenSettings={() => setSettingsOpen(true)}
      />
    )
  }, [intentCount, logEntry, quietLifeMinutes, quietTodayMinutes, quietWeekMinutes, sessionDeadline, sessionPaused, sessionSeconds, tab])

  function returnToToday(message?: string) {
    setFlow('root')
    setTab('today')
    setReason(null)
    setBreathingSeconds(settingsPreferences.beforeFeedDurationSeconds)
    setBreathingDeadline(null)
    if (message) setToast(message)
  }

  function openInstagramFromPrototype() {
    const link = document.createElement('a')
    link.href = 'https://www.instagram.com/'
    link.target = '_blank'
    link.rel = 'noopener noreferrer'
    link.hidden = true
    document.body.appendChild(link)
    link.click()
    link.remove()
    setIntentCount((value) => value + 1)
    returnToToday('Instagram opened in another tab.')
  }

  return (
    <div className="mori-v2-stage">
      <main className="mori-v2-phone">
        <div className="mori-v2-content" aria-hidden={settingsOpen || undefined}>
          <AnimatePresence mode="wait">
            {flow === 'beforeFeed' ? (
              <BeforeFeedScreen
                key="before-feed"
                reason={reason}
                onReasonChange={setReason}
                onBack={() => returnToToday()}
                onContinue={() => {
                  const durationSeconds = settingsPreferences.beforeFeedDurationSeconds
                  setBreathingSeconds(durationSeconds)
                  setBreathingDeadline(Date.now() + durationSeconds * 1000)
                  setFlow('breathing')
                }}
                onCloseInstagram={() => returnToToday('Instagram stayed closed.')}
              />
            ) : flow === 'breathing' ? (
              <BreathingScreen
                key="breathing"
                seconds={breathingSeconds}
                durationSeconds={settingsPreferences.beforeFeedDurationSeconds}
                onContinue={() => {
                  if (breathingSeconds === 0) openInstagramFromPrototype()
                }}
                onCloseInstagram={() => returnToToday('Instagram stayed closed.')}
              />
            ) : flow === 'sessionComplete' ? (
              <SessionCompleteScreen
                key="session-complete"
                quietMinutes={completionMinutes}
                onContinue={() => {
                  setSessionSeconds(25 * 60)
                  setSessionPaused(false)
                  setSessionDeadline(null)
                  returnToToday()
                }}
                onOpenInstagram={() => {
                  setSessionSeconds(25 * 60)
                  setSessionPaused(false)
                  setSessionDeadline(null)
                  openInstagramFromPrototype()
                }}
              />
            ) : (
              rootScreen
            )}
          </AnimatePresence>

          {flow === 'root' && tab !== 'focus' ? (
            <TabBar
              tab={tab}
              onChange={(nextTab) => {
                if (nextTab === 'focus') {
                  setSessionPaused(false)
                  setSessionDeadline(Date.now() + sessionSeconds * 1000)
                }
                setTab(nextTab)
                setSettingsOpen(false)
              }}
            />
          ) : null}

          <div className="mori-v2-toast" aria-live="polite" data-visible={Boolean(toast)}>
            {toast}
          </div>
        </div>

        <AnimatePresence>
          {settingsOpen ? (
            <SettingsSheet
              preferences={settingsPreferences}
              onPreferencesChange={setSettingsPreferences}
              onClose={closeSettings}
            />
          ) : null}
        </AnimatePresence>
      </main>
    </div>
  )
}
