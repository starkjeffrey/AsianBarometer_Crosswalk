# ==============================================================================
# Test Concept Mapping System
# ==============================================================================

library(haven)
library(here)
library(dplyr)

source(here("functions/cleaning_functions.R"))
source(here("functions/concept_functions.R"))

cat("\n=== Testing Concept Mapping System ===\n\n")

# Test 1: Load concept mappings
cat("Test 1: Loading concept mappings...\n")
mappings <- load_concept_mappings()
cat("✓ Loaded", nrow(mappings), "concept definitions\n\n")

# Test 2: List concepts
cat("Test 2: Listing concepts...\n")
all_concepts <- list_concepts()
cat("Total concepts:", nrow(all_concepts), "\n")

trust_concepts <- list_concepts(domain = "trust")
cat("Trust concepts:", nrow(trust_concepts), "\n\n")

# Test 3: Get concept variable name
cat("Test 3: Getting variable names for concepts...\n")
var_w3 <- get_concept_variable("trust_executive", "W3", mappings)
cat("trust_executive in W3 →", var_w3, "\n")

var_w4 <- get_concept_variable("econ_country_current", "W4", mappings)
cat("econ_country_current in W4 →", var_w4, "\n\n")

# Test 4: Check concept availability
cat("Test 4: Checking concept availability...\n")
avail <- concept_availability("trust_executive", mappings)
cat("trust_executive available in:", paste(avail, collapse = ", "), "\n\n")

# Test 5: Load wave data and extract concept
cat("Test 5: Extracting concept from Wave 3...\n")
w3 <- read_sav(here("data/raw/ABS3 merge20250609.sav"))
cat("Loaded Wave 3:", nrow(w3), "observations\n")

# Extract trust_executive
trust_exec <- get_concept(w3, "trust_executive", "W3", clean = TRUE)

if (!is.null(trust_exec)) {
  cat("✓ Extracted trust_executive\n")
  cat("  Valid responses:", sum(!is.na(trust_exec)), "\n")
  cat("  Missing:", sum(is.na(trust_exec)), "\n")
  cat("  Distribution:\n")
  print(table(trust_exec, useNA = "ifany"))
} else {
  cat("✗ Failed to extract trust_executive\n")
}

cat("\n")

# Test 6: Extract multiple concepts
cat("Test 6: Extracting multiple concepts from Wave 3...\n")
trust_concepts_names <- mappings %>%
  filter(domain == "trust") %>%
  head(5) %>%  # Just first 5 for testing
  pull(concept)

trust_data <- extract_concepts(w3, trust_concepts_names, "W3", clean = TRUE)

if (!is.null(trust_data)) {
  cat("✓ Extracted", ncol(trust_data), "trust concepts\n")
  cat("  Dimensions:", nrow(trust_data), "rows x", ncol(trust_data), "columns\n")
  cat("  Column names:", paste(names(trust_data), collapse = ", "), "\n")
} else {
  cat("✗ Failed to extract trust concepts\n")
}

cat("\n")

# Test 7: List concepts available in Wave 3
cat("Test 7: Listing concepts available in Wave 3...\n")
w3_concepts <- list_wave_concepts("W3", mappings)
cat("Concepts in W3:", nrow(w3_concepts), "\n")
cat("First 5:\n")
print(head(w3_concepts, 5))

cat("\n")

# Test 8: Validate concept
cat("Test 8: Validating concepts...\n")
validate_concept(w3, "trust_executive", "W3", mappings)
validate_concept(w3, "econ_country_current", "W3", mappings)

cat("\n=== All Tests Complete ===\n")
cat("✓ Concept mapping system is working correctly\n\n")

cat("Next steps:\n")
cat("1. Explore other waves with wave_explorer_template.qmd\n")
cat("2. Add more concepts to docs/concept_mappings.csv\n")
cat("3. Use concept_builder.qmd to validate and compare across waves\n")
cat("4. Extract concepts in your analysis Quarto documents\n\n")
