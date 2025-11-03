# ============================================================================
# Trust Scale Distribution Comparison
# ============================================================================
#
# Purpose: Compare distributions of 4-point vs 6-point trust scales
# to assess whether 0-1 normalization is appropriate for cross-wave analysis
#
# Input: Harmonized data from data/processed/ (already filtered for Cambodia)
# Output: Visualizations showing response distributions by scale type
# ============================================================================

library(here)
library(dplyr)
library(tidyr)
library(ggplot2)
library(labelled)  # For unlabelling haven data

# ============================================================================
# LOAD HARMONIZED DATA
# ============================================================================

w2 <- readRDS(here("data/processed/w2_cambodia_harmonized.rds"))
w3 <- readRDS(here("data/processed/w3_cambodia_harmonized.rds"))
w4 <- readRDS(here("data/processed/w4_cambodia_harmonized.rds"))
w5 <- readRDS(here("data/processed/w5_cambodia_harmonized.rds"))
w6 <- readRDS(here("data/processed/w6_cambodia_harmonized.rds"))

message("Data loaded from data/processed/")
message("W2: ", nrow(w2), " observations")
message("W3: ", nrow(w3), " observations")
message("W4: ", nrow(w4), " observations")
message("W5: ", nrow(w5), " observations")
message("W6: ", nrow(w6), " observations")

# ============================================================================
# PREPARE INSTITUTIONAL TRUST DATA (q7-q19)
# ============================================================================

# Institutional trust variables (harmonized)
inst_trust_vars <- paste0("q", 7:19, "_harm")

# Combine waves with scale type indicator
prepare_trust_data <- function(data, wave_name, scale_type) {
  # Determine valid range based on scale type
  valid_range <- if (scale_type == "4-point") 1:4 else 1:6

  data %>%
    select(wave, all_of(inst_trust_vars[inst_trust_vars %in% names(data)])) %>%
    mutate(across(-wave, ~as.numeric(.))) %>%  # Convert to numeric (except wave column)
    pivot_longer(
      cols = -wave,
      names_to = "variable",
      values_to = "trust"
    ) %>%
    filter(!is.na(trust) & trust %in% valid_range) %>%  # Filter to valid range only
    mutate(
      scale_type = scale_type,
      wave_label = wave_name
    )
}

inst_trust_all <- bind_rows(
  prepare_trust_data(w2, "Wave 2 (2005-08)", "4-point"),
  prepare_trust_data(w3, "Wave 3 (2010-12)", "6-point"),
  prepare_trust_data(w4, "Wave 4 (2014-16)", "4-point"),
  prepare_trust_data(w5, "Wave 5 (2018)", "6-point"),
  prepare_trust_data(w6, "Wave 6 (2020)", "4-point")
)

message("\nInstitutional trust data prepared")
message("Total observations: ", nrow(inst_trust_all))

# ============================================================================
# PREPARE SOCIAL TRUST DATA (q23-q27)
# ============================================================================

# Social trust variables (q23 = general trust, q24-q27 = specific groups)
social_trust_vars <- paste0("q", 23:27, "_harm")

prepare_social_trust_data <- function(data, wave_name, scale_type) {
  # Determine valid range based on scale type
  valid_range <- if (scale_type == "4-point") 1:4 else 1:6

  data %>%
    select(wave, all_of(social_trust_vars[social_trust_vars %in% names(data)])) %>%
    mutate(across(-wave, ~as.numeric(.))) %>%  # Convert to numeric (except wave column)
    pivot_longer(
      cols = -wave,
      names_to = "variable",
      values_to = "trust"
    ) %>%
    filter(!is.na(trust) & trust %in% valid_range) %>%  # Filter to valid range only
    mutate(
      scale_type = scale_type,
      wave_label = wave_name
    )
}

social_trust_all <- bind_rows(
  prepare_social_trust_data(w2, "Wave 2 (2005-08)", "4-point"),
  prepare_social_trust_data(w3, "Wave 3 (2010-12)", "6-point"),
  prepare_social_trust_data(w4, "Wave 4 (2014-16)", "4-point"),
  prepare_social_trust_data(w5, "Wave 5 (2018)", "6-point"),
  prepare_social_trust_data(w6, "Wave 6 (2020)", "4-point")
)

message("\nSocial trust data prepared")
message("Total observations: ", nrow(social_trust_all))

# ============================================================================
# VISUALIZATION: INSTITUTIONAL TRUST
# ============================================================================

# Overall distribution by scale type
p1 <- ggplot(inst_trust_all, aes(x = factor(trust), fill = scale_type)) +
  geom_bar(position = "fill") +
  labs(
    title = "Institutional Trust: Distribution by Scale Type",
    subtitle = "Cambodia Waves 2-6 (q7-q19 harmonized, higher = more trust)",
    y = "Proportion within scale",
    x = "Trust response",
    fill = "Scale Type"
  ) +
  scale_fill_manual(values = c("4-point" = "#2E86AB", "6-point" = "#A23B72")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top"
  )

# Distribution by wave
p2 <- ggplot(inst_trust_all, aes(x = factor(trust), fill = scale_type)) +
  geom_bar(position = "fill") +
  facet_wrap(~wave_label, ncol = 3) +
  labs(
    title = "Institutional Trust: Distribution by Wave",
    subtitle = "Cambodia Waves 2-6 (q7-q19 harmonized, higher = more trust)",
    y = "Proportion",
    x = "Trust response",
    fill = "Scale Type"
  ) +
  scale_fill_manual(values = c("4-point" = "#2E86AB", "6-point" = "#A23B72")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top",
    strip.text = element_text(face = "bold")
  )

# Save plots
ggsave(
  here("output/figures/institutional_trust_scale_comparison.png"),
  p1,
  width = 10, height = 6, dpi = 300
)

ggsave(
  here("output/figures/institutional_trust_by_wave.png"),
  p2,
  width = 12, height = 8, dpi = 300
)

message("\nInstitutional trust plots saved")

# ============================================================================
# VISUALIZATION: SOCIAL TRUST
# ============================================================================

# Overall distribution by scale type
p3 <- ggplot(social_trust_all, aes(x = factor(trust), fill = scale_type)) +
  geom_bar(position = "fill") +
  labs(
    title = "Social Trust: Distribution by Scale Type",
    subtitle = "Cambodia Waves 2-6 (q23-q27 harmonized, higher = more trust)",
    y = "Proportion within scale",
    x = "Trust response",
    fill = "Scale Type"
  ) +
  scale_fill_manual(values = c("4-point" = "#2E86AB", "6-point" = "#A23B72")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top"
  )

# Distribution by wave
p4 <- ggplot(social_trust_all, aes(x = factor(trust), fill = scale_type)) +
  geom_bar(position = "fill") +
  facet_wrap(~wave_label, ncol = 3) +
  labs(
    title = "Social Trust: Distribution by Wave",
    subtitle = "Cambodia Waves 2-6 (q23-q27 harmonized, higher = more trust)",
    y = "Proportion",
    x = "Trust response",
    fill = "Scale Type"
  ) +
  scale_fill_manual(values = c("4-point" = "#2E86AB", "6-point" = "#A23B72")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top",
    strip.text = element_text(face = "bold")
  )

# Save plots
ggsave(
  here("output/figures/social_trust_scale_comparison.png"),
  p3,
  width = 10, height = 6, dpi = 300
)

ggsave(
  here("output/figures/social_trust_by_wave.png"),
  p4,
  width = 12, height = 8, dpi = 300
)

message("\nSocial trust plots saved")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

# Institutional trust summary
inst_summary <- inst_trust_all %>%
  group_by(wave_label, scale_type) %>%
  summarize(
    n = n(),
    mean = mean(trust, na.rm = TRUE),
    median = median(trust, na.rm = TRUE),
    sd = sd(trust, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(wave_label)

# Social trust summary
social_summary <- social_trust_all %>%
  group_by(wave_label, scale_type) %>%
  summarize(
    n = n(),
    mean = mean(trust, na.rm = TRUE),
    median = median(trust, na.rm = TRUE),
    sd = sd(trust, na.rm = TRUE),
    .groups = "drop"
  )

# Print summaries
cat("\n=== INSTITUTIONAL TRUST SUMMARY ===\n")
print(inst_summary)

cat("\n=== SOCIAL TRUST SUMMARY ===\n")
print(social_summary)

# Save summaries
write.csv(inst_summary,
          here("output/tables/institutional_trust_summary.csv"),
          row.names = FALSE)

write.csv(social_summary,
          here("output/tables/social_trust_summary.csv"),
          row.names = FALSE)

message("\n=== ANALYSIS COMPLETE ===")
message("Plots saved to: output/figures/")
message("Summaries saved to: output/tables/")
