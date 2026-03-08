import React from 'react';
import './Logo.css';

export interface MoriLogoProps {
  variant?: 'full' | 'icon' | 'wordmark';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const MoriLogo: React.FC<MoriLogoProps> = ({
  variant = 'full',
  size = 'md',
  className = ''
}) => {
  const sizeMap = {
    sm: { width: 24, height: 24 },
    md: { width: 40, height: 40 },
    lg: { width: 64, height: 64 }
  };

  const fontSizeMap = {
    sm: '18px',
    md: '28px',
    lg: '42px'
  };

  return (
    <div className={`mori-logo mori-logo-${variant} mori-logo-${size} ${className}`}>
      {variant !== 'wordmark' && (
        <svg
          viewBox="0 0 64 64"
          width={sizeMap[size].width}
          height={sizeMap[size].height}
          className="mori-logo-icon"
        >
          {/* Hourglass Rose - The Hourglass */}
          <path
            d="M32 4 L56 28 L56 36 L32 60 L8 36 L8 28 Z"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="mori-logo-hourglass"
          />
          {/* Sand in bottom */}
          <path
            d="M20 46 L32 54 L44 46 L44 44 L20 44 Z"
            fill="currentColor"
            className="mori-logo-sand"
          />
          {/* Rose petal floating */}
          <path
            d="M32 20 C32 20 28 24 28 28 C28 32 32 34 32 34 C32 34 36 32 36 28 C36 24 32 20 32 20"
            fill="currentColor"
            className="mori-logo-rose"
          />
        </svg>
      )}
      {variant !== 'icon' && (
        <span 
          className="mori-logo-text"
          style={{ fontSize: fontSizeMap[size] }}
        >
          MORI
        </span>
      )}
    </div>
  );
};
