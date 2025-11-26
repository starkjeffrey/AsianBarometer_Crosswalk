# Code Style & Conventions

## R Coding Style

### Path Management
- **ALWAYS** use `here::here()` for all file paths
- **NEVER** use absolute paths or `setwd()`
- Must open `AsianBarometer.Rproj` for `here()` to work correctly

### Naming Conventions
- SPSS variable names standardized with `janitor::clean_names()` (lowercase, underscores)
- Cleaned variables get `_clean` suffix (e.g., `q1 → q1_clean`)
- Harmonized variables get `_harm` suffix (e.g., `q1 → q1_harm`)
- Concept names use snake_case (e.g., `trust_executive`, `econ_country_current`)

### Script Numbering Convention
```
scripts/
├── 00_*.R    # Setup scripts (run once)
├── 01_*.R    # Data import
├── 02_*.R    # Data cleaning
├── 03_*.R    # Analysis/processing
├── 04_*.R    # Visualization
├── 05_*.R    # Harmonization
├── 06_*.R    # Additional processing
├── 99_*.R    # Master pipeline scripts
└── verify_*.R, test_*.R  # Validation scripts
```

### Missing Value Handling
Asian Barometer standard missing codes:
- `0`: Not applicable / Skip
- `97`: Not applicable
- `98`: Don't know
- `99`: Refuse to answer / Missing

Clean using label-based approach when possible (see `functions/cleaning_functions.R`)

### Variable Suffixes
- `_clean`: Missing values recoded to NA
- `_harm`: Scale-harmonized for cross-wave comparison
- Concept names (e.g., `trust_executive`): Semantic standardized names

### Wave Identification
- Each observation tagged with `wave` column (Wave2, Wave3, Wave4, Wave5, Wave6)
- Cambodia country code: 12 (filter with `country == 12` or `COUNTRY == 12` for W5)
- Wave 6 is Cambodia-only file, no country filter needed

### Data Flow Pattern
1. Raw data in `data/raw/` - NEVER modify
2. Processed data in `data/processed/` as .rds files
3. Documentation in `docs/` as CSV/MD files
4. Outputs in `output/figures/` and `output/tables/`

### Function Documentation
Use roxygen2-style comments:
```r
#' Brief description
#'
#' @param x Parameter description
#' @return Return value description
#' @examples
#' function_example()
```

### haven_labelled Handling
For Quarto/plotting with haven_labelled data:
```r
# Use haven::zap_labels() or as.numeric() before pivot_longer()
data %>%
  mutate(var = as.numeric(var)) %>%
  pivot_longer(...)
```
