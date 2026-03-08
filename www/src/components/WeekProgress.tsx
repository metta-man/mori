import './WeekProgress.css';

interface WeekProgressProps {
  completed: number;
  total: number;
  showLabel?: boolean;
}

export function WeekProgress({ 
  completed, 
  total,
  showLabel = true 
}: WeekProgressProps) {
  const percent = total > 0 ? Math.min((completed / total) * 100, 100) : 0;
  const isComplete = percent >= 100;

  return (
    <div className={`week-progress-container ${isComplete ? 'complete' : ''}`}>
      {showLabel && (
        <div className="week-progress-header">
          <span className="week-progress-label">This Week</span>
          <span className="week-progress-percent">{Math.round(percent)}%</span>
        </div>
      )}
      
      <div className="week-progress-track">
        <div 
          className="week-progress-fill"
          style={{ width: `${percent}%` }}
        />
        {isComplete && <div className="week-progress-glow" />}
      </div>
      
      {showLabel && (
        <p className="week-progress-detail">
          {completed} of {total} habits completed
        </p>
      )}
    </div>
  );
}

export default WeekProgress;
