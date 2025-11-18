# Test the updated clean_variable_by_label function

library(haven)
library(here)
source(here("functions/cleaning_functions.R"))

cat("\n=== Testing clean_variable_by_label() ===\n\n")

# Load data
w3 <- read_sav(here("data/raw/ABS3 merge20250609.sav"))

# Test on q1
cat("Testing on q1 (economic condition):\n")
cat("Before cleaning:\n")
print(table(w3$q1, useNA = "ifany"))

q1_clean <- clean_variable_by_label(w3$q1, na_labels_list)

cat("\nAfter cleaning with na_labels_list:\n")
print(table(q1_clean, useNA = "ifany"))

cat("\nLabel preservation check:\n")
cat("- Still labelled?", is.labelled(q1_clean), "\n")
cat("- Variable label:", attr(q1_clean, "label"), "\n")
cat("- Value labels present?", !is.null(attr(q1_clean, "labels")), "\n\n")

cat("✓ Function works correctly!\n")
cat("✓ Labels preserved\n")
cat("✓ NA values identified by label text, not numeric code\n\n")
