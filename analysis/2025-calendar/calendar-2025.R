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



# ---- tweak-data-raw ------------------------------------------------------------

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
                        ,"december" ~ "winter"
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

# ---- tweak-data-0 ------------------------------------------------------------
ds0 <- 
  yeg_solar_calendar %>% 
  janitor::clean_names() %>% 
  mutate(
    date = str_c(year, date, sep = " "),     # Combine 'year' and 'date' into a single string
    date = parse_date_time(date, orders = "Y b d")  # Parse the date into "YYYY-MM-DD" format
  ) %>% 
  arrange(date) 
# rm(yeg_solar_calendar)
ds0 %>% glimpse()

rm(
  events_civic_raw
  , events_lunar_raw
  , events_solar_raw
  , yeg_solar_calendar
  , ls_object
)

# ---- tweak-data-1 ------------------------------------------------------------



ds1 <-
  ds0 %>% 
  left_join(
    events_solar %>% 
      mutate(solar_event = paste0(season," ",event)) %>% 
      select(date, season, solar_event)
                              
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
# ds1 %>% filter(date>as.Date("2024-12-18")) 
# ds1 %>% filter(date>as.Date("2024-06-25")) %>% glimpse()
# ds1  %>% filter(date>as.Date("2024-03-18")) %>% select(date,season, day_solar_season_num,solar_event)
# ds1 %>% group_by(year, season) %>% summarize(day_count = n_distinct(day_solar_season_num))

# ds1 %>% distinct(year,solar_event)
# ds1 %>% select(date, wday, wday_month_num)
ds1 %>% glimpse()


rm(events_civic_raw, events_lunar_raw, events_solar_raw, yeg_solar_calendar, ls_object)

# ---- inspect-data-2 ----------------------------------------------------------

# ---- table-1 -----------------------------------------------------------------

# ---- graph-1 -----------------------------------------------------------------
# ds1 %>% filter(date>as.Date("2024-12-18")) %>% select(date, solar_event,day_solar_season_num)

# Tile graph for the cabinets
# Step 1: Create the data (d1)
d1 <- 
  expand.grid(week_num = 1:52,day_num = 1:7) %>%
 as_tibble() %>% 
 arrange(week_num, day_num) %>% 
  mutate(
     solar_day_num = row_number()
    ,solar_season = case_when(
      solar_day_num <= 91 ~ "winter"
      ,solar_day_num <= 91*2 ~ "spring"
      ,solar_day_num <= 91*3 ~ "summer"
      ,solar_day_num <= 91*4 ~ "fall"
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
      select(date,month,wday,season, illumination_day, illumination_total, solar_event)
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
      "winter","spring","summer","fall"
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
