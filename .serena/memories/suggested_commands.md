# Suggested Commands

## Essential Setup
```bash
# Must open RStudio project first for here() to work
open AsianBarometer.Rproj
```

## R Commands (run in RStudio console)

### Initial Setup (run once)
```r
source("scripts/00_setup.R")  # Install all required packages
```

### Full Analysis Pipeline
```r
source("scripts/99_run_all.R")  # Run complete pipeline
```

### Individual Pipeline Steps
```r
source("scripts/01_data_import.R")       # Load SPSS files, filter Cambodia
source("scripts/02_data_cleaning.R")     # Clean survey variables
source("scripts/03_analysis.R")          # Statistical analysis
source("scripts/04_visualization.R")     # Generate plots
source("scripts/05_harmonize_waves.R")   # Cross-wave harmonization
```

### Verification & Testing
```r
source("scripts/verify_harmonization.R")        # Validate harmonization
source("scripts/05_trust_scale_comparison.R")   # Compare 4-pt vs 6-pt scales
source("scripts/05_detect_scale_types.R")       # Detect scale types
```

### Interactive Exploration
```r
# Render Quarto dashboards
quarto::quarto_render("trust_explorer.qmd")
quarto::quarto_render("wave_explorer_template.qmd")
quarto::quarto_render("concept_builder.qmd")
```

### Load Processed Data
```r
# Clean data (not harmonized)
cambodia_all <- readRDS(here::here("data/processed/cambodia_all_waves_clean.rds"))

# Harmonized data (for cross-wave analysis)
cambodia_harm <- readRDS(here::here("data/processed/cambodia_all_waves_harmonized.rds"))

# Wave-specific harmonized
w2 <- readRDS(here::here("data/processed/w2_cambodia_harmonized.rds"))
w6 <- readRDS(here::here("data/processed/w6_cambodia_harmonized.rds"))
```

### View Documentation
```r
# Codebook
codebook <- readr::read_csv(here::here("docs/codebook.csv"))

# Harmonization mappings
harm_codebook <- readr::read_csv(here::here("docs/harmonization_codebook.csv"))

# Main crosswalk
crosswalk <- readr::read_csv("abs_harmonization_crosswalk.csv")
```

### Test Helper Functions
```r
source("functions/cleaning_functions.R")
source("functions/wave_harmonization.R")
source("functions/concept_functions.R")

# Test cleaning
clean_variable(c(1, 2, 97, 98, 3, 0))
```

## System Commands (Darwin/macOS)
```bash
# Navigate project
cd /Users/jeffreystark/Development/key/AsianBarometer_Crosswalk

# View structure
ls -la scripts/
ls -la functions/
ls -la data/processed/

# Search for patterns
grep -r "harmonize" scripts/
grep -r "crosswalk" docs/
```
