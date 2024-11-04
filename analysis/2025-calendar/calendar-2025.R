rm(list = ls(all.names = TRUE)) # Clear the memory of variables from previous run. This is not called by knitr, because it's above the first chunk.
cat("\014") # Clear the console
# verify root location
cat("Working directory: ", getwd()) # Must be set to Project Directory
# Project Directory should be the root by default unless overwritten

# ---- load-packages -----------------------------------------------------------
# Choose to be greedy: load only what's needed
# Three ways, from least (1) to most(3) greedy:
# -- 1.Attach these packages so their functions don't need to be qualified: http://r-pkgs.had.co.nz/namespace.html#search-path
library(ggplot2)   # graphs
library(forcats)   # factors
library(stringr)   # strings
library(lubridate) # dates
library(labelled)  # labels
library(scales)    # format
library(dplyr)     # loading dplyr explicitly is my guilty pleasure
library(broom)     # for model
library(emmeans)   # for interpreting model results
library(magrittr)
library(tidyr)
library(purrr)
# -- 2.Import only certain functions of a package into the search path.
import::from("magrittr", "%>%")
# -- 3. Verify these packages are available on the machine, but their functions need to be qualified: http://r-pkgs.had.co.nz/namespace.html#search-path
requireNamespace("readr"    )# data import/export
requireNamespace("readxl"   )# data import/export
requireNamespace("tidyr"    )# tidy data
requireNamespace("janitor"  )# tidy data
requireNamespace("dplyr"    )# Avoid attaching dplyr, b/c its function names conflict with a lot of packages (esp base, stats, and plyr).
requireNamespace("testit"   )# For asserting conditions meet expected patterns.

# ---- load-sources ------------------------------------------------------------
base::source("./scripts/common-functions.R") # project-level

# ---- declare-globals ---------------------------------------------------------
# printed figures will go here:
prints_folder <- paste0("./analysis/2025-calendar/prints/")
if(!file.exists(prints_folder)){dir.create(file.path(prints_folder))}

# ---- declare-functions -------------------------------------------------------


# ---- load-data ---------------------------------------------------------------

library(readr)

ls_object <- list()
for(i in c("2024","2025","2026")){
  
  ls_object[[i]] <- readr::read_csv(
    # "data-public/raw/sunrise_sunset_2024_edmonton.csv"
    paste0("data-public/raw/sunrise_sunset_",i,"_edmonton.csv")
    , col_types = cols(
      `Civil Twilight Start` = col_time(format = "%H:%M")
      , Sunrise              = col_time(format = "%H:%M")
      , `Local Noon`         = col_time(format = "%H:%M")
      , Sunset               = col_time(format = "%H:%M")
      , `Civil Twilight End` = col_time(format = "%H:%M")
    )
  )
}
yeg_solar_calendar <- 
  bind_rows(ls_object, .id = "year") 
  

events_civic_raw <-  read_csv("data-public/raw/events-civic.csv", skip = 1) 
events_solar_raw <-  read_csv("data-public/raw/events-solar.csv", skip = 1) 
events_lunar_raw <-  read_csv("data-public/raw/events-lunar.csv", skip = 1 ) 
# ---- inspect-data-0 ------------------------------------------------------------

# ---- inspect-data-local -----------------------------------------------------
# this chunk is not sourced by the annotation layer, use a scratch pad

# ---- tweak-data-0 ------------------------------------------------------------
ds0 <- 
  yeg_solar_calendar %>% 
  janitor::clean_names() %>% 
  mutate(
    date = str_c(year, date, sep = " "),     # Combine 'year' and 'date' into a single string
    date = parse_date_time(date, orders = "Y b d")  # Parse the date into "YYYY-MM-DD" format
  ) %>% 
  arrange(date) 

ds0 %>% glimpse()

events_solar <-
  events_solar_raw %>% 
  janitor::clean_names() %>% 
  pivot_longer(
    cols = setdiff(names(.),"year")
  ) %>% 
  mutate(
    measure = (name %>% str_split(pattern = "_",simplify = T))[,3]
    ,season = (name %>% str_split(pattern = "_",simplify = T))[,1] 
    ,event  = (name %>% str_split(pattern = "_",simplify = T))[,2]
  ) %>%
  mutate(
    season = case_match(season,
      "march" ~ "spring"
      ,"september" ~ "fall"
      ,"december" ~ "finter"
      ,"june" ~ "summer"
    ) 
  ) %>% 
  select(-name) %>% 
  pivot_wider(
    id_cols = c("year","season","event")
    ,names_from = "measure"
    ,values_from = "value"

  ) %>% 
  rename(
    day = date
  ) %>% 
  mutate(
    date = str_c(year,"-",str_replace(day," ","-")) %>% parse_date_time(orders = "Y-B-d")
    # ,time2 = str_c(year,"-",str_replace(day," ","-")) %>% parse_date_time(orders = " a z")
    ,time2 = map_chr(str_split(time, " "), ~ .[1]) %>% parse_time()  # Extract the first part of `time` string
    ,timezone_abb = map_chr(str_split(time, " "), ~ .[3])
    ,timezone_full = case_match(
      timezone_abb,
      "MST" ~ "America/Denver",
      "MDT" ~ "America/Denver"
    )
    ,date_time = as.POSIXct(paste(date, time2), format="%Y-%m-%d %H:%M:%S")  # Cobine date and parsed time
  ) %>% 
  mutate(
    time = time2
  ) %>% 
  select(-time2)
events_solar %>% glimpse()


# https://www.alberta.ca/time-change-directive#:~:text=The%20change%20from%20Standard%20time,be%20effected%20for%20this%20period.
# The change from Standard time to Daylight Saving time will be effective 2:00 am
# the morning of the second Sunday in March each year. Although employees working
# a shift through 2:00 am on that morning will be working one hour less than their
# normal shift, no adjustment in pay shall be effected for this period. 

events_civic <-
  events_civic_raw 

events_lunar <-
  events_lunar_raw
# ---- tweak-data-1 ------------------------------------------------------------
ds1 <-
  ds0 %>% 
  left_join(
    events_solar %>% 
      mutate(event_solar = paste0(season," ",event)) %>% 
      select(date, season, event_solar)
    
    ,by = "date"
  ) %>%
  left_join(
    events_civic %>% 
      pivot_longer(
        cols = starts_with("date_")
        ,values_to = "date"
      ) %>% 
      select(date, event_civic)
    
  ) %>% 
  left_join(
    events_lunar %>% 
      pivot_longer(
        cols = starts_with("date_")
        ,values_to = "date"
      ) %>% 
      select(date, event_lunar)
  ) %>% 
  mutate(
    wday = lubridate::wday(date,week_start = 1,abbr = F, label = TRUE)
    ,month = lubridate::month(date, label = T, abbr = F)
  ) %>% 
  group_by(year) %>% 
  tidyr::fill(season) %>% 
  ungroup() %>% 
  mutate(
    season = case_when(
      is.na(season)~ "winter"
      ,TRUE ~ season)
  )  
rm(events_civic_raw, events_lunar_raw, events_solar_raw, yeg_solar_calendar, ls_object)
ds1 %>% glimpse()
# ---- tweak-data-2 ------------------------------------------------------------
events_solar %>% filter(year %in% c("2024","2025"),
                        season == "Winter",event == "solstice")
# solar year skeleton
ds2a <- 
  tibble(
    date = seq.Date(
      from = as.Date("2024-12-21")
      , to = as.Date("2025-12-21")
      , by = "day"
    )
  ) %>% 
  mutate(
    solar_day_num = row_number(),
    solar_week_num = ceiling(solar_day_num / 7)
  ) %>% 
  # left_join(
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
        from = as.Date("2024-12-14")
        , to = as.Date("2024-12-20")
        , by = "day"
      ) 
    ) %>% 
        left_join(ds1 )
  ) %>% 
  arrange(date)
ds2a %>% glimpse()

ds2a %>%
  select(date, illumination_total,
       # weekly_light_dur,
       # daily_light_gain, weekly_light_gain
       )

ds2b <-
  ds2a %>% 
  mutate(
    day = lubridate::mday(date)
    ,date = as.Date(date)
    ,daily_light_gain = (illumination_total - lag(illumination_total))
    ,weekly_light_gain = (illumination_total - lag(illumination_total,7))
  ) %>% 
  group_by(solar_week_num) %>% 
  mutate(
    # weekly_light_dur = min(illumination_total) 
    solar_week_day_num = row_number()
 ) %>% 
  ungroup() %>% 
  filter(
    date > as.Date("2024-12-20")
  )

spline_fit_daily <- smooth.spline(x = as.numeric(ds2b$date), y = ds2b$daily_light_gain)
spline_fit_weekly <- smooth.spline(x = as.numeric(ds2b$date), y = ds2b$weekly_light_gain)
ds2 <-
  ds2b %>% 
  mutate(
    daily_gain_smooth = predict(spline_fit_daily, as.numeric(date))$y  # Smoothing spline predictions
    ,weekly_gain_smooth = predict(spline_fit_weekly, as.numeric(date))$y  # Smoothing spline predictions
    
  )

ds2 %>% glimpse()
ds2%>% 
  select(date
         # ,event_solar
         ,season
         , solar_week_day_num
         # , illumination_total
         # , daily_light_gain
         # , weekly_light_gain
        ) %>% 
  # View()
  tail(15)
ds2$date %>% summary()

ds2 %>% glimpse()
ds2 %>% select(1:6) %>% tail()

solar_year_2025_starts_on <- 
  ds2 %>% 
  filter(event_solar == "winter solstice", year == "2024") %>% 
  pull(wday) %>% as.character()


# ---- inspect-data-2 ----------------------------------------------------------

# ---- graph-1 -----------------------------------------------------------------

gbase <-
  ds2 %>% 
  filter(date > as.Date("2024-06-20")) %>% 
  ggplot(aes(x=date))+
  scale_x_date(
    # limits = c(as.Date("2024-12-21"), NA),  # Start at Dec 21, 2024
    date_breaks = "1 weeks",                # Breaks every two weeks
    date_labels = "%d\n%b"                  # Display day and abbreviated month
  ) +
  geom_text(
    aes(label = event_solar %>% str_replace(" ", "\n"), y = Inf)
    ,vjust=-.2
    ,lineheight = .7
  )+
  scale_y_continuous(
    expand = expansion(mult = c(.05,0.05))
    ,breaks = scales::pretty_breaks()
  )+
  labs(
    title = "Duration of light day in YEG"
    ,x = solar_year_2025_starts_on
    ,y = "Hours"
  )
gbase

g1 <- gbase +
  geom_line(aes(y = illumination_total))+
  geom_line(aes(y = illumination_day))+
  geom_point(aes(y=illumination_total), data = . %>% filter(!is.na(event_solar)))
g1

g2 <- gbase %+%
  # geom_line(aes(y=daily_light_gain*60), color = "red") %+% 
  geom_line(aes(y=daily_gain_smooth*60), color = "red") %+% 
  labs(
    title = "Change in light day duration since last day"
    ,y = "Minutes"
  )
g2
g2 %>% quick_save("change-since-yesterday",w=14,h=6.5)
g3 <- gbase +
  geom_line(
    aes(y=weekly_gain_smooth*60, color = season)
    , linewidth=4, alpha = .7
    , data = . %>% filter(date < as.Date("2025-12-20"))
  ) +
  geom_line(
    aes(y=weekly_light_gain*60)
    , color = "black",linewidth=.5, alpha = .5
  ) +
  geom_point(
    aes(y=weekly_gain_smooth*60)
    ,shape = 16, alpha = .6, size = 5
    , data = . %>% filter(!is.na(event_solar))
  )+
  labs(
    title = "Change in light day duration since last week"
    ,y = "Minutes"
  )
g3
# g3 %>% quick_save("week change each week", w =16, h=6)
g3 %>% quick_save("change-since-last-week", w =14, h=6.5)
ds2 %>% glimpse()
# ---- table-1 -----------------------------------------------------------------

t1 <-
  ds2 %>%
  filter(!is.na(solar_week_num)) %>% 
  filter(solar_week_day_num==1L) %>% 
  mutate(
    week_direction = case_when(
      solar_week_num <= 27 ~ "ascending"
      ,solar_week_num > 27 ~ "descending"
    )
  )  # filter(solar_week_day_num==1L) %>% 
  select(
    date, solar_week_num, illumination_total, weekly_light_gain,
    week_direction
  )
t2 <-
  bind_rows(
    t1
    ,t1 %>% 
      filter(solar_week_num == 27) %>% 
      mutate(
        week_direction = "descending"
      )
  ) %>% 
  arrange(date)
t2  %>% print_all()
ds2 %>% glimpse()

scale_factor <- .5
g2 <-
  t2 %>%
  # filter(solar_week_num < 27) %>% 
  ggplot(aes(x=1, y = illumination_total))+
  # geom_line()+
  geom_rect(aes(
    xmin = .5, xmax = 1.5
    , ymin = illumination_total, ymax = lead(illumination_total)
    ,fill = illumination_total
    )
  )+
  geom_hline(aes(yintercept = illumination_total), color = "white")+
  # geom_point(aes(x=date, y = illumination_total))+
  geom_point(
    aes(
      # x = if_else(week_direction == "ascending", as.Date("2025-06-01"), as.Date("2025-07-01"))  # Right-align in left facet, left-align in right facet
      # x = if_else(week_direction == "ascending", as.Date(-Inf), as.Date(Inf))  # Right-align in left facet, left-align in right facet
      # x = as.Date(Inf)
    )
    ,shape = 21, fill = "white", color = "white", size = 7
    ,data = . %>% filter(!solar_week_num %in% c(27,1, 53))
  ) +
  geom_text(
    aes(
      label = solar_week_num,
      # x = if_else(week_direction == "ascending", as.Date(-Inf), as.Date(Inf))   # Right-align in left facet, left-align in right facet
      # x = as.Date(Inf)
    )
    ,data = . %>% filter(!solar_week_num %in% c(27,1, 53))
  ) +
  scale_y_continuous(
    breaks = seq(1,20,1)
    ,minor_breaks = seq(1,20,.25)
    # ,limits = c(8.5, 19)
    ,expand = expansion(add = c(0,-.0))
    # ,minor_breaks = seq(1,20,1/)
  ) +  
  scale_x_continuous(
    limits = c(.4, 1.6)
  )+
  # scale_x_date(
  #   limits = c(min(t2$date), max(t2$date) + 15),  # Adds padding to the right
  #   expand = expansion(mult = c(0, 0.1))  # Additional space on the right side
  # ) +
  # scale_fill_binned(type = "viridis")+
  # scale_fill_binned(type = "gradient")+
  scale_fill_viridis_c()+
  coord_cartesian(clip = "off")+
  facet_wrap(facets = "week_direction",nrow=1,scales = "free_x")+
  # theme_void()
  theme_minimal()+
  labs(
    y = "Hours of illumination"
    ,x = ""
  )+
  theme(
    axis.text.x = element_blank()
    ,panel.grid.major.x = element_blank()
    ,panel.grid.minor.x = element_blank()
    ,legend.position = "none"
    ,panel.grid.major.y = element_line(color = "black", size=4)
    ,panel.grid.minor.y = element_line(color = "black", size=2)
  )
g2

# Combine main plot and legend
# final_plot <- plot_grid(main_plot, legend_plot, ncol = 1, rel_heights = c(1, 0.1))

g2 %>% quick_save("solar_weeks",h=30*scale_factor,w=5*scale_factor)
# g2 %>% quick_save("solar_weeks",h=30*scale_factor,w=11.75*scale_factor)

# ---- graph-1 -----------------------------------------------------------------
# ds1 %>% filter(date>as.Date("2024-12-18")) %>% select(date, event_solar,day_solar_season_num)

# Tile graph for the cabinets
# Step 1: Create the data (d1)
d1 <- 
  expand.grid(week_num = 1:52,day_num = 1:7) %>%
 as_tibble() %>% 
 arrange(week_num, day_num) %>% 
  mutate(
     solar_day_num = row_number()
    ,solar_season = case_when(
      solar_day_num <= 91 ~ "Winter"
      ,solar_day_num <= 91*2 ~ "Spring"
      ,solar_day_num <= 91*3 ~ "Summer"
      ,solar_day_num <= 91*4 ~ "Fall"
    )
  ) %>%
  group_by(solar_season) %>% 
  mutate(
  solar_season_week_num = rep(1:13,7) %>% sort()
  ) %>% 
  ungroup()

d1
# solar year skeleton
d2 <- tibble(
  date = seq.Date(from = as.Date("2024-12-21"), to = as.Date("2025-12-20"), by = "day")
) %>% 
  mutate(
    solar_day_num = row_number()
  ) %>% 
  left_join(
    ds1 %>% 
      select(date,month,wday,season, illumination_day, illumination_total, event_solar)
  ) %>% 
  mutate(
    day = lubridate::mday(date)
    ,date = as.Date(date)
  )
d2
d3 <-
  d1 %>% 
  left_join(d2)
d3
# Step 2: Create the tile plot (g1)
g1 <- 
  d3 %>%
  mutate(
    solar_season = factor(solar_season, levels = c(
      "Winter","Spring","Summer","Fall"
    ))
    ,solar_season_week_num = factor(solar_season_week_num,levels = 13:1)
  ) %>% 
  filter(solar_day_num <= 13*7*4) %>% 
  ggplot(aes(y = solar_season_week_num, x = day_num, fill = illumination_day)) +
  geom_tile(color = "white", linewidth = 2) +               # Add white borders for clarity
  scale_fill_viridis_c(guide = "none") +      # Remove legend
  coord_fixed() +                             # Keep tiles as squares
  # facet_wrap("solar_season",ncol=4)+
  facet_grid(.~solar_season)+
  theme_void() +                              # Remove all axes and labels
  theme(
    panel.background = element_blank(),       # No background
    plot.margin = margin(0,0,0,0),          # Minimal padding around plot
    strip.text = element_text(size = 90)  
    )

# Display the plot
g1
g1 %>% quick_save("quarter1",w=(11*4),h=24)
# ---- graph-2 -----------------------------------------------------------------
ds2 %>% 
  ggplot(aes(x=employed,fill=sex)) +
  geom_bar()
# ---- save-to-disk ------------------------------------------------------------

# ---- publish ------------------------------------------------------------
path <- "./analysis/report-example/annotation-layer-Rmarkdown.Rmd"
rmarkdown::render(
  input = path ,
  output_format=c(
    "html_document"
    # "word_document"
    # "pdf_document"
  ),
  clean=TRUE
)
