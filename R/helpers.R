# R/helpers.R

print_var_info <- function(data, var) {
  cat("\n=== Variable:", var, "===\n")
  cat("Label:", attr(data[[var]], "label"), "\n")
  cat("Value labels:\n")
  print(attr(data[[var]], "labels"))
  cat("\nDistribution:\n")
  print(table(data[[var]], useNA = "always"))
  cat("\n")
}

summarise_by_country <- function(data, vars, country_var = "country_name") {
  data %>%
    group_by(.data[[country_var]]) %>%
    summarise(
      n = n(),
      across(all_of(vars),
             list(mean = ~mean(., na.rm = TRUE),
                  sd = ~sd(., na.rm = TRUE),
                  n_valid = ~sum(!is.na(.))),
             .names = "{.col}_{.fn}")
    )
}

# Create a function for the repeated pattern of checking distributions
check_distribution <- function(data, var, country_var = "country_name") {
  data %>%
    group_by(.data[[country_var]]) %>%
    summarise(
      n = n(),
      mean = mean(.data[[var]], na.rm=TRUE),
      sd = sd(.data[[var]], na.rm=TRUE),
      min = min(.data[[var]], na.rm=TRUE),
      max = max(.data[[var]], na.rm=TRUE),
      n_missing = sum(is.na(.data[[var]])),
      pct_missing = round(100 * n_missing / n(), 1)
    )
}

# Safe rowMeans that converts NaN to NA
safe_rowmeans <- function(..., na.rm = TRUE) {
  result <- rowMeans(..., na.rm = na.rm)
  ifelse(is.nan(result), NA_real_, result)
}

# Search_variables searches for variables by keyword
search_variables <- function(data, keyword, search_in = c("both", "name", "label")) {
  search_in <- match.arg(search_in)
  
  # Get all variable info
  var_info <- tibble(
    variable = names(data),
    label = map_chr(data, ~{
      lbl <- attr(.x, "label")
      if(is.null(lbl)) return("")
      return(lbl)
    })
  )
  
  # Search based on preference
  results <- var_info %>%
    filter(
      case_when(
        search_in == "name" ~ grepl(keyword, variable, ignore.case = TRUE),
        search_in == "label" ~ grepl(keyword, label, ignore.case = TRUE),
        search_in == "both" ~ grepl(keyword, variable, ignore.case = TRUE) | 
          grepl(keyword, label, ignore.case = TRUE)
      )
    )
  
  return(results)
}

# Usage:
# search_variables(data, "ethnic")
# search_variables(data, "trust")

search_across_waves <- function(keyword, file_vector, search_in = c("both", "name", "label")) {
  
  library(haven)  # for reading .sav files
  search_in <- match.arg(search_in)
  
  results <- map_dfr(file_vector, function(file) {
    # Load wave
    wave_data <- read_sav(file)
    wave_name <- basename(file)
    
    # Get variable info
    var_info <- tibble(
      file = wave_name,
      variable = names(wave_data),
      label = map_chr(wave_data, ~{
        lbl <- attr(.x, "label")
        if(is.null(lbl)) return("")
        return(lbl)
      })
    )
    
    # Search based on preference
    var_info <- var_info %>%
      filter(
        case_when(
          search_in == "name" ~ grepl(keyword, variable, ignore.case = TRUE),
          search_in == "label" ~ grepl(keyword, label, ignore.case = TRUE),
          search_in == "both" ~ grepl(keyword, variable, ignore.case = TRUE) | 
            grepl(keyword, label, ignore.case = TRUE)
        )
      )
    
    return(var_info)
  })
  
  return(results)
}

# Search for "ethnic" across all wave files
# ethnic_results <- search_across_waves("ethnic", wave_files)

# View results
# ethnic_results

