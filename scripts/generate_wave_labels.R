# Extract variable labels from Asian Barometer SPSS files
# Processes multiple waves and saves labels to separate text files

# Load required libraries
library(haven)
library(here)

# Define wave files and their output names
wave_files <- list(
  W1 = "Wave1_20170906.sav",
  W2 = "Wave2_20250609.sav",
  W3 = "ABS3 merge20250609.sav",
  W4 = "W4_v15_merged20250609_release.sav",
  W5 = "20230505_W5_merge_15.sav",
  W6_Cambodia = "W6_Cambodia_Release_20240819.sav"
)

# Function to extract all labels from a SPSS file
extract_labels <- function(file_path, wave_name) {

  cat(paste("\nProcessing", wave_name, "...\n"))

  # Read the SPSS file
  df <- read_sav(file_path)

  # Extract labels for all variables
  all_labels <- lapply(names(df), function(var_name) {

    # Get the column
    variable <- df[[var_name]]

    # Extract attributes
    var_label <- attr(variable, "label")
    val_labels <- attr(variable, "labels")

    # Return a list of the labels for this variable
    list(
      variable = var_name,
      variable_label = ifelse(is.null(var_label), "N/A", var_label),
      value_labels = val_labels
    )
  })

  return(all_labels)
}

# Function to save labels to text file
save_labels_to_file <- function(all_labels, output_path, wave_name) {

  # Open connection to output file
  sink(output_path)

  cat(paste("===================================================\n"))
  cat(paste("Variable Labels and Value Labels for", wave_name, "\n"))
  cat(paste("Generated:", Sys.time(), "\n"))
  cat(paste("===================================================\n\n"))

  # Print the extracted labels
  for (item in all_labels) {
    cat(paste("\nVariable:", item$variable, "\n"))
    cat(paste("  Question:", item$variable_label, "\n"))
    if (!is.null(item$value_labels)) {
      cat("  Value Labels:\n")
      for (name in names(item$value_labels)) {
        cat(paste("    ", item$value_labels[name], "=", name, "\n"))
      }
    }
  }

  # Close the file connection
  sink()

  cat(paste("  Saved to:", output_path, "\n"))
}

# Main processing loop
cat("\n=== Starting Label Extraction ===\n")

for (wave_name in names(wave_files)) {

  # Construct file path
  file_path <- here("data/raw", wave_files[[wave_name]])

  # Check if file exists
  if (!file.exists(file_path)) {
    cat(paste("WARNING: File not found:", wave_files[[wave_name]], "\n"))
    next
  }

  # Extract labels
  labels <- extract_labels(file_path, wave_name)

  # Construct output path
  output_path <- here("docs", paste0(wave_name, "_labels.txt"))

  # Save to file
  save_labels_to_file(labels, output_path, wave_name)
}

cat("\n=== Label Extraction Complete ===\n")
cat(paste("Output files saved in:", here("docs"), "\n\n"))
