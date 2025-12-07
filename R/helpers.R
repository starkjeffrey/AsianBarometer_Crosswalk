# R/helpers.R

# --- Helper: Check Package Availability ---
# This ensures the function doesn't crash mid-way if a package is missing entirely.
ensure_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(paste0("Package '", pkg, "' is required for this function. Please install it."), call. = FALSE)
  }
}

print_var_info <- function(data, var) {
  # No external dependencies needed for this one, mostly base R
  if (!var %in% names(data)) {
    stop(paste("Variable", var, "not found in dataframe."))
  }

  cat("\n=== Variable:", var, "===\n")
  cat("Label:", attr(data[[var]], "label"), "\n")

  # Handle value labels safely
  lbls <- attr(data[[var]], "labels")
  if (!is.null(lbls)) {
    cat("Value labels:\n")
    print(lbls)
  } else {
    cat("Value labels: None\n")
  }

  cat("\nDistribution:\n")
  # base::table is fine, but lets ensure we don't print 1000 rows for continuous vars
  if (length(unique(data[[var]])) > 50) {
    cat(" (Variable has > 50 unique values. Showing summary statistics instead)\n")
    print(summary(data[[var]]))
  } else {
    print(table(data[[var]], useNA = "always"))
  }
  cat("\n")
}

summarise_by_country <- function(data, vars, country_var = "country_name") {
  ensure_pkg("dplyr")

  data %>%
    dplyr::group_by(.data[[country_var]]) %>%
    dplyr::summarise(
      n = dplyr::n(),
      dplyr::across(dplyr::all_of(vars),
                    list(mean = ~mean(., na.rm = TRUE),
                         sd = ~sd(., na.rm = TRUE),
                         n_valid = ~sum(!is.na(.))),
                    .names = "{.col}_{.fn}")
    )
}

check_distribution <- function(data, var, country_var = "country_name") {
  ensure_pkg("dplyr")

  data %>%
    dplyr::group_by(.data[[country_var]]) %>%
    dplyr::summarise(
      n = dplyr::n(),
      mean = mean(.data[[var]], na.rm=TRUE),
      sd = sd(.data[[var]], na.rm=TRUE),
      min = min(.data[[var]], na.rm=TRUE),
      max = max(.data[[var]], na.rm=TRUE),
      n_missing = sum(is.na(.data[[var]])),
      pct_missing = round(100 * n_missing / dplyr::n(), 1)
    )
}

safe_rowmeans <- function(..., na.rm = TRUE) {
  result <- rowMeans(..., na.rm = na.rm)
  ifelse(is.nan(result), NA_real_, result)
}

search_variables <- function(data, keyword, search_in = c("both", "name", "label")) {
  ensure_pkg("dplyr")
  ensure_pkg("purrr")
  ensure_pkg("tibble")

  search_in <- match.arg(search_in)

  # Get all variable info
  var_info <- tibble::tibble(
    variable = names(data),
    label = purrr::map_chr(data, ~{
      lbl <- attr(.x, "label")
      if(is.null(lbl)) return("")
      return(as.character(lbl))
    })
  )

  # Search based on preference
  results <- var_info %>%
    dplyr::filter(
      dplyr::case_when(
        search_in == "name" ~ grepl(keyword, variable, ignore.case = TRUE),
        search_in == "label" ~ grepl(keyword, label, ignore.case = TRUE),
        search_in == "both" ~ grepl(keyword, variable, ignore.case = TRUE) |
          grepl(keyword, label, ignore.case = TRUE)
      )
    )

  return(results)
}

search_across_waves <- function(keyword, file_vector, search_in = c("both", "name", "label")) {
  ensure_pkg("haven")
  ensure_pkg("purrr")
  ensure_pkg("dplyr")
  ensure_pkg("tibble")

  search_in <- match.arg(search_in)

  results <- purrr::map_dfr(file_vector, function(file) {
    # PERFORMANCE BOOST: n_max = 0 reads only metadata, not the whole dataset
    # This makes the search nearly instant even on massive .sav files
    wave_data <- haven::read_sav(file, n_max = 0)
    wave_name <- basename(file)

    var_info <- tibble::tibble(
      file = wave_name,
      variable = names(wave_data),
      label = purrr::map_chr(wave_data, ~{
        lbl <- attr(.x, "label")
        if(is.null(lbl)) return("")
        return(as.character(lbl))
      })
    )

    var_info %>%
      dplyr::filter(
        dplyr::case_when(
          search_in == "name" ~ grepl(keyword, variable, ignore.case = TRUE),
          search_in == "label" ~ grepl(keyword, label, ignore.case = TRUE),
          search_in == "both" ~ grepl(keyword, variable, ignore.case = TRUE) |
            grepl(keyword, label, ignore.case = TRUE)
        )
      )
  })

  return(results)
}

extract_matches <- function(search_term, file_vector, print_output = TRUE) {
  ensure_pkg("haven")
  ensure_pkg("labelled")
  ensure_pkg("purrr")
  ensure_pkg("dplyr")
  ensure_pkg("tibble")

  results <- purrr::map_dfr(file_vector, function(file) {
    # n_max = 0 reads only metadata for performance
    wave_data <- haven::read_sav(file, n_max = 0)
    wave_name <- basename(file)

    var_names <- names(wave_data)

    purrr::map_dfr(var_names, function(var) {
      label <- labelled::var_label(wave_data[[var]])
      label_text <- ifelse(is.null(label), "", as.character(label))

      # Check match in variable name or label
      is_match <- grepl(search_term, var, ignore.case = TRUE) ||
        grepl(search_term, label_text, ignore.case = TRUE)

      if (is_match) {
        val_labels <- labelled::val_labels(wave_data[[var]])

        # Store values as list for flexible output
        if (!is.null(val_labels)) {
          values_list <- paste0(val_labels, " = ", names(val_labels))
        } else {
          values_list <- "[No value labels]"
        }

        tibble::tibble(
          file = wave_name,
          variable = var,
          label = label_text,
          values = list(values_list)
        )
      } else {
        NULL
      }
    })
  })

  # Print formatted output
  if (print_output && nrow(results) > 0) {
    cat("\n")
    cat(strrep("=", 60), "\n")
    cat("Search results for:", search_term, "\n")
    cat("Matches found:", nrow(results), "\n")
    cat(strrep("=", 60), "\n\n")

    for (i in seq_len(nrow(results))) {
      row <- results[i, ]
      cat("File:     ", row$file, "\n")
      cat("Variable: ", row$variable, "\n")
      cat("Label:    ", row$label, "\n")
      cat("Values:\n")
      for (v in row$values[[1]]) {
        cat("          ", v, "\n")
      }
      cat(strrep("-", 40), "\n")
    }
  }

  invisible(results)
}
