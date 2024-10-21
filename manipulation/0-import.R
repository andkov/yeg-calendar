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
  )
ds2

#+ table-1 -----------------------------------------------------------------


#+ graph-1 -----------------------------------------------------------------
d1 <- 
  ds2 %>% 
  filter(
    
  )


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


