import { motion } from 'framer-motion'
import { useState, useEffect } from 'react'

// Hero Section with Life Grid
function Hero() {
  const [filledCells, setFilledCells] = useState(0)
  const totalCells = 80 // 8x10 grid for demo
  
  useEffect(() => {
    const interval = setInterval(() => {
      setFilledCells(prev => {
        if (prev >= totalCells) {
          clearInterval(interval)
          return prev
        }
        return prev + 1
      })
    }, 30)
    return () => clearInterval(interval)
  }, [])

  return (
    <section className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden px-4 py-20">
      <div className="absolute inset-0 bg-gradient-to-b from-[#faf8f5] to-[#f0ebe3]" />
      <div className="absolute inset-0 opacity-5" style={{
        backgroundImage: `radial-gradient(circle at 1px 1px, #1a3c34 1px, transparent 0)`,
        backgroundSize: '40px 40px'
      }} />
      
      <motion.div 
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
        className="relative z-10 text-center max-w-4xl mx-auto"
      >
        <span className="inline-block px-4 py-2 bg-[#1a3c34]/10 text-[#1a3c34] rounded-full text-sm font-ui mb-6">
          Now in Early Access
        </span>
        <h1 className="text-5xl md:text-7xl font-heading text-[#1a3c34] mb-6 leading-tight">
          Nurture Good Habits,<br/>
          <span className="italic text-[#c47d5e]">One Day at a Time</span>
        </h1>
        <p className="text-xl md:text-2xl text-[#2c2c2c]/70 mb-10 max-w-2xl mx-auto font-body">
          Track habits, build gratitude, and grow mindfully. 
          Simple tools for a more intentional life.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <button className="px-8 py-4 bg-[#1a3c34] text-white rounded-full font-ui font-medium text-lg hover:bg-[#2a5c4e] transition-all hover:scale-105">
            Download for iOS
          </button>
          <button className="px-8 py-4 border-2 border-[#1a3c34] text-[#1a3c34] rounded-full font-ui font-medium text-lg hover:bg-[#1a3c34]/5 transition-all">
            Watch Demo
          </button>
        </div>
      </motion.div>

      {/* Life Grid Preview */}
      <motion.div 
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.4, duration: 0.8 }}
        className="mt-16 relative z-10"
      >
        <div className="glass-card p-6">
          <div className="grid grid-cols-10 gap-1 w-64 h-80 mx-auto">
            {Array.from({ length: totalCells }).map((_, i) => (
              <motion.div
                key={i}
                initial={{ backgroundColor: '#e5e5e5' }}
                animate={{ 
                  backgroundColor: i < filledCells ? '#8fae8b' : '#e5e5e5'
                }}
                transition={{ duration: 0.3 }}
                className="rounded-sm"
              />
            ))}
          </div>
          <p className="text-center mt-4 text-sm text-[#2c2c2c]/60 font-ui">
            Your journey, visualized
          </p>
        </div>
      </motion.div>
    </section>
  )
}

// Features Section
function Features() {
  const features = [
    { icon: '🎯', title: 'Habit Tracking', desc: 'Simple daily check-ins for habits that matter' },
    { icon: '🙏', title: 'Gratitude Journal', desc: 'Capture moments of thankfulness each day' },
    { icon: '📊', title: 'Progress Insights', desc: 'Visualize your growth over weeks and months' },
    { icon: '🌱', title: 'Gentle Reminders', desc: 'Kind nudges to keep you on track' }
  ]

  return (
    <section className="py-24 px-4 bg-white">
      <div className="max-w-6xl mx-auto">
        <motion.h2 
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          className="text-4xl md:text-5xl font-heading text-center text-[#1a3c34] mb-16"
        >
          Everything You Need to <span className="italic text-[#c47d5e]">Grow</span>
        </motion.h2>
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {features.map((f, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="glass-card p-6 text-center hover:shadow-lg transition-shadow"
            >
              <div className="text-4xl mb-4">{f.icon}</div>
              <h3 className="text-xl font-heading text-[#1a3c34] mb-2">{f.title}</h3>
              <p className="text-[#2c2c2c]/70 font-body">{f.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

// How It Works
function HowItWorks() {
  const steps = [
    { num: '01', title: 'Choose Your Habits', desc: 'Start with suggestions or create your own' },
    { num: '02', title: 'Check In Daily', desc: 'A simple moment to reflect and record' },
    { num: '03', title: 'Watch Yourself Grow', desc: 'See your progress in beautiful visualizations' }
  ]

  return (
    <section className="py-24 px-4 bg-[#faf8f5]">
      <div className="max-w-6xl mx-auto">
        <h2 className="text-4xl md:text-5xl font-heading text-center text-[#1a3c34] mb-16">
          How It <span className="italic text-[#c47d5e]">Works</span>
        </h2>
        <div className="grid md:grid-cols-3 gap-8">
          {steps.map((s, i) => (
            <div key={i} className="text-center">
              <div className="text-6xl font-heading text-[#d4a853]/30 mb-4">{s.num}</div>
              <h3 className="text-2xl font-heading text-[#1a3c34] mb-2">{s.title}</h3>
              <p className="text-[#2c2c2c]/70 font-body">{s.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

// Pricing
function Pricing() {
  return (
    <section className="py-24 px-4 bg-white">
      <div className="max-w-4xl mx-auto text-center">
        <h2 className="text-4xl md:text-5xl font-heading text-[#1a3c34] mb-6">
          Simple, <span className="italic text-[#c47d5e]">Free</span> Pricing
        </h2>
        <p className="text-xl text-[#2c2c2c]/70 mb-12 font-body">
          Mori is free to download and use. Premium features coming soon.
        </p>
        
        <div className="grid md:grid-cols-2 gap-8 max-w-3xl mx-auto">
          <div className="glass-card p-8">
            <h3 className="text-2xl font-heading text-[#1a3c34] mb-2">Free</h3>
            <div className="text-4xl font-heading text-[#1a3c34] mb-4">$0</div>
            <ul className="text-left space-y-3 text-[#2c2c2c]/70 font-body">
              <li>✓ Unlimited habit tracking</li>
              <li>✓ Gratitude journal</li>
              <li>✓ Progress visualizations</li>
              <li>✓ iCloud sync</li>
            </ul>
            <button className="mt-6 w-full py-3 bg-[#1a3c34] text-white rounded-full font-ui font-medium hover:bg-[#2a5c4e] transition-all">
              Download Free
            </button>
          </div>
          
          <div className="glass-card p-8 border-2 border-[#d4a853]">
            <div className="inline-block px-3 py-1 bg-[#d4a853]/20 text-[#d4a853] rounded-full text-sm font-ui mb-4">
              COMING SOON
            </div>
            <h3 className="text-2xl font-heading text-[#1a3c34] mb-2">Premium</h3>
            <div className="text-4xl font-heading text-[#1a3c34] mb-4">$4.99<span className="text-lg">/mo</span></div>
            <ul className="text-left space-y-3 text-[#2c2c2c]/70 font-body">
              <li>✓ Everything in Free</li>
              <li>✓ Advanced analytics</li>
              <li>✓ Custom themes</li>
              <li>✓ Priority support</li>
            </ul>
            <button className="mt-6 w-full py-3 border-2 border-[#1a3c34] text-[#1a3c34] rounded-full font-ui font-medium hover:bg-[#1a3c34]/5 transition-all" disabled>
              Coming Soon
            </button>
          </div>
        </div>
      </div>
    </section>
  )
}

// FAQ
function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null)
  const faqs = [
    { q: 'Is Mori free to use?', a: 'Yes! The core features of Mori are completely free. We believe everyone should have access to tools that help them grow.' },
    { q: 'Is my data private?', a: 'Absolutely. Your data is stored locally on your device and synced via iCloud. We never sell your personal information.' },
    { q: 'Can I use Mori on Android?', a: 'Mori is currently available on iOS. Android support is planned for the future.' },
    { q: 'How do I get started?', a: 'Simply download Mori from the App Store, create an account, and start adding habits you want to build. The app will guide you through the process.' },
    { q: 'What makes Mori different?', a: 'Mori focuses on gentle, sustainable habit building. Unlike gamified apps that use streaks and pressure, Mori emphasizes reflection and growth.' }
  ]

  return (
    <section className="py-24 px-4 bg-[#faf8f5]">
      <div className="max-w-3xl mx-auto">
        <h2 className="text-4xl md:text-5xl font-heading text-center text-[#1a3c34] mb-12">
          Frequently Asked <span className="italic text-[#c47d5e]">Questions</span>
        </h2>
        <div className="space-y-4">
          {faqs.map((faq, i) => (
            <div key={i} className="glass-card overflow-hidden">
              <button
                onClick={() => setOpenIndex(openIndex === i ? null : i)}
                className="w-full p-6 text-left flex justify-between items-center"
              >
                <span className="font-heading text-lg text-[#1a3c34]">{faq.q}</span>
                <span className="text-[#c47d5e] text-2xl">{openIndex === i ? '−' : '+'}</span>
              </button>
              {openIndex === i && (
                <div className="px-6 pb-6 text-[#2c2c2c]/70 font-body">
                  {faq.a}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

// CTA
function CTA() {
  return (
    <section className="py-24 px-4 bg-[#1a3c34] text-white text-center">
      <div className="max-w-3xl mx-auto">
        <h2 className="text-4xl md:text-5xl font-heading mb-6">
          Start Your Journey Today
        </h2>
        <p className="text-xl text-white/70 mb-10 font-body">
          Join thousands who are building better habits, one day at a time.
        </p>
        <button className="px-10 py-5 bg-[#c47d5e] text-white rounded-full font-ui font-medium text-lg hover:bg-[#d48d6e] transition-all hover:scale-105">
          Download for iOS — It's Free
        </button>
      </div>
    </section>
  )
}

// Footer
function Footer() {
  return (
    <footer className="py-12 px-4 bg-[#faf8f5] border-t border-[#1a3c34]/10">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
        <div className="text-2xl font-heading text-[#1a3c34]">Mori</div>
        <div className="flex gap-8 font-ui text-sm text-[#2c2c2c]/60">
          <a href="#" className="hover:text-[#1a3c34]">Privacy</a>
          <a href="#" className="hover:text-[#1a3c34]">Terms</a>
          <a href="#" className="hover:text-[#1a3c34]">Contact</a>
        </div>
        <div className="text-sm text-[#2c2c2c]/40 font-body">
          © 2026 Metta Labs. All rights reserved.
        </div>
      </div>
    </footer>
  )
}

export default function App() {
  return (
    <div className="min-h-screen">
      <Hero />
      <Features />
      <HowItWorks />
      <Pricing />
      <FAQ />
      <CTA />
      <Footer />
    </div>
  )
}
