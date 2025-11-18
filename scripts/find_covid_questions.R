# ==============================================================================
# Find COVID-related questions in Wave 6
# ==============================================================================

library(haven)
library(dplyr)
library(here)

cat("\n=== Finding COVID Questions in Wave 6 ===\n\n")

# Load Wave 6 (Cambodia-only)
w6 <- read_sav(here("data/raw/W6_Cambodia_Release_20240819.sav"))

cat("Wave 6 loaded:", nrow(w6), "observations,", ncol(w6), "variables\n\n")

# Get all variable labels
var_labels <- sapply(w6, function(x) {
  label <- attr(x, "label")
  if (is.null(label)) "" else label
})

# Search for COVID-related terms
covid_patterns <- c("covid", "coronavirus", "pandemic", "virus", "lockdown",
                    "quarantine", "vaccine", "mask")

covid_vars <- c()
for (pattern in covid_patterns) {
  matches <- grepl(pattern, var_labels, ignore.case = TRUE)
  if (any(matches)) {
    covid_vars <- c(covid_vars, names(var_labels)[matches])
  }
}

covid_vars <- unique(covid_vars)

if (length(covid_vars) == 0) {
  cat("No variables found with explicit COVID terms.\n")
  cat("Let me check variable ranges that might contain COVID questions...\n\n")

  # Wave 6 often has special sections - check higher question numbers
  all_vars <- names(w6)[grepl("^q", names(w6), ignore.case = TRUE)]

  cat("Total question variables:", length(all_vars), "\n")
  cat("Question range:", min(all_vars), "to", max(all_vars), "\n\n")

  # Show last 30 question variables with labels
  cat("Last 30 question variables (often where wave-specific questions are):\n")
  last_qs <- tail(all_vars[order(all_vars)], 30)

  for (q in last_qs) {
    label <- var_labels[q]
    if (label != "") {
      cat(sprintf("%-10s: %s\n", q, substr(label, 1, 80)))
    }
  }

} else {
  cat("Found", length(covid_vars), "COVID-related variables:\n\n")

  for (var in covid_vars) {
    label <- var_labels[var]
    cat("==================================================\n")
    cat("Variable:", var, "\n")
    cat("Label:", label, "\n")

    # Get value labels
    val_labs <- attr(w6[[var]], "labels")
    if (!is.null(val_labs) && length(val_labs) > 0) {
      cat("\nValue labels:\n")
      for (i in 1:length(val_labs)) {
        cat(sprintf("  %2d = %s\n", val_labs[i], names(val_labs)[i]))
      }
    }

    # Show distribution
    cat("\nDistribution:\n")
    print(table(w6[[var]], useNA = "ifany"))
    cat("\n")
  }
}

cat("\n=== Search Complete ===\n")
