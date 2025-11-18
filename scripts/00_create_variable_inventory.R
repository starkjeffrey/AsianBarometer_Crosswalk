# ==============================================================================
# 00_create_variable_inventory.R
# Create comprehensive variable inventory across all 6 Asian Barometer waves
# This is the FIRST STEP before harmonization
# ==============================================================================

cat("\n===== CREATING VARIABLE INVENTORY FOR ALL WAVES =====\n\n")

# Load required packages
library(here)
library(haven)
library(dplyr)
library(purrr)
library(tidyr)
library(readr)

# Define paths to merged wave files
wave_files <- list(
  Wave1 = here("data/raw/Wave1_20170906.sav"),
  Wave2 = here("data/raw/Wave2_20250609.sav"),
  Wave3 = here("data/raw/ABS3 merge20250609.sav"),
  Wave4 = here("data/raw/W4_v15_merged20250609_release.sav"),
  Wave5 = here("data/raw/20230505_W5_merge_15.sav"),
  Wave6 = here("data/raw/W6_Cambodia_Release_20240819.sav")  # Using Cambodia file as example
)

# Check which files exist
cat("Checking for wave files...\n")
for (wave_name in names(wave_files)) {
  if (file.exists(wave_files[[wave_name]])) {
    cat("  ✓", wave_name, "found\n")
  } else {
    cat("  ✗", wave_name, "NOT FOUND\n")
    wave_files[[wave_name]] <- NULL  # Remove from list
  }
}

# Function to extract variable metadata from SPSS file
extract_variable_metadata <- function(file_path, wave_name) {
  cat("\nProcessing", wave_name, "...\n")

  # Read SPSS file
  data <- read_sav(file_path)

  # Get variable names
  var_names <- names(data)

  # Extract variable labels
  var_labels <- map_chr(data, ~{
    label <- attr(.x, "label")
    ifelse(is.null(label), NA_character_, label)
  })

  # Extract value labels (first few values)
  var_value_labels <- map_chr(data, ~{
    val_labels <- attr(.x, "labels")
    if (is.null(val_labels) || length(val_labels) == 0) {
      return(NA_character_)
    }
    # Get first 3 value labels as example
    labels_text <- paste(
      names(val_labels)[1:min(3, length(val_labels))],
      "=",
      val_labels[1:min(3, length(val_labels))],
      collapse = "; "
    )
    labels_text
  })

  # Get variable types
  var_types <- map_chr(data, ~class(.x)[1])

  # Create metadata tibble
  metadata <- tibble(
    wave = wave_name,
    variable = var_names,
    label = var_labels,
    type = var_types,
    value_labels_sample = var_value_labels,
    n_rows = nrow(data)
  )

  cat("  - Variables:", nrow(metadata), "\n")
  cat("  - Rows:", nrow(data), "\n")

  return(metadata)
}

# Extract metadata from all available waves
all_wave_metadata <- map2_dfr(
  wave_files,
  names(wave_files),
  extract_variable_metadata
)

# Create comprehensive inventory
cat("\n===== GENERATING COMPREHENSIVE INVENTORY =====\n")

# 1. All variables across all waves (long format)
cat("\nSaving complete variable inventory...\n")
write_csv(
  all_wave_metadata,
  here("docs/variable_inventory_all_waves.csv")
)

# 2. Wide format: which variables appear in which waves
cat("Creating cross-wave variable presence matrix...\n")
variable_presence <- all_wave_metadata %>%
  select(wave, variable, label) %>%
  mutate(present = "✓") %>%
  pivot_wider(
    id_cols = c(variable, label),
    names_from = wave,
    values_from = present,
    values_fill = ""
  ) %>%
  arrange(variable)

write_csv(
  variable_presence,
  here("docs/variable_presence_by_wave.csv")
)

# 3. Common variables across all waves
cat("Identifying common variables across all waves...\n")
common_vars <- all_wave_metadata %>%
  group_by(variable) %>%
  summarise(
    n_waves = n_distinct(wave),
    waves_present = paste(wave, collapse = ", "),
    labels = paste(unique(label[!is.na(label)]), collapse = " | "),
    .groups = "drop"
  ) %>%
  arrange(desc(n_waves), variable)

write_csv(
  common_vars,
  here("docs/common_variables_across_waves.csv")
)

# 4. Question-numbered variables (q1, q2, etc.) - KEY for harmonization
cat("Identifying q-numbered variables for crosswalk mapping...\n")
q_vars <- all_wave_metadata %>%
  filter(grepl("^q[0-9]", variable, ignore.case = TRUE)) %>%
  select(wave, variable, label, value_labels_sample) %>%
  arrange(variable, wave)

write_csv(
  q_vars,
  here("docs/q_variables_by_wave.csv")
)

# 5. Summary statistics
cat("\n===== SUMMARY STATISTICS =====\n")
summary_stats <- all_wave_metadata %>%
  group_by(wave) %>%
  summarise(
    n_variables = n(),
    n_labeled = sum(!is.na(label)),
    pct_labeled = round(100 * n_labeled / n_variables, 1),
    .groups = "drop"
  )

print(summary_stats)

write_csv(
  summary_stats,
  here("docs/variable_inventory_summary.csv")
)

# 6. Create a starter crosswalk template for unmapped variables
cat("\nCreating starter crosswalk template...\n")

# Find q-variables that appear in multiple waves
potential_crosswalk <- q_vars %>%
  group_by(variable) %>%
  summarise(
    n_waves = n_distinct(wave),
    concept_label = first(label[!is.na(label)]),
    w1_label = first(label[wave == "Wave1"]),
    w2_label = first(label[wave == "Wave2"]),
    w3_label = first(label[wave == "Wave3"]),
    w4_label = first(label[wave == "Wave4"]),
    w5_label = first(label[wave == "Wave5"]),
    w6_label = first(label[wave == "Wave6"]),
    .groups = "drop"
  ) %>%
  filter(n_waves >= 2) %>%  # Only variables in 2+ waves
  arrange(desc(n_waves), variable)

write_csv(
  potential_crosswalk,
  here("docs/potential_crosswalk_variables.csv")
)

cat("\n===== INVENTORY COMPLETE =====\n")
cat("\nGenerated files in docs/:\n")
cat("  1. variable_inventory_all_waves.csv - Complete variable list\n")
cat("  2. variable_presence_by_wave.csv - Which vars in which waves\n")
cat("  3. common_variables_across_waves.csv - Variables by frequency\n")
cat("  4. q_variables_by_wave.csv - Q-numbered variables for mapping\n")
cat("  5. variable_inventory_summary.csv - Summary statistics\n")
cat("  6. potential_crosswalk_variables.csv - Starter template for crosswalk\n")
cat("\n✓ NEXT STEP: Review these files to validate/refine abs_harmonization_crosswalk.csv\n\n")
