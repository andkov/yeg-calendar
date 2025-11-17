# Edmonton Climate and Astronomical Visualization Graphs
# This script creates a series of visualizations to understand Edmonton's
# climate and astronomical reality, including daylight patterns, seasonal changes,
# and astronomical events throughout the solar year.

rm(list = ls(all.names = TRUE)) # Clear the memory
cat("\014") # Clear the console

# ---- load-packages -----------------------------------------------------------
# Load required packages for data manipulation and visualization
library(ggplot2)   # graphs
library(dplyr)     # data manipulation
library(tidyr)     # data tidying
library(lubridate) # date handling
library(stringr)   # string manipulation
library(readr)     # reading CSV files
library(scales)    # formatting scales

# ---- load-sources ------------------------------------------------------------
base::source("./scripts/common-functions.R") # project-level functions

# ---- declare-globals ---------------------------------------------------------
# Create output folder for generated graphs
prints_folder <- paste0("./analysis/prints/")
if(!file.exists(prints_folder)){dir.create(file.path(prints_folder))}

# ---- declare-functions -------------------------------------------------------
print_all <- function(d){ print(d, n = nrow(d)) }

# ---- load-data ---------------------------------------------------------------
# Load sunrise/sunset data for multiple years
ls_object <- list()
for(i in c("2024", "2025", "2026")){
  ls_object[[i]] <- readr::read_csv(
    paste0("data-public/raw/sunrise_sunset_", i, "_edmonton.csv"),
    col_types = cols(
      `Civil Twilight Start` = col_time(format = "%H:%M"),
      Sunrise                = col_time(format = "%H:%M"),
      `Local Noon`           = col_time(format = "%H:%M"),
      Sunset                 = col_time(format = "%H:%M"),
      `Civil Twilight End`   = col_time(format = "%H:%M")
    )
  )
}
yeg_solar_calendar <- bind_rows(ls_object, .id = "year")

# Load event data
events_civic_raw <- read_csv("data-public/raw/events-civic.csv", skip = 1)
events_solar_raw <- read_csv("data-public/raw/events-solar.csv", skip = 1)
events_lunar_raw <- read_csv("data-public/raw/events-lunar.csv", skip = 1)

# ---- tweak-data-0 ------------------------------------------------------------
# Process and clean the solar calendar data
ds0 <- 
  yeg_solar_calendar %>% 
  janitor::clean_names() %>% 
  mutate(
    date = str_c(year, date, sep = " "),
    date = parse_date_time(date, orders = "Y b d")
  ) %>% 
  arrange(date)

# Process solar events (equinoxes and solstices)
events_solar <-
  events_solar_raw %>% 
  janitor::clean_names() %>% 
  pivot_longer(cols = setdiff(names(.), "year")) %>% 
  mutate(
    measure = (name %>% str_split(pattern = "_", simplify = TRUE))[,3],
    season  = (name %>% str_split(pattern = "_", simplify = TRUE))[,1],
    event   = (name %>% str_split(pattern = "_", simplify = TRUE))[,2]
  ) %>%
  mutate(
    season = case_match(season,
      "march"     ~ "spring",
      "september" ~ "fall",
      "december"  ~ "winter",
      "june"      ~ "summer"
    )
  ) %>% 
  select(-name) %>% 
  pivot_wider(
    id_cols = c("year", "season", "event"),
    names_from = "measure",
    values_from = "value"
  ) %>% 
  rename(day = date) %>% 
  mutate(
    date = str_c(year, "-", str_replace(day, " ", "-")) %>% 
           parse_date_time(orders = "Y-B-d"),
    time2 = map_chr(str_split(time, " "), ~ .[1]) %>% parse_time(),
    timezone_abb = map_chr(str_split(time, " "), ~ .[3]),
    date_time = as.POSIXct(paste(date, time2), format = "%Y-%m-%d %H:%M:%S"),
    time = time2
  ) %>% 
  select(-time2)

events_civic <- events_civic_raw
events_lunar <- events_lunar_raw

# ---- tweak-data-1 ------------------------------------------------------------
# Join all event data with solar calendar
ds1 <-
  ds0 %>% 
  left_join(
    events_solar %>% 
      mutate(event_solar = paste0(season, " ", event)) %>% 
      select(date, season, event_solar),
    by = "date"
  ) %>%
  left_join(
    events_civic %>% 
      pivot_longer(
        cols = starts_with("date_"),
        values_to = "date"
      ) %>% 
      select(date, event_civic)
  ) %>% 
  left_join(
    events_lunar %>% 
      pivot_longer(
        cols = starts_with("date_"),
        values_to = "date"
      ) %>% 
      select(date, event_lunar)
  ) %>% 
  mutate(
    wday  = lubridate::wday(date, week_start = 1, abbr = FALSE, label = TRUE),
    month = lubridate::month(date, label = TRUE, abbr = FALSE)
  ) %>% 
  group_by(year) %>% 
  tidyr::fill(season) %>% 
  ungroup() %>% 
  mutate(
    season = case_when(
      is.na(season) ~ "winter",
      TRUE ~ season
    )
  )

# Clean up temporary objects
rm(events_civic_raw, events_lunar_raw, events_solar_raw, yeg_solar_calendar, ls_object)

# ---- tweak-data-2 ------------------------------------------------------------
# Create solar year dataset (from winter solstice to winter solstice)
ds2a <- 
  tibble(
    date = seq.Date(
      from = as.Date("2024-12-21"),
      to   = as.Date("2025-12-21"),
      by   = "day"
    )
  ) %>% 
  mutate(
    solar_day_num  = row_number(),
    solar_week_num = ceiling(solar_day_num / 7)
  ) %>% 
  full_join(
    ds1 %>% 
      select(
        date, month, wday, season, 
        event_civic, event_lunar, event_solar,
        illumination_day, illumination_total,
        everything()
      )
  ) %>% 
  bind_rows(
    tibble(
      date = seq.Date(
        from = as.Date("2024-12-14"),
        to   = as.Date("2024-12-20"),
        by   = "day"
      )
    ) %>% 
    left_join(ds1)
  ) %>% 
  arrange(date)

# Calculate daily and weekly light gains
ds2b <-
  ds2a %>% 
  mutate(
    day = lubridate::mday(date),
    date = as.Date(date),
    daily_light_gain  = (illumination_total - lag(illumination_total)),
    weekly_light_gain = (illumination_total - lag(illumination_total, 7))
  ) %>% 
  group_by(solar_week_num) %>% 
  mutate(
    solar_week_day_num = row_number()
  ) %>% 
  ungroup() %>% 
  filter(date > as.Date("2024-12-20"))

# Apply smoothing splines to the data
spline_fit_daily  <- smooth.spline(x = as.numeric(ds2b$date), 
                                   y = ds2b$daily_light_gain)
spline_fit_weekly <- smooth.spline(x = as.numeric(ds2b$date), 
                                   y = ds2b$weekly_light_gain)

ds2 <-
  ds2b %>% 
  mutate(
    daily_gain_smooth  = predict(spline_fit_daily, as.numeric(date))$y,
    weekly_gain_smooth = predict(spline_fit_weekly, as.numeric(date))$y
  )

# Get the day of week that solar year 2025 starts on
solar_year_2025_starts_on <- 
  ds2 %>% 
  filter(event_solar == "winter solstice", year == "2024") %>% 
  pull(wday) %>% 
  as.character()

# ---- graph-1-illumination-duration -------------------------------------------
# Graph 1: Daily illumination duration throughout the year
cat("\nGenerating Graph 1: Annual illumination duration...\n")

gbase <-
  ds2 %>% 
  filter(date > as.Date("2024-06-20")) %>% 
  ggplot(aes(x = date)) +
  scale_x_date(
    date_breaks = "1 week",
    date_labels = "%d\n%b"
  ) +
  geom_text(
    aes(label = event_solar %>% str_replace(" ", "\n"), y = Inf),
    vjust = -0.2,
    lineheight = 0.7
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.05, 0.05)),
    breaks = scales::pretty_breaks()
  ) +
  labs(
    title = "Duration of Light Day in Edmonton (YEG)",
    subtitle = "Showing daily illumination and total illumination (including twilight)",
    x = paste("Solar Year 2025 starts on", solar_year_2025_starts_on),
    y = "Hours"
  )

g1 <- gbase +
  geom_line(aes(y = illumination_total), color = "steelblue", linewidth = 1) +
  geom_line(aes(y = illumination_day), color = "orange", linewidth = 0.8) +
  geom_point(
    aes(y = illumination_total), 
    data = . %>% filter(!is.na(event_solar)),
    color = "red", size = 3
  ) +
  annotate(
    "text", x = as.Date("2025-02-01"), y = 17,
    label = "Total illumination\n(including twilight)",
    color = "steelblue", hjust = 0
  ) +
  annotate(
    "text", x = as.Date("2025-02-01"), y = 15,
    label = "Daylight only",
    color = "orange", hjust = 0
  )

g1
g1 %>% quick_save("1-annual-illumination-duration", w = 14, h = 7)

# ---- graph-2-daily-change ----------------------------------------------------
# Graph 2: Day-to-day change in daylight duration
cat("Generating Graph 2: Day-to-day change in daylight...\n")

g2 <- 
  ds2 %>% 
  filter(date > as.Date("2024-06-20")) %>% 
  ggplot(aes(x = date)) +
  scale_x_date(
    date_breaks = "1 week",
    date_labels = "%d\n%b"
  ) +
  geom_text(
    aes(label = event_solar %>% str_replace(" ", "\n"), y = Inf),
    vjust = -0.2,
    lineheight = 0.7
  ) +
  geom_line(aes(y = daily_gain_smooth * 60), color = "red", linewidth = 1.2) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  scale_y_continuous(
    expand = expansion(mult = c(0.05, 0.05)),
    breaks = scales::pretty_breaks()
  ) +
  labs(
    title = "Daily Change in Illumination Duration",
    subtitle = "How many minutes of daylight are gained or lost each day",
    x = paste("Solar Year 2025 starts on", solar_year_2025_starts_on),
    y = "Minutes gained/lost per day"
  )

g2
g2 %>% quick_save("2-daily-change-in-daylight", w = 14, h = 7)

# ---- graph-3-weekly-change ---------------------------------------------------
# Graph 3: Week-to-week change in daylight duration (by season)
cat("Generating Graph 3: Week-to-week change in daylight...\n")

g3 <- 
  ds2 %>% 
  filter(date > as.Date("2024-06-20")) %>% 
  ggplot(aes(x = date)) +
  scale_x_date(
    date_breaks = "1 week",
    date_labels = "%d\n%b"
  ) +
  geom_text(
    aes(label = event_solar %>% str_replace(" ", "\n"), y = Inf),
    vjust = -0.2,
    lineheight = 0.7
  ) +
  geom_line(
    aes(y = weekly_gain_smooth * 60, color = season),
    linewidth = 4, alpha = 0.7,
    data = . %>% filter(date < as.Date("2025-12-20"))
  ) +
  geom_line(
    aes(y = weekly_light_gain * 60),
    color = "black", linewidth = 0.5, alpha = 0.5
  ) +
  geom_point(
    aes(y = weekly_gain_smooth * 60),
    shape = 16, alpha = 0.6, size = 5,
    data = . %>% filter(!is.na(event_solar))
  ) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  scale_y_continuous(
    expand = expansion(mult = c(0.05, 0.05)),
    breaks = scales::pretty_breaks()
  ) +
  labs(
    title = "Weekly Change in Illumination Duration",
    subtitle = "How many minutes of daylight are gained or lost each week (by season)",
    x = paste("Solar Year 2025 starts on", solar_year_2025_starts_on),
    y = "Minutes gained/lost per week",
    color = "Season"
  )

g3
g3 %>% quick_save("3-weekly-change-in-daylight", w = 14, h = 7)

# ---- graph-4-seasonal-comparison ---------------------------------------------
# Graph 4: Comparing illumination across seasons
cat("Generating Graph 4: Seasonal comparison...\n")

g4 <- 
  ds2 %>% 
  filter(!is.na(season)) %>% 
  ggplot(aes(x = solar_day_num, y = illumination_total, color = season)) +
  geom_line(linewidth = 1.2) +
  geom_point(
    data = . %>% filter(!is.na(event_solar)),
    size = 4, shape = 21, fill = "white", stroke = 2
  ) +
  geom_text(
    aes(label = event),
    data = . %>% filter(!is.na(event_solar)),
    vjust = -1, hjust = 0.5, size = 3
  ) +
  scale_x_continuous(breaks = seq(0, 365, 30)) +
  scale_y_continuous(
    breaks = seq(8, 18, 2),
    minor_breaks = seq(8, 18, 1)
  ) +
  labs(
    title = "Edmonton's Annual Solar Cycle",
    subtitle = "Total illumination (daylight + twilight) by day of solar year",
    x = "Day of Solar Year (starting from Winter Solstice 2024)",
    y = "Hours of Illumination",
    color = "Season"
  ) +
  theme(
    legend.position = "bottom"
  )

g4
g4 %>% quick_save("4-seasonal-comparison", w = 12, h = 7)

# ---- graph-5-sunrise-sunset-times --------------------------------------------
# Graph 5: Sunrise and sunset times throughout the year
cat("Generating Graph 5: Sunrise and sunset times...\n")

# Convert times to decimal hours for plotting
ds_times <- 
  ds2 %>% 
  filter(!is.na(sunrise)) %>% 
  mutate(
    sunrise_decimal = as.numeric(sunrise) / 3600,
    sunset_decimal  = as.numeric(sunset) / 3600,
    civil_start_decimal = as.numeric(civil_twilight_start) / 3600,
    civil_end_decimal   = as.numeric(civil_twilight_end) / 3600
  )

g5 <- 
  ds_times %>% 
  ggplot(aes(x = date)) +
  geom_ribbon(
    aes(ymin = civil_start_decimal, ymax = civil_end_decimal),
    fill = "lightblue", alpha = 0.3
  ) +
  geom_ribbon(
    aes(ymin = sunrise_decimal, ymax = sunset_decimal),
    fill = "yellow", alpha = 0.5
  ) +
  geom_line(aes(y = sunrise_decimal), color = "orange", linewidth = 1) +
  geom_line(aes(y = sunset_decimal), color = "darkblue", linewidth = 1) +
  geom_point(
    aes(y = 12),
    data = . %>% filter(!is.na(event_solar)),
    color = "red", size = 3
  ) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b"
  ) +
  scale_y_continuous(
    breaks = seq(0, 24, 2),
    labels = function(x) sprintf("%02d:00", as.integer(x))
  ) +
  labs(
    title = "Sunrise and Sunset Times in Edmonton",
    subtitle = "Yellow area = daylight, Light blue area = civil twilight",
    x = "Month",
    y = "Time of Day"
  ) +
  annotate(
    "text", x = as.Date("2025-01-15"), y = 8,
    label = "Sunrise", color = "orange", hjust = 0
  ) +
  annotate(
    "text", x = as.Date("2025-01-15"), y = 16.5,
    label = "Sunset", color = "darkblue", hjust = 0
  )

g5
g5 %>% quick_save("5-sunrise-sunset-times", w = 14, h = 7)

# ---- graph-6-weekly-illumination-bars ----------------------------------------
# Graph 6: Weekly illumination as vertical bars
cat("Generating Graph 6: Weekly illumination visualization...\n")

# Prepare data for weekly visualization
t1 <-
  ds2 %>%
  filter(!is.na(solar_week_num)) %>% 
  filter(solar_week_day_num == 1L) %>% 
  mutate(
    week_direction = case_when(
      solar_week_num <= 27 ~ "ascending",
      solar_week_num > 27 ~ "descending"
    )
  ) %>% 
  select(
    date, solar_week_num, illumination_total, weekly_light_gain,
    week_direction
  )

t2 <-
  bind_rows(
    t1,
    t1 %>% 
      filter(solar_week_num == 27) %>% 
      mutate(week_direction = "descending")
  ) %>% 
  arrange(date)

scale_factor <- 0.5

g6 <-
  t2 %>%
  ggplot(aes(x = 1, y = illumination_total)) +
  geom_rect(
    aes(
      xmin = 0.5, xmax = 1.5,
      ymin = illumination_total, ymax = lead(illumination_total),
      fill = illumination_total
    )
  ) +
  geom_hline(aes(yintercept = illumination_total), color = "white") +
  geom_point(
    shape = 21, fill = "white", color = "white", size = 7,
    data = . %>% filter(!solar_week_num %in% c(27, 1, 53))
  ) +
  geom_text(
    aes(label = solar_week_num),
    data = . %>% filter(!solar_week_num %in% c(27, 1, 53))
  ) +
  scale_y_continuous(
    breaks = seq(1, 20, 1),
    minor_breaks = seq(1, 20, 0.25),
    expand = expansion(add = c(0, -0.0))
  ) +  
  scale_x_continuous(limits = c(0.4, 1.6)) +
  scale_fill_viridis_c() +
  coord_cartesian(clip = "off") +
  facet_wrap(facets = "week_direction", nrow = 1, scales = "free_x") +
  theme_minimal() +
  labs(
    title = "Solar Week Illumination Progression",
    subtitle = "52 weeks from Winter Solstice to Winter Solstice",
    y = "Hours of Illumination",
    x = ""
  ) +
  theme(
    axis.text.x = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.position = "none",
    panel.grid.major.y = element_line(color = "black", linewidth = 4),
    panel.grid.minor.y = element_line(color = "black", linewidth = 2)
  )

g6
g6 %>% quick_save("6-solar-weeks-illumination", h = 30 * scale_factor, w = 5 * scale_factor)

# ---- graph-7-quarterly-calendar ----------------------------------------------
# Graph 7: Quarterly tile calendar visualization
cat("Generating Graph 7: Quarterly calendar tiles...\n")

# Create solar calendar skeleton
d1 <- 
  expand.grid(week_num = 1:52, day_num = 1:7) %>%
  as_tibble() %>% 
  arrange(week_num, day_num) %>% 
  mutate(
    solar_day_num = row_number(),
    solar_season = case_when(
      solar_day_num <= 91     ~ "Winter",
      solar_day_num <= 91 * 2 ~ "Spring",
      solar_day_num <= 91 * 3 ~ "Summer",
      solar_day_num <= 91 * 4 ~ "Fall"
    )
  ) %>%
  group_by(solar_season) %>% 
  mutate(
    solar_season_week_num = rep(1:13, 7) %>% sort()
  ) %>% 
  ungroup()

# Solar year data
d2 <- 
  tibble(
    date = seq.Date(
      from = as.Date("2024-12-21"),
      to = as.Date("2025-12-20"),
      by = "day"
    )
  ) %>% 
  mutate(solar_day_num = row_number()) %>% 
  left_join(
    ds1 %>% 
      select(date, month, wday, season, illumination_day, 
             illumination_total, event_solar)
  ) %>% 
  mutate(
    day = lubridate::mday(date),
    date = as.Date(date)
  )

# Combine calendar structure with data
d3 <- d1 %>% left_join(d2)

# Create tile plot
g7 <- 
  d3 %>%
  mutate(
    solar_season = factor(solar_season, levels = c(
      "Winter", "Spring", "Summer", "Fall"
    )),
    solar_season_week_num = factor(solar_season_week_num, levels = 13:1)
  ) %>% 
  filter(solar_day_num <= 13 * 7 * 4) %>% 
  ggplot(aes(y = solar_season_week_num, x = day_num, fill = illumination_day)) +
  geom_tile(color = "white", linewidth = 2) +
  scale_fill_viridis_c(guide = "none") +
  coord_fixed() +
  facet_grid(. ~ solar_season) +
  theme_void() +
  theme(
    panel.background = element_blank(),
    plot.margin = margin(0, 0, 0, 0),
    strip.text = element_text(size = 90)
  )

g7
g7 %>% quick_save("7-quarterly-calendar-tiles", w = (11 * 4), h = 24)

# ---- graph-8-extreme-days ----------------------------------------------------
# Graph 8: Highlighting extreme days (longest, shortest, fastest change)
cat("Generating Graph 8: Extreme days in the solar year...\n")

# Find extreme days
extreme_days <- 
  ds2 %>% 
  filter(!is.na(illumination_total)) %>% 
  summarise(
    longest_day_date = date[which.max(illumination_total)],
    longest_day_hours = max(illumination_total, na.rm = TRUE),
    shortest_day_date = date[which.min(illumination_total)],
    shortest_day_hours = min(illumination_total, na.rm = TRUE),
    fastest_gain_date = date[which.max(daily_gain_smooth)],
    fastest_gain_minutes = max(daily_gain_smooth, na.rm = TRUE) * 60,
    fastest_loss_date = date[which.min(daily_gain_smooth)],
    fastest_loss_minutes = min(daily_gain_smooth, na.rm = TRUE) * 60
  )

g8 <- 
  ds2 %>% 
  filter(!is.na(illumination_total)) %>% 
  ggplot(aes(x = date, y = illumination_total)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(
    data = data.frame(
      date = extreme_days$longest_day_date,
      illumination_total = extreme_days$longest_day_hours
    ),
    color = "gold", size = 6, shape = 16
  ) +
  geom_point(
    data = data.frame(
      date = extreme_days$shortest_day_date,
      illumination_total = extreme_days$shortest_day_hours
    ),
    color = "navy", size = 6, shape = 16
  ) +
  annotate(
    "text",
    x = extreme_days$longest_day_date,
    y = extreme_days$longest_day_hours + 0.5,
    label = sprintf("Longest day:\n%.1f hours", extreme_days$longest_day_hours),
    color = "gold", fontface = "bold"
  ) +
  annotate(
    "text",
    x = extreme_days$shortest_day_date,
    y = extreme_days$shortest_day_hours - 0.5,
    label = sprintf("Shortest day:\n%.1f hours", extreme_days$shortest_day_hours),
    color = "navy", fontface = "bold"
  ) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b"
  ) +
  labs(
    title = "Extreme Days in Edmonton's Solar Year",
    subtitle = sprintf(
      "Variation of %.1f hours from shortest to longest day",
      extreme_days$longest_day_hours - extreme_days$shortest_day_hours
    ),
    x = "Month",
    y = "Hours of Illumination"
  )

g8
g8 %>% quick_save("8-extreme-days", w = 12, h = 7)

# ---- summary-report ----------------------------------------------------------
cat("\n========================================\n")
cat("VISUALIZATION GENERATION COMPLETE\n")
cat("========================================\n\n")
cat("Generated 8 visualization graphs:\n")
cat("1. Annual illumination duration\n")
cat("2. Daily change in daylight\n")
cat("3. Weekly change in daylight (by season)\n")
cat("4. Seasonal comparison of illumination\n")
cat("5. Sunrise and sunset times\n")
cat("6. Solar weeks illumination progression\n")
cat("7. Quarterly calendar tiles\n")
cat("8. Extreme days in the solar year\n\n")

cat("Key findings for Edmonton (53.5°N):\n")
cat(sprintf("- Longest day: %.1f hours on %s\n", 
            extreme_days$longest_day_hours,
            format(extreme_days$longest_day_date, "%B %d")))
cat(sprintf("- Shortest day: %.1f hours on %s\n", 
            extreme_days$shortest_day_hours,
            format(extreme_days$shortest_day_date, "%B %d")))
cat(sprintf("- Total variation: %.1f hours (%.1f%%)\n", 
            extreme_days$longest_day_hours - extreme_days$shortest_day_hours,
            100 * (extreme_days$longest_day_hours - extreme_days$shortest_day_hours) / 
            extreme_days$shortest_day_hours))
cat(sprintf("- Fastest daily gain: %.1f minutes per day around %s\n",
            extreme_days$fastest_gain_minutes,
            format(extreme_days$fastest_gain_date, "%B %d")))
cat(sprintf("- Fastest daily loss: %.1f minutes per day around %s\n",
            abs(extreme_days$fastest_loss_minutes),
            format(extreme_days$fastest_loss_date, "%B %d")))

cat("\nAll graphs saved to:", prints_folder, "\n")
cat("========================================\n")
