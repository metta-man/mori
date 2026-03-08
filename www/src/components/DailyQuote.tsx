import './DailyQuote.css';

interface Quote {
  text: string;
  author: string;
}

const QUOTES: Quote[] = [
  { text: "Memento mori. Remember that you will die, so you may truly live.", author: "Marcus Aurelius" },
  { text: "The only way to do great work is to love what you do.", author: "Steve Jobs" },
  { text: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.", author: "Aristotle" },
  { text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein" },
  { text: "The unexamined life is not worth living.", author: "Socrates" },
  { text: "It is not death that a man should fear, but he should fear never beginning to live.", author: "Marcus Aurelius" },
  { text: "Waste no more time arguing about what a good man should be. Be one.", author: "Marcus Aurelius" },
  { text: "The obstacle is the way.", author: "Marcus Aurelius" },
  { text: "Very little is needed to make a happy life; it is all within yourself.", author: "Marcus Aurelius" },
  { text: "Begin at once to live, and count each separate day as a separate life.", author: "Seneca" },
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
