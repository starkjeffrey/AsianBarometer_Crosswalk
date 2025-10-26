# ============================================================================
# Cross-Wave Harmonization Script
# ============================================================================
#
# This script demonstrates how to use the wave harmonization functions
# to create comparable variables across Asian Barometer waves
#
# Usage:
#   source("scripts/05_harmonize_waves.R")
#
# ============================================================================

library(haven)
library(here)
library(dplyr)

# Load harmonization functions
source(here("functions/wave_harmonization.R"))

cat("\n=== Asian Barometer Cross-Wave Harmonization ===\n\n")

# ============================================================================
# STEP 1: Load raw data files
# ============================================================================

cat("Step 1: Loading raw SPSS files...\n")

# Load each wave
w2_raw <- read_sav(here("data/raw/Wave2_20250609.sav"))
w3_raw <- read_sav(here("data/raw/ABS3 merge20250609.sav"))
w4_raw <- read_sav(here("data/raw/W4_v15_merged20250609_release.sav"))
w5_raw <- read_sav(here("data/raw/20230505_W5_merge_15.sav"))
w6_raw <- read_sav(here("data/raw/W6_Cambodia_Release_20240819.sav"))

cat("  ✓ All waves loaded\n\n")

# ============================================================================
# STEP 2: Filter for Cambodia (W2-W5 only; W6 is Cambodia-only)
# ============================================================================

cat("Step 2: Filtering for Cambodia...\n")

w2_cambodia <- w2_raw %>% filter(country == 12)
w3_cambodia <- w3_raw %>% filter(country == 12)
w4_cambodia <- w4_raw %>% filter(country == 12)
w5_cambodia <- w5_raw %>% filter(COUNTRY == 12)  # Note: uppercase in W5
w6_cambodia <- w6_raw  # Already Cambodia-only

cat(sprintf("  W2: %d cases\n", nrow(w2_cambodia)))
cat(sprintf("  W3: %d cases\n", nrow(w3_cambodia)))
cat(sprintf("  W4: %d cases\n", nrow(w4_cambodia)))
cat(sprintf("  W5: %d cases\n", nrow(w5_cambodia)))
cat(sprintf("  W6: %d cases\n", nrow(w6_cambodia)))
cat("\n")

# ============================================================================
# STEP 3: Apply harmonization to each wave
# ============================================================================

cat("Step 3: Applying harmonization...\n")

w2_harm <- harmonize_wave(w2_cambodia, "W2")
w3_harm <- harmonize_wave(w3_cambodia, "W3")
w4_harm <- harmonize_wave(w4_cambodia, "W4")
w5_harm <- harmonize_wave(w5_cambodia, "W5")
w6_harm <- harmonize_wave(w6_cambodia, "W6")

cat("  ✓ Harmonization complete for all waves\n\n")

# ============================================================================
# STEP 4: Demonstrate harmonization effects
# ============================================================================

cat("Step 4: Demonstrating harmonization effects...\n\n")

cat("--- Economic Questions (q1: Country economic condition) ---\n")
cat("Original scales:\n")
cat("  W2 q1: 1=Very bad → 5=Very good\n")
cat("  W4 q1: 1=Very good → 5=Very bad (REVERSED!)\n\n")

cat("Before harmonization:\n")
if ("q1" %in% names(w2_harm)) {
  cat(sprintf("  W2 q1 mean: %.2f\n", mean(w2_harm$q1, na.rm = TRUE)))
}
if ("q1" %in% names(w4_harm)) {
  cat(sprintf("  W4 q1 mean: %.2f\n", mean(w4_harm$q1, na.rm = TRUE)))
}

cat("\nAfter harmonization (both now: 1=Very bad → 5=Very good):\n")
if ("q1_harm" %in% names(w2_harm)) {
  cat(sprintf("  W2 q1_harm mean: %.2f\n", mean(w2_harm$q1_harm, na.rm = TRUE)))
}
if ("q1_harm" %in% names(w4_harm)) {
  cat(sprintf("  W4 q1_harm mean: %.2f\n", mean(w4_harm$q1_harm, na.rm = TRUE)))
}
cat("\n")

cat("--- Trust Questions (q7: Trust in executive) ---\n")
cat("Original scales:\n")
cat("  W2 q7: 1=None at all → 4=Great deal (4-point)\n")
cat("  W3 q7: 1=Trust fully → 6=Distrust fully (6-point, REVERSED!)\n")
cat("  W4 q7: 1=Great deal → 4=None at all (4-point, REVERSED!)\n\n")

cat("After harmonization (all scales: higher = more trust):\n")
if ("q7_harm" %in% names(w2_harm)) {
  cat(sprintf("  W2 q7_harm mean: %.2f (4-point scale)\n", mean(w2_harm$q7_harm, na.rm = TRUE)))
}
if ("q7_harm" %in% names(w3_harm)) {
  cat(sprintf("  W3 q7_harm mean: %.2f (6-point scale)\n", mean(w3_harm$q7_harm, na.rm = TRUE)))
}
if ("q7_harm" %in% names(w4_harm)) {
  cat(sprintf("  W4 q7_harm mean: %.2f (4-point scale)\n", mean(w4_harm$q7_harm, na.rm = TRUE)))
}
cat("\n")

# ============================================================================
# STEP 5: Create standardized variable names
# ============================================================================

cat("Step 5: Creating standardized variable names...\n")
cat("Examples of standardized variables available:\n")
cat("  - econ_country_current (was q1 in all waves)\n")
cat("  - trust_executive (was q7 in all waves)\n")
cat("  - satisfaction_democracy (was q93/q89/q92/q90 across waves)\n")
cat("  - democracy_preferable (was q121/q132/q125/q124 across waves)\n\n")

# Check if standardized variables were created
if ("econ_country_current" %in% names(w2_harm)) {
  cat(sprintf("  ✓ W2 econ_country_current mean: %.2f\n", mean(w2_harm$econ_country_current, na.rm = TRUE)))
}
if ("econ_country_current" %in% names(w4_harm)) {
  cat(sprintf("  ✓ W4 econ_country_current mean: %.2f\n", mean(w4_harm$econ_country_current, na.rm = TRUE)))
}
cat("\n")

# ============================================================================
# STEP 6: Save harmonized datasets
# ============================================================================

cat("Step 6: Saving harmonized datasets...\n")

saveRDS(w2_harm, here("data/processed/w2_cambodia_harmonized.rds"))
saveRDS(w3_harm, here("data/processed/w3_cambodia_harmonized.rds"))
saveRDS(w4_harm, here("data/processed/w4_cambodia_harmonized.rds"))
saveRDS(w5_harm, here("data/processed/w5_cambodia_harmonized.rds"))
saveRDS(w6_harm, here("data/processed/w6_cambodia_harmonized.rds"))

cat("  ✓ Saved to data/processed/\n\n")

# ============================================================================
# STEP 7: Create combined dataset with all waves
# ============================================================================

cat("Step 7: Creating combined dataset...\n")

# Select common variables for combining
# (You may want to customize this list based on your analysis needs)
common_vars <- c(
  "wave",
  # Harmonized economic variables
  "q1_harm", "q2_harm", "q3_harm", "q4_harm", "q5_harm", "q6_harm",
  # Harmonized trust variables
  "q7_harm", "q8_harm", "q9_harm", "q10_harm", "q11_harm",
  # Standardized concept names
  "econ_country_current", "econ_family_current",
  "trust_executive", "trust_courts", "trust_national_gov",
  "satisfaction_democracy", "level_democracy"
)

# Find variables that exist in each dataset
w2_common <- intersect(common_vars, names(w2_harm))
w3_common <- intersect(common_vars, names(w3_harm))
w4_common <- intersect(common_vars, names(w4_harm))
w5_common <- intersect(common_vars, names(w5_harm))
w6_common <- intersect(common_vars, names(w6_harm))

# Find variables present in ALL waves
all_waves_vars <- Reduce(intersect, list(w2_common, w3_common, w4_common, w5_common, w6_common))

cat(sprintf("  Found %d variables common to all waves\n", length(all_waves_vars)))

# Combine datasets (only common variables)
cambodia_combined <- bind_rows(
  w2_harm %>% select(all_of(all_waves_vars)),
  w3_harm %>% select(all_of(all_waves_vars)),
  w4_harm %>% select(all_of(all_waves_vars)),
  w5_harm %>% select(all_of(all_waves_vars)),
  w6_harm %>% select(all_of(all_waves_vars))
)

cat(sprintf("  Combined dataset: %d observations\n", nrow(cambodia_combined)))

# Save combined dataset
saveRDS(cambodia_combined, here("data/processed/cambodia_all_waves_harmonized.rds"))
cat("  ✓ Saved to data/processed/cambodia_all_waves_harmonized.rds\n\n")

# ============================================================================
# STEP 8: Generate harmonization codebook
# ============================================================================

cat("Step 8: Generating harmonization codebook...\n")

codebook <- create_harmonization_codebook()
write.csv(codebook, here("docs/harmonization_codebook.csv"), row.names = FALSE)

cat("  ✓ Saved to docs/harmonization_codebook.csv\n")
cat(sprintf("  Codebook contains %d concept mappings\n\n", nrow(codebook)))

# ============================================================================
# Summary
# ============================================================================

cat("=== Harmonization Complete ===\n\n")
cat("Key output files:\n")
cat("  1. data/processed/w*_cambodia_harmonized.rds - Individual wave files\n")
cat("  2. data/processed/cambodia_all_waves_harmonized.rds - Combined dataset\n")
cat("  3. docs/harmonization_codebook.csv - Variable mapping reference\n\n")

cat("Variables with '_harm' suffix have been harmonized for cross-wave comparison.\n")
cat("Standardized concept names (e.g., 'econ_country_current') are also available.\n\n")

cat("Next steps:\n")
cat("  - Use harmonized variables (*_harm) for cross-wave analysis\n")
cat("  - Refer to harmonization_codebook.csv for variable mappings\n")
cat("  - Check docs/cross_wave.md for details on scale changes\n\n")
