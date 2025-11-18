# Asian Barometer Cross-Wave Harmonization Roadmap

**Date**: 2025-11-18
**Project**: AsianBarometer_Crosswalk
**Scope**: Waves 1-6 harmonization and comprehensive crosswalk generation

---

## Executive Summary

### Current Status
- ✅ **Variable Inventory Complete**: All 6 waves analyzed (1,684 total variables)
- ✅ **Initial Crosswalk Exists**: `abs_harmonization_crosswalk.csv` (46 concepts mapped)
- ⚠️ **Accuracy Concerns**: W6 merged file (`w6_all_countries_merged.rds`) accuracy questioned
- ⚠️ **Question Instability**: Same variable names (e.g., q100-q148) have **completely different questions** across waves

### Critical Finding: Variable Name Instability
**The q-variable numbering system is NOT consistent across waves.**

Example: **q100** in different waves:
- **Wave 1**: "Where would you place our country under the present government?"
- **Wave 2**: "In your opinion, what are the most important questions facing the country?"
- **Wave 3**: "Between elections, the people have no way of holding the government responsible"
- **Wave 4**: "How likely is it that the government will solve the most important problem?"
- **Wave 5**: "In your opinion how much of a democracy is our country?"
- **Wave 6**: "In our country, parties and candidates not in power have opportunities to be elected"

**Implication**: You CANNOT rely on variable names (q1, q2, q100, etc.) for harmonization. Must use **content-based matching** via variable labels.

---

## Data Inventory Summary

### Waves Available
| Wave | SPSS File | Countries | Rows | Variables | Label Coverage |
|------|-----------|-----------|------|-----------|----------------|
| Wave 1 | Wave1_20170906.sav | Multiple | 12,217 | 217 | 99.1% |
| Wave 2 | Wave2_20250609.sav | Multiple | 19,798 | 252 | 99.6% |
| Wave 3 | ABS3 merge20250609.sav | Multiple | 19,436 | 272 | 100% |
| Wave 4 | W4_v15_merged20250609_release.sav | Multiple | 20,667 | 289 | 100% |
| Wave 5 | 20230505_W5_merge_15.sav | Multiple | 26,951 | 308 | 100% |
| Wave 6 (Cambodia) | W6_Cambodia_Release_20240819.sav | Cambodia | 1,242 | 346 | 100% |

### Wave 6 Country Files Available
Additional W6 files found in `data/raw/`:
- W6_11_Vietnam_Release_20250117.sav
- W6_8_Thailand_Release_20250108.sav
- W6_15_Australia_Release_20250305.sav
- W6_Indonesia_release_20240402.sav
- W6_Korea_Release_20241220.sav
- W6_Mongolia_Release_20241223.sav
- W6_Philippines_release_20240403.sav
- W6_Taiwan_EN_20240402.sav

### Key Variable Patterns
- **208 variables** appear in 2+ waves (crosswalk candidates)
- **1,163 q-variables** total across all waves
- **Variable labels are the stable identifier**, not variable names

---

## Existing Crosswalk Analysis

### Current Coverage (abs_harmonization_crosswalk.csv)
**46 concepts mapped** across 7 domains:

#### By Domain:
1. **Trust** (13 concepts): Executive, courts, national govt, parties, parliament, civil service, military, police, local govt, election commission, NGOs, general trust, interpersonal trust
2. **Economic** (6 concepts): Country/family current/past/future conditions
3. **Politics** (3 concepts): Political interest, follow news, voting
4. **Democracy** (3 concepts): Satisfaction, level, preference
5. **COVID-19** (6 concepts - W6 only): Infection, economic impact, trust info, govt handling, vaccination, emergency powers
6. **Social** (2 concepts): Contact frequency, social support
7. **Demographics** (5 concepts): Age, education, gender, income, urban/rural
8. **Identifiers** (3 concepts): Country, year, respondent ID

### Crosswalk Strengths
✅ **Trust variables well-mapped** (q7-q17 institutional trust)
✅ **Economic perceptions covered** (q1-q6)
✅ **COVID section documented** (W6-specific)
✅ **Scale type documented** (4pt, 6pt, binary, categorical)
✅ **Reversal needs identified** (W4 reversals noted)

### Crosswalk Gaps
❌ **Democracy/governance questions** (q100-q150+) - Many missing
❌ **Political attitudes** beyond basic interest/voting
❌ **Wave 1 variables** - Not fully integrated
❌ **Country-specific modules** - Not documented
❌ **Scale harmonization details** - Lacks specific formulas

---

## First Steps: Validation & Expansion

### Step 1: Validate Existing Crosswalk ✅ COMPLETE
**Action**: Create variable inventory across all 6 waves
**Script**: `scripts/00_create_variable_inventory.R`
**Output**:
- `docs/variable_inventory_all_waves.csv` - Complete variable list
- `docs/variable_presence_by_wave.csv` - Variable × Wave matrix
- `docs/common_variables_across_waves.csv` - Cross-wave frequency
- `docs/q_variables_by_wave.csv` - All q-variables with labels
- `docs/potential_crosswalk_variables.csv` - Crosswalk starter template

**Status**: ✅ **COMPLETED** - Files generated successfully

### Step 2: Map Core Questions Using Label Matching 🔄 NEXT
**Goal**: Expand crosswalk from 46 → ~150-200 core concepts

**Priority Domains**:
1. **Democracy indicators** (q100-q150 range) - Critical for governance analysis
2. **Political efficacy** (participation, influence questions)
3. **Institutional quality** (accountability, rule of law)
4. **Social capital** (group membership, civic engagement)
5. **Values/cultural attitudes** (traditional vs modern)

**Approach**:
- Use **fuzzy string matching** on variable labels (not names)
- Group similar questions across waves
- Create concept IDs based on content similarity
- Document scale types and reversals by wave

**Recommended Script**: `scripts/01_fuzzy_label_matching.R`
- Read `docs/q_variables_by_wave.csv`
- Apply string similarity algorithm (e.g., stringdist, fuzzyjoin)
- Generate concept clusters
- Output: `docs/crosswalk_expansion_candidates.csv`

### Step 3: Expert Review & Refinement 📋 PENDING
**Goal**: Human validation of automated matches

**Process**:
1. Review auto-generated concept clusters
2. Verify question equivalence across waves
3. Resolve ambiguous matches manually
4. Document non-comparable questions
5. Add domain/subdomain classifications

**Output**: `docs/validated_crosswalk_v2.csv`

### Step 4: Scale Harmonization Documentation 📊 PENDING
**Goal**: Document exact harmonization formulas

For each concept:
- Identify native scale by wave (4pt, 5pt, 6pt)
- Determine target harmonized scale
- Specify reversal formulas by wave
- Document collapsing rules (6pt → 4pt)
- Test on sample data

**Output**: `docs/scale_harmonization_formulas.csv`

### Step 5: Generate Harmonization R Functions ⚙️ PENDING
**Goal**: Automated harmonization pipeline

**Create**:
- `functions/harmonize_wave1.R` through `functions/harmonize_wave6.R`
- `functions/apply_scale_transformations.R`
- `functions/create_concept_variables.R`

**Test**: Apply to Cambodia data first, then expand to all countries

### Step 6: Full Multi-Country Harmonization 🌏 PENDING
**Goal**: Create comprehensive harmonized dataset

**Deliverables**:
- `data/processed/abs_w1_w6_all_countries_harmonized.rds`
- Country-specific harmonized files
- Validation reports by wave and country
- Missing data documentation

---

## Recommended Tools & Packages

### For Fuzzy Label Matching:
```r
install.packages(c(
  "stringdist",    # String distance algorithms
  "fuzzyjoin",     # Fuzzy join operations
  "RecordLinkage", # Record linkage/matching
  "textclean",     # Text standardization
  "qdapRegex"      # Pattern extraction
))
```

### For Crosswalk Management:
```r
install.packages(c(
  "pointblank",    # Data validation
  "janitor",       # Data cleaning (already installed)
  "skimr",         # Data summaries
  "DataExplorer"   # Automated EDA
))
```

---

## Quality Control Checks

### For Each Harmonized Variable:
1. ✅ **Label consistency**: Same question content across waves
2. ✅ **Scale consistency**: Documented scale type by wave
3. ✅ **Direction consistency**: Higher = better/more after harmonization
4. ✅ **Range validation**: Values within expected bounds
5. ✅ **Missing data**: Proper NA handling for wave-specific questions
6. ✅ **Sample sizes**: Reasonable N by wave and country

### For Complete Crosswalk:
1. ✅ **Coverage**: All core ABS domains represented
2. ✅ **Wave representation**: No systematic wave exclusions
3. ✅ **Documentation**: Each concept has clear description
4. ✅ **Domain classification**: Hierarchical categorization
5. ✅ **Comparability notes**: Non-comparable items flagged
6. ✅ **Citation**: Source wave/questionnaire documented

---

## File Structure Organization

```
AsianBarometer_Crosswalk/
├── docs/
│   ├── HARMONIZATION_ROADMAP.md                 # This file
│   ├── variable_inventory_all_waves.csv         # ✅ Complete
│   ├── variable_presence_by_wave.csv            # ✅ Complete
│   ├── common_variables_across_waves.csv        # ✅ Complete
│   ├── q_variables_by_wave.csv                  # ✅ Complete
│   ├── potential_crosswalk_variables.csv        # ✅ Complete
│   ├── crosswalk_expansion_candidates.csv       # 🔄 Next step
│   ├── validated_crosswalk_v2.csv               # 📋 Pending
│   ├── scale_harmonization_formulas.csv         # 📊 Pending
│   └── abs_harmonization_crosswalk.csv          # ✅ Original (46 concepts)
├── scripts/
│   ├── 00_create_variable_inventory.R           # ✅ Complete
│   ├── 01_fuzzy_label_matching.R                # 🔄 Create next
│   ├── 02_expand_crosswalk.R                    # 📋 Future
│   ├── 03_harmonize_waves.R                     # ⚙️ Future
│   └── 04_validate_harmonization.R              # 🔍 Future
└── data/
    └── processed/
        ├── abs_w1_w6_all_countries_harmonized.rds  # 🌏 Ultimate goal
        └── [wave-specific harmonized files]
```

---

## Next Immediate Action

### RUN THIS COMMAND:
```r
# Step 2: Create fuzzy label matching script
source("scripts/01_fuzzy_label_matching.R")  # After creating the script
```

**Before that, you need to create the fuzzy matching script.**

Would you like me to:
1. ✅ **Create the fuzzy label matching script** (`scripts/01_fuzzy_label_matching.R`)
2. Review specific variable patterns in the inventory
3. Examine the existing crosswalk for specific domains
4. Analyze a specific wave's variable structure

**Recommendation**: Start with option 1 - create the automated label matching script to expand the crosswalk systematically.
