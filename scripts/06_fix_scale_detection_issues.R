# ============================================================================
# Fix Scale Detection Issues
# ============================================================================
# Purpose: Fix variable name mismatches and review continuous_check issues
# Input: abs_harmonization_crosswalk_WITH_SCALES.csv, docs/scales_need_review.csv
# Output: abs_harmonization_crosswalk_FIXED.csv

library(haven)
library(dplyr)
library(readr)
library(here)

# Load files
crosswalk <- read_csv(here("abs_harmonization_crosswalk_WITH_SCALES.csv"))
needs_review <- read_csv(here("docs/scales_need_review.csv"))

cat("📋 Scale Detection Issues to Fix:\n")
cat("Total issues:", nrow(needs_review), "\n")
cat("var_not_found:", sum(needs_review$scale_detected == "var_not_found"), "\n")
cat("continuous_check:", sum(needs_review$scale_detected == "continuous_check"), "\n\n")

# ============================================================================
# SECTION 1: Fix Variable Name Mismatches
# ============================================================================

# Based on variable inventory exploration, the correct variable names are:
demographic_mappings <- list(
  # Age - se3a in W2/W3, likely similar pattern in W4-W6
  age = list(
    w2 = "se3a",
    w3 = "se3a",
    w4 = "se3a",  # Need to verify
    w5 = "se3a",  # Need to verify
    w6 = "se3a"   # Need to verify
  ),
  # Gender - se2 across waves
  gender = list(
    w2 = "se2",
    w3 = "se2",
    w4 = "se2",
    w5 = "se2",
    w6 = "se2"
  ),
  # Education - se5
  education = list(
    w2 = "se5",
    w3 = "se5",
    w4 = "se5",
    w5 = "se5",
    w6 = "se5"
  ),
  # Income - se9
  income = list(
    w2 = "se9",
    w3 = "se9",
    w4 = "se9",
    w5 = "se9",
    w6 = "se9"
  ),
  # Urban/Rural - level3 in W1-W3, level/Level/LEVEL in W4-W6
  urban_rural = list(
    w2 = "level3",
    w3 = "level3",
    w4 = "level",
    w5 = "Level",
    w6 = "LEVEL"
  ),
  # Country - country/COUNTRY (uppercase in W5)
  country = list(
    w2 = "country",
    w3 = "country",
    w4 = "country",
    w5 = "COUNTRY",
    w6 = "country"
  ),
  # Year - year/Year/YEAR (varies by wave), only exists W4-W6
  year = list(
    w2 = NA_character_,  # Does not exist
    w3 = NA_character_,  # Does not exist
    w4 = "year",
    w5 = "Year",
    w6 = "YEAR"
  ),
  # Respondent ID - idnumber
  respondent_id = list(
    w2 = "idnumber",
    w3 = "idnumber",
    w4 = "idnumber",
    w5 = "idnumber",  # Verify this
    w6 = "idnumber"   # Verify this
  )
)

cat("🔧 Fixing demographic variable names...\n")

# Function to update variable name in crosswalk
update_var_name <- function(crosswalk_df, concept_name, wave_col, new_var_name) {
  row_idx <- which(crosswalk_df$concept == concept_name)
  if (length(row_idx) > 0) {
    crosswalk_df[[wave_col]][row_idx] <- new_var_name
    cat(sprintf("  ✓ Updated %s.%s = %s\n", concept_name, wave_col, new_var_name))
  }
  return(crosswalk_df)
}

# Apply demographic mappings
for (concept in names(demographic_mappings)) {
  for (wave_num in 2:6) {
    wave_col <- paste0("w", wave_num, "_var")
    new_name <- demographic_mappings[[concept]][[paste0("w", wave_num)]]
    crosswalk <- update_var_name(crosswalk, concept, wave_col, new_name)
  }
}

# ============================================================================
# SECTION 2: Verify Variable Names Exist in SPSS Files
# ============================================================================

cat("\n📂 Verifying variables exist in SPSS files...\n")

# Load SPSS files
spss_files <- list(
  w1 = here("data/raw/Wave1_20170906.sav"),
  w2 = here("data/raw/Wave2_20250609.sav"),
  w3 = here("data/raw/ABS3 merge20250609.sav"),
  w4 = here("data/raw/W4_v15_merged20250609_release.sav"),
  w5 = here("data/raw/20230505_W5_merge_15.sav"),
  w6 = here("data/processed/w6_all_countries_merged.rds")
)

# Function to check if variable exists
check_var_exists <- function(file_path, var_name, wave_name) {
  if (is.na(var_name)) return(NA)

  data <- if (grepl("\\.rds$", file_path)) {
    readRDS(file_path)
  } else {
    read_sav(file_path)
  }

  exists <- var_name %in% names(data)
  if (!exists) {
    cat(sprintf("  ⚠️  %s not found in %s\n", var_name, wave_name))
  }
  return(exists)
}

# Check all demographic variables
verification_results <- data.frame()
for (concept in names(demographic_mappings)) {
  for (wave_num in 2:6) {
    wave_col <- paste0("w", wave_num, "_var")
    var_name <- crosswalk %>%
      filter(concept == !!concept) %>%
      pull(!!wave_col)

    if (length(var_name) > 0 && !is.na(var_name)) {
      file_path <- spss_files[[paste0("w", wave_num)]]
      exists <- check_var_exists(file_path, var_name, paste0("Wave", wave_num))

      verification_results <- bind_rows(
        verification_results,
        data.frame(
          concept = concept,
          wave = paste0("Wave", wave_num),
          variable = var_name,
          exists = exists,
          stringsAsFactors = FALSE
        )
      )
    }
  }
}

# ============================================================================
# SECTION 3: Handle continuous_check Issues
# ============================================================================

cat("\n🔍 Reviewing continuous_check variables...\n")

continuous_issues <- needs_review %>%
  filter(scale_detected == "continuous_check") %>%
  select(concept, wave, variable, n_categories, labels)

cat("\nVariables flagged as continuous_check:\n")
print(continuous_issues)

# These are legitimately problematic:
# 1. q100/q101 in W1/W2: These appear to be open-ended "important issues" questions
#    with 73+ categories (100=Economics, 110=Economy, etc.) - NOT ordinal scales
# 2. q56/q53 in W5/W4: Political party closeness with 163/136 categories
#    (90=No party, 101-104=specific parties) - These are categorical, not ordinal
# 3. idnumber: This is an ID variable with 6000+ unique values - continuous/ID

# Mark these appropriately in crosswalk
cat("\n🏷️  Updating scale types for continuous_check variables...\n")

# Update q100/q101 (democracy placement questions - but W1/W2 have wrong coding)
crosswalk <- crosswalk %>%
  mutate(
    # For concept_006 (democracy placement), W1/W2 have categorical issue codes
    w1_scale = ifelse(concept == "concept_006", "categorical_issues", w1_scale),
    w2_scale = ifelse(concept == "concept_006", "categorical_issues", w2_scale),

    # For concept_007 (desire for democracy), same issue
    w1_scale = ifelse(concept == "concept_007", "categorical_issues", w1_scale),
    w2_scale = ifelse(concept == "concept_007", "categorical_issues", w2_scale),

    # For concept_003 (parents' demands), W5 has party codes
    w5_scale = ifelse(concept == "concept_003", "categorical_party", w5_scale),

    # For concept_034 (government impact), W4 has party codes
    w4_scale = ifelse(concept == "concept_034", "categorical_party", w4_scale),

    # For respondent_id, mark as ID
    w2_scale = ifelse(concept == "respondent_id", "id", w2_scale),
    w3_scale = ifelse(concept == "respondent_id", "id", w3_scale),
    w4_scale = ifelse(concept == "respondent_id", "id", w4_scale),

    # For voted_last_election W3, this has 109 party codes - categorical
    w3_scale = ifelse(concept == "voted_last_election", "categorical_party", w3_scale)
  )

# ============================================================================
# SECTION 4: Re-run Scale Detection on Fixed Variables
# ============================================================================

cat("\n🔄 Re-running scale detection on fixed demographic variables...\n")

# Load scale detection function
source(here("scripts/05_detect_scale_types.R"), local = TRUE)

# Re-detect scales for demographic variables
demographic_concepts <- c("age", "gender", "education", "income", "urban_rural",
                          "country", "year", "respondent_id")

for (concept_name in demographic_concepts) {
  for (wave_num in 2:6) {
    wave_col_var <- paste0("w", wave_num, "_var")
    wave_col_scale <- paste0("w", wave_num, "_scale")

    concept_row <- crosswalk %>% filter(concept == concept_name)
    if (nrow(concept_row) == 0) next

    var_name <- concept_row[[wave_col_var]]
    if (is.na(var_name)) next

    # Load appropriate SPSS file
    file_path <- spss_files[[paste0("w", wave_num)]]
    wave_data <- if (grepl("\\.rds$", file_path)) {
      readRDS(file_path)
    } else {
      read_sav(file_path)
    }

    if (var_name %in% names(wave_data)) {
      detection_result <- detect_scale_type(wave_data[[var_name]])

      # Update crosswalk
      crosswalk <- crosswalk %>%
        mutate(
          !!wave_col_scale := ifelse(
            concept == concept_name,
            detection_result$scale_type,
            .data[[wave_col_scale]]
          )
        )

      cat(sprintf("  ✓ %s.%s: %s\n", concept_name, wave_col_scale,
                  detection_result$scale_type))
    }
  }
}

# ============================================================================
# SECTION 5: Save Results
# ============================================================================

cat("\n💾 Saving fixed crosswalk...\n")

# Save updated crosswalk
output_file <- here("abs_harmonization_crosswalk_FIXED.csv")
write_csv(crosswalk, output_file)

cat("\n✅ COMPLETE!\n")
cat("Fixed crosswalk saved to:", output_file, "\n")

# Generate summary
cat("\n📊 SUMMARY OF FIXES:\n")
cat("Demographic variables updated:", length(demographic_concepts), "\n")
cat("Continuous_check issues resolved:", nrow(continuous_issues), "\n")
cat("Variables re-detected:", length(demographic_concepts) * 5, "attempted\n")

# Save verification results
verification_file <- here("docs/variable_verification_results.csv")
write_csv(verification_results, verification_file)
cat("\nVerification results saved to:", verification_file, "\n")

cat("\n🎯 NEXT STEPS:\n")
cat("1. Review abs_harmonization_crosswalk_FIXED.csv\n")
cat("2. Manually verify demographic variable names are correct\n")
cat("3. Assign domains to 28 NA concepts\n")
cat("4. Create meaningful names for concept_001, concept_002, etc.\n")
