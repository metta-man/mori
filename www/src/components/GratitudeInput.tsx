import { useState } from 'react';
import './GratitudeInput.css';

interface GratitudeInputProps {
  maxLength?: number;
  onSubmit?: (text: string) => void;
  placeholder?: string;
}

export function GratitudeInput({ 
  maxLength = 280, 
  onSubmit,
  placeholder = "What are you grateful for today?"
}: GratitudeInputProps) {
  const [text, setText] = useState('');
  const [isFocused, setIsFocused] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  const handleSubmit = () => {
    if (text.trim()) {
      onSubmit?.(text.trim());
      setIsSubmitted(true);
      setTimeout(() => {
        setText('');
        setIsSubmitted(false);
      }, 2000);
    }
  };

  const charCount = text.length;
  const isOverLimit = charCount > maxLength;

  return (
    <div className={`gratitude-container mori-entrance ${isSubmitted ? 'submitted' : ''}`}>
      <div className="gratitude-header">
        <span className="gratitude-icon">🙏</span>
        <h2 className="gratitude-title">Today's Gratitude</h2>
      </div>

      <p className="gratitude-prompt">
        What are you grateful for today?
      </p>

      <div className={`gratitude-input-wrapper ${isFocused ? 'focused' : ''}`}>
        <textarea
          className="gratitude-textarea"
          placeholder={placeholder}
          value={text}
          onChange={(e) => setText(e.target.value)}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          maxLength={maxLength + 20} // Allow slight overflow for UX
        />
        
        <div className="gratitude-footer">
          <span className={`char-counter ${isOverLimit ? 'over-limit' : ''}`}>
            {charCount} / {maxLength}
          </span>
          
          <button 
            className="gratitude-submit"
            onClick={handleSubmit}
            disabled={!text.trim() || isOverLimit}
          >
            {isSubmitted ? '✓ Saved' : 'Save'}
          </button>
        </div>
      </div>

      {isSubmitted && (
        <div className="gratitude-success">
          <span className="success-icon">✨</span>
          <span>Your gratitude has been recorded</span>
        </div>
      )}
    </div>
  );
}

export default GratitudeInput;
