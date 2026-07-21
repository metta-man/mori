import { motion, useReducedMotion } from 'framer-motion'
import { useEffect, useState } from 'react'
import MoriV2Prototype from './MoriV2Prototype'
import appLimitPaper from './assets/botanical/app-limit-paper.png'
import onboardingPaper from './assets/botanical/onboarding-paper.png'
import practicePaper from './assets/botanical/practice-paper.png'
import todayPaper from './assets/botanical/today-paper.png'
import { MoriIcon } from './components/Icon'
import {
  dictionaries,
  initialLocale,
  localeOptions,
  type MoriCopy,
  type MoriWebLocale,
} from './i18n'

type CopyProps = {
  copy: MoriCopy
}

type FlowStepIndex = 0 | 1 | 2

const previewImages = [appLimitPaper, todayPaper, practicePaper] as const

function LanguageSelector({
  locale,
  setLocale,
  copy,
}: CopyProps & {
  locale: MoriWebLocale
  setLocale: (locale: MoriWebLocale) => void
}) {
  return (
    <label className="fixed right-4 top-4 z-50 flex items-center gap-2 rounded-[8px] border border-[#243833]/20 bg-[#fffaf0]/80 px-3 py-2 text-sm font-ui text-[#243833] shadow-[0_12px_30px_rgba(36,56,51,0.08)] backdrop-blur">
      <span className="sr-only">{copy.languageLabel}</span>
      <select
        value={locale}
        onChange={(event) => setLocale(event.target.value as MoriWebLocale)}
        className="bg-transparent text-sm font-medium outline-none"
        aria-label={copy.languageLabel}
      >
        {localeOptions.map((option) => (
          <option key={option.locale} value={option.locale}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  )
}

function AppLimitPreview({ copy }: CopyProps) {
  const [activeStep, setActiveStep] = useState<FlowStepIndex>(0)
  const step = copy.steps[activeStep]

  function advanceStep() {
    setActiveStep(((activeStep + 1) % 3) as FlowStepIndex)
  }

  return (
    <div className="mori-experience-grid">
      <div className="mori-app-preview" aria-label={copy.previewLabel}>
        <img
          src={previewImages[activeStep]}
          alt=""
          aria-hidden="true"
          className="mori-preview-paper"
        />
        <div className="mori-app-chrome">
          <div className="mori-preview-status">
            <span>{copy.heroPanelTitle}</span>
            <strong>{copy.heroPanelSubtitle}</strong>
          </div>

          <div className="mori-preview-list" aria-live="polite">
            {copy.steps.map((item, index) => {
              const isActive = index === activeStep
              const isComplete = index < activeStep

              return (
                <button
                  key={item.num}
                  type="button"
                  className="mori-preview-row"
                  data-active={isActive}
                  onClick={() => setActiveStep(index as FlowStepIndex)}
                  aria-pressed={isActive}
                >
                  <MoriIcon
                    name={isComplete ? 'leaf' : isActive ? 'focus' : 'timer'}
                    size={22}
                  />
                  <span>
                    <strong>{item.title}</strong>
                    <small>{item.desc}</small>
                  </span>
                </button>
              )
            })}
          </div>

          <div className="mori-preview-tabbar" aria-hidden="true">
            <span data-active="true">
              <MoriIcon name="home" size={17} />
              {copy.surfaceToday}
            </span>
            <span>
              <MoriIcon name="breathe" size={17} />
              {copy.surfaceReset}
            </span>
            <span>
              <MoriIcon name="journal" size={17} />
              {copy.surfaceLog}
            </span>
          </div>
        </div>
      </div>

      <div className="mori-flow-copy">
        <span className="mori-kicker">{copy.earlyAccess}</span>
        <h2>{step.title}</h2>
        <p>{step.desc}</p>
        <button type="button" className="mori-flow-button" onClick={advanceStep}>
          <MoriIcon name="play" size={18} />
          {activeStep === 2 ? copy.ctaBody : copy.watchDemo}
        </button>
      </div>
    </div>
  )
}

function ProductPromise({ copy }: CopyProps) {
  const featureImages = [appLimitPaper, practicePaper, todayPaper, onboardingPaper]

  return (
    <section className="mori-proof-band" aria-labelledby="mori-proof-title">
      <div className="mori-proof-inner">
        <div>
          <span className="mori-kicker">{copy.weeksHeldSoftly}</span>
          <h2 id="mori-proof-title">
            {copy.featuresTitle} <em>{copy.featuresAccent}</em>
          </h2>
        </div>

        <div className="mori-proof-grid">
          {copy.features.map((feature, index) => (
            <article key={feature.title} className="mori-proof-item">
              <img
                src={featureImages[index % featureImages.length]}
                alt=""
                aria-hidden="true"
              />
              <span>{feature.mark}</span>
              <h3>{feature.title}</h3>
              <p>{feature.desc}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}

function Hero({ copy }: CopyProps) {
  const shouldReduceMotion = useReducedMotion()
  const copyInitial = shouldReduceMotion ? { opacity: 1, y: 0 } : { opacity: 0, y: 24 }
  const previewInitial = shouldReduceMotion ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }
  const copyTransition = shouldReduceMotion ? { duration: 0 } : { duration: 0.65 }
  const previewTransition = shouldReduceMotion ? { duration: 0 } : { delay: 0.12, duration: 0.65 }

  return (
    <section className="mori-web-hero">
      <img src={onboardingPaper} alt="" aria-hidden="true" className="mori-hero-paper" />
      <div className="mori-paper-grain" />
      <div className="mori-hero-content">
        <motion.div
          initial={copyInitial}
          animate={{ opacity: 1, y: 0 }}
          transition={copyTransition}
          className="mori-hero-copy"
        >
          <span className="mori-kicker">{copy.footerBrandLine}</span>
          <h1>
            {copy.heroTitleLine}
            <em>{copy.heroTitleAccent}</em>
          </h1>
          <p>{copy.heroBody}</p>
          <div className="mori-hero-actions">
            <button type="button">
              <MoriIcon name="leaf" size={18} />
              {copy.downloadIos}
            </button>
            <a href="#first-limit">
              <MoriIcon name="play" size={18} />
              {copy.watchDemo}
            </a>
          </div>
        </motion.div>

        <motion.div
          id="first-limit"
          initial={previewInitial}
          animate={{ opacity: 1, y: 0 }}
          transition={previewTransition}
        >
          <AppLimitPreview copy={copy} />
        </motion.div>
      </div>
    </section>
  )
}

function Footer({ copy }: CopyProps) {
  return (
    <footer className="mori-footer">
      <div>
        <strong>Mori</strong>
        <span>{copy.footerBrandLine}</span>
      </div>
      <nav aria-label="Footer">
        <a href="#">{copy.privacy}</a>
        <a href="#">{copy.terms}</a>
        <a href="#">{copy.contact}</a>
      </nav>
      <small>{copy.copyright}</small>
    </footer>
  )
}

function MarketingApp() {
  const [locale, setLocale] = useState<MoriWebLocale>(() => initialLocale())
  const copy = dictionaries[locale]

  useEffect(() => {
    window.localStorage.setItem('mori.locale', locale)
    document.documentElement.lang = locale
  }, [locale])

  return (
    <div className="min-h-screen">
      <LanguageSelector locale={locale} setLocale={setLocale} copy={copy} />
      <Hero copy={copy} />
      <ProductPromise copy={copy} />
      <Footer copy={copy} />
    </div>
  )
}

export default function App() {
  if (window.location.pathname === '/mori-v2' || window.location.pathname.startsWith('/mori-v2/')) {
    return <MoriV2Prototype />
  }

  return <MarketingApp />
}
