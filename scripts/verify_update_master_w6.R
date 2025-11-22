# ==============================================================================
# verify_update_master_w6.R
# Cross-verifies Wave 6 variables against the MASTER crosswalk and applies
# corrections based on W6_Cambodia_labels.txt analysis
# CRITICAL: W6 contains COVID-19 questions and has significant restructuring
# ==============================================================================

library(dplyr)
library(readr)
library(here)

cat("\n")
cat("=================================================================\n")
cat("  WAVE 6 CROSS-VERIFICATION AND UPDATE\n")
cat("  NOTE: W6 contains COVID-19 questions and structural changes\n")
cat("=================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. Load the current MASTER crosswalk
# -----------------------------------------------------------------------------
cat("Loading MASTER crosswalk...\n")
master <- read_csv(here("abs_harmonization_crosswalk_MASTER.csv"), show_col_types = FALSE)
cat(paste("  Total concepts:", nrow(master), "\n"))

# Current W6 coverage
w6_coverage_before <- sum(!is.na(master$w6_var) & master$w6_var != "NA")
cat(paste("  W6 variables before update:", w6_coverage_before, "\n\n"))

# -----------------------------------------------------------------------------
# 2. W6 CORRECTIONS - Based on W6_Cambodia_labels.txt analysis
# W6 has SIGNIFICANT variable number changes from W5
# W6 trust uses 4pt scale (1=great deal to 4=none) vs W5's 6pt
# -----------------------------------------------------------------------------
cat("Applying W6 corrections based on W6_Cambodia_labels.txt verification...\n\n")

# CRITICAL CORRECTIONS for W6:
# W6 q47 = Interest in politics (not q91)
# W6 q48 = Follow news (not q94)
# W6 q49 = Discuss politics (not same as W5)
# W6 q90 = Satisfaction with democracy (not q92)
# W6 q91 = How much democracy (4pt)
# W6 q92 = Democracy scale current (10pt)
# W6 q93 = Democracy scale past (10pt)
# W6 q94 = Democracy scale future (10pt)
# W6 q95 = Democracy suitable (10pt)
# W6 q96 = Govt satisfaction
# W6 q124 = Democracy preferable (not q125)
# W6 q129 = Strong leader support (not q130)
# W6 q130 = One party rule (not q131)
# W6 q131 = Army rule
# W6 q132 = Expert decide

w6_corrections <- tribble(
  ~concept, ~correct_w6_var, ~correct_w6_scale, ~note,

  # POLITICAL INTEREST - CRITICAL CORRECTIONS
  "interest_politics", "q47", "4pt_1high", "W6 q47 is interest in politics (1=very interested to 4=not at all)",
  "follow_news", "q48", "5pt_1high", "W6 q48 is follow news (1=everyday to 5=practically never)",
  "discuss_politics", "q49", "3pt_1high", "W6 q49 is discuss politics (1=frequently to 3=never)",

  # DEMOCRACY/REGIME SCALES - CRITICAL CORRECTIONS
  "satisfaction_democracy", "q90", "4pt_1high", "W6 q90 is satisfaction with democracy (1=very satisfied to 4=not at all)",
  "level_democracy", "q91", "4pt_1high", "W6 q91 is how much democracy (1=full to 4=not democracy)",
  "democracy_scale_current", "q92", "10pt_1low", "W6 q92 is democracy scale present (1=undemocratic to 10=democratic)",
  "democracy_scale_past", "q93", "10pt_1low", "W6 q93 is democracy scale 10 years ago",
  "democracy_scale_future", "q94", "10pt_1low", "W6 q94 is democracy scale 10 years from now",
  "democracy_suitable", "q95", "10pt_1low", "W6 q95 is democracy suitable (1=unsuitable to 10=suitable)",
  "govt_satisfaction", "q96", "4pt_1high", "W6 q96 is satisfaction with govt (1=very satisfied to 4=very dissatisfied)",

  # REGIME SUPPORT - CRITICAL CORRECTIONS
  "democracy_preferable", "q124", "3opt", "W6 q124 is democracy preferable statement",
  "strong_leader_support", "q129", "4pt_1agree", "W6 q129 is strong leader (1=strongly approve to 4=strongly disapprove)",
  "one_party_rule_support", "q130", "4pt_1agree", "W6 q130 is one party allowed (1=strongly approve to 4=strongly disapprove)",
  "army_rule_support", "q131", "4pt_1agree", "W6 q131 is army should govern (1=strongly approve to 4=strongly disapprove)",
  "expert_decide_support", "q132", "4pt_1agree", "W6 q132 is experts make decisions (1=strongly approve to 4=strongly disapprove)"
)

# Apply corrections
corrections_applied <- 0
for (i in seq_len(nrow(w6_corrections))) {
  concept_name <- w6_corrections$concept[i]
  correct_var <- w6_corrections$correct_w6_var[i]
  correct_scale <- w6_corrections$correct_w6_scale[i]

  row_idx <- which(master$concept == concept_name)
  if (length(row_idx) == 1) {
    old_var <- master$w6_var[row_idx]
    if (!is.na(old_var) && old_var != "NA" && old_var != correct_var) {
      cat(paste("  CORRECTING", concept_name, ":", old_var, "->", correct_var, "\n"))
      master$w6_var[row_idx] <- correct_var
      master$w6_scale[row_idx] <- correct_scale
      corrections_applied <- corrections_applied + 1
    } else if (is.na(old_var) || old_var == "NA") {
      cat(paste("  ADDING", concept_name, ":", correct_var, "\n"))
      master$w6_var[row_idx] <- correct_var
      master$w6_scale[row_idx] <- correct_scale
      corrections_applied <- corrections_applied + 1
    }
  }
}

cat(paste("\n  Corrections applied:", corrections_applied, "\n\n"))

# -----------------------------------------------------------------------------
# 3. W6-specific concepts to add to existing concepts
# -----------------------------------------------------------------------------
cat("Adding W6 mappings to existing concepts...\n")

w6_existing_additions <- tribble(
  ~concept, ~w6_var, ~w6_scale, ~note,

  # Trust variables - W6 uses 4pt scale (1=great deal to 4=none)
  "trust_executive", "q7", "4pt", "W6 4pt trust scale (1=great deal to 4=none at all)",
  "trust_courts", "q8", "4pt", "W6 4pt trust scale",
  "trust_national_govt", "q9", "4pt", "W6 4pt trust scale",
  "trust_parties", "q10", "4pt", "W6 4pt trust scale",
  "trust_parliament", "q11", "4pt", "W6 4pt trust scale",
  "trust_civil_service", "q12", "4pt", "W6 4pt trust scale",
  "trust_military", "q13", "4pt", "W6 4pt trust scale",
  "trust_police", "q14", "4pt", "W6 4pt trust scale",
  "trust_local_govt", "q15", "4pt", "W6 4pt trust scale",
  "trust_election_commission", "q16", "4pt", "W6 4pt trust scale",
  "trust_ngos", "q17", "4pt", "W6 4pt trust scale",

  # Social trust - W6 uses different scales
  "trust_gen_binary", "q22", "binary", "W6 q22 is most people trusted (binary)",
  "trust_gen_trustworthy", "q23", "4pt_1agree", "W6 q23 is most people trustworthy (agree scale)",
  "trust_relatives", "q24", "4pt_1high", "W6 q24 is trust in relatives (4pt)",
  "trust_neighbors", "q25", "4pt_1high", "W6 q25 is trust in neighbors (4pt)",
  "trust_others_interact", "q26", "4pt_1high", "W6 q26 is trust in people you interact with",
  "trust_first_meet", "q27", "4pt_1high", "W6 q27 is trust in people you meet first time",

  # Social capital
  "contact_frequency", "q28", "5cat", "W6 q28 is people contacted in typical week",
  "network_status", "q29", "4cat", "W6 q29 is social status of contacts",
  "network_politics", "q30", "5cat", "W6 q30 is political views of contacts",
  "support_receive", "q31", "4pt_1high", "W6 q31 is people to help with problems",
  "political_tolerance", "q32", "4pt_1high", "W6 q32 is difficulty conversing with different views",

  # Electoral participation
  "voted_last_election", "q33", "binary", "W6 q33 is voted in national election",
  "which_party_voted", "q34", "country_specific", "W6 q34 is which party voted for",
  "attend_campaign", "q35", "binary_1yes", "W6 q35 is attended campaign (1=yes, 2=no)",
  "persuade_vote", "q36", "binary_1yes", "W6 q36 is tried to persuade others",
  "work_for_party", "q37", "binary_1yes", "W6 q37 is worked for party/candidate",
  "election_free_fair", "q38", "4pt_1best", "W6 q38 is election free and fair",

  # Safety
  "safety_neighborhood", "q46", "4pt_1high", "W6 q46 is safety of living area (1=very safe to 4=very unsafe)",

  # Partisanship
  "party_closeness", "q54", "categorical", "W6 q54 is which party closest to",
  "party_closeness_strength", "q55", "3pt_1high", "W6 q55 is how close to party",

  # Traditionalism
  "family_over_individual", "q56", "4pt_1trad", "W6 q56 is family over individual",
  "sacrifice_individual_group", "q57", "4pt_1trad", "W6 q57 is sacrifice for group",
  "sacrifice_individual_nation", "q58", "4pt_1trad", "W6 q58 is sacrifice for nation",
  "immediate_vs_longterm", "q59", "4pt_1trad", "W6 q59 is long-term relationships",
  "obey_parents_unreasonable", "q60", "4pt_1trad", "W6 q60 is obey parents even if unreasonable",
  "mother_in_law_conflict", "q61", "4pt_1trad", "W6 q61 is mother-in-law conflict",
  "not_question_teacher", "q62", "4pt_1trad", "W6 q62 is don't question teacher",
  "avoid_open_quarrel", "q63", "4pt_1trad", "W6 q63 is avoid open quarrel",
  "avoid_disagreement_conflict", "q64", "4pt_1trad", "W6 q64 is avoid conflict with disagreement",
  "not_insist_opinion_coworkers", "q65", "4pt_1trad", "W6 q65 is not insist opinion if coworkers disagree",
  "fate_determines_success", "q66", "4pt_1trad", "W6 q66 is fate determines success",
  "prefer_boy_child", "q67", "4pt_1trad", "W6 q67 is prefer boy over girl",

  # Participation - W6 uses 5pt scale
  "contact_elected_officials", "q68", "5pt_done", "W6 q68 is contact elected officials",
  "contact_higher_officials", "q69", "5pt_done", "W6 q69 is contact civil servants",
  "contact_influential_people", "q70", "5pt_done", "W6 q70 is contact influential people",
  "contact_media", "q71", "5pt_done", "W6 q71 is contact news media",
  "petition_sign", "q72", "5pt_done", "W6 q72 is signed petition (paper or online)",
  "internet_politics_express", "q73", "5pt_done", "W6 q73 is used internet for political opinions",
  "join_group_cause", "q74", "5pt_done", "W6 q74 is joined group for cause",
  "collective_problem_solving", "q75", "5pt_done", "W6 q75 is got together to resolve local problems",
  "attend_demonstration", "q76", "5pt_done", "W6 q76 is attended demonstration/protest",
  "use_force_violence", "q77", "5pt_done", "W6 q77 is risky political action",
  "voting_frequency_pattern", "q78", "4pt_1high", "W6 q78 is voting frequency",

  # Democracy evaluation
  "democracy_solve_problems", "q125", "binary", "W6 q125 is democracy can solve problems",
  "democracy_vs_development", "q126", "5pt_compare", "W6 q126 is democracy vs economic development",
  "equality_vs_freedom", "q127", "5pt_compare", "W6 q127 is equality vs freedom",
  "democracy_best_form", "q128", "4pt_1agree", "W6 q128 is democracy best form despite problems",

  # Political efficacy
  "political_efficacy_ability", "q133", "4pt_1agree", "W6 q133 is ability to participate in politics",
  "political_efficacy_understand_w3", "q134", "4pt_1agree", "W6 q134 is politics too complicated",
  "political_efficacy_voice_w3", "q135", "4pt_1agree", "W6 q135 is people like me no influence"
)

additions_made <- 0
for (i in seq_len(nrow(w6_existing_additions))) {
  concept_name <- w6_existing_additions$concept[i]
  w6_var <- w6_existing_additions$w6_var[i]
  w6_scale <- w6_existing_additions$w6_scale[i]

  row_idx <- which(master$concept == concept_name)
  if (length(row_idx) == 1) {
    if (is.na(master$w6_var[row_idx]) || master$w6_var[row_idx] == "NA") {
      master$w6_var[row_idx] <- w6_var
      master$w6_scale[row_idx] <- w6_scale
      cat(paste("  Added W6 to", concept_name, ":", w6_var, "\n"))
      additions_made <- additions_made + 1
    }
  }
}

cat(paste("\n  W6 additions to existing concepts:", additions_made, "\n"))

# -----------------------------------------------------------------------------
# 4. NEW W6 CONCEPTS - COVID-19 and W6-specific variables
# -----------------------------------------------------------------------------
cat("\nAdding new W6 concepts (including COVID-19 questions)...\n")

new_w6_concepts <- tribble(
  ~concept, ~domain, ~description, ~w6_var, ~w6_scale, ~notes,

  # COVID-19 QUESTIONS - CRITICAL W6 ADDITIONS
  "covid_infection", "covid", "Personal/family COVID-19 infection", "q138", "binary_1yes", "*** W6 ONLY - KEY for Paper 1 (Vietnam Paradox) ***",
  "covid_economic_impact", "covid", "COVID-19 impact on family livelihood", "q140", "4pt_1serious", "W6 q140. 1=very serious to 4=not much impact",
  "covid_trust_info", "covid", "Trust in govt COVID-19 information", "q141", "4pt_1high", "*** W6 ONLY - KEY MEDIATOR for Paper 1 ***",
  "covid_govt_handling", "covid", "Government pandemic handling assessment", "q142", "4pt_1good", "*** W6 ONLY - KEY DV for Paper 1 ***",
  "covid_vaccination", "covid", "COVID-19 vaccination status", "q144", "categorical", "W6 q144. Multiple categories including vaccine hesitancy",

  # Emergency powers - COVID related authoritarianism
  "emergency_powers_covid", "covid", "Justify emergency powers for COVID pandemic", "q172a", "4pt_1justified", "W6 q172a. 1=very justified to 4=not at all",
  "emergency_powers_economic", "covid", "Justify emergency powers for economic crisis", "q172b", "4pt_1justified", "W6 q172b. Economic crisis justification",
  "emergency_powers_corruption", "covid", "Justify emergency powers to reduce corruption", "q172c", "4pt_1justified", "W6 q172c. Corruption justification",
  "emergency_powers_security", "covid", "Justify emergency powers for security crisis", "q172d", "4pt_1justified", "W6 q172d. Security/terrorism justification",
  "emergency_powers_war", "covid", "Justify emergency powers when at war", "q172e", "4pt_1justified", "W6 q172e. War justification",

  # Service access - W6 specific
  "access_roads", "governance", "How easy to obtain roads in good condition", "q39", "4pt_1easy", "W6 q39. 1=very easy to 4=very difficult",
  "access_water", "governance", "How easy to obtain running water", "q40", "4pt_1easy", "W6 q40. 1=very easy to 4=very difficult",
  "access_transport", "governance", "How easy to obtain public transportation", "q41", "4pt_1easy", "W6 q41. 1=very easy to 4=very difficult",
  "access_healthcare", "governance", "How easy to obtain healthcare", "q42", "4pt_1easy", "W6 q42. 1=very easy to 4=very difficult",
  "access_police", "governance", "How easy to obtain help from police", "q43", "4pt_1easy", "W6 q43. 1=very easy to 4=very difficult",
  "access_internet", "governance", "How easy to obtain internet access", "q44", "4pt_1easy", "W6 q44. 1=very easy to 4=very difficult",
  "access_childcare", "governance", "How easy to obtain childcare", "q45", "4pt_1easy", "W6 q45. 1=very easy to 4=very difficult",

  # Social media platforms - W6 specific
  "socialmedia_facebook", "internet", "Actively use Facebook", "q51a_Facebook", "binary_1yes", "W6 q51a. Binary yes/no",
  "socialmedia_twitter", "internet", "Actively use Twitter", "q51b_Twitter", "binary_1yes", "W6 q51b. Binary yes/no",
  "socialmedia_instagram", "internet", "Actively use Instagram", "q51c_Instagram", "binary_1yes", "W6 q51c. Binary yes/no",
  "socialmedia_youtube", "internet", "Actively use YouTube", "q51d_Youtube", "binary_1yes", "W6 q51d. Binary yes/no",
  "socialmedia_tiktok", "internet", "Actively use TikTok", "q51e_Tiktok", "binary_1yes", "W6 q51e. Binary yes/no",
  "socialmedia_messenger", "internet", "Actively use Messenger", "q51f_Messenger", "binary_1yes", "W6 q51f. Binary yes/no",
  "socialmedia_telegram", "internet", "Actively use Telegram", "q51g_Telegram", "binary_1yes", "W6 q51g. Binary yes/no",
  "socialmedia_line", "internet", "Actively use Line", "q51h_Line", "binary_1yes", "W6 q51h. Binary yes/no",
  "socialmedia_whatsapp", "internet", "Actively use WhatsApp", "q51i_Whatsapp", "binary_1yes", "W6 q51i. Binary yes/no",

  # Social media usage frequency - W6 specific
  "socialmedia_connect", "internet", "Use social media to connect with people", "q52a", "4pt_1often", "W6 q52a. 1=often to 4=never",
  "socialmedia_politics", "internet", "Use social media for political opinions", "q52b", "4pt_1often", "W6 q52b. 1=often to 4=never",
  "socialmedia_share", "internet", "Use social media to share news", "q52c", "4pt_1often", "W6 q52c. 1=often to 4=never",
  "socialmedia_organize", "internet", "Use social media to organize for political influence", "q52d", "4pt_1often", "W6 q52d. 1=often to 4=never",

  # Information source
  "info_channel_politics", "internet", "Most important channel for political information", "q53", "categorical", "W6 q53. TV/newspaper/internet/radio/face-to-face",

  # Vote buying
  "vote_buying_experience", "electoral", "Offered something in return for vote", "q79", "3pt_1often", "W6 q79. 1=often, 2=sometimes, 3=never",
  "vote_winner_loser", "electoral", "Voted for winning or losing camp", "q34a", "categorical", "W6 q34a. Winner/loser/not sure",

  # Democracy characteristics (forced choice sets)
  "demchar_set1", "democracy", "Most essential democracy characteristic (set 1)", "q85", "4opt", "W6 q85. Four options forced choice",
  "demchar_set2", "democracy", "Most essential democracy characteristic (set 2)", "q86", "4opt", "W6 q86. Four options forced choice",
  "demchar_set3", "democracy", "Most essential democracy characteristic (set 3)", "q87", "4opt", "W6 q87. Four options forced choice",
  "demchar_set4", "democracy", "Most essential democracy characteristic (set 4)", "q88", "4opt", "W6 q88. Four options forced choice",
  "democracy_meaning", "democracy", "What does democracy mean (open-ended)", "q89", "open_ended", "W6 q89. Open-ended question",

  # Country problems
  "country_problem_1", "governance", "Most important problem facing country (1st)", "q97", "categorical", "W6 q97. Multiple categories",
  "country_problem_2", "governance", "Most important problem facing country (2nd)", "q97a", "categorical", "W6 q97a. Second most important",
  "country_problem_3", "governance", "Most important problem facing country (3rd)", "q97b", "categorical", "W6 q97b. Third most important",
  "govt_solve_problem", "governance", "How likely govt will solve main problem", "q98", "4pt_1high", "W6 q98. 1=very likely to 4=not at all likely",

  # International relations - W6 specific
  "asia_influence_country", "international", "Which country has most influence in Asia", "q173", "categorical", "W6 q173. China/Japan/India/USA/Others",
  "usa_asia_impact", "international", "Does USA do more good or harm to Asia", "q174", "4pt", "W6 q174. 1=much more good to 4=much more harm",
  "usa_world_influence", "international", "US influence on world affairs", "q175", "6pt", "W6 q175. 1=very positive to 6=very negative",
  "china_world_influence", "international", "China influence on world affairs", "q176", "6pt", "W6 q176. 1=very positive to 6=very negative"
)

# Add new concepts
new_concepts_added <- 0
for (i in seq_len(nrow(new_w6_concepts))) {
  concept_name <- new_w6_concepts$concept[i]

  # Check if concept already exists
  if (!concept_name %in% master$concept) {
    new_row <- tibble(
      concept = concept_name,
      domain = new_w6_concepts$domain[i],
      description = new_w6_concepts$description[i],
      w1_var = NA_character_,
      w1_scale = NA_character_,
      w2_var = NA_character_,
      w2_scale = NA_character_,
      w3_var = NA_character_,
      w3_scale = NA_character_,
      w4_var = NA_character_,
      w4_scale = NA_character_,
      w5_var = NA_character_,
      w5_scale = NA_character_,
      w6_var = new_w6_concepts$w6_var[i],
      w6_scale = new_w6_concepts$w6_scale[i],
      harmonized_name = NA_character_,
      harmonize_to = NA_character_,
      reverse_waves = NA_character_,
      notes = new_w6_concepts$notes[i],
      source = "w6_verification",
      w1_label = NA_character_
    )
    master <- bind_rows(master, new_row)
    new_concepts_added <- new_concepts_added + 1
    cat(paste("  NEW:", concept_name, "->", new_w6_concepts$w6_var[i], "\n"))
  }
}

cat(paste("\n  New W6 concepts added:", new_concepts_added, "\n"))

# -----------------------------------------------------------------------------
# 5. Summary and save
# -----------------------------------------------------------------------------
cat("\n=================================================================\n")
cat("  W6 VERIFICATION SUMMARY\n")
cat("=================================================================\n\n")

w6_coverage_after <- sum(!is.na(master$w6_var) & master$w6_var != "NA")
cat(paste("W6 variables before:", w6_coverage_before, "\n"))
cat(paste("W6 variables after:", w6_coverage_after, "\n"))
cat(paste("Net change:", w6_coverage_after - w6_coverage_before, "\n"))
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
# 6. W6 SCALE AND COVID NOTES
# -----------------------------------------------------------------------------
cat("\n\nW6 SCALE CODING NOTES:\n")
cat("-------------------------\n")
cat("TRUST (q7-q17): 4pt scale (1=Great deal to 4=None at all). HIGHER=LESS trust\n")
cat("  NOTE: This is DIFFERENT from W5 (6pt) - same direction but different scale length\n")
cat("ECONOMIC (q1-q6): 5pt scale (1=Very good to 5=Very bad). Same direction as previous waves\n")
cat("INTEREST (q47): 4pt (1=Very interested to 4=Not at all). HIGHER=LESS interested\n")
cat("  NOTE: Scale direction REVERSED from W5 (W5: 1=not at all to 4=very)\n")
cat("FOLLOW NEWS (q48): 5pt (1=Everyday to 5=Practically never). HIGHER=LESS\n")
cat("PARTICIPATION (q68-q77): 5pt scale same as W5\n")
cat("  1=More than 3 times, 2=2-3 times, 3=Once, 4=Not done but might, 5=Would not do\n")
cat("TRADITIONALISM (q56-q67): 4pt agree-disagree (1=Strongly agree to 4=Strongly disagree)\n")
cat("DEMOCRACY SCALES (q92-q95): 10pt (1=undemocratic/unsuitable to 10=democratic/suitable)\n")
cat("REGIME SUPPORT (q129-q132): 4pt (1=Strongly approve to 4=Strongly disapprove)\n")
cat("  NOTE: W6 uses 'approve/disapprove' vs W5 'agree/disagree' - same direction\n")
cat("\n")
cat("COVID-19 QUESTIONS (W6 ONLY):\n")
cat("-----------------------------\n")
cat("q138: COVID infection (binary)\n")
cat("q140: COVID economic impact (1=very serious to 4=not much)\n")
cat("q141: COVID trust in govt info (4pt trust scale)\n")
cat("q142: COVID govt handling (1=very well to 4=very badly)\n")
cat("q144: COVID vaccination status (categorical with hesitancy options)\n")
cat("q172a-e: Emergency powers justification (1=very justified to 4=not at all)\n")
cat("\n")
