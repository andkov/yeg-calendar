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
prints_folder <- paste0("./analysis/kitchen-cabinet/prints/")
if(!file.exists(prints_folder)){dir.create(file.path(prints_folder))}

# ---- declare-functions -------------------------------------------------------


# ---- load-data ---------------------------------------------------------------
# Load libraries
# Load libraries
library(ggplot2)
library(dplyr)

# Step 1: Create the data (d1)
set.seed(123)  # For reproducibility
d1 <- expand.grid(day = 1:7, week = 1:52) %>%
  mutate(value = runif(n = n(), min = 0, max = 1)) %>%   # Random values between 0 and 1
  as_tibble() %>% 
  mutate(
    solar_day_num = row_number()
  )
d1
# Step 2: Create the tile plot (g1)
g1 <- d1 %>%
  ggplot(aes(x = x, y = y, fill = value)) +
  geom_tile(color = "white") +               # Add white borders for clarity
  scale_fill_viridis_c(guide = "none") +      # Remove legend
  coord_fixed() +                             # Keep tiles as squares
  theme_void() +                              # Remove all axes and labels
  theme(
    panel.background = element_blank(),       # No background
    plot.margin = margin(5, 5, 5, 5)          # Minimal padding around plot
  )

# Display the plot
g1
g1 %>% quick_save("quarter1",w=11,h=24)
# ---- inspect-data-0 ------------------------------------------------------------

# ---- inspect-data-local -----------------------------------------------------
# this chunk is not sourced by the annotation layer, use a scratch pad

# ---- tweak-data-0 ------------------------------------------------------------

# ---- tweak-data-1 ------------------------------------------------------------

# ---- inspect-data-2 ----------------------------------------------------------
ds2 %>% select(sex) %>% labelled::lookfor()
# ---- table-1 -----------------------------------------------------------------
ds2 %>% 
  select(sex, employed) %>% 
  tableone::CreateTableOne(data=.,strata = "sex")

# ---- graph-1 -----------------------------------------------------------------
ds2 %>% 
  ggplot(aes(x=date,y = earnings, color=sex)) +
  geom_point()

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
