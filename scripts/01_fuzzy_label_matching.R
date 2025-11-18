# ==============================================================================
# 01_fuzzy_label_matching.R
# Use fuzzy string matching to identify comparable variables across waves
# Goal: Expand crosswalk from 46 concepts to comprehensive coverage
# ==============================================================================

cat("\n===== FUZZY LABEL MATCHING FOR CROSSWALK EXPANSION =====\n\n")

# Load required packages
library(here)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(stringdist)  # For fuzzy matching
library(purrr)

# Install stringdist if needed
if (!require("stringdist")) {
  install.packages("stringdist")
  library(stringdist)
}

# ---------------------
# 1. Load variable inventory
# ---------------------
cat("Loading variable inventory...\n")
q_vars <- read_csv(here("docs/q_variables_by_wave.csv"))

cat("  - Total q-variables:", nrow(q_vars), "\n")
cat("  - Unique variables:", n_distinct(q_vars$variable), "\n")
cat("  - Waves covered:", paste(unique(q_vars$wave), collapse = ", "), "\n\n")

# ---------------------
# 2. Clean and standardize labels for matching
# ---------------------
cat("Standardizing labels for matching...\n")

clean_label_for_matching <- function(label) {
  # Vectorized version
  result <- label
  result[is.na(result)] <- NA_character_

  result <- result %>%
    tolower() %>%                                    # Lowercase
    str_remove_all("^q[0-9]+\\.?\\s*") %>%          # Remove "q123." prefix
    str_remove_all("^[0-9]+\\.?\\s*") %>%           # Remove "123." prefix
    str_remove_all("\\(hk:.*?\\)") %>%              # Remove HK-specific notes
    str_remove_all("\\[.*?\\]") %>%                 # Remove [bracketed] text
    str_squish() %>%                                 # Remove extra whitespace
    str_replace_all("[^a-z0-9\\s]", " ") %>%        # Replace punctuation with space
    str_squish() %>%                                 # Clean again
    str_trunc(200)                                   # Truncate to 200 chars

  return(result)
}

q_vars_clean <- q_vars %>%
  mutate(
    label_clean = clean_label_for_matching(label),
    label_short = str_trunc(label_clean, 100)  # Shorter version for display
  )

cat("  ✓ Labels cleaned and standardized\n\n")

# ---------------------
# 3. Create pairwise similarity matrix
# ---------------------
cat("Computing label similarity scores...\n")
cat("  (This may take a few minutes for", n_distinct(q_vars_clean$variable), "unique variables)\n\n")

# Get unique variable-label combinations
unique_vars <- q_vars_clean %>%
  group_by(variable) %>%
  summarise(
    label_clean = first(label_clean[!is.na(label_clean)]),
    label_short = first(label_short[!is.na(label_short)]),
    label_original = first(label[!is.na(label)]),
    n_waves = n_distinct(wave),
    waves = paste(wave, collapse = ", "),
    .groups = "drop"
  ) %>%
  filter(!is.na(label_clean))

cat("  - Unique labeled variables:", nrow(unique_vars), "\n\n")

# Compute similarity between all pairs (using Jaro-Winkler distance)
# This is computationally intensive, so we'll do it in batches

compute_similarity_batch <- function(vars_data, batch_size = 50) {

  similarity_results <- list()
  n_vars <- nrow(vars_data)

  for (i in seq(1, n_vars, by = batch_size)) {
    batch_end <- min(i + batch_size - 1, n_vars)
    cat("  Processing batch", i, "to", batch_end, "of", n_vars, "\n")

    batch_data <- vars_data[i:batch_end, ]

    # Compute pairwise similarity for this batch
    batch_results <- map_dfr(1:nrow(batch_data), function(row_idx) {
      var1 <- batch_data$variable[row_idx]
      label1 <- batch_data$label_clean[row_idx]

      # Compute similarity with all OTHER variables
      other_vars <- vars_data %>%
        filter(variable != var1)  # Don't compare to self

      if (nrow(other_vars) == 0) return(NULL)

      similarities <- stringdist::stringsim(
        label1,
        other_vars$label_clean,
        method = "jw"  # Jaro-Winkler
      )

      # Keep only high-similarity matches (>= 0.7)
      high_sim <- which(similarities >= 0.7)

      if (length(high_sim) == 0) return(NULL)

      tibble(
        var1 = var1,
        var2 = other_vars$variable[high_sim],
        label1_short = batch_data$label_short[row_idx],
        label2_short = other_vars$label_short[high_sim],
        similarity = similarities[high_sim],
        waves1 = batch_data$waves[row_idx],
        waves2 = other_vars$waves[high_sim]
      )
    })

    similarity_results[[length(similarity_results) + 1]] <- batch_results
  }

  bind_rows(similarity_results)
}

# Run the similarity computation
similar_vars <- compute_similarity_batch(unique_vars, batch_size = 50)

cat("\n  ✓ Similarity computation complete\n")
cat("  - High-similarity pairs found:", nrow(similar_vars), "\n\n")

# ---------------------
# 4. Identify concept clusters
# ---------------------
cat("Identifying concept clusters...\n")

# Group similar variables into concepts
# Strategy: Variables with high similarity (>= 0.85) likely measure same concept

concept_clusters <- similar_vars %>%
  filter(similarity >= 0.85) %>%  # Very high similarity threshold
  arrange(desc(similarity))

# Create concept IDs based on clusters
# Use a simple approach: alphabetically first variable in cluster becomes concept ID
create_concept_id <- function(var1, var2) {
  paste(sort(c(var1, var2)), collapse = "_")
}

concept_clusters <- concept_clusters %>%
  mutate(
    concept_id = map2_chr(var1, var2, create_concept_id)
  )

cat("  - Concept clusters identified:", n_distinct(concept_clusters$concept_id), "\n\n")

# ---------------------
# 5. Create expanded crosswalk candidates
# ---------------------
cat("Creating expanded crosswalk template...\n")

# Reorganize into wide format: one row per concept
crosswalk_expanded <- q_vars_clean %>%
  # Add wave-specific columns
  select(wave, variable, label, value_labels_sample) %>%
  pivot_wider(
    id_cols = variable,
    names_from = wave,
    values_from = c(label, value_labels_sample),
    names_glue = "{wave}_{.value}"
  ) %>%
  # Clean up column names
  rename_with(
    ~str_replace(.x, "Wave(\\d+)_label", "w\\1_label"),
    starts_with("Wave")
  ) %>%
  rename_with(
    ~str_replace(.x, "Wave(\\d+)_value_labels_sample", "w\\1_values"),
    starts_with("Wave")
  ) %>%
  # Add presence indicators
  mutate(
    across(starts_with("w") & ends_with("_label"), ~!is.na(.x), .names = "{.col}_present")
  ) %>%
  # Count waves present
  rowwise() %>%
  mutate(
    n_waves_present = sum(c_across(ends_with("_label_present")), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  # Only keep variables in 2+ waves
  filter(n_waves_present >= 2) %>%
  arrange(desc(n_waves_present), variable)

cat("  - Variables in 2+ waves:", nrow(crosswalk_expanded), "\n\n")

# ---------------------
# 6. Add concept suggestions from similarity analysis
# ---------------------
cat("Adding concept suggestions from fuzzy matching...\n")

# For each variable, find its most similar variables from other waves
concept_suggestions <- map_dfr(crosswalk_expanded$variable, function(var) {

  # Find similar variables
  similar <- similar_vars %>%
    filter((var1 == var | var2 == var) & similarity >= 0.8) %>%
    arrange(desc(similarity)) %>%
    head(5)  # Top 5 matches

  if (nrow(similar) == 0) return(NULL)

  # Get the other variable in each pair
  other_vars <- ifelse(similar$var1 == var, similar$var2, similar$var1)

  tibble(
    variable = var,
    similar_variables = paste(other_vars, collapse = "; "),
    similarity_scores = paste(round(similar$similarity, 3), collapse = "; "),
    suggested_concept_group = paste(sort(unique(c(var, other_vars))), collapse = ", ")
  )
})

# Merge concept suggestions into crosswalk
crosswalk_with_suggestions <- crosswalk_expanded %>%
  left_join(concept_suggestions, by = "variable")

cat("  ✓ Concept suggestions added\n\n")

# ---------------------
# 7. Create domain classification hints
# ---------------------
cat("Generating domain classification hints...\n")

# Define keyword patterns for automatic domain assignment
domain_keywords <- tribble(
  ~domain, ~keywords,
  "trust", "trust|confidence",
  "economic", "economic|livelihood|income|poverty|employment|job",
  "democracy", "democracy|democratic|authoritarian",
  "politics", "politic|election|vote|party|campaign",
  "governance", "government|official|bureaucra|administration|public service",
  "corruption", "corrupt|bribe|bribery",
  "freedom", "freedom|liberty|free to",
  "equality", "equal|inequality|discrimination",
  "participation", "participate|join|involve|organize",
  "efficacy", "influence|say|voice|opinion matters",
  "satisfaction", "satisf|content|happy with",
  "media", "media|newspaper|television|tv|radio|internet|social media",
  "civil_society", "ngo|civil society|association|organization",
  "judiciary", "court|judge|legal|law enforcement",
  "legislature", "parliament|congress|legislature|assembly",
  "executive", "president|prime minister|executive|government leader",
  "military", "military|army|armed forces",
  "police", "police|law enforcement",
  "local_govt", "local government|municipal|village|community",
  "covid", "covid|coronavirus|pandemic|vaccination|vaccine",
  "identity", "identity|ethnic|religion|race|nationality",
  "social_capital", "neighbor|friend|relative|family|people you know",
  "values", "tradition|modern|religion|moral|value",
  "demographics", "age|education|gender|sex|income|occupation|residence"
)

# Function to suggest domain based on label keywords
suggest_domain <- function(label) {
  if (is.na(label)) return(NA_character_)

  label_lower <- tolower(label)

  # Find matching domains
  matches <- domain_keywords %>%
    filter(str_detect(label_lower, keywords)) %>%
    pull(domain)

  if (length(matches) == 0) return("other")

  # Return first match (or could concatenate multiple)
  paste(matches, collapse = "; ")
}

# Add domain suggestions
crosswalk_with_domains <- crosswalk_with_suggestions %>%
  mutate(
    suggested_domain = map_chr(w1_label %||% w2_label %||% w3_label %||% w4_label %||% w5_label %||% w6_label,
                                suggest_domain)
  )

cat("  ✓ Domain classification hints added\n\n")

# ---------------------
# 8. Export results
# ---------------------
cat("Exporting crosswalk expansion files...\n")

# Main expanded crosswalk template
write_csv(
  crosswalk_with_domains,
  here("docs/crosswalk_expanded_automated.csv")
)
cat("  ✓ docs/crosswalk_expanded_automated.csv\n")

# High-similarity pairs for manual review
write_csv(
  similar_vars %>%
    filter(similarity >= 0.85) %>%
    arrange(desc(similarity)),
  here("docs/high_similarity_pairs.csv")
)
cat("  ✓ docs/high_similarity_pairs.csv\n")

# Concept clusters for review
write_csv(
  concept_clusters %>%
    arrange(concept_id, desc(similarity)),
  here("docs/concept_clusters.csv")
)
cat("  ✓ docs/concept_clusters.csv\n")

# Domain-sorted variables for easier manual classification
domain_sorted <- crosswalk_with_domains %>%
  arrange(suggested_domain, desc(n_waves_present), variable) %>%
  select(
    variable,
    suggested_domain,
    n_waves_present,
    starts_with("w1_label"),
    starts_with("w2_label"),
    starts_with("w3_label"),
    starts_with("w4_label"),
    starts_with("w5_label"),
    starts_with("w6_label"),
    similar_variables,
    similarity_scores
  )

write_csv(
  domain_sorted,
  here("docs/crosswalk_by_domain.csv")
)
cat("  ✓ docs/crosswalk_by_domain.csv\n")

# Summary statistics
summary_stats <- tibble(
  metric = c(
    "Total q-variables across all waves",
    "Unique q-variables",
    "Variables in 2+ waves",
    "Variables in all 6 waves",
    "High-similarity pairs (>= 0.85)",
    "Concept clusters identified",
    "Variables with domain suggestions"
  ),
  count = c(
    nrow(q_vars),
    n_distinct(q_vars$variable),
    nrow(crosswalk_expanded),
    sum(crosswalk_expanded$n_waves_present == 6),
    nrow(similar_vars %>% filter(similarity >= 0.85)),
    n_distinct(concept_clusters$concept_id),
    sum(!is.na(crosswalk_with_domains$suggested_domain) &
          crosswalk_with_domains$suggested_domain != "other")
  )
)

write_csv(
  summary_stats,
  here("docs/crosswalk_expansion_summary.csv")
)
cat("  ✓ docs/crosswalk_expansion_summary.csv\n")

# ---------------------
# 9. Print summary
# ---------------------
cat("\n===== FUZZY MATCHING COMPLETE =====\n\n")

print(summary_stats)

cat("\n📊 GENERATED FILES:\n")
cat("  1. crosswalk_expanded_automated.csv - Main expanded crosswalk (",
    nrow(crosswalk_with_domains), " variables)\n", sep = "")
cat("  2. high_similarity_pairs.csv - Variables with 85%+ label similarity\n")
cat("  3. concept_clusters.csv - Grouped similar variables\n")
cat("  4. crosswalk_by_domain.csv - Variables sorted by domain\n")
cat("  5. crosswalk_expansion_summary.csv - Summary statistics\n")

cat("\n🔍 NEXT STEPS:\n")
cat("  1. Review 'crosswalk_by_domain.csv' for domain-specific variables\n")
cat("  2. Use 'high_similarity_pairs.csv' to validate automated matches\n")
cat("  3. Create concept names and harmonization rules\n")
cat("  4. Merge with existing 'abs_harmonization_crosswalk.csv'\n")
cat("  5. Document scale types and reversal needs by wave\n\n")

cat("✓ Ready for manual review and crosswalk expansion!\n\n")
