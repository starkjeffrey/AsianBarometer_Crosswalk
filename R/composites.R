# R/composites.R

#' Create standardized composite from multiple scales
#'
#' @param data Data frame
#' @param vars Character vector of variable names
#' @param min_items Minimum number of non-missing items required
#' @return Standardized composite score (z-score)
create_composite <- function(data, vars, min_items = NULL) {
  if (is.null(min_items)) {
    min_items <- length(vars)
  }
  
  # Standardize each variable
  data_std <- data %>%
    mutate(across(all_of(vars), 
                  ~scale(.)[,1], 
                  .names = "{.col}_std"))
  
  # Calculate composite
  composite_vector <- data_std %>%
    mutate(
      composite = rowMeans(
        select(., ends_with("_std")),
        na.rm = TRUE
      ),
      n_items = rowSums(!is.na(select(., all_of(vars)))),
      composite = if_else(n_items >= min_items, composite, NA_real_)
    ) %>%
    pull(composite)
  
  # Final step to standardize the composite itself
  return(scale(composite_vector)[,1])
}

create_binary_composite <- function(data, vars, threshold = 0.5) {
  composite <- rowMeans(select(data, all_of(vars)), na.rm = TRUE)
  if_else(composite >= threshold, 1, 0)
}

create_count_composite <- function(data, vars) {
  rowSums(select(data, all_of(vars)), na.rm = FALSE)
}