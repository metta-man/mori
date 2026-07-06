import React from 'react';
import bellIcon from '../assets/icons/mori-icon-bell.png';
import breatheIcon from '../assets/icons/mori-icon-breathe.png';
import chevronIcon from '../assets/icons/mori-icon-chevron.png';
import focusIcon from '../assets/icons/mori-icon-focus.png';
import hapticsIcon from '../assets/icons/mori-icon-haptics.png';
import heartIcon from '../assets/icons/mori-icon-heart.png';
import homeIcon from '../assets/icons/mori-icon-home.png';
import journalIcon from '../assets/icons/mori-icon-journal.png';
import leafIcon from '../assets/icons/mori-icon-leaf.png';
import lockShieldIcon from '../assets/icons/mori-icon-lock-shield.png';
import minusIcon from '../assets/icons/mori-icon-minus.png';
import pauseIcon from '../assets/icons/mori-icon-pause.png';
import playIcon from '../assets/icons/mori-icon-play.png';
import plusIcon from '../assets/icons/mori-icon-plus.png';
import pulseIcon from '../assets/icons/mori-icon-pulse.png';
import quietIcon from '../assets/icons/mori-icon-quiet.png';
import refreshIcon from '../assets/icons/mori-icon-refresh.png';
import rootsIcon from '../assets/icons/mori-icon-roots.png';
import settingsIcon from '../assets/icons/mori-icon-settings.png';
import soundIcon from '../assets/icons/mori-icon-sound.png';
import stopIcon from '../assets/icons/mori-icon-stop.png';
import timerIcon from '../assets/icons/mori-icon-timer.png';

export type MoriIconName =
  | 'home'
  | 'breathe'
  | 'focus'
  | 'bell'
  | 'roots'
  | 'pulse'
  | 'journal'
  | 'quiet'
  | 'settings'
  | 'chevron'
  | 'plus'
  | 'minus'
  | 'play'
  | 'pause'
  | 'stop'
  | 'refresh'
  | 'sound'
  | 'haptics'
  | 'leaf'
  | 'lockShield'
  | 'timer'
  | 'heart';

export interface MoriIconProps {
  name: MoriIconName;
  size?: number;
  className?: string;
  decorative?: boolean;
}

const iconAssets: Record<MoriIconName, string> = {
  home: homeIcon,
  breathe: breatheIcon,
  focus: focusIcon,
  bell: bellIcon,
  roots: rootsIcon,
  pulse: pulseIcon,
  journal: journalIcon,
  quiet: quietIcon,
  settings: settingsIcon,
  chevron: chevronIcon,
  plus: plusIcon,
  minus: minusIcon,
  play: playIcon,
  pause: pauseIcon,
  stop: stopIcon,
  refresh: refreshIcon,
  sound: soundIcon,
  haptics: hapticsIcon,
  leaf: leafIcon,
  lockShield: lockShieldIcon,
  timer: timerIcon,
  heart: heartIcon,
};

const iconLabels: Record<MoriIconName, string> = {
  home: 'Home',
  breathe: 'Breathe',
  focus: 'Focus',
  bell: 'Bell',
  roots: 'Roots',
  pulse: 'Pulse',
  journal: 'Journal',
  quiet: 'Quiet',
  settings: 'Settings',
  chevron: 'Chevron',
  plus: 'Plus',
  minus: 'Minus',
  play: 'Play',
  pause: 'Pause',
  stop: 'Stop',
  refresh: 'Refresh',
  sound: 'Sound',
  haptics: 'Haptics',
  leaf: 'Leaf',
  lockShield: 'Lock Shield',
  timer: 'Timer',
  heart: 'Heart',
};

export const MoriIcon: React.FC<MoriIconProps> = ({
  name,
  size = 24,
  className = '',
  decorative = true,
}) => {
  return (
    <img
      src={iconAssets[name]}
      width={size}
      height={size}
      alt={decorative ? '' : iconLabels[name]}
      aria-hidden={decorative ? 'true' : undefined}
      className={`mori-icon mori-icon-${name} ${className}`}
      decoding="async"
      loading="lazy"
    />
  );
};
