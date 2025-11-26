# R/recoding.R
# Recoding functions for Asian Barometer analysis

safe_reverse_3pt <- function(x, missing_codes = c(-1, 0, 7, 8, 9)) {
  dplyr::case_when(
    x %in% 1:3 ~ 4 - x,
    x %in% missing_codes ~ NA_real_,
    TRUE ~ NA_real_
  )
}

safe_reverse_4pt <- function(x, missing_codes = c(-1, 0, 7, 8, 9)) {
  dplyr::case_when(
    x %in% 1:4 ~ 5 - x,
    x %in% missing_codes ~ NA_real_,
    TRUE ~ NA_real_
  )
}

safe_reverse_5pt <- function(x, missing_codes = c(-1, 0, 7, 8, 9)) {
  dplyr::case_when(
    x %in% 1:5 ~ 6 - x,
    x %in% missing_codes ~ NA_real_,
    TRUE ~ NA_real_
  )
}

cat("✓ Loaded recoding functions\n")
