# Codebase Structure

```
AsianBarometer_Crosswalk/
├── AsianBarometer.Rproj          # RStudio project file (MUST open this)
├── CLAUDE.md                     # Project instructions for Claude
├── README.md                     # Full documentation
├── QUICKSTART.md                 # Quick start guide
│
├── scripts/                      # Numbered workflow scripts
│   ├── 00_setup.R               # Package installation (run once)
│   ├── 00_create_variable_inventory.R
│   ├── 01_data_import.R         # Load SPSS → filter Cambodia → combine
│   ├── 01_fuzzy_label_matching.R
│   ├── 02_data_cleaning.R       # Recode missing values
│   ├── 03_analysis.R            # Statistical analysis
│   ├── 03_expand_crosswalk_intelligently.R
│   ├── 04_visualization.R       # Generate plots
│   ├── 04_add_wave1_to_crosswalk.R
│   ├── 05_harmonize_waves.R     # Scale harmonization
│   ├── 05_trust_scale_comparison.R
│   ├── 05_detect_scale_types.R
│   ├── 06_create_w6_covid_dataset.R
│   ├── 06_fix_scale_detection_issues.R
│   ├── 99_run_all.R             # Master pipeline
│   ├── verify_harmonization.R   # Validation checks
│   └── test_*.R                 # Test scripts
│
├── functions/                    # Reusable helper functions
│   ├── cleaning_functions.R     # clean_variable(), clean_variable_by_label()
│   ├── wave_harmonization.R     # harmonize_wave(), scale reversals
│   └── concept_functions.R      # Concept mapping functions
│
├── data/
│   ├── raw/                     # Original SPSS files - NEVER MODIFY
│   │   ├── Wave1_*.sav
│   │   ├── Wave2_*.sav
│   │   ├── ABS3 merge*.sav      # Wave 3
│   │   ├── W4_*.sav
│   │   ├── *_W5_*.sav
│   │   └── W6_*.sav             # Multiple country files
│   └── processed/               # Cleaned/harmonized .rds files
│       ├── cambodia_all_waves_harmonized.rds
│       ├── w2_cambodia_harmonized.rds
│       ├── w3_cambodia_harmonized.rds
│       ├── w4_cambodia_harmonized.rds
│       ├── w5_cambodia_harmonized.rds
│       └── w6_cambodia_harmonized.rds
│
├── docs/                         # Documentation & codebooks
│   ├── codebook.csv             # Raw variable labels from SPSS
│   ├── harmonization_codebook.csv # Raw → harmonized → concept mappings
│   ├── *_crosswalk.csv          # Domain-specific crosswalks
│   ├── section_summaries/       # Section documentation
│   └── *.md                     # Various documentation
│
├── output/
│   ├── figures/                 # Generated plots (.png)
│   └── tables/                  # Exported data (.csv, .html)
│
├── abs_harmonization_crosswalk*.csv  # Main crosswalk files (root level)
│
├── *.qmd                        # Quarto documents
│   ├── trust_explorer.qmd       # Interactive trust variable dashboard
│   ├── wave_explorer_template.qmd
│   └── concept_builder.qmd
│
└── *.html                       # Rendered Quarto outputs
```

## Key Files by Purpose

### Data Import/Processing
- `scripts/01_data_import.R` - Load and combine waves
- `scripts/02_data_cleaning.R` - Handle missing values
- `scripts/05_harmonize_waves.R` - Cross-wave harmonization

### Core Functions
- `functions/cleaning_functions.R` - Missing value handling
- `functions/wave_harmonization.R` - Scale reversal/harmonization
- `functions/concept_functions.R` - Concept naming

### Crosswalk Documentation
- `abs_harmonization_crosswalk.csv` - Main crosswalk
- `abs_harmonization_crosswalk_ALL_WAVES.csv` - Complete coverage
- `abs_harmonization_crosswalk_WITH_SCALES.csv` - Includes scale info

### Interactive Exploration
- `trust_explorer.qmd` - Trust variable dashboard
- `concept_builder.qmd` - Concept building interface
