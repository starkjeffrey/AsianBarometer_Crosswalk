# ==============================================================================
# run_crosswalk_extension_pipeline.R
# Master script to run the complete crosswalk extension pipeline from R
#
# This orchestrates:
#   1. Variable inventory creation
#   2. Fuzzy label matching (R)
#   3. NLP-based semantic matching (Python)
#   4. Intelligent crosswalk expansion
#
# Usage: source("scripts/run_crosswalk_extension_pipeline.R")
# ==============================================================================

cat("\n")
cat("======================================================================\n")
cat("         CROSSWALK EXTENSION PIPELINE - MASTER CONTROLLER\n")
cat("======================================================================\n\n")

# Load required packages
library(here)

# Configuration
config <- list(
  skip_inventory = FALSE,    # Set TRUE to skip inventory if already exists
  run_python_nlp = TRUE,     # Set FALSE to skip Python NLP step
  python_cmd = "python3",    # Python command (python3 or python)
  install_python_deps = FALSE # Set TRUE to install Python deps first
)

# Check for existing inventory
if (file.exists(here("docs/q_variables_by_wave.csv"))) {
  cat("Existing variable inventory found.\n")
  cat("Set config$skip_inventory <- TRUE to skip recreation.\n\n")
}

# Helper function to run script with error handling
run_script <- function(script_path, script_name) {
  cat("\n")
  cat("------------------------------------------------------------------\n")
  cat(paste0("Running: ", script_name, "\n"))
  cat("------------------------------------------------------------------\n")

  tryCatch({
    source(script_path)
    cat(paste0("\n[SUCCESS] ", script_name, " completed.\n"))
    return(TRUE)
  }, error = function(e) {
    cat(paste0("\n[ERROR] ", script_name, " failed: ", e$message, "\n"))
    return(FALSE)
  })
}

# Helper function to run Python script
run_python <- function(script_path, script_name) {
  cat("\n")
  cat("------------------------------------------------------------------\n")
  cat(paste0("Running: ", script_name, " (Python)\n"))
  cat("------------------------------------------------------------------\n")

  # Check if Python is available
  python_check <- system2(config$python_cmd, "--version", stdout = TRUE, stderr = TRUE)
  if (length(python_check) == 0 || !grepl("Python", python_check[1])) {
    cat("[WARNING] Python not found. Skipping NLP step.\n")
    cat("Install Python 3 to enable NLP-based matching.\n")
    return(FALSE)
  }

  # Check if NLP dependencies are installed
  dep_check <- system2(
    config$python_cmd,
    c("-c", "import sentence_transformers"),
    stdout = TRUE, stderr = TRUE
  )

  if (length(dep_check) > 0 && grepl("ModuleNotFoundError", paste(dep_check, collapse = ""))) {
    cat("[WARNING] Python NLP dependencies not installed.\n")

    if (config$install_python_deps) {
      cat("Installing dependencies...\n")
      system2("pip", c("install", "-r", here("requirements.txt")))
    } else {
      cat("Run: pip install -r requirements.txt\n")
      cat("Or set config$install_python_deps <- TRUE\n")
      return(FALSE)
    }
  }

  # Run the Python script
  result <- system2(
    config$python_cmd,
    script_path,
    stdout = TRUE, stderr = TRUE
  )

  # Print output
  cat(paste(result, collapse = "\n"))
  cat("\n")

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    cat(paste0("[ERROR] ", script_name, " failed.\n"))
    return(FALSE)
  }

  cat(paste0("[SUCCESS] ", script_name, " completed.\n"))
  return(TRUE)
}

# ==============================================================================
# Pipeline execution
# ==============================================================================

pipeline_start <- Sys.time()
results <- list()

# Step 1: Create Variable Inventory
cat("\n")
cat("======================================================================\n")
cat("STEP 1/4: VARIABLE INVENTORY\n")
cat("======================================================================\n")

if (config$skip_inventory && file.exists(here("docs/q_variables_by_wave.csv"))) {
  cat("Skipping inventory (already exists and skip_inventory = TRUE)\n")
  results$inventory <- TRUE
} else {
  results$inventory <- run_script(
    here("scripts/00_create_variable_inventory.R"),
    "Variable Inventory Creation"
  )
}

# Check if inventory exists before proceeding
if (!file.exists(here("docs/q_variables_by_wave.csv"))) {
  stop("Variable inventory not found. Cannot continue without docs/q_variables_by_wave.csv")
}

# Step 2: Fuzzy Label Matching (R)
cat("\n")
cat("======================================================================\n")
cat("STEP 2/4: FUZZY LABEL MATCHING (R)\n")
cat("======================================================================\n")

results$fuzzy <- run_script(
  here("scripts/01_fuzzy_label_matching.R"),
  "Fuzzy Label Matching"
)

# Step 3: NLP-Based Semantic Matching (Python)
cat("\n")
cat("======================================================================\n")
cat("STEP 3/4: NLP-BASED SEMANTIC MATCHING (Python)\n")
cat("======================================================================\n")

if (config$run_python_nlp) {
  results$nlp <- run_python(
    here("scripts/02_advanced_nlp_matching.py"),
    "Advanced NLP Matching"
  )
} else {
  cat("Skipping NLP step (run_python_nlp = FALSE)\n")
  results$nlp <- NA
}

# Step 4: Intelligent Crosswalk Expansion
cat("\n")
cat("======================================================================\n")
cat("STEP 4/4: INTELLIGENT CROSSWALK EXPANSION\n")
cat("======================================================================\n")

# Only run if we have the required input files
required_files <- c(
  here("abs_harmonization_crosswalk.csv"),
  here("docs/high_similarity_pairs.csv"),
  here("docs/crosswalk_expanded_automated.csv")
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  cat("[WARNING] Missing required files:\n")
  cat(paste("  -", missing_files, collapse = "\n"))
  cat("\n\nSkipping crosswalk expansion step.\n")
  results$expansion <- FALSE
} else {
  # Check if NLP file exists (optional but useful)
  if (!file.exists(here("docs/crosswalk_nlp_enhanced.csv"))) {
    cat("[INFO] NLP-enhanced crosswalk not found. Expansion will proceed without NLP data.\n")
  }

  results$expansion <- run_script(
    here("scripts/03_expand_crosswalk_intelligently.R"),
    "Intelligent Crosswalk Expansion"
  )
}

# ==============================================================================
# Summary
# ==============================================================================

pipeline_end <- Sys.time()
duration <- round(difftime(pipeline_end, pipeline_start, units = "mins"), 2)

cat("\n")
cat("======================================================================\n")
cat("                    PIPELINE EXECUTION SUMMARY\n")
cat("======================================================================\n\n")

cat("Step Results:\n")
cat(paste0("  1. Variable Inventory:     ", ifelse(results$inventory, "SUCCESS", "FAILED"), "\n"))
cat(paste0("  2. Fuzzy Matching (R):     ", ifelse(results$fuzzy, "SUCCESS", "FAILED"), "\n"))
cat(paste0("  3. NLP Matching (Python):  ",
           ifelse(is.na(results$nlp), "SKIPPED",
                  ifelse(results$nlp, "SUCCESS", "FAILED")), "\n"))
cat(paste0("  4. Crosswalk Expansion:    ", ifelse(results$expansion, "SUCCESS", "FAILED"), "\n"))

cat(paste0("\nTotal duration: ", duration, " minutes\n"))

# List generated files
cat("\nGenerated/Updated Files:\n")
output_files <- c(
  "docs/q_variables_by_wave.csv",
  "docs/high_similarity_pairs.csv",
  "docs/concept_clusters.csv",
  "docs/crosswalk_expanded_automated.csv",
  "docs/crosswalk_nlp_enhanced.csv",
  "docs/semantic_similarity_pairs.csv",
  "abs_harmonization_crosswalk_EXPANDED.csv"
)

for (f in output_files) {
  if (file.exists(here(f))) {
    info <- file.info(here(f))
    cat(paste0("  [OK] ", f, " (", format(info$size, big.mark = ","), " bytes)\n"))
  }
}

cat("\n")
cat("======================================================================\n")
cat("                         NEXT STEPS\n")
cat("======================================================================\n")
cat("
1. Review generated files in docs/
2. Validate high_similarity_pairs.csv for accuracy
3. Check concept_clusters.csv for proper groupings
4. Merge approved concepts into abs_harmonization_crosswalk_MASTER.csv
5. Run scale detection: source('scripts/05_detect_scale_types.R')
6. Verify harmonization: source('scripts/verify_harmonization.R')
")

cat("\nPipeline complete!\n\n")
