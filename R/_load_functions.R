# R/_load_functions.R
# Load all custom functions

# Load required packages for helper functions
library(haven)  # Required for search_across_waves()
library(purrr)  # Required for map_dfr() in helper functions

source(here::here("R", "recoding.R"))
source(here::here("R", "validation.R"))
source(here::here("R", "helpers.R"))
source(here::here("R", "composites.R"))
source(here::here("R", "clear_env.R"))
# Note: lint.R is NOT sourced here - it's a standalone script meant to be run manually

cat("\n=== Custom Functions Loaded ===\n")
cat("Available functions:\n")
cat("  - safe_reverse_3pt()\n")
cat("  - safe_reverse_4pt()\n")
cat("  - safe_reverse_5pt()\n")
cat("  - check_unexpected_values()\n")
cat("==============================\n\n")


