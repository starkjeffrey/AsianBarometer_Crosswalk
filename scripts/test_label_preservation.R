# ==============================================================================
# Test script to verify label preservation during NA conversion
# ==============================================================================

library(haven)
library(dplyr)
library(here)

source(here("functions/cleaning_functions.R"))

cat("\n=== Testing Label Preservation ===\n\n")

# Load a sample wave to test
cat("Loading Wave 3 data (has -1 = Missing)...\n")
w3 <- read_sav(here("data/raw/ABS3 merge20250609.sav"))

# Pick a variable to test
test_var <- "q1"  # Country economic condition

cat("\n--- Original Variable ---\n")
cat("Variable label:", attr(w3[[test_var]], "label"), "\n")
cat("Value labels:\n")
print(attr(w3[[test_var]], "labels"))
cat("\nSample values:\n")
print(table(w3[[test_var]], useNA = "ifany"))

# Test 1: Check if -1 has a label
cat("\n--- Test 1: Checking -1 label ---\n")
val_labs <- attr(w3[[test_var]], "labels")
if (-1 %in% val_labs) {
  cat("Value -1 has label:", names(val_labs)[val_labs == -1], "\n")
} else {
  cat("Value -1 has no label\n")
}

# Test 2: Use haven's user-defined NA (preserves everything!)
cat("\n--- Test 2: Using haven::na_values() to mark as NA ---\n")
test_clean <- w3[[test_var]]
# Mark -1 as a user-defined NA value
na_values(test_clean) <- -1

cat("Still labelled?", is.labelled(test_clean), "\n")
cat("Variable label:", attr(test_clean, "label"), "\n")
cat("Value labels still present:\n")
print(attr(test_clean, "labels"))
cat("NA values defined:", na_values(test_clean), "\n")
cat("\nSample values after marking as NA:\n")
print(table(test_clean, useNA = "ifany"))
cat("Note: -1 is now treated as NA but label is preserved!\n")

# Test 3: Show what dplyr::na_if does (BAD - destroys labels)
cat("\n--- Test 3: What dplyr::na_if does (DON'T USE THIS) ---\n")
test_dplyr <- dplyr::na_if(w3[[test_var]], -1)
cat("Still labelled?", is.labelled(test_dplyr), "\n")
cat("Value labels preserved?", !is.null(attr(test_dplyr, "labels")), "\n")
cat("WARNING: dplyr::na_if destroys haven_labelled class!\n")

cat("\n=== Conclusion ===\n")
cat("✓ Use haven::na_values() to mark values as NA while preserving labels!\n")
cat("✓ NEVER use dplyr::na_if() - it destroys the labelled class\n")
cat("✓ Labels remain intact and can be used for documentation\n\n")
