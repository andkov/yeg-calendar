# Edmonton Solar Calendar Visualizations - Index

## Quick Start

### For Quick Preview (3 graphs, ~30 seconds)
```r
source("./analysis/demo-visualization.R")
```
Generates:
- Annual pattern line graph
- Monthly summary bar chart  
- Seasonal distribution boxplots

### For Complete Analysis (8 graphs, ~2 minutes)
```r
source("./analysis/visualization-graphs.R")
```
Generates:
- All 8 comprehensive visualizations
- Detailed statistical summary
- Professional-quality outputs

## Generated Files

All graphs are saved to `./analysis/prints/` as high-resolution JPG files.

### Demo Outputs (from demo-visualization.R)
1. `demo-annual-pattern.jpg` - Simple annual curve
2. `demo-monthly-summary.jpg` - Monthly averages with ranges
3. `demo-seasonal-distribution.jpg` - Boxplots by season

### Main Outputs (from visualization-graphs.R)
1. `1-annual-illumination-duration.jpg` - Full year daylight cycle
2. `2-daily-change-in-daylight.jpg` - Day-to-day change rate
3. `3-weekly-change-in-daylight.jpg` - Week-to-week change by season
4. `4-seasonal-comparison.jpg` - Solar year perspective
5. `5-sunrise-sunset-times.jpg` - Clock times with twilight
6. `6-solar-weeks-illumination.jpg` - Vertical week bars
7. `7-quarterly-calendar-tiles.jpg` - Heat map calendar
8. `8-extreme-days.jpg` - Longest/shortest day highlights

## Documentation Files

- **VISUALIZATION-README.md** - Complete guide to all visualizations
  - What each graph shows
  - How to interpret them
  - Technical details
  - Data sources
  
- **VISUALIZATION-RATIONALE.md** - Design philosophy and reasoning
  - Why each visualization was chosen
  - What insights each provides
  - Human-centered design decisions
  - Edmonton-specific context

- **INDEX.md** (this file) - Navigation and quick reference

## File Organization

```
analysis/
├── demo-visualization.R           # Quick demo script (3 graphs)
├── visualization-graphs.R         # Main analysis script (8 graphs)
├── VISUALIZATION-README.md        # Complete documentation
├── VISUALIZATION-RATIONALE.md     # Design rationale
├── INDEX.md                       # This file
└── prints/                        # Output folder (git-ignored)
    ├── demo-*.jpg                 # Demo outputs
    └── [1-8]-*.jpg               # Main outputs
```

## Requirements

### R Packages
```r
# Core packages
library(ggplot2)   # visualization
library(dplyr)     # data manipulation
library(tidyr)     # data tidying
library(lubridate) # date handling
library(readr)     # CSV import
library(stringr)   # string operations
library(scales)    # plot formatting
library(janitor)   # data cleaning
```

### Data Files
The scripts automatically load from:
```
data-public/raw/
├── sunrise_sunset_2024_edmonton.csv
├── sunrise_sunset_2025_edmonton.csv
├── sunrise_sunset_2026_edmonton.csv
├── events-solar.csv    # Solstices, equinoxes
├── events-civic.csv    # Holidays
└── events-lunar.csv    # Moon phases
```

## Usage Scenarios

### 1. First-Time User
"I want to see what this is about."
```r
source("./analysis/demo-visualization.R")
```
Then look at the 3 demo graphs in `analysis/prints/`

### 2. Detailed Analysis
"I want all the insights."
```r
source("./analysis/visualization-graphs.R")
```
Then review all 8 graphs and read VISUALIZATION-README.md

### 3. Understanding Design
"I want to know why these graphs were chosen."

Read VISUALIZATION-RATIONALE.md

### 4. Customization
"I want to modify the graphs."

1. Copy `visualization-graphs.R` to a new file
2. Edit the graph sections (marked with `# ---- graph-N ----`)
3. Modify colors, sizes, labels as needed
4. Re-run to see your changes

### 5. Presentation
"I need to present these findings."

Use the graphs in this order:
1. Start with `1-annual-illumination-duration.jpg` (foundation)
2. Show `2-daily-change-in-daylight.jpg` (rate of change)
3. Present `5-sunrise-sunset-times.jpg` (practical times)
4. Highlight `8-extreme-days.jpg` (the extremes)
5. End with `7-quarterly-calendar-tiles.jpg` (beautiful summary)

## Key Statistics (2025)

From the visualizations, you can see:
- **Shortest day**: ~7.5 hours (December 21)
- **Longest day**: ~17 hours (June 20)
- **Variation**: 9.5 hours (127% difference)
- **Fastest gain**: ~4 minutes/day (March equinox)
- **Fastest loss**: ~4 minutes/day (September equinox)
- **Peak weekly gain**: ~30 minutes/week (spring)
- **Peak weekly loss**: ~30 minutes/week (fall)

## Common Questions

**Q: Why are there multiple visualization files?**
A: `demo-visualization.R` is a quick preview, `visualization-graphs.R` is the complete analysis. Different use cases need different depth.

**Q: Where are the PNG files?**
A: They're in `./analysis/prints/` but git-ignored. Run the scripts to generate them locally.

**Q: Can I change the output format?**
A: Yes! Edit the `quick_save()` function in `scripts/common-functions.R` to change from JPG to PNG, PDF, or SVG.

**Q: Why start at winter solstice?**
A: The "solar year" is more astronomically meaningful. Winter solstice is the shortest day and natural starting point for the yearly cycle.

**Q: What's the difference between illumination_day and illumination_total?**
A: 
- `illumination_day`: Sunrise to sunset (direct sunlight)
- `illumination_total`: Including civil twilight (usable light)

**Q: Can I compare multiple years?**
A: The main script loads 2024-2026 data. You can extend the visualizations to show multi-year comparisons by modifying the code.

**Q: Is this data accurate?**
A: Yes, it's calculated from NOAA algorithms for solar position. Times are accurate to within 1-2 minutes.

## For Developers

### Modifying Existing Graphs
Each graph is in its own clearly-marked section:
```r
# ---- graph-1-illumination-duration ---
# Code for graph 1
```

### Adding New Graphs
1. Follow the pattern of existing sections
2. Use the prepared datasets: `ds1`, `ds2`, or create new ones
3. Use `quick_save()` to save your graph
4. Add documentation to VISUALIZATION-README.md

### Data Pipeline
```
Raw CSV files 
  → Load and parse (---- load-data ----)
  → Clean and join (---- tweak-data-0/1 ----)
  → Calculate metrics (---- tweak-data-2 ----)
  → Visualize (---- graph-N ----)
  → Save (quick_save())
```

### Testing Changes
```r
# Quick test with demo
source("./analysis/demo-visualization.R")

# Full test
source("./analysis/visualization-graphs.R")
```

## Credits and Sources

- **Data**: NOAA Solar Calculator, TimeAndDate.com
- **Design inspiration**: Edward Tufte, visualization best practices
- **Color palettes**: Viridis (perceptually uniform, color-blind friendly)
- **Framework**: tidyverse ecosystem for R

## License

See repository LICENSE file.

## Contributing

To contribute:
1. Follow existing code style and structure
2. Add clear comments and documentation  
3. Test with multiple years of data
4. Update this INDEX.md and other docs
5. Consider accessibility (color-blind friendly palettes)

## Contact

For questions, issues, or suggestions, please open an issue on the GitHub repository.

---

*Last updated: 2025*  
*Part of the yeg-calendar project*
