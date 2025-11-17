# Quick Demo: Edmonton Daylight Visualization
# A simplified script to generate a few key visualizations quickly

rm(list = ls(all.names = TRUE))
cat("\014")

# ---- load-packages -----------------------------------------------------------
library(ggplot2)
library(dplyr)
library(lubridate)
library(readr)

# ---- load-sources ------------------------------------------------------------
source("./scripts/common-functions.R")

# ---- setup -------------------------------------------------------------------
prints_folder <- paste0("./analysis/prints/")
if(!file.exists(prints_folder)){dir.create(file.path(prints_folder))}

cat("Loading Edmonton solar data...\n")

# ---- load-data ---------------------------------------------------------------
# Load 2025 data only for quick demo
solar_2025 <- readr::read_csv(
  "data-public/raw/sunrise_sunset_2025_edmonton.csv",
  col_types = cols(
    `Civil Twilight Start` = col_time(format = "%H:%M"),
    Sunrise                = col_time(format = "%H:%M"),
    `Local Noon`           = col_time(format = "%H:%M"),
    Sunset                 = col_time(format = "%H:%M"),
    `Civil Twilight End`   = col_time(format = "%H:%M")
  )
) %>% 
  janitor::clean_names() %>% 
  mutate(
    date = paste0("2025 ", date),
    date = parse_date_time(date, orders = "Y b d")
  )

# ---- demo-graph-1 ------------------------------------------------------------
cat("Creating Graph 1: Annual Daylight Pattern...\n")

g1 <- 
  solar_2025 %>% 
  ggplot(aes(x = date, y = illumination_total)) +
  geom_line(color = "steelblue", linewidth = 1.5) +
  geom_smooth(se = FALSE, color = "orange", linetype = "dashed") +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  labs(
    title = "Edmonton's Annual Daylight Pattern (2025)",
    subtitle = "Total daily illumination (daylight + civil twilight)",
    x = "Month",
    y = "Hours of Illumination",
    caption = "Data source: NOAA Solar Calculator"
  ) +
  theme_minimal(base_size = 12)

g1
g1 %>% quick_save("demo-annual-pattern", w = 10, h = 6)

# ---- demo-graph-2 ------------------------------------------------------------
cat("Creating Graph 2: Monthly Daylight Summary...\n")

monthly_summary <- 
  solar_2025 %>% 
  mutate(month = month(date, label = TRUE, abbr = FALSE)) %>% 
  group_by(month) %>% 
  summarise(
    avg_illumination = mean(illumination_total),
    min_illumination = min(illumination_total),
    max_illumination = max(illumination_total)
  )

g2 <- 
  monthly_summary %>% 
  ggplot(aes(x = month, y = avg_illumination)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  geom_errorbar(
    aes(ymin = min_illumination, ymax = max_illumination),
    width = 0.2
  ) +
  geom_hline(yintercept = 12, linetype = "dashed", color = "red") +
  labs(
    title = "Monthly Average Daylight in Edmonton",
    subtitle = "Error bars show range within each month",
    x = "Month",
    y = "Hours of Illumination",
    caption = "Red line indicates 12 hours (equinox)"
  ) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

g2
g2 %>% quick_save("demo-monthly-summary", w = 10, h = 6)

# ---- demo-graph-3 ------------------------------------------------------------
cat("Creating Graph 3: Day Length by Season...\n")

seasonal_data <- 
  solar_2025 %>% 
  mutate(
    season = case_when(
      month(date) %in% c(12, 1, 2) ~ "Winter",
      month(date) %in% c(3, 4, 5) ~ "Spring",
      month(date) %in% c(6, 7, 8) ~ "Summer",
      month(date) %in% c(9, 10, 11) ~ "Fall"
    ),
    season = factor(season, levels = c("Winter", "Spring", "Summer", "Fall"))
  )

g3 <- 
  seasonal_data %>% 
  ggplot(aes(x = season, y = illumination_total, fill = season)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.2, size = 0.5) +
  scale_fill_manual(
    values = c("Winter" = "#3B82F6", "Spring" = "#10B981", 
               "Summer" = "#F59E0B", "Fall" = "#EF4444")
  ) +
  labs(
    title = "Daylight Distribution by Season",
    subtitle = "Each point represents one day",
    x = "Season",
    y = "Hours of Illumination"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

g3
g3 %>% quick_save("demo-seasonal-distribution", w = 10, h = 6)

# ---- summary -----------------------------------------------------------------
cat("\n========================================\n")
cat("DEMO COMPLETE\n")
cat("========================================\n\n")
cat("Generated 3 demonstration graphs:\n")
cat("1. demo-annual-pattern.jpg - Annual daylight curve\n")
cat("2. demo-monthly-summary.jpg - Monthly averages with ranges\n")
cat("3. demo-seasonal-distribution.jpg - Seasonal comparison boxplots\n\n")

# Calculate some interesting statistics
stats <- solar_2025 %>% 
  summarise(
    min_day = min(illumination_total),
    max_day = max(illumination_total),
    avg_year = mean(illumination_total),
    variation = max_day - min_day
  )

cat("Edmonton Daylight Statistics (2025):\n")
cat(sprintf("- Shortest day: %.1f hours\n", stats$min_day))
cat(sprintf("- Longest day: %.1f hours\n", stats$max_day))
cat(sprintf("- Annual average: %.1f hours\n", stats$avg_year))
cat(sprintf("- Total variation: %.1f hours (%.0f%% difference)\n", 
            stats$variation, 100 * stats$variation / stats$min_day))

cat("\nGraphs saved to:", prints_folder, "\n")
cat("\nFor more detailed visualizations, run:\n")
cat("  source('./analysis/visualization-graphs.R')\n")
cat("========================================\n")
