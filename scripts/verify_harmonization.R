# Quick verification script to demonstrate harmonization effects
# Run after 05_harmonize_waves.R

library(here)
library(dplyr)
library(haven)

cat("\n=== Harmonization Verification ===\n\n")

# Load combined dataset
cambodia <- readRDS(here("data/processed/cambodia_all_waves_harmonized.rds"))

# Convert haven_labelled to numeric for analysis
cambodia <- cambodia %>%
  mutate(across(where(is.labelled), as.numeric))

cat("Combined dataset loaded:\n")
cat(sprintf("  Total observations: %d\n", nrow(cambodia)))
cat(sprintf("  Total variables: %d\n", ncol(cambodia)))
cat("\n")

# Show sample counts by wave
wave_counts <- table(cambodia$wave)
cat("Observations by wave:\n")
print(wave_counts)
cat("\n")

# Demonstrate economic question harmonization
cat("--- Economic Question Harmonization ---\n")
cat("Variable: q1 (Country economic condition)\n")
cat("After harmonization: All waves use 1=Very bad, 5=Very good\n\n")

econ_summary <- cambodia %>%
  group_by(wave) %>%
  summarize(
    mean = round(mean(econ_country_current, na.rm = TRUE), 2),
    sd = round(sd(econ_country_current, na.rm = TRUE), 2),
    n = sum(!is.na(econ_country_current))
  )

print(econ_summary)
cat("\n")

# Demonstrate trust question harmonization
cat("--- Trust Question Harmonization ---\n")
cat("Variable: q7 (Trust in executive)\n")
cat("Note: W2/W4/W6 use 4-point scale, W3 uses 6-point scale\n")
cat("After harmonization: All scales = higher means more trust\n\n")

trust_summary <- cambodia %>%
  group_by(wave) %>%
  summarize(
    mean = round(mean(trust_executive, na.rm = TRUE), 2),
    sd = round(sd(trust_executive, na.rm = TRUE), 2),
    n = sum(!is.na(trust_executive))
  )

print(trust_summary)
cat("\n")

# Show available variables
cat("--- Available Harmonized Variables (sample) ---\n")
harm_vars <- grep("_harm$", names(cambodia), value = TRUE)
cat(sprintf("Total harmonized variables: %d\n", length(harm_vars)))
cat("Examples:\n")
cat(paste("  -", head(harm_vars, 10)), sep = "\n")
cat("\n")

# Show standardized concept names
cat("--- Standardized Concept Names (sample) ---\n")
concept_vars <- c("econ_country_current", "econ_family_current",
                  "trust_executive", "trust_courts", "trust_national_gov",
                  "satisfaction_democracy", "level_democracy",
                  "interest_politics", "follow_news")
available_concepts <- intersect(concept_vars, names(cambodia))
cat(sprintf("Total concept variables: %d\n", length(available_concepts)))
cat("Examples:\n")
cat(paste("  -", available_concepts), sep = "\n")
cat("\n")

cat("=== Verification Complete ===\n")
cat("\nThe harmonized dataset is ready for cross-wave analysis!\n")
cat("Use variables with '_harm' suffix or standardized concept names.\n\n")
