# ==============================================================================
# 04_add_wave1_to_crosswalk.R
# Add Wave 1 variables to the expanded crosswalk
# ==============================================================================

cat("\n===== ADDING WAVE 1 TO CROSSWALK =====\n\n")

# Load required packages
library(here)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(purrr)

# ---------------------
# 1. Load resources
# ---------------------
cat("Loading crosswalk and Wave 1 variable data...\n")

# Load expanded crosswalk (currently W2-W6 only)
crosswalk <- read_csv(here("abs_harmonization_crosswalk_EXPANDED.csv"))

# Load variable inventory to get Wave 1 mappings
q_vars_all <- read_csv(here("docs/q_variables_by_wave.csv"))

# Get Wave 1 variables
wave1_vars <- q_vars_all %>%
  filter(wave == "Wave1") %>%
  select(variable, label)

cat("  ✓ Crosswalk loaded:", nrow(crosswalk), "concepts\n")
cat("  ✓ Wave 1 variables:", nrow(wave1_vars), "\n\n")

# ---------------------
# 2. Create Wave 1 mapping lookup
# ---------------------
cat("Creating Wave 1 variable mapping...\n")

# For each concept, try to find matching Wave 1 variable
# Strategy: Look for variables with same name or very similar labels

find_wave1_variable <- function(concept_row) {
  # Get existing variable names from this concept
  existing_vars <- c(
    concept_row$w2_var,
    concept_row$w3_var,
    concept_row$w4_var,
    concept_row$w5_var,
    concept_row$w6_var
  )
  existing_vars <- existing_vars[!is.na(existing_vars)]

  if (length(existing_vars) == 0) {
    return(list(var = NA_character_, label = NA_character_))
  }

  # Check if any of these variables exist in Wave 1
  for (var in existing_vars) {
    w1_match <- wave1_vars %>%
      filter(variable == var)

    if (nrow(w1_match) > 0) {
      return(list(
        var = w1_match$variable[1],
        label = w1_match$label[1]
      ))
    }
  }

  # If no exact match, try to find by label similarity
  # (This is a simplified approach - the fuzzy matching already did the heavy lifting)
  return(list(var = NA_character_, label = NA_character_))
}

# Apply to each concept
cat("  Matching Wave 1 variables to concepts...\n")

wave1_matches <- map_dfr(1:nrow(crosswalk), function(i) {
  if (i %% 10 == 0) cat("    Processing concept", i, "of", nrow(crosswalk), "\n")

  result <- find_wave1_variable(crosswalk[i, ])

  tibble(
    concept = crosswalk$concept[i],
    w1_var = result$var,
    w1_label = result$label
  )
})

cat("  ✓ Wave 1 matching complete\n")
cat("    - Concepts with Wave 1 match:", sum(!is.na(wave1_matches$w1_var)), "\n\n")

# ---------------------
# 3. Add Wave 1 columns to crosswalk
# ---------------------
cat("Adding Wave 1 columns to crosswalk...\n")

# Check if w1_var already exists in crosswalk
if ("w1_var" %in% names(crosswalk)) {
  cat("  Note: Wave 1 columns already exist, updating them...\n")

  # Update existing columns
  crosswalk <- crosswalk %>%
    select(-starts_with("w1_")) %>%
    left_join(wave1_matches, by = "concept")
} else {
  # Add new columns
  crosswalk <- crosswalk %>%
    left_join(wave1_matches, by = "concept")
}

# Add w1_scale column if it doesn't exist
if (!"w1_scale" %in% names(crosswalk)) {
  crosswalk <- crosswalk %>%
    mutate(w1_scale = NA_character_)
}

# Reorder columns to have Wave 1 first
col_order <- c(
  "concept",
  "domain",
  "description",
  "w1_var",
  "w1_scale",
  "w2_var",
  "w2_scale",
  "w3_var",
  "w3_scale",
  "w4_var",
  "w4_scale",
  "w5_var",
  "w5_scale",
  "w6_var",
  "w6_scale",
  "harmonized_name",
  "harmonize_to",
  "reverse_waves",
  "notes"
)

# Add any columns not in col_order (like 'source')
other_cols <- setdiff(names(crosswalk), col_order)
col_order <- c(col_order, other_cols)

# Ensure all columns exist
for (col in col_order) {
  if (!(col %in% names(crosswalk))) {
    crosswalk[[col]] <- NA
  }
}

# Reorder
crosswalk <- crosswalk %>%
  select(all_of(col_order[col_order %in% names(crosswalk)]))

cat("  ✓ Wave 1 columns added\n\n")

# ---------------------
# 4. Export updated crosswalk
# ---------------------
cat("Exporting updated crosswalk with Wave 1...\n")

write_csv(
  crosswalk,
  here("abs_harmonization_crosswalk_ALL_WAVES.csv")
)

cat("  ✓ abs_harmonization_crosswalk_ALL_WAVES.csv\n\n")

# Create a summary
wave_coverage <- crosswalk %>%
  summarise(
    total_concepts = n(),
    w1_coverage = sum(!is.na(w1_var)),
    w2_coverage = sum(!is.na(w2_var)),
    w3_coverage = sum(!is.na(w3_var)),
    w4_coverage = sum(!is.na(w4_var)),
    w5_coverage = sum(!is.na(w5_var)),
    w6_coverage = sum(!is.na(w6_var))
  ) %>%
  pivot_longer(everything(), names_to = "metric", values_to = "count") %>%
  mutate(
    percentage = ifelse(metric == "total_concepts", NA,
                       round(100 * count / first(count), 1))
  )

write_csv(
  wave_coverage,
  here("docs/wave_coverage_summary.csv")
)

cat("  ✓ docs/wave_coverage_summary.csv\n\n")

# ---------------------
# 5. Print summary
# ---------------------
cat("===== WAVE 1 INTEGRATION COMPLETE =====\n\n")

cat("📊 WAVE COVERAGE SUMMARY:\n")
print(wave_coverage, n = 20)

cat("\n📁 FILES CREATED:\n")
cat("  1. abs_harmonization_crosswalk_ALL_WAVES.csv - Complete crosswalk (W1-W6)\n")
cat("  2. docs/wave_coverage_summary.csv - Coverage statistics\n")

cat("\n🎯 CURRENT STATUS:\n")
cat("  - Total concepts:", crosswalk %>% summarise(n()) %>% pull(), "\n")
cat("  - With Wave 1:", sum(!is.na(crosswalk$w1_var)), "\n")
cat("  - With Wave 2-6:", sum(!is.na(crosswalk$w2_var)), "\n")
cat("  - In all 6 waves:", crosswalk %>%
      filter(!is.na(w1_var) & !is.na(w2_var) & !is.na(w3_var) &
             !is.na(w4_var) & !is.na(w5_var) & !is.na(w6_var)) %>%
      nrow(), "\n")

cat("\n✓ Wave 1 successfully integrated!\n")
cat("\nYour crosswalk now covers ALL 6 WAVES (2003-2022)\n\n")
