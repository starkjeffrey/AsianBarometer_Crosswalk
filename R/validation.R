# R/validation.R
# Validation functions

check_unexpected_values <- function(data, vars, expected) {
  issues_found <- FALSE

  for (var in vars) {
    if (!var %in% names(data)) {
      cat("❌ Variable", var, "not found\n")
      issues_found <- TRUE
      next
    }

    unexpected <- data %>%
      dplyr::filter(!.data[[var]] %in% c(expected, NA))

    if (nrow(unexpected) > 0) {
      cat("⚠️ ", var, ":", nrow(unexpected), "unexpected values\n")
      issues_found <- TRUE
    }
  }

  if (!issues_found) {
    cat("✓ All variables have expected values\n")
  }

  invisible(!issues_found)
}

verify_reversal <- function(original, recoded) {
  cor_val <- suppressWarnings(cor(original, recoded, use = "complete.obs"))

  if (is.na(cor_val)) {
    cat("⚠️ Cannot compute correlation (insufficient data)\n")
    return(FALSE)
  }

  if (cor_val < -0.99) {
    cat("✓ Reversal correct (r =", round(cor_val, 3), ")\n")
    return(TRUE)
  } else {
    cat("❌ ERROR: Reversal incorrect (r =", round(cor_val, 3), ")\n")
    return(FALSE)
  }
}

create_verification_table <- function(data, original_vars, recoded_vars) {
  result <- tibble::tibble(
    original = original_vars,
    recoded = recoded_vars
  ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      correlation = suppressWarnings(cor(data[[original]], data[[recoded]],
                                         use = "complete.obs")),
      n_valid = sum(!is.na(data[[original]])),
      reversal_ok = correlation < -0.99
    ) %>%
    dplyr::ungroup()

  invisible(result)
}

verify_no_invalid_codes <- function(data, vars, valid_range) {
  data %>%
    dplyr::select(dplyr::all_of(vars)) %>%
    dplyr::summarise(
      dplyr::across(
        dplyr::everything(),
        ~sum(. < valid_range[1] | . > valid_range[2], na.rm = TRUE)
      )
    ) %>%
    tidyr::pivot_longer(dplyr::everything()) %>%
    dplyr::filter(value > 0)
}

message("✓ Loaded validation functions")