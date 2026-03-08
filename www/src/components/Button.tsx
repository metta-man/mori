import React from 'react';
import './Button.css';

export interface MoriButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}

export const MoriButton: React.FC<MoriButtonProps> = ({
  variant = 'primary',
  size = 'md',
  children,
  className = '',
  ...props
}) => {
  return (
    <button
      className={`mori-btn mori-btn-${variant} mori-btn-${size} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};
