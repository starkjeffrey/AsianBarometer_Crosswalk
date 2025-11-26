# Project Overview: Asian Barometer Crosswalk

## Purpose
R-based analysis project for Asian Barometer survey data focused on Cambodia across Waves 1-6. The project creates harmonized crosswalks to enable valid cross-wave comparisons despite different response scales and polarity reversals.

## Key Challenge Addressed
Asian Barometer uses different response scales across waves:
- **4-point scales**: Waves 2, 4, 6
- **6-point scales**: Waves 3, 5
- **Polarity reversals**: Some waves use 1="positive"→5="negative", others reverse this

The project harmonizes these to create comparable variables across all waves.

## Tech Stack
- **Language**: R (primarily)
- **IDE**: RStudio with .Rproj project file
- **Core Packages**:
  - Data manipulation: dplyr, purrr, tidyr
  - Data import: haven (SPSS files), readr
  - Data cleaning: janitor, labelled
  - Path management: here
  - Analysis: survey, srvyr
  - Visualization: ggplot2, plotly
  - Tables: gtsummary, DT
  - Interactive: Quarto, shiny, crosstalk

## Data Sources
- Raw SPSS (.sav) files in `data/raw/`
- Cambodia country code: 12 (for filtering multi-country waves)
- Wave 6 is Cambodia-only (no country filter needed)

## Key Outputs
- Harmonized datasets with `*_harm` suffix variables
- Crosswalk CSVs mapping variables across waves
- Interactive Quarto dashboards for exploration
- Codebooks documenting all variable mappings
