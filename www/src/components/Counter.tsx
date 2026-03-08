import React from 'react';
import './Counter.css';

export interface MoriCounterProps {
  value: number | string;
  label: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  animated?: boolean;
  className?: string;
}

export const MoriCounter: React.FC<MoriCounterProps> = ({
  value,
  label,
  size = 'md',
  animated = false,
  className = ''
}) => {
  return (
    <div className={`mori-counter-wrapper ${className}`}>
      <span 
        className={`mori-counter mori-counter-${size} ${animated ? 'mori-number-update' : ''}`}
      >
        {value}
      </span>
      <span className="mori-counter-label">
        {label}
      </span>
    </div>
  );
};
