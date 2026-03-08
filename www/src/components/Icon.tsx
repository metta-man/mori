import React from 'react';

export type MoriIconName = 
  | 'hourglass' 
  | 'rose' 
  | 'chart' 
  | 'sunset' 
  | 'target' 
  | 'star' 
  | 'book' 
  | 'leaf'
  | 'sun'
  | 'moon'
  | 'clock'
  | 'heart';

export interface MoriIconProps {
  name: MoriIconName;
  size?: number;
  className?: string;
}

const iconPaths: Record<MoriIconName, string> = {
  hourglass: 'M12 2v4m0 12v4M4 8h16M4 16h16m-8-4l-4-4m4 4l4-4m-4 12l-4 4m4-4l4 4',
  rose: 'M12 21c-4-4-8-7-8-12a8 8 0 1116 0c0 5-4 8-8 12z',
  chart: 'M3 3v18h18M7 16l4-4 4 4 5-6',
  sunset: 'M17 18a5 5 0 000-10H5m12 5a5 5 0 01-5 5H5m12-8l-4-4m0 0L9 7m4 4l-4 4',
  target: 'M12 2a10 10 0 100 20 10 10 0 000-20zm0 5v5l3 3',
  star: 'M12 2l3 7h7l-5.5 4.5 2 7.5-6.5-4.5-6.5 4.5 2-7.5L2 9h7l3-7z',
  book: 'M4 19.5A2.5 2.5 0 016.5 17H20M4 4.5v15A2.5 2.5 0 016.5 17H20V2H6.5A2.5 2.5 0 004 4.5z',
  leaf: 'M11 20A7 7 0 0113.56 6.44l-2.12-6.36a1 1 0 00-1.74 0L7 12.86 3 21h14l-4-8.56z',
  sun: 'M12 1v2m0 18v2M4.22 4.22l1.42 1.42m12.72 12.72l1.42 1.42M1 12h2m18 0h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42',
  moon: 'M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z',
  clock: 'M12 6v6l4 2m4-2a8 8 0 11-16 0 8 8 0 0116 0z',
  heart: 'M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z'
};

export const MoriIcon: React.FC<MoriIconProps> = ({
  name,
  size = 24,
  className = ''
}) => {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={`mori-icon mori-icon-${name} ${className}`}
    >
      <path d={iconPaths[name]} />
    </svg>
  );
};
