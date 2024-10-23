#' ---
#' title: "0-import"
#' author: "First Last"
#' date: "YYYY-MM-DD"
#' ---
#+ echo=F
# rmarkdown::render(input = "./manipulation/1-ellis.R") # run to knit, don't uncomment
#+ echo=F ----------------------------------------------------------------------
library(knitr)
# align the root with the project working directory
opts_knit$set(root.dir='../')  #Don't combine this call with any
#+ echo=F ----------------------------------------------------------------------
rm(list = ls(all.names = TRUE)) # Clear the memory of variables from previous run.
#This is not called by knitr, because it's above the first chunk.
#+ results="hide",echo=F -------------------------------------------------------
cat("/014") # Clear the console
#+ echo=FALSE, results="show" --------------------------------------------------
cat("Working directory: ", getwd()) # Must be set to Project Directory
#+ echo=F, results="asis" ------------------------------------------------------
cat("\n# 1.Environment")
#+ set_options, echo=F ---------------------------------------------------------
echo_chunks <- TRUE
eval_chunks <- TRUE
cache_chunks <- TRUE
report_render_start_time <- Sys.time()
#+ load-sources ------------------------------------------------------------
base::source("./scripts/common-functions.R") # project-level

#+ load-packages -----------------------------------------------------------
library(tidyverse)

#+ declare-globals ---------------------------------------------------------

#+ declare-functions -------------------------------------------------------
# store script-specific function here

#+ load-data ---------------------------------------------------------------
yeg_sunrise <- read_csv("data-public/raw/yeg-sunrise.csv",
                        col_types = cols(
                          .default = col_time(format = "%H:%M:%S"),
                          Day = col_character() # Replace 'first_column_name' with the actual name of the first column
                        )) 
yeg_sunrise 
yeg_sunset <- read_csv("data-public/raw/yeg-sunset.csv",
                        col_types = cols(
                          .default = col_time(format = "%H:%M:%S"),
                          Day = col_character() # Replace 'first_column_name' with the actual name of the first column
                        )) 
yeg_sunset 

yeg_noon <- read_csv("data-public/raw/yeg-noon.csv",
                        col_types = cols(
                          .default = col_time(format = "%H:%M:%S"),
                          Day = col_character() # Replace 'first_column_name' with the actual name of the first column
                        )) 
yeg_noon 


events_civic <-  read_csv("data-public/raw/events-civic.csv", skip = 1) 
events_sun   <-  read_csv("data-public/raw/events-sun.csv", skip = 0) 
events_moon  <-  read_csv("data-public/raw/events-moon.csv", skip = 0) 

#+ inspect-data ------------------------------------------------------------


#+ tweak-data-0 --------------------------------------------------------------
ds0 <- 
  bind_rows(
    list(
      "sunrise" = yeg_sunrise
      ,"sunset" = yeg_sunset
      ,"noon" = yeg_noon
    )
    ,.id = "event"
  )


events_civic <- 
  events_civic %>% 
  pivot_longer(
    cols = starts_with("date_")
    ,names_to = "year"
    ,values_to = "date"
    ,names_prefix = "date_"
  ) %>% 
  mutate_at(
    .vars = c("holiday","float")
    ,.funs = ~if_else(is.na(.),FALSE,.)
  )
events_civic


events_sun <-
  events_sun%>% 
  pivot_longer(
    cols = starts_with("date_")
    ,names_to = "year"
    ,values_to = "date"
    ,names_prefix = "date_"
  ) %>% 
  mutate(
    year = year %>% as.integer()
  )

events_moon <-
  events_moon%>% 
  pivot_longer(
    cols = starts_with("date_")
    ,names_to = "year"
    ,values_to = "date"
    ,names_prefix = "date_"
  ) %>% 
  mutate(
    year = year %>% as.integer()
  )



#+ tweak-data-1 --------------------------------------------------------------
ds1 <- 
  ds0 %>% 
  pivot_longer(
    cols = all_of(month.abb)
    ,names_to = "month"
    ,values_to = "time"
  ) %>% 
  janitor::clean_names() %>% 
  mutate(
    month = month %>% factor(levels = month.abb)
    ,day = day %>% as.integer()
    # ,day_num = row_number()
    ) %>%
  # relocate(day_num) %>% 
  pivot_wider(
    names_from = "event"
    ,values_from = "time"
  ) %>% 
  arrange(month, day) %>% 
  filter(!is.na(sunrise)) %>% 
  mutate(
    day_num = row_number()
  ) %>% 
  select(day_num, month,day,sunrise, sunset, noon) 

ds1 # 366 days, based on a leap year

# ds1 %>% readr::write_csv('./data-public/derived/yeg-calendar.csv')
#+ tweak-data-1 --------------------------------------------------------------

ds2_24 <- 
  ds1 %>% 
  mutate(date = as.Date("2024-01-01") + row_number() - 1) 
ds2_25 <- 
  ds1 %>% 
  filter(!(month=="Feb" & day=="29")) %>% # not a leap year
  mutate(date = as.Date("2025-01-01") + row_number() - 1) 

ds2 <- 
  bind_rows(
    list(
      "2024" = ds2_24
      ,"2025" = ds2_25
    )
    ,.id = "year"
  ) %>% 
  mutate(
    year = year %>% as.integer()
  ) %>% 
  left_join(
    events_civic %>% select(event_civic, holiday, date)
    , by = "date"
  ) %>% 
  left_join(events_sun) %>% 
  left_join(events_moon) %>%  
  mutate(
    wday = lubridate::wday(date, label = T, abbr= F)
    ,day_off = case_when(
      wday %in% c("Saturday","Sunday") ~ TRUE
      ,holiday ~ TRUE
      ,(month=="Dec") & (day %in% c(24:31)) ~ TRUE
      ,TRUE ~ FALSE
    )
    ,week_num = lubridate::isoweek(date)
    ,daily_light_minutes = difftime(sunset,sunrise,units = "min") %>% as.numeric()
    ,daily_light_gain = daily_light_minutes- lag(daily_light_minutes) %>% as.numeric()
  )
ds2
ds2 %>% glimpse()
ds2 %>% select()


#+ daily-values -----------------------------------------------------------------
# d1 <- 
#   ds2 %>% 
#   pivot_longer(c("daily_light_minutes", "daily_light_gain"),names_to = "measure",values_to = "value") 
# d1 %>% glimpse()
ds2 %>% glimpse()
gbase <-
  ds2 %>% 
  filter(date > as.Date("2024-12-15")) %>%
  filter(date > as.Date("2025-12-31")) %>%
  # filter(year == 2025) %>% 
  ggplot(aes(x=date, y = daily_light_minutes %>% as.numeric()))+
  geom_line()+
  scale_x_date(
    date_breaks = "2 weeks",          # Breaks every month
    date_labels = "%d\n%b"             # Display as abbreviated month and year (e.g., Jan 2025)
  )+
  geom_text(
    aes(label = event_sun %>% str_replace(" ", "\n"), y = Inf)
    ,vjust=-.2
    ,lineheight = .7
  )+
  scale_y_continuous(expand = expansion(mult = c(.05,0.05)))+
  labs(
    title = "Duration of light day in YEG"
    ,x = "Monday"
    ,y = "Minutes"
  )
gbase
g1 <- gbase %+%
  geom_line(linewidth=1,color="blue") +
  geom_vline(aes(xintercept=date),data=ds2 %>% filter(!is.na(event_sun)))+
  geom_hline(aes(yintercept=720))+
  geom_text(aes(label = "Day = Night", x = as.Date("2025-01-15"), y = 740),
            data = . %>% slice(1))+
  coord_cartesian(clip = "off") 
g1
g2 <- gbase %+%
  aes(y=daily_light_gain) %+% 
  geom_line(color="red", linewidth=1) +
  geom_vline(aes(xintercept=date),data=ds2 %>% filter(!is.na(event_sun)))+
  geom_hline(aes(yintercept=0))+
  labs(
    title = "Change in light day duration since last week"
    ,y = "Minutes"
  )
g2

library(patchwork)
g_weekly <- g1/g2
prints_folder <- "./manipulation/"
g_weekly %>% quick_save("daily",w=16,h=9)
#+ graph-1 -----------------------------------------------------------------

d1 <- 
  ds2 %>% 
  # filter(year == 2025) %>% 
  # filter(date > as.Date("2024-12-01")) %>%
  group_by(year, week_num) %>% 
  summarize(
    mean_duration = daily_light_minutes %>% as.numeric() %>%  mean() 
    ,min_duration = daily_light_minutes %>% as.numeric() %>% min() # on Monday
    ,week_of = date %>% min() # 
    ,.groups = "drop"
  ) %>% 
  ungroup() %>% 
  mutate(
    # light_gain = mean_duration- lag(mean_duration)
    light_gain = min_duration- lag(min_duration)
  ) 
d1 %>% glimpse()

gbase <-
  d1 %>% 
  filter(week_of > as.Date("2024-12-15")) %>% 
  ggplot(aes(x=week_of, y = min_duration))+
  geom_line()+
  scale_x_date(
    date_breaks = "2 weeks",          # Breaks every month
    date_labels = "%d\n%b"             # Display as abbreviated month and year (e.g., Jan 2025)
  )+
  labs(
    title = "Duration of light day in YEG"
    ,x = "The week of Monday, ..."
    ,y = "Minutes"
  )
gbase
g1 <- gbase %+%
  geom_line(linewidth=1,color="blue") +
  geom_vline(aes(xintercept=date),data=ds2 %>% filter(!is.na(event_sun)))+
  geom_hline(aes(yintercept=720))+
  geom_text(aes(label = "Day = Night", x = as.Date("2025-01-15"), y = 740),
            data = . %>% slice(1))+
  annotate("text", label = "Equinox", x = as.Date("2025-03-17"), y = 960, hjust = -0.1) +
  coord_cartesian(clip = "off")   # This allows annotations to be outside the plot area
g1
g2 <- gbase %+%
  aes(y=light_gain) %+% 
  geom_line(color="red", linewidth=1) +
  geom_vline(aes(xintercept=date),data=ds2 %>% filter(!is.na(event_sun)))+
  geom_hline(aes(yintercept=0))+
  labs(
    title = "Change in light day duration since last week"
    ,y = "Minutes"
  )
g2

library(patchwork)
g_weekly <- g1/g2
prints_folder <- "./manipulation/"
g_weekly %>% quick_save("weekly",w=12,h=8)
#+ graph-2 -----------------------------------------------------------------

d1 <- 
  ds2 %>% 
  # filter(year == 2025) %>% 
  # filter(date > as.Date("2024-12-01")) %>%
  group_by(year, week_num) %>% 
  summarize(
    mean_duration = daily_light_minutes %>% as.numeric() %>%  mean() 
    ,min_duration = daily_light_minutes %>% as.numeric() %>% min() # on Monday
    ,week_of = date %>% min() # 
    ,.groups = "drop"
  ) %>% 
  ungroup() %>% 
  mutate(
    # light_gain = mean_duration- lag(mean_duration)
    light_gain = min_duration- lag(min_duration)
  ) 
d1 %>% glimpse()

gbase <-
  d1 %>% 
  filter(week_of > as.Date("2024-06-15")) %>% 
  filter(week_of < as.Date("2025-06-27")) %>% 
  ggplot(aes(x=week_of, y = min_duration))+
  geom_line()+ 
  scale_x_date(
    date_breaks = "2 weeks",          # Breaks every month
    date_labels = "%d\n%b"             # Display as abbreviated month and year (e.g., Jan 2025)
  )+
  labs(
    title = "Duration of light day in YEG"
    ,x = "The week of Monday, ..."
    ,y = "Minutes"
  )
gbase
g1 <- gbase %+%
  geom_line(linewidth=1,color="blue") +
  geom_vline(aes(xintercept=date),data=ds2 %>% filter(!is.na(event_sun)))+
  geom_hline(aes(yintercept=720))+
  geom_text(aes(label = "Day = Night", x = as.Date("2024-06-23"), y = 735),
            data = . %>% slice(1), hjust = -0)+
  scale_y_continuous(expand = expansion(mult = c(.05,0.05)))+
  annotate("text", label = "Equinox", x = as.Date("2024-09-22"),  y = 920, hjust = .5, vjust=-2) +
  annotate("text", label = "Equinox", x = as.Date("2025-03-20"),  y = 920, hjust = .5, vjust=-2) +
  annotate("text", label = "Solstice", x = as.Date("2024-12-22"), y = 920, hjust = .5, vjust=-2) +
  annotate("text", label = "Solstice", x = as.Date("2025-06-22"), y = 920, hjust = .5, vjust=-2) +
  coord_cartesian(clip = "off")   # This allows annotations to be outside the plot are3
g1
g2 <- gbase %+%
  aes(y=light_gain) %+% 
  geom_line(color="red", linewidth=1) +
  geom_vline(aes(xintercept=date),data=ds2 %>% filter(!is.na(event_sun)))+
  geom_hline(aes(yintercept=0))+
  labs(
    title = "Speed of Time - Change in light day duration since last week"
    ,y = "Minutes"
  )
g2

library(patchwork)
g_weekly <- g1/g2
prints_folder <- "./manipulation/"
g_weekly %>% quick_save("weekly2",w=12,h=8)
#+ graph-2 -----------------------------------------------------------------

#+ save-to-disk ------------------------------------------------------------
# naming convention: step_id - step_name - cohort_id
dto %>% readr::write_rds("./data-private/derived/0-import.rds",compress = "xz")

#+ results="asis", echo=echo_chunks
cat("\n# A. Session Information{#session-info}")
#' For the sake of documentation and reproducibility, the current report was rendered in the following environment.
if( requireNamespace("devtools", quietly = TRUE) ) {
  devtools::session_info()
} else {
  sessionInfo()
}
report_render_duration_in_seconds <- scales::comma(as.numeric(difftime(Sys.time(), report_render_start_time, units="secs")),accuracy=1)
report_render_duration_in_minutes <- scales::comma(as.numeric(difftime(Sys.time(), report_render_start_time, units="mins")),accuracy=1)
#' Report rendered by `r Sys.info()["user"]` at `r strftime(Sys.time(), "%Y-%m-%d, %H:%M %z")` in `r report_render_duration_in_seconds` seconds ( or `r report_render_duration_in_minutes` minutes)


