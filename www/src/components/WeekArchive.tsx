import './WeekArchive.css';

interface WeekArchiveProps {
  currentWeek?: number;
  currentYear?: number;
  totalWeeks?: number;
  years?: number;
  onCellClick?: (week: number, year: number) => void;
}

export function WeekArchive({
  currentWeek = 12, 
  currentYear = 2026,
  totalWeeks = 52,
  years = 80,
  onCellClick
}: WeekArchiveProps) {
  const gridCells = [];
  
  for (let year = 0; year < years; year++) {
    for (let week = 0; week < totalWeeks; week++) {
      const weekNumber = year * totalWeeks + week + 1;
      const isPast = weekNumber < (currentYear - 1990) * totalWeeks + currentWeek;
      const isCurrent = weekNumber === (currentYear - 1990) * totalWeeks + currentWeek;
      const isNearCurrent = weekNumber === (currentYear - 1990) * totalWeeks + currentWeek + 1;
      
      let cellClass = 'week-archive-cell';
      if (isPast) cellClass += ' cell-past';
      if (isCurrent) cellClass += ' cell-current';
      if (isNearCurrent) cellClass += ' cell-near';
      
      gridCells.push(
        <div 
          key={`${year}-${week}`}
          className={cellClass}
          data-week={weekNumber}
          onClick={() => onCellClick?.(week, year)}
          title={`Archive week ${weekNumber} of year ${year + 1}`}
        />
      );
    }
  }
  
  const totalCells = years * totalWeeks;
  const currentCell = (currentYear - 1990) * totalWeeks + currentWeek;
  const progressPercent = Math.min((currentCell / totalCells) * 100, 100);
  
  return (
    <div className="week-archive-container mori-entrance">
      <div className="week-archive-header">
        <h2 className="week-archive-title">Weeks Archive</h2>
        <p className="week-archive-subtitle">
          {progressPercent.toFixed(1)}% of lived weeks held softly
        </p>
      </div>
      
      <div className="week-archive-wrapper">
        <div className="week-archive-grid">
          {gridCells}
        </div>
      </div>
      
      <div className="week-archive-legend">
        <div className="legend-item">
          <span className="legend-dot cell-past"></span>
          <span>Held</span>
        </div>
        <div className="legend-item">
          <span className="legend-dot cell-current"></span>
          <span>Current</span>
        </div>
        <div className="legend-item">
          <span className="legend-dot cell-future"></span>
          <span>Remaining</span>
        </div>
      </div>
    </div>
  );
}

export default WeekArchive;
