export type MoriWebLocale = 'en' | 'zh-Hans' | 'zh-Hant'

export const localeOptions: Array<{ locale: MoriWebLocale; label: string }> = [
  { locale: 'en', label: 'English' },
  { locale: 'zh-Hans', label: '简体中文' },
  { locale: 'zh-Hant', label: '繁體中文' },
]

const en = {
  languageLabel: 'Language',
  earlyAccess: 'Now in Early Access',
  heroTitleLine: 'Limit one app,',
  heroTitleAccent: 'reclaim this hour',
  heroBody: 'Start with one Screen Time App Limit. Choose the feed that pulls hardest, add friction before it opens, then leave the phone alone.',
  downloadIos: 'Download for iOS',
  watchDemo: 'See App Limit Flow',
  heroPanelTitle: 'First App Limit',
  heroPanelSubtitle: 'One app. Less gravity.',
  heroMetricOne: 'app',
  heroMetricPermission: 'Screen Time',
  heroMetricResult: 'before feed',
  weeksHeldSoftly: 'weeks archive',
  previewLabel: 'First App Limit preview',
  surfaceToday: 'Today',
  surfaceReset: 'Reset',
  surfaceLog: 'Journal',
  featuresTitle: 'One Small',
  featuresAccent: 'Friction',
  features: [
    { mark: '1', title: 'First App Limit', desc: 'Choose one app or website to slow down before feeds' },
    { mark: '2', title: 'Before Feed Reset', desc: 'Add a small pause before the scroll begins' },
    { mark: '3', title: 'Today Focus', desc: 'Keep one action visible before the phone gets loud' },
    { mark: '4', title: 'Weeks Archive', desc: 'Review lived weeks without making the archive the whole product' },
  ],
  howTitle: 'How It',
  howAccent: 'Works',
  steps: [
    { num: '01', title: 'Pick One App', desc: 'Use Screen Time to choose the feed that pulls hardest' },
    { num: '02', title: 'Turn Limit On', desc: 'Let the next open hit friction before the scroll begins' },
    { num: '03', title: 'Do One Reset', desc: 'Use the pause to start one small reset or leave the app' },
  ],
  pricingTitle: 'Simple,',
  pricingAccent: 'Free',
  pricingSuffix: 'Pricing',
  pricingBody: 'Mori is free to download and use. The first promise is simple: one App Limit, one reset, one protected next minute.',
  freePlan: 'Free',
  freeItems: ['✓ First App Limit setup', '✓ Before Feed reset', '✓ Today focus', '✓ Weeks archive'],
  downloadFree: 'Download Free',
  comingSoon: 'COMING SOON',
  premiumPlan: 'Premium',
  premiumItems: ['✓ Everything in Free', '✓ Deeper attention patterns', '✓ More protected routines', '✓ Priority support'],
  faqTitle: 'Frequently Asked',
  faqAccent: 'Questions',
  faqs: [
    { q: 'Is Mori free to use?', a: 'Yes. The core features of Mori are free so more people can access calmer growth tools.' },
    { q: 'Is my data private?', a: 'Your data is stored locally on your device and synced via iCloud when enabled. Mori does not sell personal information.' },
    { q: 'Can I use Mori on Android?', a: 'Mori is currently focused on iOS. Android support is planned for the future.' },
    { q: 'How do I get started?', a: 'Download Mori, then set one Screen Time App Limit for the app that pulls you into feeds fastest.' },
    { q: 'What makes Mori different?', a: 'Mori starts with actual phone friction. It does not just report the problem; it helps slow the next open.' },
  ],
  ctaTitle: 'Protect the Next Open',
  ctaBody: 'Pick one app. Add friction before the feed.',
  ctaButton: "Download for iOS - It's Free",
  footerBrandLine: 'Botanical attention design',
  privacy: 'Privacy',
  terms: 'Terms',
  contact: 'Contact',
  copyright: '© 2026 Metta Labs. All rights reserved.',
}

const zhHans: typeof en = {
  languageLabel: '语言',
  earlyAccess: '现已开放早期体验',
  heroTitleLine: '限制一个 App，',
  heroTitleAccent: '拿回这一小时',
  heroBody: '先设置一个屏幕时间 App 限制。选择最容易把你拉进信息流的 App，在打开前加入摩擦，然后离开手机。',
  downloadIos: '下载 iOS 版',
  watchDemo: '查看 App 限制流程',
  heroPanelTitle: '第一个 App 限制',
  heroPanelSubtitle: '一个 App。少一点重力。',
  heroMetricOne: '个 App',
  heroMetricPermission: '屏幕时间',
  heroMetricResult: '信息流前',
  weeksHeldSoftly: '周归档',
  previewLabel: '第一个 App 限制预览',
  surfaceToday: '今天',
  surfaceReset: '重置',
  surfaceLog: '记录',
  featuresTitle: '一个小',
  featuresAccent: '摩擦',
  features: [
    { mark: '1', title: '第一个 App 限制', desc: '选择一个要在信息流前放慢的 App 或网站' },
    { mark: '2', title: '信息流前重置', desc: '在滚动开始前加入一个小停顿' },
    { mark: '3', title: '今日焦点', desc: '在手机变吵前保留一个清楚行动' },
    { mark: '4', title: '周归档', desc: '回看已经活过的周，但不让归档变成整个产品' },
  ],
  howTitle: '它如何',
  howAccent: '运作',
  steps: [
    { num: '01', title: '选择一个 App', desc: '用屏幕时间选中最容易把你拉入信息流的 App' },
    { num: '02', title: '打开限制', desc: '让下一次打开在滚动前先遇到摩擦' },
    { num: '03', title: '做一次重置', desc: '用这个停顿开始一个小练习，或直接离开 App' },
  ],
  pricingTitle: '简单，',
  pricingAccent: '免费',
  pricingSuffix: '定价',
  pricingBody: 'Mori 可免费下载和使用。第一个承诺很简单：一个 App 限制、一次重置、一个被保护的下一分钟。',
  freePlan: '免费',
  freeItems: ['✓ 第一个 App 限制设置', '✓ 信息流前重置', '✓ 今日焦点', '✓ 周归档'],
  downloadFree: '免费下载',
  comingSoon: '即将推出',
  premiumPlan: '高级版',
  premiumItems: ['✓ 免费版全部功能', '✓ 更深入的注意力模式', '✓ 更多受保护流程', '✓ 优先支持'],
  faqTitle: '常见',
  faqAccent: '问题',
  faqs: [
    { q: 'Mori 可以免费使用吗？', a: '可以。Mori 的核心功能免费开放，让更多人可以使用更平静的成长工具。' },
    { q: '我的数据是私密的吗？', a: '你的数据会存储在设备本地，并在启用时通过 iCloud 同步。Mori 不会出售个人信息。' },
    { q: 'Mori 有 Android 版吗？', a: 'Mori 目前专注于 iOS。Android 支持已在未来计划中。' },
    { q: '如何开始？', a: '下载 Mori，然后为最容易把你拉进信息流的 App 设置一个屏幕时间限制。' },
    { q: 'Mori 有什么不同？', a: 'Mori 从真实手机摩擦开始。它不只报告问题，而是帮你放慢下一次打开。' },
  ],
  ctaTitle: '保护下一次打开',
  ctaBody: '选择一个 App。在信息流前加入摩擦。',
  ctaButton: '免费下载 iOS 版',
  footerBrandLine: '植物水彩注意力设计',
  privacy: '隐私',
  terms: '条款',
  contact: '联系',
  copyright: '© 2026 Metta Labs。保留所有权利。',
}

const zhHant: typeof en = {
  languageLabel: '語言',
  earlyAccess: '現已開放早期體驗',
  heroTitleLine: '限制一個 App，',
  heroTitleAccent: '攞返呢一小時',
  heroBody: '先設定一個螢幕時間 App 限制。揀最容易拉你入資訊流嘅 App，在打開前加一點摩擦，然後離開手機。',
  downloadIos: '下載 iOS 版',
  watchDemo: '查看 App 限制流程',
  heroPanelTitle: '第一個 App 限制',
  heroPanelSubtitle: '一個 App。少一點重力。',
  heroMetricOne: '個 App',
  heroMetricPermission: '螢幕時間',
  heroMetricResult: '資訊流前',
  weeksHeldSoftly: '週歸檔',
  previewLabel: '第一個 App 限制預覽',
  surfaceToday: '今日',
  surfaceReset: '重置',
  surfaceLog: '記錄',
  featuresTitle: '一個小',
  featuresAccent: '摩擦',
  features: [
    { mark: '1', title: '第一個 App 限制', desc: '選擇一個要在資訊流前放慢的 App 或網站' },
    { mark: '2', title: '資訊流前重置', desc: '在滾動開始前加入一個小停頓' },
    { mark: '3', title: '今日焦點', desc: '在手機變吵前保留一個清楚行動' },
    { mark: '4', title: '週歸檔', desc: '回看已經活過的週，但唔令歸檔變成整個產品' },
  ],
  howTitle: '它如何',
  howAccent: '運作',
  steps: [
    { num: '01', title: '選擇一個 App', desc: '用螢幕時間選中最容易把你拉入資訊流的 App' },
    { num: '02', title: '打開限制', desc: '讓下一次打開在滾動前先遇到摩擦' },
    { num: '03', title: '做一次重置', desc: '用這個停頓開始一個小練習，或直接離開 App' },
  ],
  pricingTitle: '簡單，',
  pricingAccent: '免費',
  pricingSuffix: '定價',
  pricingBody: 'Mori 可免費下載和使用。第一個承諾很簡單：一個 App 限制、一次重置、一個被保護的下一分鐘。',
  freePlan: '免費',
  freeItems: ['✓ 第一個 App 限制設定', '✓ 資訊流前重置', '✓ 今日焦點', '✓ 週歸檔'],
  downloadFree: '免費下載',
  comingSoon: '即將推出',
  premiumPlan: '進階版',
  premiumItems: ['✓ 免費版全部功能', '✓ 更深入的注意力模式', '✓ 更多受保護流程', '✓ 優先支援'],
  faqTitle: '常見',
  faqAccent: '問題',
  faqs: [
    { q: 'Mori 可以免費使用嗎？', a: '可以。Mori 的核心功能免費開放，讓更多人可以使用更平靜的成長工具。' },
    { q: '我的資料是私密的嗎？', a: '你的資料會儲存在裝置本地，並在啟用時透過 iCloud 同步。Mori 不會出售個人資訊。' },
    { q: 'Mori 有 Android 版嗎？', a: 'Mori 目前專注於 iOS。Android 支援已在未來計劃中。' },
    { q: '如何開始？', a: '下載 Mori，然後為最容易把你拉進資訊流的 App 設定一個螢幕時間限制。' },
    { q: 'Mori 有甚麼不同？', a: 'Mori 從真實手機摩擦開始。它不只報告問題，而是幫你放慢下一次打開。' },
  ],
  ctaTitle: '保護下一次打開',
  ctaBody: '選擇一個 App。在資訊流前加入摩擦。',
  ctaButton: '免費下載 iOS 版',
  footerBrandLine: '植物水彩注意力設計',
  privacy: '私隱',
  terms: '條款',
  contact: '聯絡',
  copyright: '© 2026 Metta Labs。保留所有權利。',
}

export const dictionaries = {
  en,
  'zh-Hans': zhHans,
  'zh-Hant': zhHant,
}

export type MoriCopy = typeof en

export function resolveLocale(rawLocale: string | undefined): MoriWebLocale {
  const normalized = rawLocale?.replace('_', '-').toLowerCase() ?? ''
  if (normalized.startsWith('zh-hant') || normalized.includes('-hk') || normalized.includes('-mo') || normalized.includes('-tw')) {
    return 'zh-Hant'
  }
  if (normalized.startsWith('zh')) {
    return 'zh-Hans'
  }
  return 'en'
}

export function initialLocale(): MoriWebLocale {
  const stored = window.localStorage.getItem('mori.locale')
  if (stored === 'en' || stored === 'zh-Hans' || stored === 'zh-Hant') {
    return stored
  }
  return resolveLocale(window.navigator.languages?.[0] ?? window.navigator.language)
}
