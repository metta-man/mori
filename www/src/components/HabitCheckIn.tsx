import { useState } from 'react';
import './HabitCheckIn.css';

interface Habit {
  id: string;
  name: string;
  icon: string;
}

interface HabitCheckInProps {
  habits: Habit[];
  onToggle?: (habitId: string, completed: boolean) => void;
}

export function HabitCheckIn({ habits: initialHabits, onToggle }: HabitCheckInProps) {
  const [habits, setHabits] = useState<Record<string, boolean>>(
    initialHabits.reduce((acc, h) => ({ ...acc, [h.id]: false }), {})
  );

  const toggleHabit = (habitId: string) => {
    const newState = !habits[habitId];
    setHabits(prev => ({ ...prev, [habitId]: newState }));
    onToggle?.(habitId, newState);
  };

  const completedCount = Object.values(habits).filter(Boolean).length;
  const totalCount = initialHabits.length;
  const progressPercent = totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

  return (
    <div className="habit-checkin-container mori-entrance">
      <div className="habit-checkin-header">
        <h2 className="habit-checkin-title">Today's Habits</h2>
        <p className="habit-checkin-progress">
          {completedCount} of {totalCount} complete
        </p>
      </div>

      <div className="habit-progress-bar">
        <div 
          className="habit-progress-fill" 
          style={{ width: `${progressPercent}%` }}
        />
      </div>

      <div className="habit-list">
        {initialHabits.map(habit => (
          <div 
            key={habit.id} 
            className={`habit-row ${habits[habit.id] ? 'completed' : ''}`}
            onClick={() => toggleHabit(habit.id)}
          >
            <span className="habit-icon">{habit.icon}</span>
            <span className="habit-name">{habit.name}</span>
            <div className={`habit-toggle ${habits[habit.id] ? 'complete' : ''}`}>
              {habits[habit.id] && (
                <svg className="checkmark" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                  <polyline points="20 6 9 17 4 12" />
                </svg>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default HabitCheckIn;
