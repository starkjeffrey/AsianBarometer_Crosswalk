# ==============================================================================
# create_master_crosswalk.R
# Creates the most comprehensive crosswalk by merging ALL_WAVES with domain files
# ==============================================================================

library(dplyr)
library(readr)
library(here)

cat("\n")
cat("=================================================================\n")
cat("  CREATING MASTER CROSSWALK - MAXIMUM COVERAGE\n")
cat("=================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. Load the base ALL_WAVES crosswalk
# -----------------------------------------------------------------------------
cat("Loading base crosswalk (ALL_WAVES)...\n")
base <- read_csv(here("abs_harmonization_crosswalk_ALL_WAVES.csv"), show_col_types = FALSE)
cat(paste("  Base concepts:", nrow(base), "\n"))

# Separate named concepts from placeholders
named_concepts <- base %>% filter(!grepl("^concept_", concept))
placeholder_concepts <- base %>% filter(grepl("^concept_", concept))
cat(paste("  Named concepts:", nrow(named_concepts), "\n"))
cat(paste("  Placeholder concepts:", nrow(placeholder_concepts), "\n\n"))

# -----------------------------------------------------------------------------
# 2. Load all domain-specific crosswalks
# -----------------------------------------------------------------------------
cat("Loading domain-specific crosswalks...\n")

domain_files <- c(
  "docs/traditionalism_crosswalk.csv",
  "docs/political_participation_crosswalk.csv",
  "docs/electoral_participation_crosswalk.csv",
  "docs/regime_preference_crosswalk.csv",
  "docs/social_capital_crosswalk_enhanced.csv",
  "docs/internet_socialmedia_crosswalk.csv",
  "docs/economic_perceptions_crosswalk.csv",
  "docs/political_interest_crosswalk.csv",
  "docs/partisanship_crosswalk.csv"
)

domain_data <- lapply(domain_files, function(f) {
  df <- read_csv(here(f), show_col_types = FALSE)
  cat(paste("  ", basename(f), ":", nrow(df), "concepts\n"))
  df
})

# Combine all domain crosswalks
all_domain <- bind_rows(domain_data)
cat(paste("\nTotal domain concepts loaded:", nrow(all_domain), "\n"))

# -----------------------------------------------------------------------------
# 3. Identify unique concepts from domain files not in named_concepts
# -----------------------------------------------------------------------------
cat("\nIdentifying unique domain concepts not in base...\n")

existing_concepts <- named_concepts$concept
domain_unique <- all_domain %>%
  filter(!concept %in% existing_concepts) %>%
  distinct(concept, .keep_all = TRUE)

cat(paste("  New unique concepts from domain files:", nrow(domain_unique), "\n"))

# Show what's being added by domain
domain_unique %>%
  count(domain) %>%
  arrange(desc(n)) %>%
  mutate(msg = paste("    ", domain, ":", n, "new concepts")) %>%
  pull(msg) %>%
  cat(sep = "\n")

# -----------------------------------------------------------------------------
# 4. Ensure domain files have same columns as base
# -----------------------------------------------------------------------------
cat("\nStandardizing column structure...\n")

base_cols <- names(base)

# Add missing columns to domain_unique if needed
for (col in base_cols) {
  if (!col %in% names(domain_unique)) {
    domain_unique[[col]] <- NA
  }
}

# Reorder columns to match base
domain_unique <- domain_unique %>% select(all_of(base_cols))

# -----------------------------------------------------------------------------
# 5. Update source column for domain concepts
# -----------------------------------------------------------------------------
domain_unique <- domain_unique %>%
  mutate(source = ifelse(is.na(source), "domain-specific", source))

# -----------------------------------------------------------------------------
# 6. Combine: named_concepts + domain_unique + (optionally) placeholders
# -----------------------------------------------------------------------------
cat("\nCombining crosswalks...\n")

# Option 1: Include placeholders (they may have variables not in domain files)
master_with_placeholders <- bind_rows(
  named_concepts,
  domain_unique,
  placeholder_concepts
)

# Option 2: Exclude placeholders (cleaner, but may lose some variables)
master_clean <- bind_rows(
  named_concepts,
  domain_unique
)

cat(paste("  Master WITH placeholders:", nrow(master_with_placeholders), "concepts\n"))
cat(paste("  Master CLEAN (no placeholders):", nrow(master_clean), "concepts\n"))

# -----------------------------------------------------------------------------
# 7. Check for duplicates and resolve
# -----------------------------------------------------------------------------
cat("\nChecking for duplicates...\n")

# Some concepts may appear in multiple domain files (e.g., trust_relatives)
duplicates <- master_clean %>%
  group_by(concept) %>%
  filter(n() > 1) %>%
  select(concept, domain) %>%
  distinct()

if (nrow(duplicates) > 0) {
  cat("  Found duplicates (keeping first occurrence):\n")
  print(duplicates)

  master_clean <- master_clean %>%
    distinct(concept, .keep_all = TRUE)
}

cat(paste("  Final clean count:", nrow(master_clean), "concepts\n"))

# -----------------------------------------------------------------------------
# 8. Sort by domain for organization
# -----------------------------------------------------------------------------
cat("\nOrganizing by domain...\n")

# Define domain order
domain_order <- c(
  "trust", "economic", "democracy", "regime", "politics", "political_interest",
  "participation", "electoral", "partisanship", "traditionalism", "social_capital",
  "internet", "social", "covid", "demographics", "identifiers", "corruption",
  "governance", "local_govt", "other", NA
)

master_clean <- master_clean %>%
  mutate(domain_order = match(domain, domain_order)) %>%
  mutate(domain_order = ifelse(is.na(domain_order), 999, domain_order)) %>%
  arrange(domain_order, concept) %>%
  select(-domain_order)

# -----------------------------------------------------------------------------
# 9. Save the master crosswalks
# -----------------------------------------------------------------------------
cat("\nSaving master crosswalks...\n")

# Save clean version (recommended)
write_csv(master_clean, here("abs_harmonization_crosswalk_MASTER.csv"))
cat(paste("  Saved: abs_harmonization_crosswalk_MASTER.csv (", nrow(master_clean), " concepts)\n"))

# Save version with placeholders
write_csv(master_with_placeholders, here("abs_harmonization_crosswalk_MASTER_WITH_PLACEHOLDERS.csv"))
cat(paste("  Saved: abs_harmonization_crosswalk_MASTER_WITH_PLACEHOLDERS.csv (", nrow(master_with_placeholders), " concepts)\n"))

# -----------------------------------------------------------------------------
# 10. Generate summary report
# -----------------------------------------------------------------------------
cat("\n=================================================================\n")
cat("  MASTER CROSSWALK SUMMARY\n")
cat("=================================================================\n\n")

summary_by_domain <- master_clean %>%
  group_by(domain) %>%
  summarise(
    n_concepts = n(),
    has_w1 = sum(!is.na(w1_var) & w1_var != "NA"),
    has_w2 = sum(!is.na(w2_var) & w2_var != "NA"),
    has_w3 = sum(!is.na(w3_var) & w3_var != "NA"),
    has_w4 = sum(!is.na(w4_var) & w4_var != "NA"),
    has_w5 = sum(!is.na(w5_var) & w5_var != "NA"),
    has_w6 = sum(!is.na(w6_var) & w6_var != "NA"),
    .groups = "drop"
  ) %>%
  arrange(desc(n_concepts))

cat("Coverage by Domain:\n")
print(summary_by_domain, n = 25)

cat("\n\nTotal Concepts by Wave Coverage:\n")
wave_coverage <- master_clean %>%
  mutate(
    w1 = !is.na(w1_var) & w1_var != "NA",
    w2 = !is.na(w2_var) & w2_var != "NA",
    w3 = !is.na(w3_var) & w3_var != "NA",
    w4 = !is.na(w4_var) & w4_var != "NA",
    w5 = !is.na(w5_var) & w5_var != "NA",
    w6 = !is.na(w6_var) & w6_var != "NA"
  ) %>%
  summarise(
    W1 = sum(w1),
    W2 = sum(w2),
    W3 = sum(w3),
    W4 = sum(w4),
    W5 = sum(w5),
    W6 = sum(w6)
  )

print(wave_coverage)

cat("\n\n")
cat("=================================================================\n")
cat("  MASTER CROSSWALK CREATION COMPLETE!\n")
cat("=================================================================\n")
cat("\nFiles created:\n")
cat("  1. abs_harmonization_crosswalk_MASTER.csv\n")
cat("     - Clean version with properly named concepts\n")
cat("     - Use this as your primary crosswalk\n\n")
cat("  2. abs_harmonization_crosswalk_MASTER_WITH_PLACEHOLDERS.csv\n")
cat("     - Includes auto-generated concept_XXX entries\n")
cat("     - Use for reference to find additional variables\n\n")
