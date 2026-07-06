import './DailyQuote.css';

interface Quote {
  text: string;
  author: string;
}

const QUOTES: Quote[] = [
  { text: "Limit the next feed. Protect the next hour.", author: "Mori" },
  { text: "One breath before one more tap.", author: "Mori" },
  { text: "The smallest pause can change the next open.", author: "Mori" },
  { text: "Let the screen lose its grip before the day gets loud.", author: "Mori" },
  { text: "Choose one clear action, then leave the app.", author: "Mori" },
  { text: "A reset is working when the phone feels less heavy.", author: "Mori" },
  { text: "Keep the archive soft. Change the next minute.", author: "Mori" },
  { text: "Friction beats willpower at the moment of opening.", author: "Mori" },
  { text: "Enough signal. No more scroll.", author: "Mori" },
  { text: "Start small enough that calm can actually happen.", author: "Mori" },
];

interface DailyQuoteProps {
  quoteIndex?: number;
}

export function DailyQuote({ quoteIndex }: DailyQuoteProps) {
  // Use date-based index for daily rotation
  const today = new Date();
  const dayOfYear = Math.floor((today.getTime() - new Date(today.getFullYear(), 0, 0).getTime()) / (1000 * 60 * 60 * 24));
  const index = quoteIndex ?? dayOfYear % QUOTES.length;
  const quote = QUOTES[index];

  return (
    <div className="daily-quote-container mori-entrance">
      <span className="quote-mark">"</span>
      
      <blockquote className="quote-text">
        {quote.text}
      </blockquote>
      
      <cite className="quote-author">
        — {quote.author}
      </cite>
    </div>
  );
}

export default DailyQuote;
