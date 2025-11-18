# 🚀 How to Expand Your Crosswalk from 64 to 120+ Concepts

**Current Status**: 64 concepts
**Goal**: 120-150 concepts (comprehensive coverage)
**Available**: 207 variables appearing in 2+ waves

---

## 📊 Understanding Your Current Situation

### What You Have Now (64 concepts)
- **45 concepts**: From your original manual crosswalk
- **19 concepts**: Added via automated matching (95%+ similarity)
- **Coverage**: Conservative, high-confidence matches only

### What's Available (207 variables)
- **Variables in 2+ waves**: 207 total
- **Already mapped**: 64 concepts
- **Remaining unmapped**: ~143 variables
- **Potential new concepts**: 50-80 (many variables are part of same concepts)

---

## 🎯 Three Expansion Strategies

### STRATEGY 1: Lower Similarity Threshold (Quick - 30 min)

**How it works**: Use 85% similarity instead of 95%

**Steps**:
1. Edit `scripts/03_expand_crosswalk_intelligently.R`
2. Change line ~57 from `>= 0.95` to `>= 0.85`
3. Run the script again

**Expected result**: +30-50 concepts
**Confidence level**: Medium (needs more manual review)
**Best for**: Quick expansion with some validation work

**Code to change**:
```r
# Current (line 57):
filter(similarity >= 0.95) %>%

# Change to:
filter(similarity >= 0.85) %>%
```

Then run:
```r
source("scripts/03_expand_crosswalk_intelligently.R")
source("scripts/04_add_wave1_to_crosswalk.R")
```

---

### STRATEGY 2: Manual Review of Medium-Similarity Pairs (Thorough - 2-3 hours)

**How it works**: Review 85-94% similarity pairs manually

**Steps**:

#### Step 1: Filter for medium-similarity pairs
```r
library(readr)
library(dplyr)

# Load the similarity pairs
pairs <- read_csv("docs/high_similarity_pairs.csv")

# Filter for 85-94% similarity
medium_sim <- pairs %>%
  filter(similarity >= 0.85 & similarity < 0.95) %>%
  arrange(desc(similarity))

# Export for review
write_csv(medium_sim, "docs/medium_similarity_for_review.csv")

# View in R
View(medium_sim)
```

#### Step 2: Review each pair
For each pair, ask:
- ✓ Do the labels describe the same concept?
- ✓ Are the response scales compatible?
- ✓ Is the question meaning consistent across waves?

#### Step 3: Manually add valid matches
Add approved pairs to `abs_harmonization_crosswalk_WITH_SCALES.csv`

**Expected result**: +20-30 concepts
**Confidence level**: High (you verified each one)
**Best for**: Quality over speed, research-critical variables

---

### STRATEGY 3: Domain-Specific Expansion (Most Comprehensive - 4-6 hours)

**How it works**: Review all variables by domain and add important ones

**Steps**:

#### Step 1: Load domain-sorted variables
```r
# Load the domain-sorted list
by_domain <- read_csv("docs/crosswalk_by_domain.csv")

# View by specific domain
View(by_domain %>% filter(suggested_domain == "corruption"))
View(by_domain %>% filter(suggested_domain == "democracy"))
View(by_domain %>% filter(suggested_domain == "economic"))
```

#### Step 2: Identify key domains for your research

**Priority domains** (based on Asian Barometer importance):
1. **Democracy** (support, satisfaction, evaluation)
2. **Trust** (institutional, interpersonal)
3. **Economic** (evaluations, inequality)
4. **Corruption** (perceptions, experiences)
5. **Political efficacy** (participation, influence)
6. **Media** (consumption, trust)
7. **Civil society** (membership, participation)
8. **Governance** (quality, accountability, rule of law)
9. **Identity** (national, ethnic, religious)
10. **Values** (traditional vs modern)

#### Step 3: For each priority domain, review variables

Example for **Corruption domain**:
```r
# Get all corruption-related variables
corruption_vars <- by_domain %>%
  filter(grepl("corrupt|bribe", suggested_domain, ignore.case = TRUE) |
         grepl("corrupt|bribe", w2_label, ignore.case = TRUE) |
         grepl("corrupt|bribe", w3_label, ignore.case = TRUE))

# Check how many waves each appears in
corruption_vars %>%
  select(variable, n_waves_present, starts_with("w")) %>%
  arrange(desc(n_waves_present))
```

#### Step 4: Create concept groups manually

For variables that:
- Appear in 3+ waves → High priority
- Measure important constructs → Add even if 2 waves
- Are unique to 1 wave but critical → Document as wave-specific

**Expected result**: +40-60 concepts
**Confidence level**: Highest (domain expert review)
**Best for**: Comprehensive research coverage

---

## 🔍 Finding Specific Types of Questions

### Example: All Democracy Questions

```r
library(readr)
library(dplyr)
library(stringr)

# Load inventory
inventory <- read_csv("docs/q_variables_by_wave.csv")

# Search for democracy questions
democracy_q <- inventory %>%
  filter(str_detect(tolower(label),
                   "democra|authoritarian|dictator|military rule|one party"))

# Group by variable name
democracy_concepts <- democracy_q %>%
  group_by(variable) %>%
  summarise(
    n_waves = n_distinct(wave),
    waves = paste(wave, collapse = ", "),
    label_example = first(label),
    .groups = "drop"
  ) %>%
  filter(n_waves >= 2) %>%
  arrange(desc(n_waves))

View(democracy_concepts)
```

### Example: All Trust Questions

```r
trust_q <- inventory %>%
  filter(str_detect(tolower(label), "trust|confidence"))

trust_concepts <- trust_q %>%
  group_by(variable) %>%
  summarise(
    n_waves = n_distinct(wave),
    waves = paste(wave, collapse = ", "),
    label_example = first(label),
    .groups = "drop"
  ) %>%
  filter(n_waves >= 2) %>%
  arrange(desc(n_waves))

View(trust_concepts)
```

---

## 📋 Recommended Expansion Workflow

### Phase 1: Quick Wins (Week 1)
1. ✅ Run Strategy 1 (lower threshold to 85%)
2. ✅ Add 30-50 high-probability concepts
3. ✅ Run scale detection on new concepts
4. ✅ **Result**: ~100 concepts

### Phase 2: Quality Review (Week 2)
1. ✅ Use Strategy 2 (manual review of medium-similarity)
2. ✅ Add 20-30 validated concepts
3. ✅ Focus on research-critical domains
4. ✅ **Result**: ~120-130 concepts

### Phase 3: Comprehensive Coverage (Week 3)
1. ✅ Use Strategy 3 (domain-specific expansion)
2. ✅ Review priority domains thoroughly
3. ✅ Add wave-specific concepts (e.g., COVID in W6)
4. ✅ **Result**: ~150+ concepts

---

## 🎨 Example: Adding a Concept Manually

Let's say you want to add "political interest" across waves:

### Step 1: Find the variables
```r
inventory %>%
  filter(str_detect(tolower(label), "interest.*politic|politic.*interest")) %>%
  select(wave, variable, label)
```

Result might show:
- W2: q92 - "How interested are you in politics?"
- W3: q88 - "How interested are you in politics?"
- W4: q91 - "How interested are you in politics?"
- W5: q89 - "How interested are you in politics?"
- W6: q91 - "How interested are you in politics?"

### Step 2: Check if already in crosswalk
```r
crosswalk <- read_csv("abs_harmonization_crosswalk_WITH_SCALES.csv")

# Check if any of these variables already mapped
crosswalk %>%
  filter(w2_var == "q92" | w3_var == "q88" | w4_var == "q91")
```

### Step 3: If not present, add new row

Create new concept entry:
```csv
political_interest,politics,Interest in politics,NA,NA,q92,4pt,q88,4pt,q91,4pt,q89,4pt,q91,4pt,pol_interest_harm,4pt_1high,none,Standard 4pt scale across all waves
```

---

## 💡 Smart Expansion Tips

### 1. **Prioritize by Wave Coverage**
- **6 waves**: Highest priority (longitudinal trends)
- **5 waves**: High priority
- **4 waves**: Medium priority
- **3 waves**: Consider if important
- **2 waves**: Only if critical to research

### 2. **Check Existing Literature**
What questions do other Asian Barometer studies use?
- Look at published papers
- Check what variables are commonly analyzed
- Prioritize those concepts

### 3. **Consider Your Research Questions**
If your research focuses on:
- **Trust** → Expand all trust concepts (institutional + interpersonal)
- **Democracy** → All democracy support/satisfaction/quality
- **Corruption** → Perceptions, experiences, government response
- **COVID** → Wave 6 specific + trust/economy links

### 4. **Group Related Questions**
Some concepts have multiple indicators:
- **Economic evaluation**: Country economy + family economy + past + future
- **Media consumption**: TV, newspaper, radio, internet
- **Group membership**: Types of organizations

Create one concept per dimension, not per question.

### 5. **Don't Over-Harmonize**
Some questions legitimately changed between waves:
- Question wording evolved
- Response scales changed intentionally
- New topics emerged

Document these as wave-specific or note comparability limits.

---

## 🚦 Decision Tree: Should I Add This Variable?

```
┌─ Is it in 2+ waves?
│   ├─ YES → Continue
│   └─ NO → Skip (unless wave-specific and critical)
│
├─ Are the questions asking the same thing?
│   ├─ YES → Continue
│   └─ NO → Document as not comparable
│
├─ Are the scales compatible?
│   ├─ YES → Continue
│   └─ MAYBE → Note: requires scale transformation
│
├─ Is it important for your research?
│   ├─ YES → ADD IT
│   └─ NO → Is it a core ABS concept?
│       ├─ YES → ADD IT
│       └─ NO → Skip for now
```

---

## 📊 Expected Expansion Trajectory

| Strategy | Time | New Concepts | Total | Confidence |
|----------|------|--------------|-------|------------|
| Current | - | 0 | 64 | High |
| Strategy 1 (85% threshold) | 30 min | +35 | 99 | Medium |
| Strategy 2 (Manual review) | 2 hrs | +25 | 124 | High |
| Strategy 3 (Domain review) | 4 hrs | +30 | 154 | Very High |

---

## 🎯 Your Next Immediate Action

**RECOMMENDED**: Start with Strategy 1

1. **Edit** `scripts/03_expand_crosswalk_intelligently.R`:
   - Change `>= 0.95` to `>= 0.85` on line 57

2. **Run** the expansion:
```r
source("scripts/03_expand_crosswalk_intelligently.R")
source("scripts/04_add_wave1_to_crosswalk.R")
```

3. **Review** the new concepts:
```r
new_concepts <- read_csv("docs/new_concepts_needs_review.csv")
View(new_concepts)
```

4. **Document** scale types for the new concepts

**This will get you from 64 → ~100 concepts in 30 minutes!**

---

## ❓ Common Questions

**Q: Won't lowering the threshold give me bad matches?**
A: 85% similarity is still very high. You'll get some false positives, but most will be valid. Review the `similarity` score - anything above 0.90 is usually safe.

**Q: How do I know if a match is good?**
A: Check if:
- Labels are nearly identical
- Question intent is the same
- Response scales are similar
- Makes conceptual sense

**Q: Should I include Wave 1?**
A: Yes! Even though coverage is lower (14%), those 9 variables give you 20 years of data (2003-2022).

**Q: What if a question exists in only one wave?**
A: If it's important (e.g., COVID in W6), add it as a wave-specific concept. Note in the `notes` column: "W6 only - COVID-specific"

---

## ✅ Success Criteria

You'll know you have good coverage when:
- ✓ All major ABS domains represented
- ✓ Core concepts appear in 4+ waves
- ✓ Important wave-specific modules documented
- ✓ Scale types specified (no more "varies")
- ✓ Harmonization strategy clear for each concept

**Target**: 120-150 concepts covering the most important questions across all 6 waves.

---

**Ready to expand? Let me know which strategy you want to try first!** 🚀
