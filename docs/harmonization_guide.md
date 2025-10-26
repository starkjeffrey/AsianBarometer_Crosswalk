# Asian Barometer Wave Harmonization Guide

## Overview

The Asian Barometer survey changed question numbering and **reversed many scales** between waves. This guide explains the harmonization system that makes cross-wave comparisons valid.

## Critical Scale Changes

### 🚨 Economic Questions (q1-q6)

**Problem**: Scale direction reversed after Wave 2

| Wave | Original Scale | Interpretation |
|------|---------------|----------------|
| W2 | 1 = Very bad → 5 = Very good | Higher = Better |
| W3-W6 | 1 = Very good → 5 = Very bad | **Higher = Worse** ⚠️ |

**Solution**: All harmonized to `1 = Very bad, 5 = Very good`

**Variables affected**:
- `q1` - Country economic condition
- `q2` - Country economic change
- `q3` - Country economic future
- `q4` - Family economic situation
- `q5` - Family economic change
- `q6` - Family economic future

### 🚨 Trust Questions (q7-q19)

**Problem**: Scale direction AND number of points changed

| Wave | Original Scale | Points |
|------|---------------|--------|
| W2 | 1 = None at all → 4 = Great deal | 4-point ✓ |
| W3, W5 | 1 = Trust fully → 6 = Distrust fully | 6-point (reversed!) ⚠️ |
| W4, W6 | 1 = Great deal → 4 = None at all | 4-point (reversed!) ⚠️ |

**Solution**: All harmonized so **higher = more trust**
- W2: Kept as-is (4-point scale)
- W3, W5: Reversed to 6-point scale (6 = trust fully)
- W4, W6: Reversed to 4-point scale (4 = great deal)

**Note**: W3/W5 remain 6-point scales. For direct comparison, you may want to rescale to 4-point.

**Variables affected**:
- `q7` - Trust executive
- `q8` - Trust courts
- `q9` - Trust national government
- `q10` - Trust parties
- `q11` - Trust parliament
- `q12` - Trust civil service
- `q13` - Trust military
- `q14` - Trust police
- `q15` - Trust local government
- Plus social trust questions (q24-q27)

## Using the Harmonization Functions

### Quick Start

```r
library(here)
source(here("functions/wave_harmonization.R"))

# Load your data
w2_data <- read_sav(here("data/raw/Wave2_20250609.sav"))

# Apply harmonization
w2_harmonized <- harmonize_wave(w2_data, wave = "W2")

# Use harmonized variables (have '_harm' suffix)
summary(w2_harmonized$q1_harm)  # Harmonized country economic condition
summary(w2_harmonized$q7_harm)  # Harmonized trust in executive
```

### Run Complete Harmonization Pipeline

```r
# Process all waves and create combined dataset
source("scripts/05_harmonize_waves.R")

# This creates:
# 1. Individual harmonized wave files in data/processed/
# 2. Combined dataset: cambodia_all_waves_harmonized.rds
# 3. Codebook: docs/harmonization_codebook.csv
```

### Load Pre-Harmonized Data

```r
# Load harmonized combined dataset
cambodia <- readRDS(here("data/processed/cambodia_all_waves_harmonized.rds"))

# Use harmonized variables
library(ggplot2)
ggplot(cambodia, aes(x = wave, y = q1_harm)) +
  geom_boxplot() +
  labs(title = "Country Economic Condition Across Waves",
       y = "1=Very bad, 5=Very good")
```

## Variable Naming System

### Three Types of Variables

1. **Original variables** (`q1`, `q7`, etc.)
   - Unchanged from SPSS files
   - ⚠️ **Do not use for cross-wave comparison** - scales are inconsistent!

2. **Harmonized variables** (`q1_harm`, `q7_harm`, etc.)
   - Same question number as original
   - Scale-corrected for cross-wave comparison
   - ✅ **Use these for analysis**

3. **Standardized concept names** (`econ_country_current`, `trust_executive`, etc.)
   - Descriptive names that work across all waves
   - Automatically uses harmonized version
   - ✅ **Best for readable code**

### Example Comparison

```r
# ❌ WRONG - comparing incompatible scales
mean(w2_data$q1)  # 1=bad, 5=good
mean(w4_data$q1)  # 1=good, 5=bad (opposite!)

# ✅ CORRECT - using harmonized variables
mean(w2_harmonized$q1_harm)  # 1=bad, 5=good
mean(w4_harmonized$q1_harm)  # 1=bad, 5=good (consistent!)

# ✅ ALSO CORRECT - using concept names
mean(w2_harmonized$econ_country_current)
mean(w4_harmonized$econ_country_current)
```

## Function Reference

### Main Functions

#### `harmonize_wave(data, wave, add_wave_column = TRUE)`
Apply all harmonization to one wave dataset.

**Parameters**:
- `data`: Data frame for one wave
- `wave`: Character string ("W2", "W3", "W4", "W5", or "W6")
- `add_wave_column`: Add 'wave' identifier column?

**Returns**: Harmonized data frame with:
- Original variables (unchanged)
- `*_harm` variables (scale-corrected)
- Standardized concept names

**Example**:
```r
w3_harm <- harmonize_wave(w3_data, "W3")
```

#### `harmonize_economic(data, wave, vars = c("q1", "q2", "q3", "q4", "q5", "q6"))`
Reverse-code economic questions where needed.

**Example**:
```r
# Apply only economic harmonization
w4_econ <- harmonize_economic(w4_data, "W4")
summary(w4_econ$q1_harm)
```

#### `harmonize_trust(data, wave, vars = paste0("q", 7:19))`
Reverse-code trust questions where needed.

**Example**:
```r
# Apply only trust harmonization
w4_trust <- harmonize_trust(w4_data, "W4")
```

#### `standardize_variables(data, wave, harmonize = TRUE)`
Create standardized concept names across waves.

**Example**:
```r
w2_std <- standardize_variables(w2_data, "W2")
# Now has variables like: econ_country_current, trust_executive, etc.
```

### Utility Functions

#### `reverse_5point(x)`, `reverse_4point(x)`, `reverse_6point(x)`
Low-level functions to reverse Likert scales.

**Example**:
```r
# Manually reverse a scale
reversed <- reverse_5point(original_var)
# 1→5, 2→4, 3→3, 4→2, 5→1
```

#### `create_harmonization_codebook()`
Generate a reference table showing variable mappings.

**Example**:
```r
codebook <- create_harmonization_codebook()
write.csv(codebook, "harmonization_reference.csv")
```

## Question Mappings Across Waves

Some questions changed numbers between waves. The `question_map` list handles this automatically.

### Examples

| Concept | W2 | W3 | W4 | W5 | W6 |
|---------|----|----|----|----|-----|
| Trust election commission | q18 | q16 | q16 | q18 | q16 |
| Trust NGOs | q19 | q17 | q19 | q17 | q17 |
| Interest in politics | q43 | q43 | q44 | q47 | q47 |
| Satisfaction with democracy | q93 | q89 | q92 | q90 | q90 |
| Democracy preferable | q121 | q132 | q125 | q124 | q124 |

**Solution**: Use standardized concept names:
```r
# Works across all waves
cambodia$trust_election_commission  # Automatically uses correct q-number
cambodia$satisfaction_democracy     # Automatically uses correct q-number
```

## Common Analysis Patterns

### Compare Economic Perceptions Across Waves

```r
library(dplyr)
library(ggplot2)

# Load harmonized data
cambodia <- readRDS(here("data/processed/cambodia_all_waves_harmonized.rds"))

# Summarize by wave
econ_summary <- cambodia %>%
  group_by(wave) %>%
  summarize(
    mean_country = mean(econ_country_current, na.rm = TRUE),
    mean_family = mean(econ_family_current, na.rm = TRUE),
    n = n()
  )

# Plot trend
ggplot(econ_summary, aes(x = wave, y = mean_country, group = 1)) +
  geom_line() +
  geom_point() +
  labs(title = "Country Economic Perceptions Over Time",
       y = "Mean (1=Very bad, 5=Very good)")
```

### Compare Trust Levels Across Waves

**Note**: W3/W5 use 6-point scales, W2/W4/W6 use 4-point scales.

```r
# For comparing trends, you may want to rescale W3/W5 to 4-point
cambodia <- cambodia %>%
  mutate(
    trust_exec_4pt = case_when(
      wave %in% c("W3", "W5") ~ (q7_harm - 1) * 3/5 + 1,  # Rescale 6pt to 4pt
      TRUE ~ q7_harm
    )
  )

# Now compare
trust_summary <- cambodia %>%
  group_by(wave) %>%
  summarize(
    mean_trust = mean(trust_exec_4pt, na.rm = TRUE),
    n = n()
  )
```

### Regression with Wave Fixed Effects

```r
library(lm)

# Use harmonized variables in regression
model <- lm(satisfaction_democracy ~ econ_country_current +
            trust_national_gov + wave,
            data = cambodia)
summary(model)
```

## Checking Your Work

### Verify Harmonization Worked

```r
# Check means before and after
cat("W2 q1 original:", mean(w2_data$q1, na.rm = TRUE), "\n")
cat("W4 q1 original:", mean(w4_data$q1, na.rm = TRUE), "\n")
# These should be opposite direction!

cat("\nW2 q1 harmonized:", mean(w2_harm$q1_harm, na.rm = TRUE), "\n")
cat("W4 q1 harmonized:", mean(w4_harm$q1_harm, na.rm = TRUE), "\n")
# These should be comparable!
```

### View Harmonization Codebook

```r
codebook <- read.csv(here("docs/harmonization_codebook.csv"))
View(codebook)
```

## Troubleshooting

### "Variable not found" errors

**Problem**: Some questions don't exist in all waves.

**Solution**: Check the codebook to see which waves have which variables.

```r
codebook <- read.csv(here("docs/harmonization_codebook.csv"))
# Look for NA values to see missing variables
```

### Unexpected means/distributions

**Problem**: Forgetting to use harmonized variables.

**Solution**: Always use `*_harm` suffix or standardized concept names.

```r
# ❌ Wrong
summary(data$q1)

# ✅ Right
summary(data$q1_harm)
summary(data$econ_country_current)
```

### Combining waves with different scales

**Problem**: Trust questions have different number of points (4pt vs 6pt).

**Solution**: Either:
1. Rescale to common scale (e.g., convert 6pt to 4pt)
2. Analyze waves separately
3. Standardize to z-scores

```r
# Option 1: Rescale to 4-point
data <- data %>%
  mutate(trust_4pt = case_when(
    wave %in% c("W3", "W5") ~ (q7_harm - 1) * 3/5 + 1,
    TRUE ~ q7_harm
  ))

# Option 3: Standardize
data <- data %>%
  group_by(wave) %>%
  mutate(trust_z = scale(q7_harm)[,1]) %>%
  ungroup()
```

## References

- `functions/wave_harmonization.R` - Harmonization functions
- `scripts/05_harmonize_waves.R` - Complete harmonization pipeline
- `docs/cross_wave.md` - Detailed cross-wave analysis
- `docs/harmonization_codebook.csv` - Variable mapping reference

## Summary

✅ **Always use harmonized variables** (`*_harm` or concept names) for cross-wave analysis

✅ **Check the codebook** to see which variables exist in which waves

✅ **Be aware of scale differences** (4-point vs 6-point trust scales)

❌ **Never compare original variables** across waves - scales are inconsistent!
