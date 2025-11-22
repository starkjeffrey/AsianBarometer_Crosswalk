# ==============================================================================
# verify_update_master_w5.R
# Cross-verifies Wave 5 variables against the MASTER crosswalk and applies
# corrections based on W5_labels.txt analysis
# ==============================================================================

library(dplyr)
library(readr)
library(here)

cat("\n")
cat("=================================================================\n")
cat("  WAVE 5 CROSS-VERIFICATION AND UPDATE\n")
cat("=================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. Load the current MASTER crosswalk
# -----------------------------------------------------------------------------
cat("Loading MASTER crosswalk...\n")
master <- read_csv(here("abs_harmonization_crosswalk_MASTER.csv"), show_col_types = FALSE)
cat(paste("  Total concepts:", nrow(master), "\n"))

# Current W5 coverage
w5_coverage_before <- sum(!is.na(master$w5_var) & master$w5_var != "NA")
cat(paste("  W5 variables before update:", w5_coverage_before, "\n\n"))

# -----------------------------------------------------------------------------
# 2. W5 CORRECTIONS - Based on W5_labels.txt analysis
# Wave 5 has DIFFERENT variable numbering from W4 in many key areas
# -----------------------------------------------------------------------------
cat("Applying W5 corrections based on W5_labels.txt verification...\n\n")

# CRITICAL CORRECTIONS:
# W5 q46 = Interest in politics (MASTER incorrectly has q89)
# W5 q47 = Follow news about politics (MASTER incorrectly has q92)
# W5 q48 = Discuss political matters with family/friends
# W5 q99 = Satisfaction with democracy (MASTER incorrectly has q90)
# W5 q100 = How much of a democracy (4pt) - different from 10pt democracy_scale
# W5 q101 = Democracy scale current (10pt)
# W5 q102 = Democracy scale past (10pt)
# W5 q103 = Democracy scale future (10pt)
# W5 q104 = Democracy suitable for country (10pt)
# W5 q105 = Government satisfaction (4pt)
# W5 q132 = Democracy preferable (MASTER incorrectly has q124)
# W5 q137 = Strong leader support (MASTER incorrectly has q132)
# W5 q138 = One party rule support
# W5 q139 = Army rule support (MASTER incorrectly has q133)
# W5 q140 = Expert decide support (MASTER incorrectly has q134)

# Define corrections as a named vector: concept -> correct_w5_var
w5_corrections <- tribble(
  ~concept, ~correct_w5_var, ~correct_w5_scale, ~note,

  # POLITICAL INTEREST - CRITICAL CORRECTIONS
  "interest_politics", "q46", "4pt_1low", "W5 q46 is interest in politics (1=not at all to 4=very interested)",
  "follow_news", "q47", "5pt_1high", "W5 q47 is follow news (1=daily to 5=never)",

  # DEMOCRACY/REGIME SCALES - CRITICAL CORRECTIONS
  "satisfaction_democracy", "q99", "4pt_1high", "W5 q99 is satisfaction with democracy (1=very satisfied to 4=not at all)",
  "democracy_scale_current", "q101", "10pt_1low", "W5 q101 is democracy scale present (1=undemocratic to 10=democratic)",
  "democracy_scale_past", "q102", "10pt_1low", "W5 q102 is democracy scale 10 years ago",
  "democracy_scale_future", "q103", "10pt_1low", "W5 q103 is democracy scale 10 years from now",
  "democracy_suitable", "q104", "10pt_1low", "W5 q104 is democracy suitable for country (1=unsuitable to 10=suitable)",
  "govt_satisfaction", "q105", "4pt_1high", "W5 q105 is satisfaction with government (1=very satisfied to 4=very dissatisfied)",
  "level_democracy", "q100", "4pt_1high", "W5 q100 is how much of a democracy (1=full to 4=not democracy)",

  # REGIME SUPPORT - CRITICAL CORRECTIONS
  "democracy_preferable", "q132", "3opt", "W5 q132 is democracy preferable statement",
  "strong_leader_support", "q137", "4pt_1agree", "W5 q137 is strong leader without elections (1=strongly agree to 4=strongly disagree)",
  "army_rule_support", "q139", "4pt_1agree", "W5 q139 is army should govern (1=strongly agree to 4=strongly disagree)",
  "expert_decide_support", "q140", "4pt_1agree", "W5 q140 is experts make decisions (1=strongly agree to 4=strongly disagree)"
)

# Apply corrections
corrections_applied <- 0
for (i in seq_len(nrow(w5_corrections))) {
  concept_name <- w5_corrections$concept[i]
  correct_var <- w5_corrections$correct_w5_var[i]
  correct_scale <- w5_corrections$correct_w5_scale[i]

  row_idx <- which(master$concept == concept_name)
  if (length(row_idx) == 1) {
    old_var <- master$w5_var[row_idx]
    if (!is.na(old_var) && old_var != correct_var) {
      cat(paste("  CORRECTING", concept_name, ":", old_var, "->", correct_var, "\n"))
      master$w5_var[row_idx] <- correct_var
      master$w5_scale[row_idx] <- correct_scale
      corrections_applied <- corrections_applied + 1
    } else if (is.na(old_var) || old_var == "NA") {
      cat(paste("  ADDING", concept_name, ":", correct_var, "\n"))
      master$w5_var[row_idx] <- correct_var
      master$w5_scale[row_idx] <- correct_scale
      corrections_applied <- corrections_applied + 1
    }
  }
}

cat(paste("\n  Corrections applied:", corrections_applied, "\n\n"))

# -----------------------------------------------------------------------------
# 3. Add one_party_rule_support for W5 (q138)
# -----------------------------------------------------------------------------
cat("Adding one_party_rule_support W5 variable...\n")
row_idx <- which(master$concept == "one_party_rule_support")
if (length(row_idx) == 1) {
  if (is.na(master$w5_var[row_idx]) || master$w5_var[row_idx] == "NA") {
    master$w5_var[row_idx] <- "q138"
    master$w5_scale[row_idx] <- "4pt_1agree"
    cat("  Added: one_party_rule_support -> q138\n")
  }
}

# -----------------------------------------------------------------------------
# 4. W5-specific concepts to add to existing concepts
# These exist in W5 but may not have W5 mappings in MASTER
# -----------------------------------------------------------------------------
cat("\nAdding W5 mappings to existing concepts...\n")

w5_existing_additions <- tribble(
  ~concept, ~w5_var, ~w5_scale, ~note,

  # Trust variables - W5 uses 6pt scale (1=trust fully to 6=distrust fully)
  # These should already be in MASTER but verify scale designation
  "trust_executive", "q7", "6pt", "W5 6pt trust scale (1=trust fully to 6=distrust fully)",
  "trust_courts", "q8", "6pt", "W5 6pt trust scale",
  "trust_national_govt", "q9", "6pt", "W5 6pt trust scale",
  "trust_parties", "q10", "6pt", "W5 6pt trust scale",
  "trust_parliament", "q11", "6pt", "W5 6pt trust scale",
  "trust_civil_service", "q12", "6pt", "W5 6pt trust scale",
  "trust_military", "q13", "6pt", "W5 6pt trust scale",
  "trust_police", "q14", "6pt", "W5 6pt trust scale",
  "trust_local_govt", "q15", "6pt", "W5 6pt trust scale",
  "trust_election_commission", "q16", "6pt", "W5 6pt trust scale",
  "trust_ngos", "q17", "6pt", "W5 6pt trust scale",

  # Participation - W5 has 5pt scale (1=more than 3 times... 5=would not do)
  "contact_elected_officials", "q70", "5pt_done", "W5 q70 is contact elected officials (5pt participation scale)",
  "contact_higher_officials", "q71", "5pt_done", "W5 q71 is contact civil servants (5pt participation scale)",
  "contact_influential_people", "q72", "5pt_done", "W5 q72 is contact influential people outside govt",
  "contact_media", "q73", "5pt_done", "W5 q73 is contact news media",
  "petition_sign", "q74", "5pt_done", "W5 q74 is signed paper petition",
  "collective_problem_solving", "q78", "5pt_done", "W5 q78 is got together to resolve local problems",
  "attend_demonstration", "q79", "5pt_done", "W5 q79 is attended demonstration/protest",
  "use_force_violence", "q80", "5pt_done", "W5 q80 is risky political action",

  # Electoral participation
  "voting_frequency_pattern", "q81", "4pt_1high", "W5 q81 is voting frequency (1=every to 4=hardly ever)",

  # Traditionalism - W5 uses 4pt agree-disagree
  "family_over_individual", "q58", "4pt_1trad", "W5 q58 is family over individual",
  "sacrifice_individual_group", "q59", "4pt_1trad", "W5 q59 is sacrifice for group",
  "sacrifice_individual_nation", "q60", "4pt_1trad", "W5 q60 is sacrifice for nation",
  "immediate_vs_longterm", "q61", "4pt_1trad", "W5 q61 is long-term relationships",
  "obey_parents_unreasonable", "q62", "4pt_1trad", "W5 q62 is obey parents even if unreasonable",
  "mother_in_law_conflict", "q63", "4pt_1trad", "W5 q63 is mother-in-law conflict",
  "not_question_teacher", "q64", "4pt_1trad", "W5 q64 is don't question teacher",
  "avoid_open_quarrel", "q65", "4pt_1trad", "W5 q65 is avoid open quarrel",
  "avoid_disagreement_conflict", "q66", "4pt_1trad", "W5 q66 is avoid conflict with disagreement",
  "not_insist_opinion_coworkers", "q67", "4pt_1trad", "W5 q67 is not insist opinion if coworkers disagree",
  "fate_determines_success", "q68", "4pt_1trad", "W5 q68 is fate determines success",
  "prefer_boy_child", "q69", "4pt_1trad", "W5 q69 is prefer boy over girl",

  # System support
  "system_solve_problems", "q86", "4pt_1agree", "W5 q86 is system capable of solving problems",
  "system_pride", "q87", "4pt_1agree", "W5 q87 is proud of system",
  "system_deserves_support", "q88", "4pt_1agree", "W5 q88 is system deserves support",
  "system_prefer_own", "q89", "4pt_1agree", "W5 q89 is prefer own system",
  "system_change_needed", "q90", "4pt_1fine", "W5 q90 is system works fine vs needs change",

  # Partisanship
  "party_closeness", "q55", "categorical", "W5 q55 is which party closest to",
  "party_closeness_strength", "q56", "3pt_1high", "W5 q56 is how close to party",

  # Social trust
  "trust_gen_binary", "q22", "3opt", "W5 q22 is most people can be trusted (3 options)",
  "trust_gen_trustworthy", "q23", "4pt_1agree", "W5 q23 is most people trustworthy (agree scale)",
  "trust_relatives", "q24", "6pt_1high", "W5 q24 is trust in relatives (6pt)",
  "trust_neighbors", "q25", "6pt_1high", "W5 q25 is trust in neighbors (6pt)",
  "trust_others_interact", "q26", "6pt_1high", "W5 q26 is trust in people you interact with",
  "trust_first_meet", "q27", "6pt_1high", "W5 q27 is trust in people you meet first time",

  # Social capital
  "support_receive", "q31", "4pt_1high", "W5 q31 is people to help with problems",
  "political_tolerance", "q32", "4pt_1high", "W5 q32 is difficulty conversing with different views",

  # Democracy questions
  "democracy_best_form", "q136", "4pt_1agree", "W5 q136 is democracy best form despite problems",
  "democracy_solve_problems", "q133", "binary", "W5 q133 is democracy can solve problems (binary)",
  "democracy_vs_development", "q134", "5pt_compare", "W5 q134 is democracy vs economic development",
  "equality_vs_freedom", "q135", "5pt_compare", "W5 q135 is equality vs freedom"
)

additions_made <- 0
for (i in seq_len(nrow(w5_existing_additions))) {
  concept_name <- w5_existing_additions$concept[i]
  w5_var <- w5_existing_additions$w5_var[i]
  w5_scale <- w5_existing_additions$w5_scale[i]

  row_idx <- which(master$concept == concept_name)
  if (length(row_idx) == 1) {
    if (is.na(master$w5_var[row_idx]) || master$w5_var[row_idx] == "NA") {
      master$w5_var[row_idx] <- w5_var
      master$w5_scale[row_idx] <- w5_scale
      cat(paste("  Added W5 to", concept_name, ":", w5_var, "\n"))
      additions_made <- additions_made + 1
    }
  }
}

cat(paste("\n  W5 additions to existing concepts:", additions_made, "\n"))

# -----------------------------------------------------------------------------
# 5. NEW W5 CONCEPTS - Variables unique to W5 or not yet in MASTER
# -----------------------------------------------------------------------------
cat("\nAdding new W5 concepts...\n")

new_w5_concepts <- tribble(
  ~concept, ~domain, ~description, ~w5_var, ~w5_scale, ~notes,

  # Media trust - W5 specific items
  "trust_tv_w5", "trust", "Trust in television (W5 specific)", "q53", "6pt", "W5 q53 is trust in TV (6pt 1=trust fully to 6=distrust)",
  "trust_newspapers_w5", "trust", "Trust in newspapers (W5 specific)", "q54", "6pt", "W5 q54 is trust in newspapers (6pt)",
  "trust_internet_news_w5", "trust", "Trust in internet news (W5 specific)", "q57", "6pt", "W5 q57 is trust in internet news (6pt)",

  # Online petition (distinct from paper petition)
  "petition_sign_online", "participation", "Signed an online petition", "q75", "5pt_done", "W5 q75 is signed online petition (5pt participation scale)",

  # Internet political participation
  "internet_express_politics_w5", "participation", "Used internet/social media to express political opinions", "q76", "5pt_done", "W5 q76 is internet for political opinions (5pt participation)",

  # Join group for cause
  "join_group_cause", "participation", "Joined group to support a cause (including online)", "q77", "5pt_done", "W5 q77 is joined group for cause (5pt participation)",

  # Government responsiveness binary choices
  "govt_implement_vs_decide", "governance", "Govt implements voter wants vs does what thinks best", "q82", "binary_choice", "W5 q82 is govt responsiveness binary choice",
  "accountability_vs_efficiency", "governance", "Hold govt accountable vs get things done", "q83", "binary_choice", "W5 q83 is accountability vs efficiency binary",
  "press_freedom_vs_control", "governance", "Media right to publish vs govt right to prevent", "q84", "binary_choice", "W5 q84 is press freedom binary choice",
  "leaders_elected_vs_virtue", "governance", "Leaders chosen by election vs by virtue/capability", "q85", "binary_choice", "W5 q85 is leader selection binary choice",

  # Democracy understanding 10pt scales
  "demchar_courts_protect", "democracy", "Courts protect from govt abuse (essential for democracy)", "q91", "10pt_1low", "W5 q91 is courts protect (1=not essential to 10=essential)",
  "demchar_clean_politics", "democracy", "Politics clean and free of corruption (essential)", "q92", "10pt_1low", "W5 q92 is clean politics (10pt essential scale)",
  "demchar_protest_freedom", "democracy", "Freedom to protest (essential for democracy)", "q93", "10pt_1low", "W5 q93 is protest freedom (10pt essential scale)",
  "demchar_religious_authority", "democracy", "Govt consults religious authorities (essential)", "q94", "10pt_1low", "W5 q94 is religious authority (10pt essential scale)",
  "demchar_leader_wisdom", "democracy", "Leaders rule by wisdom not preferences (essential)", "q95", "10pt_1low", "W5 q95 is leader wisdom (10pt essential scale)",
  "demchar_one_party", "democracy", "One party represents all classes (essential)", "q96", "10pt_1low", "W5 q96 is one party (10pt essential scale)",
  "demchar_religious_leaders", "democracy", "Religious leaders pre-select candidates (essential)", "q97", "10pt_1low", "W5 q97 is religious selection (10pt essential scale)",

  # Most essential democracy element (forced choice)
  "democracy_essential_choice", "democracy", "Most essential element of democracy (forced choice)", "q98", "4opt", "W5 q98 is forced choice between 4 democracy elements",

  # Democracy perceptions of other countries
  "democracy_china", "international", "Where place China on democracy scale", "q127", "10pt_1low", "W5 q127 is China democracy perception (10pt)",
  "democracy_usa", "international", "Where place USA on democracy scale", "q128", "10pt_1low", "W5 q128 is USA democracy perception (10pt)",
  "democracy_japan", "international", "Where place Japan on democracy scale", "q130", "10pt_1low", "W5 q130 is Japan democracy perception (10pt)",
  "democracy_india", "international", "Where place India on democracy scale", "q131", "10pt_1low", "W5 q131 is India democracy perception (10pt)",

  # Social media specific items
  "socialmedia_connect_w5", "internet", "Use social media to connect with people (W5)", "q51a", "binary_1yes", "W5 q51a is social media for connecting (binary)",
  "socialmedia_politics_w5", "internet", "Use social media for political opinions (W5)", "q51b", "binary_1yes", "W5 q51b is social media for politics (binary)",
  "socialmedia_share_w5", "internet", "Use social media to share news/info (W5)", "q51c", "binary_1yes", "W5 q51c is social media for sharing (binary)"
)

# Add new concepts
new_concepts_added <- 0
for (i in seq_len(nrow(new_w5_concepts))) {
  concept_name <- new_w5_concepts$concept[i]

  # Check if concept already exists
  if (!concept_name %in% master$concept) {
    new_row <- tibble(
      concept = concept_name,
      domain = new_w5_concepts$domain[i],
      description = new_w5_concepts$description[i],
      w1_var = NA_character_,
      w1_scale = NA_character_,
      w2_var = NA_character_,
      w2_scale = NA_character_,
      w3_var = NA_character_,
      w3_scale = NA_character_,
      w4_var = NA_character_,
      w4_scale = NA_character_,
      w5_var = new_w5_concepts$w5_var[i],
      w5_scale = new_w5_concepts$w5_scale[i],
      w6_var = NA_character_,
      w6_scale = NA_character_,
      harmonized_name = NA_character_,
      harmonize_to = NA_character_,
      reverse_waves = NA_character_,
      notes = new_w5_concepts$notes[i],
      source = "w5_verification",
      w1_label = NA_character_
    )
    master <- bind_rows(master, new_row)
    new_concepts_added <- new_concepts_added + 1
    cat(paste("  NEW:", concept_name, "->", new_w5_concepts$w5_var[i], "\n"))
  }
}

cat(paste("\n  New W5 concepts added:", new_concepts_added, "\n"))

# -----------------------------------------------------------------------------
# 6. Summary and save
# -----------------------------------------------------------------------------
cat("\n=================================================================\n")
cat("  W5 VERIFICATION SUMMARY\n")
cat("=================================================================\n\n")

w5_coverage_after <- sum(!is.na(master$w5_var) & master$w5_var != "NA")
cat(paste("W5 variables before:", w5_coverage_before, "\n"))
cat(paste("W5 variables after:", w5_coverage_after, "\n"))
cat(paste("Net change:", w5_coverage_after - w5_coverage_before, "\n"))
cat(paste("Corrections applied:", corrections_applied, "\n"))
cat(paste("New concepts added:", new_concepts_added, "\n\n"))

# Coverage summary
cat("Coverage summary:\n")
master %>%
  summarise(
    Total_Concepts = n(),
    Has_W1 = sum(!is.na(w1_var) & w1_var != "NA"),
    Has_W2 = sum(!is.na(w2_var) & w2_var != "NA"),
    Has_W3 = sum(!is.na(w3_var) & w3_var != "NA"),
    Has_W4 = sum(!is.na(w4_var) & w4_var != "NA"),
    Has_W5 = sum(!is.na(w5_var) & w5_var != "NA"),
    Has_W6 = sum(!is.na(w6_var) & w6_var != "NA")
  ) %>%
  print()

# Save updated crosswalk
cat("\n\nSaving updated MASTER crosswalk...\n")
write_csv(master, here("abs_harmonization_crosswalk_MASTER.csv"))
cat("  Saved: abs_harmonization_crosswalk_MASTER.csv\n")

# -----------------------------------------------------------------------------
# 7. W5 SCALE NOTES
# -----------------------------------------------------------------------------
cat("\n\nW5 SCALE CODING NOTES:\n")
cat("-------------------------\n")
cat("TRUST (q7-q17): 6pt scale (1=Trust fully to 6=Distrust fully). HIGHER=LESS trust\n")
cat("  NOTE: This is DIFFERENT from W4 (4pt) and needs special handling for harmonization\n")
cat("ECONOMIC (q1-q6): 5pt scale (1=Very good to 5=Very bad). Same direction as W3-W4\n")
cat("INTEREST (q46): 4pt (1=Not interested at all to 4=Very interested). HIGHER=MORE\n")
cat("FOLLOW NEWS (q47): 5pt (1=Every day to 5=Never). HIGHER=LESS\n")
cat("PARTICIPATION (q70-q80): 5pt scale with:\n")
cat("  1=More than 3 times, 2=2-3 times, 3=Once, 4=Not done but might, 5=Would not do\n")
cat("  HIGHER=LESS participation\n")
cat("TRADITIONALISM (q58-q69): 4pt agree-disagree (1=Strongly agree to 4=Strongly disagree)\n")
cat("  Agreement with traditional items = more traditional, so 1=MOST traditional\n")
cat("DEMOCRACY SCALES (q101-q104): 10pt (1=undemocratic/unsuitable to 10=democratic/suitable)\n")
cat("REGIME SUPPORT (q137-q140): 4pt agree-disagree (1=Strongly agree to 4=Strongly disagree)\n")
cat("  Agreement = support for authoritarianism, so 1=MOST authoritarian\n")
cat("\n")
