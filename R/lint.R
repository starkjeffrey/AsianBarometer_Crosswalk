#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(lintr))

cat("\n=== Linting R/ directory ===\n")
lints_r <- lintr::lint_dir("R")
print(lints_r)

cat("\n=== Linting Quarto/Rmd files ===\n")
qmd_files <- list.files(path = ".", pattern = "\\.(qmd|Rmd)$", recursive = TRUE, full.names = TRUE)
if (length(qmd_files) == 0) {
  cat("No Quarto/Rmd files found.\n")
  lints_qmd <- list()
} else {
  lints_qmd <- unlist(lapply(qmd_files, lintr::lint), recursive = FALSE)
  print(lints_qmd)
}

exit_status <- if ((length(lints_r) + length(lints_qmd)) > 0) 1 else 0
cat(sprintf("\nLintr found %d issues.\n", length(lints_r) + length(lints_qmd)))

if (interactive()) {
  invisible(NULL)
} else {
  quit(save = "no", status = exit_status)
}

