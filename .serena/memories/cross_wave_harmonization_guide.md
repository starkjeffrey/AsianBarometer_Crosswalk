# Cross-Wave Harmonization Guide

## Critical Rule
**NEVER compare raw `q*` variables across waves. Always use `*_harm` variables.**

## Scale Types by Wave
| Wave | Trust Scale | Common Scale Types |
|------|-------------|-------------------|
| Wave 2 | 4-point | Various |
| Wave 3 | 6-point | Various |
| Wave 4 | 4-point | Various |
| Wave 5 | 6-point | Various |
| Wave 6 | 4-point | Various |

## Harmonization Process

### 1. Scale Reversal
Some waves use reversed polarity (1=positive → 5=negative vs 1=negative → 5=positive).
Harmonization flips reversed scales to consistent directionality: **higher = more positive/trust**

### 2. Variable Naming Convention
- Raw: `q1`, `q2`, `q92`, etc.
- Cleaned: `q1_clean`, `q92_clean` (missing values → NA)
- Harmonized: `q1_harm`, `q92_harm` (consistent scale direction)
- Concept: `trust_executive`, `econ_country_current` (semantic names)

### 3. Key Concept Variables
| Concept Name | Description |
|--------------|-------------|
| `econ_country_current` | Current national economic situation |
| `econ_family_current` | Current household economic situation |
| `trust_executive` | Trust in president/PM |
| `trust_courts` | Trust in courts/judiciary |
| `trust_national_gov` | Trust in national government |
| `trust_parties` | Trust in political parties |
| `trust_parliament` | Trust in parliament/legislature |
| `satisfaction_democracy` | Satisfaction with democracy |
| `democracy_preferable` | Democracy is preferable regime |
| `interest_politics` | Interest in politics |

## Validation Workflow
```r
# After making harmonization changes
source("scripts/05_harmonize_waves.R")
source("scripts/verify_harmonization.R")
# Check console output for directionality confirmation
```

## Common Issues

### 1. Cross-wave comparisons seem wrong
- Verify using `*_harm` variables, not raw `q*`
- Check `docs/harmonization_codebook.csv` for scale direction
- Run `verify_harmonization.R`

### 2. Negative values in trust data
- Check if scale reversal function received correct inputs
- Use validation functions

### 3. haven_labelled errors in Quarto
- Use `haven::zap_labels()` or `as.numeric()` before pivoting/plotting

## Crosswalk Files
- `abs_harmonization_crosswalk.csv` - Main crosswalk
- `abs_harmonization_crosswalk_ALL_WAVES.csv` - Full coverage
- `abs_harmonization_crosswalk_WITH_SCALES.csv` - With scale metadata
- `docs/harmonization_codebook.csv` - Variable mapping documentation
