# ==============================================================================
# 03_expand_crosswalk_intelligently.R
# Intelligently expand the existing crosswalk using automated matching results
# This is your NEXT STEP - run this to expand from 46 to 150+ concepts
# ==============================================================================

cat("\n===== INTELLIGENT CROSSWALK EXPANSION =====\n\n")

# Load required packages
library(here)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(purrr)

# ---------------------
# 1. Load existing resources
# ---------------------
cat("Loading existing crosswalk and automated matches...\n")

# Load your existing manually-created crosswalk (46 concepts)
existing_crosswalk <- read_csv(here("abs_harmonization_crosswalk.csv"))

# Load automated matching results
high_sim_pairs <- read_csv(here("docs/high_similarity_pairs.csv"))
crosswalk_expanded <- read_csv(here("docs/crosswalk_expanded_automated.csv"))
nlp_enhanced <- read_csv(here("docs/crosswalk_nlp_enhanced.csv"))

cat("  ✓ Existing crosswalk:", nrow(existing_crosswalk), "concepts\n")
cat("  ✓ High-similarity pairs:", nrow(high_sim_pairs), "pairs\n")
cat("  ✓ Expanded candidates:", nrow(crosswalk_expanded), "variables\n\n")

# ---------------------
# 2. Extract variables already in existing crosswalk
# ---------------------
cat("Identifying variables already mapped...\n")

# Get all variable names from existing crosswalk across all waves
existing_vars <- existing_crosswalk %>%
  select(w2_var, w3_var, w4_var, w5_var, w6_var) %>%
  pivot_longer(everything(), values_to = "variable") %>%
  filter(!is.na(variable)) %>%
  pull(variable) %>%
  unique()

cat("  - Variables already mapped:", length(existing_vars), "\n\n")

# ---------------------
# 3. Find new high-quality matches
# ---------------------
cat("Finding new variables with high-quality matches...\n")

# Strategy: Focus on pairs with 95%+ similarity that aren't already mapped
new_high_quality <- high_sim_pairs %>%
  filter(similarity >= 0.85) %>%
  # Exclude pairs where both variables are already mapped
  filter(!(var1 %in% existing_vars & var2 %in% existing_vars)) %>%
  # Sort by similarity
  arrange(desc(similarity))

cat("  - New high-quality pairs (85%+):", nrow(new_high_quality), "\n\n")

# ---------------------
# 4. Group pairs into concept clusters
# ---------------------
cat("Grouping similar variables into concepts...\n")

# Create concept groups from high-similarity pairs
# Strategy: Variables that match each other form a concept

create_concept_clusters <- function(pairs_df) {
  # Start with empty clusters
  clusters <- list()
  cluster_id <- 1

  # Track which variables have been assigned
  assigned_vars <- c()

  for (i in 1:nrow(pairs_df)) {
    var1 <- pairs_df$var1[i]
    var2 <- pairs_df$var2[i]

    # Check if either variable is already in a cluster
    cluster_found <- FALSE
    for (j in seq_along(clusters)) {
      if (var1 %in% clusters[[j]] || var2 %in% clusters[[j]]) {
        clusters[[j]] <- unique(c(clusters[[j]], var1, var2))
        cluster_found <- TRUE
        break
      }
    }

    # If not found in existing cluster, create new one
    if (!cluster_found) {
      clusters[[cluster_id]] <- c(var1, var2)
      cluster_id <- cluster_id + 1
    }
  }

  # Convert to dataframe
  cluster_df <- map_dfr(seq_along(clusters), function(i) {
    tibble(
      cluster_id = i,
      variable = clusters[[i]]
    )
  })

  return(cluster_df)
}

concept_clusters <- create_concept_clusters(new_high_quality)

cat("  - Concept clusters created:", max(concept_clusters$cluster_id), "\n\n")

# ---------------------
# 5. Create expanded crosswalk entries
# ---------------------
cat("Creating new crosswalk entries...\n")

# For each cluster, get wave-specific information
new_crosswalk_entries <- concept_clusters %>%
  left_join(
    crosswalk_expanded %>%
      select(variable, starts_with("w"), n_waves_present, suggested_domain),
    by = "variable"
  ) %>%
  group_by(cluster_id) %>%
  summarise(
    # Collect all variables in cluster
    all_variables = paste(variable, collapse = ", "),
    n_variables = n(),

    # Get wave coverage (including Wave 1)
    w1_var = first(variable[!is.na(w1_label_present) & w1_label_present]),
    w2_var = first(variable[!is.na(w2_label_present) & w2_label_present]),
    w3_var = first(variable[!is.na(w3_label_present) & w3_label_present]),
    w4_var = first(variable[!is.na(w4_label_present) & w4_label_present]),
    w5_var = first(variable[!is.na(w5_label_present) & w5_label_present]),
    w6_var = first(variable[!is.na(w6_label_present) & w6_label_present]),

    # Get labels (including Wave 1)
    w1_label = first(w1_label[!is.na(w1_label)]),
    w2_label = first(w2_label[!is.na(w2_label)]),
    w3_label = first(w3_label[!is.na(w3_label)]),
    w4_label = first(w4_label[!is.na(w4_label)]),
    w5_label = first(w5_label[!is.na(w5_label)]),
    w6_label = first(w6_label[!is.na(w6_label)]),

    # Count waves present
    waves_present = sum(!is.na(c_across(starts_with("w") & ends_with("_var")))),

    # Get domain suggestion
    suggested_domain = first(suggested_domain[!is.na(suggested_domain)]),

    .groups = "drop"
  ) %>%
  # Only keep concepts with 2+ waves
  filter(waves_present >= 2) %>%
  # Add concept ID
  mutate(
    concept = paste0("concept_", str_pad(cluster_id, 3, pad = "0"))
  )

cat("  - New crosswalk entries:", nrow(new_crosswalk_entries), "\n")
cat("  - Average waves per concept:", round(mean(new_crosswalk_entries$waves_present), 1), "\n\n")

# ---------------------
# 6. Generate concept names and descriptions
# ---------------------
cat("Generating concept names from labels...\n")

# Function to create a concept name from labels
create_concept_name <- function(labels) {
  # Get non-NA labels
  valid_labels <- labels[!is.na(labels)]
  if (length(valid_labels) == 0) return(NA_character_)

  # Use first label as base
  label <- valid_labels[1]

  # Extract key words (simplified approach)
  label_lower <- tolower(label)

  # Shorten to first ~50 chars
  concept_desc <- str_trunc(label, 50)

  return(concept_desc)
}

new_crosswalk_entries <- new_crosswalk_entries %>%
  rowwise() %>%
  mutate(
    description = create_concept_name(c(w1_label, w2_label, w3_label, w4_label, w5_label, w6_label))
  ) %>%
  ungroup()

cat("  ✓ Concept names generated\n\n")

# ---------------------
# 7. Format to match existing crosswalk structure
# ---------------------
cat("Formatting to match existing crosswalk structure...\n")

# Create new entries in same format as existing crosswalk
new_entries_formatted <- new_crosswalk_entries %>%
  transmute(
    concept = concept,
    domain = suggested_domain,
    description = description,

    # Wave 1 (ADDED)
    w1_var = w1_var,
    w1_scale = NA_character_,  # To be filled manually

    # Wave 2
    w2_var = w2_var,
    w2_scale = NA_character_,

    # Wave 3
    w3_var = w3_var,
    w3_scale = NA_character_,

    # Wave 4
    w4_var = w4_var,
    w4_scale = NA_character_,

    # Wave 5
    w5_var = w5_var,
    w5_scale = NA_character_,

    # Wave 6
    w6_var = w6_var,
    w6_scale = NA_character_,

    # Harmonization fields
    harmonized_name = paste0(concept, "_harm"),
    harmonize_to = NA_character_,
    reverse_waves = NA_character_,
    notes = paste0("Auto-generated from ", waves_present, " waves (including W1 where present). REVIEW NEEDED.")
  )

cat("  ✓ Formatted", nrow(new_entries_formatted), "new entries\n\n")

# ---------------------
# 8. Combine with existing crosswalk
# ---------------------
cat("Combining with existing crosswalk...\n")

# Ensure column compatibility
existing_cols <- names(existing_crosswalk)
new_cols <- names(new_entries_formatted)

# Add missing columns to new entries if needed
for (col in existing_cols) {
  if (!(col %in% new_cols)) {
    new_entries_formatted[[col]] <- NA
  }
}

# Reorder columns to match
new_entries_formatted <- new_entries_formatted %>%
  select(all_of(existing_cols))

# Combine
expanded_crosswalk <- bind_rows(
  existing_crosswalk %>% mutate(source = "existing"),
  new_entries_formatted %>% mutate(source = "auto-generated")
)

cat("  ✓ Combined crosswalk:\n")
cat("    - Existing concepts:", sum(expanded_crosswalk$source == "existing"), "\n")
cat("    - New concepts:", sum(expanded_crosswalk$source == "auto-generated"), "\n")
cat("    - Total concepts:", nrow(expanded_crosswalk), "\n\n")

# ---------------------
# 9. Create summary by domain
# ---------------------
cat("Creating domain summary...\n")

domain_summary <- expanded_crosswalk %>%
  group_by(domain, source) %>%
  summarise(
    n_concepts = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = source,
    values_from = n_concepts,
    values_fill = 0
  ) %>%
  mutate(
    total = existing + `auto-generated`
  ) %>%
  arrange(desc(total))

cat("  ✓ Domain summary created\n\n")

# ---------------------
# 10. Export results
# ---------------------
cat("Exporting expanded crosswalk...\n")

# Main expanded crosswalk
write_csv(
  expanded_crosswalk,
  here("abs_harmonization_crosswalk_EXPANDED.csv")
)
cat("  ✓ abs_harmonization_crosswalk_EXPANDED.csv\n")

# Variables for manual review (ones needing scale documentation)
needs_review <- expanded_crosswalk %>%
  filter(source == "auto-generated") %>%
  select(concept, domain, description, w2_var:w6_var, notes)

write_csv(
  needs_review,
  here("docs/new_concepts_needs_review.csv")
)
cat("  ✓ docs/new_concepts_needs_review.csv\n")

# Domain summary
write_csv(
  domain_summary,
  here("docs/crosswalk_expansion_by_domain.csv")
)
cat("  ✓ docs/crosswalk_expansion_by_domain.csv\n")

# Detailed mapping showing cluster membership
detailed_mapping <- concept_clusters %>%
  left_join(
    new_crosswalk_entries %>% select(cluster_id, concept, description, waves_present),
    by = "cluster_id"
  ) %>%
  arrange(concept, variable)

write_csv(
  detailed_mapping,
  here("docs/concept_cluster_membership.csv")
)
cat("  ✓ docs/concept_cluster_membership.csv\n\n")

# ---------------------
# 11. Print summary
# ---------------------
cat("===== CROSSWALK EXPANSION COMPLETE =====\n\n")

cat("📊 SUMMARY:\n")
cat("  Original crosswalk:", sum(expanded_crosswalk$source == "existing"), "concepts\n")
cat("  New concepts added:", sum(expanded_crosswalk$source == "auto-generated"), "concepts\n")
cat("  Total crosswalk:", nrow(expanded_crosswalk), "concepts\n\n")

cat("📈 DOMAIN DISTRIBUTION:\n")
print(domain_summary, n = 20)

cat("\n📁 GENERATED FILES:\n")
cat("  1. abs_harmonization_crosswalk_EXPANDED.csv - Main expanded crosswalk\n")
cat("  2. docs/new_concepts_needs_review.csv - New concepts requiring manual review\n")
cat("  3. docs/crosswalk_expansion_by_domain.csv - Domain summary\n")
cat("  4. docs/concept_cluster_membership.csv - Detailed cluster membership\n")

cat("\n🔍 NEXT STEPS:\n")
cat("  1. Review 'new_concepts_needs_review.csv'\n")
cat("  2. For each new concept:\n")
cat("     a. Verify the description is accurate\n")
cat("     b. Assign domain (trust, economic, democracy, etc.)\n")
cat("     c. Document scale types (4pt, 5pt, 6pt, etc.)\n")
cat("     d. Identify which waves need reversal\n")
cat("  3. Update 'abs_harmonization_crosswalk_EXPANDED.csv' with your edits\n")
cat("  4. Run harmonization functions to create harmonized datasets\n\n")

cat("✓ Ready for manual review and scale documentation!\n\n")
