import React from 'react';
import './Card.css';

export interface MoriCardProps {
  children: React.ReactNode;
  variant?: 'default' | 'elevated' | 'outlined';
  className?: string;
  onClick?: () => void;
}

export const MoriCard: React.FC<MoriCardProps> = ({
  children,
  variant = 'default',
  className = '',
  onClick
}) => {
  return (
    <div 
      className={`mori-card mori-card-${variant} ${className}`}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {children}
    </div>
  );
};
