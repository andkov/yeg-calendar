# Visualization Design Rationale

## Purpose

This document explains the thought process and design decisions behind the Edmonton climate and astronomical visualizations, addressing why each graph was chosen and what insights it provides.

## Design Philosophy

### 1. Progressive Complexity
The visualizations are ordered from simple to complex:
- Start with familiar line graphs showing annual patterns
- Progress to derived metrics (rates of change)
- End with novel representations (tile calendars, vertical bars)

### 2. Multiple Perspectives
Each visualization shows the same underlying data (sun/twilight times) from different angles:
- **Absolute values**: Total hours of light
- **Rates of change**: How fast daylight increases/decreases
- **Cumulative change**: Weekly accumulation
- **Time-of-day**: Actual clock times of sunrise/sunset
- **Spatial arrangement**: Calendar grids

### 3. Human-Centered Design
All graphs answer practical questions people in Edmonton ask:
- "How much daylight is there today?"
- "How quickly are the days getting longer?"
- "When will the sun set today?"
- "How does this season compare to others?"

## Why These Specific Visualizations?

### Graph 1: Annual Illumination Duration
**Rationale**: This is the foundational graph that everyone needs to see first.

**Why it matters**:
- Shows the dramatic 9+ hour swing from winter to summer
- Distinguishes between strict daylight and civil twilight
- Marks key astronomical events (solstices, equinoxes)
- Provides context for all other visualizations

**Design choices**:
- Two lines (daylight vs total illumination) show that usable light extends beyond sunrise/sunset
- Blue and orange colors distinguish the measures clearly
- Red dots mark solstices/equinoxes as reference points
- Starting from mid-2024 shows the transition through winter solstice

**Human insight**: "I can see why January feels so dark - we're only getting 7.5 hours of light!"

### Graph 2: Daily Change in Daylight
**Rationale**: People notice when days are "getting longer" or "getting shorter" but rarely quantify it.

**Why it matters**:
- Shows that change is not uniform throughout the year
- Explains why equinoxes feel more dramatic than solstices
- Helps understand seasonal transitions
- Smoothed curve removes daily noise

**Design choices**:
- Red color emphasizes the change aspect
- Zero line shows the transition between gaining and losing light
- Minutes (not hours) make the scale more intuitive
- Spline smoothing removes measurement artifacts

**Human insight**: "In March, I'm gaining 4 minutes of daylight EVERY DAY - no wonder spring feels energizing!"

### Graph 3: Weekly Change in Daylight
**Rationale**: Weekly patterns are more meaningful for human planning than daily changes.

**Why it matters**:
- A week is a natural human time unit (work week, school week)
- 30 minutes per week is very noticeable to people
- Color coding by season connects change to experience
- Shows asymmetry between spring and fall

**Design choices**:
- Thick colored lines make seasonal patterns obvious
- Thin black line shows raw data for transparency
- Points at solstices/equinoxes provide reference
- Season colors: winter=blue, spring=green, summer=yellow/orange, fall=red

**Human insight**: "Ah, that's why February feels so much better than January - we're gaining 2 hours of light per month!"

### Graph 4: Seasonal Comparison
**Rationale**: The "solar year" perspective (solstice to solstice) is more astronomically meaningful than the calendar year.

**Why it matters**:
- Shows the year as a continuous cycle
- Clarifies that "astronomical seasons" don't match calendar months
- Demonstrates the symmetry (and asymmetry) of Earth's orbit
- Useful for long-term planning and understanding

**Design choices**:
- X-axis is "day of solar year" not calendar date
- Color by season makes quarters obvious
- Events labeled directly on the curve
- Starts at winter solstice (day 0)

**Human insight**: "The 'solar year' view makes more sense than January-December for understanding seasons."

### Graph 5: Sunrise/Sunset Times
**Rationale**: People care about WHEN the sun rises/sets, not just how long it's up.

**Why it matters**:
- Clock times affect daily schedules
- Shows summer's extreme early sunrises and late sunsets
- Demonstrates the shift in "midday sun" throughout the year
- Twilight bands show extended usable light

**Design choices**:
- Ribbon plots show periods (not just lines)
- Yellow = daylight, light blue = twilight for intuitive understanding
- Y-axis formatted as clock times (08:00, 16:00)
- Orange sunrise line, dark blue sunset line for contrast

**Human insight**: "In June, the sun rises at 5 AM and sets at 10 PM - that's why summer evenings feel endless!"

### Graph 6: Solar Weeks Illumination
**Rationale**: A unique visualization that treats each week as a unit and shows progression vertically.

**Why it matters**:
- Novel perspective breaks from standard line graphs
- Shows the 52-week cycle as discrete steps
- Split view (ascending/descending) emphasizes the peak
- Works well as a physical display/poster

**Design choices**:
- Vertical bars emphasize weekly chunks
- Split into two panels at summer solstice (week 26/27)
- Color gradient shows smooth progression
- Week numbers labeled for reference
- Thick grid lines act as measurement rulers

**Human insight**: "This would make a great wall calendar showing which 'solar week' we're in!"

### Graph 7: Quarterly Calendar Tiles
**Rationale**: Heat maps are excellent for showing patterns in calendar-structured data.

**Why it matters**:
- Most familiar format (calendar grid)
- Quarters of 13 weeks are astronomically meaningful
- Color intensity makes patterns instantly visible
- Useful for planning year-round

**Design choices**:
- Four quarters (Winter, Spring, Summer, Fall) shown side-by-side
- Each quarter: 13 weeks × 7 days = 91 days
- Viridis color scale (color-blind friendly)
- Tile size and spacing optimized for readability
- Large season labels at top

**Human insight**: "I can see at a glance that mid-June is the peak - every day in that week is bright yellow!"

### Graph 8: Extreme Days
**Rationale**: Highlighting extremes helps people understand the range of their environment.

**Why it matters**:
- Quantifies the total variation (9+ hours)
- Shows specific dates for longest/shortest days
- Calculates percentage change (125%!)
- Provides concrete numbers for discussion

**Design choices**:
- Gold point for longest day (peak summer)
- Navy point for shortest day (depth of winter)
- Labels with exact values
- Subtitle emphasizes the magnitude of variation
- Simple line graph keeps focus on extremes

**Human insight**: "Edmonton has 125% MORE daylight in summer than winter - that's more extreme than I thought!"

## What Makes These Graphs Important for Understanding Edmonton?

### Geographic Context Matters
At 53.5°N latitude, Edmonton is:
- Farther north than most major US cities (Seattle is 47.6°N)
- Similar to cities like Hamburg, Dublin, Edinburgh
- Far enough north for dramatic seasonal differences
- But not far enough for true "midnight sun"

### Psychological Impact
The visualizations help explain:
- **Seasonal Affective Disorder (SAD)**: The graphs show why winter is psychologically challenging
- **Spring excitement**: The rapid change in March/April is visible and quantifiable
- **Summer energy**: Extended daylight enables outdoor activities and social life
- **Fall adjustment**: The rapid loss of light requires mental preparation

### Practical Applications

**Energy Planning**:
- Heating needs correlate with lack of solar gain
- Lighting needs peak during winter months
- Summer cooling despite long days (temperature lags sunlight)

**Urban Planning**:
- Street lighting schedules
- Park and facility hours
- School start times (kids waiting for buses in darkness)
- Traffic patterns (rush hour in darkness in winter)

**Agriculture**:
- Growing season clearly defined
- Frost dates correlate with daylight changes
- Plant selection must account for extreme variation

**Tourism**:
- Summer festivals capitalize on long evenings
- Winter tourism requires indoor options
- Shoulder seasons (spring/fall) have unique appeal

**Mental Health Services**:
- Light therapy needs peak in winter
- Seasonal counseling timing
- Vitamin D supplementation recommendations

### Cultural Integration
The visualizations show how civic events align (or don't) with astronomical reality:
- Canada Day (July 1) is near but after the summer solstice
- Thanksgiving (October) is during rapid daylight loss
- Christmas (December 25) is just after winter solstice
- New Year (January 1) is during slow daylight gain

## Design Decisions for Human Comprehension

### Color Choices
- **Blue/Orange/Red**: High contrast, accessible to most color-blind individuals
- **Seasonal colors**: Intuitive associations (blue=winter, yellow=summer)
- **Viridis scale**: Scientifically designed for perception and accessibility

### Units and Scales
- **Hours** for absolute illumination (familiar unit)
- **Minutes** for daily/weekly changes (more tangible than decimal hours)
- **Clock times** for sunrise/sunset (what people actually use)
- **Day numbers** for solar year (emphasizes continuous cycle)

### Annotations and Labels
- **Event markers**: Solstices and equinoxes as reference points
- **Legends**: Minimal and clear
- **Titles and subtitles**: Descriptive and informative
- **Axis labels**: Complete with units

### Layout and Composition
- **Wide format (14×7)**: Accommodates time series without compression
- **Consistent theme**: Minimal theme with clear grid lines
- **White space**: Prevents visual clutter
- **High DPI**: "Retina" quality for printing and display

## Potential Extensions

### Interactive Features (Future)
- **Zoom**: Focus on specific time periods
- **Hover**: Show exact values for any day
- **Compare**: Multiple years or cities side-by-side
- **Animate**: Watch the year progress in real-time

### Additional Data Layers
- **Temperature**: Overlay average daily temps
- **Precipitation**: Show rainy/snowy days
- **Cloud cover**: Actual vs possible sunshine
- **Moon phases**: Add lunar cycle information
- **Aurora potential**: Geomagnetic activity for northern lights

### Alternative Visualizations
- **Polar plots**: Circular year representation
- **3D surface**: Time × day of year × illumination
- **Small multiples**: Compare many years at once
- **Difference plots**: This year vs average
- **Anomaly detection**: Unusual weather patterns

## Conclusion

These visualizations were designed to:
1. **Educate**: Help people understand Edmonton's unique climate
2. **Quantify**: Put numbers to subjective experiences
3. **Predict**: Show what to expect in coming months
4. **Appreciate**: Highlight the beauty of astronomical cycles
5. **Plan**: Enable informed decision-making

The graphs progress from simple (annual pattern) to sophisticated (tile calendars), from absolute measures (hours of light) to derived metrics (rate of change), and from scientific (solar weeks) to practical (clock times).

Together, they provide a comprehensive view of Edmonton's relationship with the sun - a relationship that profoundly affects daily life for everyone in the city.

---

*"We are all in the gutter, but some of us are looking at the stars."* - Oscar Wilde

*These visualizations help Edmontonians understand not just the stars, but the sun's path through their sky, and how it shapes their experience of home.*
