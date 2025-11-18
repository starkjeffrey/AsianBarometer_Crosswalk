# ==============================================================================
# Test script: The CORRECT way to handle NAs while preserving labels
# ==============================================================================

library(haven)
library(dplyr)
library(here)

cat("\n=== Label Preservation: The Right Way ===\n\n")

# Load Wave 3
w3 <- read_sav(here("data/raw/ABS3 merge20250609.sav"))
test_var <- "q1"

cat("Original variable:\n")
cat("- Variable label:", attr(w3[[test_var]], "label"), "\n")
cat("- Value labels present:", !is.null(attr(w3[[test_var]], "labels")), "\n")
cat("- -1 is labeled as:", names(attr(w3[[test_var]], "labels"))[attr(w3[[test_var]], "labels") == -1], "\n\n")

# THE SOLUTION: Use as_factor() to work with labels, then recode
cat("=== SOLUTION 1: Convert to factor, work with labels ===\n")
test_factor <- as_factor(w3[[test_var]])
cat("After as_factor():\n")
cat("- Class:", class(test_factor), "\n")
cat("- Levels:", paste(head(levels(test_factor), 10), collapse = ", "), "\n")
cat("- 'Missing' is now a factor level that can be set to NA\n")

# Replace factor level "Missing" with NA
test_clean_factor <- test_factor
test_clean_factor[test_clean_factor == "Missing"] <- NA
cat("\nAfter setting 'Missing' to NA:\n")
print(table(test_clean_factor, useNA = "ifany"))

cat("\n=== SOLUTION 2: Keep as labelled, replace by value ===\n")
# This preserves the labelled class but converts specific values to NA
test_clean_labelled <- w3[[test_var]]

# Replace -1 with NA (using base R)
test_clean_labelled[test_clean_labelled == -1] <- NA

cat("After replacing -1 with NA:\n")
cat("- Still labelled?", is.labelled(test_clean_labelled), "\n")
cat("- Variable label preserved?", !is.null(attr(test_clean_labelled, "label")), "\n")
cat("- Value labels preserved?", !is.null(attr(test_clean_labelled, "labels")), "\n")
cat("\nValue counts:\n")
print(table(test_clean_labelled, useNA = "ifany"))

cat("\n=== SOLUTION 3: Work with labels using your na_labels_list ===\n")
# Function to find values that have labels in na_labels_list
find_na_values_by_label <- function(x, na_label_patterns) {
  if (!is.labelled(x)) return(NULL)

  val_labs <- attr(x, "labels")
  lab_names <- names(val_labs)

  # Find which labels match our NA patterns
  matching <- lab_names %in% na_label_patterns

  # Return the VALUES (not labels) that should be NA
  return(val_labs[matching])
}

# Test it
na_labels_to_find <- c("Missing", "Don't know", "Can't choose",
                       "Decline to answer", "Do not understand the question")

na_vals <- find_na_values_by_label(w3[[test_var]], na_labels_to_find)
cat("Values to convert to NA based on labels:\n")
print(na_vals)

# Apply it
test_clean_by_label <- w3[[test_var]]
for (val in na_vals) {
  test_clean_by_label[test_clean_by_label == val] <- NA
}

cat("\nAfter converting label-based NAs:\n")
print(table(test_clean_by_label, useNA = "ifany"))

cat("\n=== KEY INSIGHTS ===\n")
cat("1. haven_labelled variables preserve labels even after subsetting\n")
cat("2. Use x[x == value] <- NA to replace specific values\n")
cat("3. Labels remain intact for documentation and interpretation\n")
cat("4. Can work with either numeric codes OR label text\n")
cat("5. NEVER use dplyr::na_if() - it strips the labelled class\n\n")
