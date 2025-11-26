library(tidyverse)
library(here)

# Get waves 1-5
wave_dirs <- list.files(
  here("data/raw"), 
  pattern = "^wave[1-5]$", 
  full.names = TRUE
)

wave_files <- map(wave_dirs, ~{
  list.files(.x, pattern = "\\.sav$", full.names = TRUE)
}) %>% 
  unlist()

# Add wave 6 Cambodia
wave6_cambodia <- here("data/raw/wave6/W6_Cambodia_Release_20240819.sav")

# Combine
wave_files <- c(wave_files, wave6_cambodia)

# Check
length(wave_files)
wave_files
