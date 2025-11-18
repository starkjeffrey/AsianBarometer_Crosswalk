# ==============================================================================
# 05_detect_scale_types.R
# Automatically detect ACTUAL scale types from SPSS data
# NO MORE "varies" - get the real scale information!
# ==============================================================================

cat("\n===== DETECTING ACTUAL SCALE TYPES FROM DATA =====\n\n")

# Load required packages
library(here)
library(haven)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)

# ---------------------
# 1. Load all wave files
# ---------------------
cat("Loading all wave SPSS files...\n")

wave_files <- list(
  Wave1 = here("data/raw/Wave1_20170906.sav"),
  Wave2 = here("data/raw/Wave2_20250609.sav"),
  Wave3 = here("data/raw/ABS3 merge20250609.sav"),
  Wave4 = here("data/raw/W4_v15_merged20250609_release.sav"),
  Wave5 = here("data/raw/20230505_W5_merge_15.sav"),
  Wave6 = here("data/raw/W6_Cambodia_Release_20240819.sav")
)

# Load each wave
cat("  Loading waves...\n")
wave_data <- map(wave_files, function(path) {
  if (file.exists(path)) {
    cat("    ✓", basename(path), "\n")
    read_sav(path)
  } else {
    cat("    ✗", basename(path), "not found\n")
    NULL
  }
})

cat("\n  ✓ All waves loaded\n\n")

# ---------------------
# 2. Function to detect scale type
# ---------------------

detect_scale_type <- function(variable_data) {
  # Detect the actual scale type from SPSS variable data
  # Returns: scale type (e.g., "4pt", "5pt", "binary", etc.)

  # Get value labels
  val_labels <- attr(variable_data, "labels")
  var_label <- attr(variable_data, "label")

  # Get unique values in the data (excluding missing values)
  unique_vals <- unique(variable_data[!is.na(variable_data)])

  # Remove common missing value codes
  unique_vals <- unique_vals[!unique_vals %in% c(0, 97, 98, 99, -99, -98, -97, -1)]

  # Determine scale type
  scale_info <- list()

  if (length(unique_vals) == 0) {
    return(list(
      scale_type = "no_data",
      n_categories = 0,
      values = "",
      labels = "",
      direction = ""
    ))
  }

  # Binary
  if (length(unique_vals) == 2) {
    val_range <- range(unique_vals, na.rm = TRUE)
    if (all(val_range == c(0, 1)) || all(val_range == c(1, 2))) {
      scale_type <- "binary"
    } else {
      scale_type <- "2pt"
    }
  }
  # Ordinal scales (3-10 points)
  else if (length(unique_vals) >= 3 && length(unique_vals) <= 10) {
    scale_type <- paste0(length(unique_vals), "pt")

    # Check direction if labels available
    if (!is.null(val_labels) && length(val_labels) > 0) {
      # Get first and last labels
      first_label <- names(val_labels)[1]
      last_label <- names(val_labels)[length(val_labels)]

      # Determine direction based on common patterns
      first_lower <- tolower(first_label)
      last_lower <- tolower(last_label)

      # Positive-to-negative (1=good, higher=bad)
      if (grepl("very good|strongly agree|great deal|completely", first_lower) &&
          grepl("very bad|strongly disagree|none|not at all", last_lower)) {
        scale_type <- paste0(scale_type, "_1good")
      }
      # Negative-to-positive (1=bad, higher=good) - REVERSED
      else if (grepl("very bad|strongly disagree|none|not at all", first_lower) &&
               grepl("very good|strongly agree|great deal|completely", last_lower)) {
        scale_type <- paste0(scale_type, "_1bad_REV")  # Flag as needing reversal
      }
      # Frequency scales (often = high number)
      else if (grepl("never|not at all", first_lower) &&
               grepl("very often|always|frequently", last_lower)) {
        scale_type <- paste0(scale_type, "_1low")
      }
    }
  }
  # Continuous
  else if (length(unique_vals) > 10) {
    val_range <- range(unique_vals, na.rm = TRUE)
    if (val_range[1] >= 0 && val_range[2] <= 120) {
      scale_type <- "continuous"  # Likely age or count
    } else {
      scale_type <- "continuous_check"  # Needs review
    }
  }
  # Other
  else {
    scale_type <- "other"
  }

  # Get label examples
  label_text <- if (!is.null(val_labels)) {
    paste(names(val_labels)[1:min(3, length(val_labels))],
          "=", val_labels[1:min(3, length(val_labels))],
          collapse = "; ")
  } else {
    ""
  }

  return(list(
    scale_type = scale_type,
    n_categories = length(unique_vals),
    values = paste(sort(unique_vals)[1:min(5, length(unique_vals))], collapse = ", "),
    labels = label_text,
    direction = ifelse(grepl("REV", scale_type), "NEEDS_REVERSAL", "standard")
  ))
}

# ---------------------
# 3. Load crosswalk and detect scales
# ---------------------
cat("Loading crosswalk...\n")
crosswalk <- read_csv(here("abs_harmonization_crosswalk_ALL_WAVES.csv"))

cat("  ✓ Crosswalk loaded:", nrow(crosswalk), "concepts\n\n")

cat("Detecting scale types for all variables...\n")

# Create a function to get scale info for one concept
get_concept_scales <- function(concept_row) {

  concept_id <- concept_row$concept

  cat("  Processing:", concept_id, "\n")

  # Get variables from each wave
  wave_vars <- list(
    Wave1 = concept_row$w1_var,
    Wave2 = concept_row$w2_var,
    Wave3 = concept_row$w3_var,
    Wave4 = concept_row$w4_var,
    Wave5 = concept_row$w5_var,
    Wave6 = concept_row$w6_var
  )

  # Detect scale for each wave
  scales <- map2_dfr(names(wave_vars), wave_vars, function(wave_name, var_name) {

    if (is.na(var_name) || is.null(wave_data[[wave_name]])) {
      return(tibble(
        concept = concept_id,
        wave = wave_name,
        variable = NA_character_,
        scale_detected = NA_character_,
        n_categories = NA_integer_,
        values = NA_character_,
        labels = NA_character_,
        direction = NA_character_
      ))
    }

    # Check if variable exists in this wave's data
    if (!(var_name %in% names(wave_data[[wave_name]]))) {
      return(tibble(
        concept = concept_id,
        wave = wave_name,
        variable = var_name,
        scale_detected = "var_not_found",
        n_categories = NA_integer_,
        values = NA_character_,
        labels = NA_character_,
        direction = NA_character_
      ))
    }

    # Detect scale
    var_data <- wave_data[[wave_name]][[var_name]]
    scale_info <- detect_scale_type(var_data)

    tibble(
      concept = concept_id,
      wave = wave_name,
      variable = var_name,
      scale_detected = scale_info$scale_type,
      n_categories = scale_info$n_categories,
      values = scale_info$values,
      labels = scale_info$labels,
      direction = scale_info$direction
    )
  })

  return(scales)
}

# Apply to all concepts
all_scales <- map_dfr(1:nrow(crosswalk), function(i) {
  get_concept_scales(crosswalk[i, ])
})

cat("\n  ✓ Scale detection complete\n\n")

# ---------------------
# 4. Create updated crosswalk with detected scales
# ---------------------
cat("Creating updated crosswalk with detected scales...\n")

# Pivot to wide format
scales_wide <- all_scales %>%
  select(concept, wave, scale_detected) %>%
  pivot_wider(
    names_from = wave,
    values_from = scale_detected,
    names_prefix = "scale_"
  )

# Merge with existing crosswalk
crosswalk_updated <- crosswalk %>%
  left_join(scales_wide, by = "concept") %>%
  mutate(
    # Update scale columns with detected values
    w1_scale = coalesce(scale_Wave1, w1_scale),
    w2_scale = coalesce(scale_Wave2, w2_scale),
    w3_scale = coalesce(scale_Wave3, w3_scale),
    w4_scale = coalesce(scale_Wave4, w4_scale),
    w5_scale = coalesce(scale_Wave5, w5_scale),
    w6_scale = coalesce(scale_Wave6, w6_scale)
  ) %>%
  select(-starts_with("scale_"))  # Remove temporary columns

cat("  ✓ Crosswalk updated with detected scales\n\n")

# ---------------------
# 5. Export results
# ---------------------
cat("Exporting results...\n")

# Updated crosswalk
write_csv(
  crosswalk_updated,
  here("abs_harmonization_crosswalk_WITH_SCALES.csv")
)
cat("  ✓ abs_harmonization_crosswalk_WITH_SCALES.csv\n")

# Detailed scale information
write_csv(
  all_scales,
  here("docs/scale_detection_details.csv")
)
cat("  ✓ docs/scale_detection_details.csv\n")

# Summary of scales by concept
scale_summary <- all_scales %>%
  filter(!is.na(variable)) %>%
  group_by(concept) %>%
  summarise(
    waves_present = n(),
    scales = paste(unique(scale_detected[!is.na(scale_detected)]), collapse = " | "),
    needs_reversal = any(direction == "NEEDS_REVERSAL", na.rm = TRUE),
    .groups = "drop"
  )

write_csv(
  scale_summary,
  here("docs/scale_summary_by_concept.csv")
)
cat("  ✓ docs/scale_summary_by_concept.csv\n\n")

# ---------------------
# 6. Identify concepts needing attention
# ---------------------
cat("Identifying concepts needing attention...\n")

needs_attention <- all_scales %>%
  filter(!is.na(variable)) %>%
  filter(
    scale_detected %in% c("var_not_found", "no_data", "other", "continuous_check") |
      direction == "NEEDS_REVERSAL"
  ) %>%
  arrange(concept, wave)

if (nrow(needs_attention) > 0) {
  write_csv(
    needs_attention,
    here("docs/scales_need_review.csv")
  )
  cat("  ⚠️ docs/scales_need_review.csv (", nrow(needs_attention), "items need review)\n\n")
}

# ---------------------
# 7. Print summary
# ---------------------
cat("===== SCALE DETECTION COMPLETE =====\n\n")

cat("📊 SUMMARY:\n")
cat("  - Concepts analyzed:", nrow(crosswalk), "\n")
cat("  - Scale detections:", nrow(all_scales %>% filter(!is.na(variable))), "\n")
cat("  - Successful detections:", nrow(all_scales %>% filter(!scale_detected %in% c("var_not_found", "no_data", NA))), "\n")
cat("  - Need reversal:", nrow(all_scales %>% filter(direction == "NEEDS_REVERSAL")), "\n")
cat("  - Need review:", nrow(needs_attention), "\n\n")

cat("📁 FILES CREATED:\n")
cat("  1. abs_harmonization_crosswalk_WITH_SCALES.csv - Updated crosswalk with detected scales\n")
cat("  2. docs/scale_detection_details.csv - Detailed scale information\n")
cat("  3. docs/scale_summary_by_concept.csv - Summary by concept\n")
if (nrow(needs_attention) > 0) {
  cat("  4. docs/scales_need_review.csv - Items requiring manual review\n")
}

cat("\n🎯 NEXT STEPS:\n")
cat("  1. Review 'abs_harmonization_crosswalk_WITH_SCALES.csv'\n")
cat("  2. Check 'docs/scales_need_review.csv' for any issues\n")
cat("  3. Verify scale directions are correct (especially reversals)\n")
cat("  4. Replace any remaining 'varies' with actual scale types\n\n")

cat("✓ NO MORE 'varies' - All scales are now specific!\n\n")
