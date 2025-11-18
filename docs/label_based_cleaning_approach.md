# Label-Based NA Cleaning Approach

## The Problem

Asian Barometer survey data has inconsistent numeric missing value codes across questions:
- Question A: 7 = "Don't know", 8 = "Refuse", 9 = "NA"
- Question B: 6 = "Don't know", 7 = valid data, 8 = "Refuse"
- Question C: -1 = "Missing", 7 = valid data

**Old approach (WRONG)**: Blanket rule like "convert all 7, 8, 9 to NA" destroys valid data.

**New approach (CORRECT)**: Use SPSS value **labels** to identify missing values, not numeric codes.

## The Solution

### Step 1: Master NA Labels List

In `functions/cleaning_functions.R`, maintain `na_labels_list`:

```r
na_labels_list <- c(
  "Missing",
  "Don't know",
  "Can't choose",
  "Refused",
  "Decline to answer",
  # ... add more as you discover them
)
```

### Step 2: Label-Based Cleaning Function

`clean_variable_by_label(x, na_labels_list)`:
1. Reads SPSS value labels from the variable
2. Finds which values have labels matching `na_labels_list`
3. Converts those specific values to NA
4. **Preserves** the `haven_labelled` class and all label attributes

### Step 3: Why This Works

```r
# Example: Wave 3, q1
# Value -1 has label "Missing"
# Value 7 has label "Do not understand the question"
# Value 8 has label "Can't choose"

# Function finds: -1, 7, 8 match na_labels_list
# Converts only those values to NA
# Valid responses (1-5) remain untouched
```

## Usage Examples

### Clean Single Variable
```r
library(haven)
source("functions/cleaning_functions.R")

# Load data
w3 <- read_sav("data/raw/ABS3 merge20250609.sav")

# Clean using standard NA labels
q1_clean <- clean_variable_by_label(w3$q1, na_labels_list)

# Add question-specific NA label
q20_clean <- clean_variable_by_label(w3$q20,
                                      c(na_labels_list, "Not a member"))
```

### Clean Multiple Variables
```r
# Clean all trust variables
trust_vars <- paste0("q", 7:19)

data_clean <- w3 %>%
  mutate(across(all_of(trust_vars),
                ~clean_variable_by_label(., na_labels_list),
                .names = "{.col}_clean"))
```

## Label Preservation Verification

The function **preserves**:
- ✓ Variable label (question text)
- ✓ Value labels for valid responses
- ✓ haven_labelled class
- ✓ All SPSS attributes

Test it:
```r
# Original
is.labelled(w3$q1)  # TRUE
attr(w3$q1, "label")  # "q1. How would you rate..."
attr(w3$q1, "labels")  # All value labels present

# After cleaning
q1_clean <- clean_variable_by_label(w3$q1, na_labels_list)
is.labelled(q1_clean)  # Still TRUE
attr(q1_clean, "label")  # Still present
attr(q1_clean, "labels")  # Still present
```

## Building the NA Labels List

As you explore each wave in Quarto, add new patterns:

```r
# Find all unique value labels in a wave
all_labels <- w3 %>%
  select(starts_with("q")) %>%
  map(~attr(., "labels")) %>%
  map(names) %>%
  unlist() %>%
  unique() %>%
  sort()

# Look for missing-value patterns
grep("missing|don't|can't|refuse|NA", all_labels,
     value = TRUE, ignore.case = TRUE)
```

## Wave-by-Wave Exploration Workflow

1. Load wave data with haven
2. Explore variable labels to find concepts (trust, democracy, etc.)
3. Check value labels for each variable
4. Add new NA label patterns to `na_labels_list`
5. Apply `clean_variable_by_label()` to relevant variables
6. Document concept-to-variable mappings

## Key Advantages

1. **Robustness**: Works even when numeric codes vary
2. **Transparency**: Can see exactly which labels are treated as NA
3. **Preservation**: All SPSS metadata remains intact
4. **Flexibility**: Easy to add question-specific NA patterns
5. **Consistency**: Same NA labels apply across all waves

## Critical Rules

- ⚠️ NEVER use `dplyr::na_if()` - it destroys the labelled class
- ✓ Always use `clean_variable_by_label()` or base R `x[x == val] <- NA`
- ✓ Keep variables as `haven_labelled` until final analysis
- ✓ Use `as_factor()` or `as.numeric()` only when needed for specific operations
- ✓ Add new NA label patterns as you discover them during exploration
