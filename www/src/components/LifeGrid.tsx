import './LifeGrid.css';

interface LifeGridProps {
  currentWeek?: number;
  currentYear?: number;
  totalWeeks?: number;
  years?: number;
  onCellClick?: (week: number, year: number) => void;
}

export function LifeGrid({ 
  currentWeek = 12, 
  currentYear = 2026,
  totalWeeks = 52,
  years = 80,
  onCellClick
}: LifeGridProps) {
  // Generate grid data
  const gridCells = [];
  
  for (let year = 0; year < years; year++) {
    for (let week = 0; week < totalWeeks; week++) {
      const weekNumber = year * totalWeeks + week + 1;
      const isPast = weekNumber < (currentYear - 1990) * totalWeeks + currentWeek;
      const isCurrent = weekNumber === (currentYear - 1990) * totalWeeks + currentWeek;
      const isNearCurrent = weekNumber === (currentYear - 1990) * totalWeeks + currentWeek + 1;
      
      let cellClass = 'life-cell';
      if (isPast) cellClass += ' cell-past';
      if (isCurrent) cellClass += ' cell-current';
      if (isNearCurrent) cellClass += ' cell-near';
      
      gridCells.push(
        <div 
          key={`${year}-${week}`}
          className={cellClass}
          data-week={weekNumber}
          onClick={() => onCellClick?.(week, year)}
          title={`Week ${weekNumber} of Year ${year + 1}`}
        />
      );
    }
  }
  
  // Calculate life progress
  const totalCells = years * totalWeeks;
  const currentCell = (currentYear - 1990) * totalWeeks + currentWeek;
  const progressPercent = Math.min((currentCell / totalCells) * 100, 100);
  
  return (
    <div className="life-grid-container mori-entrance">
      <div className="life-grid-header">
        <h2 className="life-grid-title">Your Life Grid</h2>
        <p className="life-grid-subtitle">
          {progressPercent.toFixed(1)}% of your life weeks completed
        </p>
      </div>
      
      <div className="life-grid-wrapper">
        <div className="life-grid">
          {gridCells}
        </div>
      </div>
      
      <div className="life-grid-legend">
        <div className="legend-item">
          <span className="legend-dot cell-past"></span>
          <span>Lived</span>
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

export default LifeGrid;
