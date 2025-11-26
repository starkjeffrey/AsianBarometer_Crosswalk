# Task Completion Checklist

## After Modifying R Code

### 1. Verify Script Runs
```r
# Test the modified script individually
source("scripts/XX_modified_script.R")
```

### 2. Check Data Integrity
```r
# Verify processed data loads correctly
data <- readRDS(here::here("data/processed/relevant_file.rds"))
str(data)
summary(data)
```

### 3. Validate Harmonization (if applicable)
```r
# Run validation script
source("scripts/verify_harmonization.R")
```

## After Adding New Variables to Crosswalk

### 1. Check Variable Exists in Codebook
```r
codebook <- readr::read_csv(here::here("docs/codebook.csv"))
codebook %>% filter(grepl("variable_name", variable))
```

### 2. Update Harmonization Functions
- Edit `functions/wave_harmonization.R` if scale reversal needed
- Add to concept mapping function

### 3. Regenerate Harmonized Data
```r
source("scripts/05_harmonize_waves.R")
```

### 4. Verify Results
```r
source("scripts/verify_harmonization.R")
# Check console output for directionality confirmation
```

## After Adding New Wave

### 1. Update Import Script
- Add path definition in `scripts/01_data_import.R`
- Add to `bind_rows()` section

### 2. Update Harmonization
- Add wave-specific logic in `functions/wave_harmonization.R`
- Update `harmonize_wave()` function

### 3. Run Full Pipeline
```r
source("scripts/99_run_all.R")
```

### 4. Update Crosswalk CSV
- Add wave column to `abs_harmonization_crosswalk.csv`

## File Locations to Update

| Change Type | Files to Update |
|-------------|-----------------|
| New variable | `02_data_cleaning.R`, `05_harmonize_waves.R`, crosswalk CSVs |
| New wave | `01_data_import.R`, `wave_harmonization.R`, `05_harmonize_waves.R` |
| New concept | `concept_functions.R`, `docs/harmonization_codebook.csv` |
| Scale changes | `wave_harmonization.R`, `docs/harmonization_codebook.csv` |

## Quality Checks

- [ ] No absolute paths used
- [ ] `here::here()` for all file paths
- [ ] Missing values handled correctly (0, 97, 98, 99)
- [ ] Harmonized variables have `_harm` suffix
- [ ] Cross-wave comparisons use `*_harm` variables only
- [ ] Documentation updated in `docs/`
