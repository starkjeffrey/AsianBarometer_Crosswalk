# ==============================================================================
# verify_update_master_w4.R
# Cross-verifies W4_labels.txt against MASTER crosswalk, corrects errors, adds new concepts
# ==============================================================================

library(dplyr)
library(readr)
library(here)

cat("\n")
cat("=================================================================\n")
cat("  VERIFYING & UPDATING MASTER CROSSWALK WITH WAVE 4 ANALYSIS\n")
cat("=================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. Load the current MASTER crosswalk
# -----------------------------------------------------------------------------
cat("Loading MASTER crosswalk...\n")
master <- read_csv(here("abs_harmonization_crosswalk_MASTER.csv"), show_col_types = FALSE)
cat(paste("  Total concepts:", nrow(master), "\n\n"))

w4_coverage_before <- sum(!is.na(master$w4_var) & master$w4_var != "NA")
cat(paste("  W4 variables before update:", w4_coverage_before, "\n\n"))

# =============================================================================
# W4 SCALE DIRECTION ANALYSIS
# =============================================================================
cat("=================================================================\n")
cat("  W4 SCALE DIRECTION ANALYSIS\n")
cat("=================================================================\n\n")

cat("CRITICAL FINDINGS FROM W4_labels.txt:\n")
cat("--------------------------------------\n")
cat("TRUST (q7-q19): 4pt scale 1=Great deal of trust -> 4=None at all\n")
cat("  W4 direction: HIGHER = LESS trust (SAME as W3)\n")
cat("  MASTER currently says '4pt_rev' - this is CORRECT\n\n")

cat("ECONOMIC (q1-q6): 5pt scale 1=Very good -> 5=Very bad\n")
cat("  W4 direction: HIGHER = WORSE (SAME as W3, REVERSED from W2)\n")
cat("  MASTER currently says '5pt_rev' - this is CORRECT\n\n")

cat("PARTICIPATION (q69-q77): 3pt scale 1=More than once, 2=Once, 3=Never\n")
cat("  W4 direction: HIGHER = LESS participation (SAME as W3)\n\n")

cat("INTEREST IN POLITICS (q44): 4pt 1=Very interested -> 4=Not at all\n")
cat("  W4 direction: HIGHER = LESS interest\n")
cat("  MASTER says q91 for W4 - NEEDS CORRECTION to q44\n\n")

cat("FOLLOW NEWS (q45): 5pt 1=Everyday -> 5=Practically never\n")
cat("  W4 direction: HIGHER = LESS news following\n")
cat("  MASTER says q94 for W4 - NEEDS CORRECTION to q45\n\n")

cat("DISCUSS POLITICS (q46): 3pt 1=Frequently -> 3=Never\n")
cat("  W4 direction: HIGHER = LESS discussion (SAME as W3)\n\n")

cat("DEMOCRACY SCALES (q94-q97): 10pt 1=Undemocratic -> 10=Democratic\n")
cat("  W4 direction: HIGHER = MORE democratic\n")
cat("  q94=current, q95=10yrs ago, q96=10yrs future, q97=suitable\n\n")

cat("REGIME SUPPORT (q130-q133): 4pt agree-disagree\n")
cat("  q130=strong leader, q131=one party, q132=army rule, q133=expert rule\n\n")

# =============================================================================
# PART 1: CORRECTIONS TO EXISTING W4 MAPPINGS
# =============================================================================
cat("=================================================================\n")
cat("  PART 1: CORRECTIONS TO EXISTING W4 MAPPINGS\n")
cat("=================================================================\n\n")

# Define corrections based on W4_labels.txt analysis
corrections <- tribble(
  ~concept, ~field, ~old_value, ~new_value,

  # Interest in politics: MASTER says q91, but W4 q91 is "most essential characteristics of democracy"
  # The actual interest in politics question is q44
  "interest_politics", "w4_var", "q91", "q44",
  "interest_politics", "w4_scale", "4pt", "4pt_1high",

  # Follow news: MASTER says q94, but W4 q94 is "democracy scale current"
  # The actual follow news question is q45
  "follow_news", "w4_var", "q94", "q45",
  "follow_news", "w4_scale", "varies", "5pt_1high",

  # Satisfaction democracy: MASTER says q92, which is correct in W4
  # Already correct

  # Democracy scale current: MASTER says q94, which is correct in W4
  # Already correct

  # Democracy scale past: MASTER says q95, which is correct in W4
  # Already correct

  # Democracy scale future: MASTER says q96, which is correct in W4
  # Already correct

  # Democracy suitable: MASTER says q97, which is correct in W4
  # Already correct

  # Govt satisfaction: MASTER says q98, which is correct in W4
  # Already correct

  # Democracy preferable: MASTER says q125, which is correct in W4
  # Already correct

  # Strong leader support: W4 is q130 (MASTER has q130)
  # Already correct

  # Army rule support: W4 is q132 - MASTER says q131 but correct is q132
  "army_rule_support", "w4_var", "q131", "q132",

  # Expert decide support: W4 is q133 - MASTER says q132 but correct is q133
  "expert_decide_support", "w4_var", "q132", "q133",

  # One party rule - W4 q131
  "one_party_rule_support", "w4_var", "NA", "q131",
  "one_party_rule_support", "w4_scale", "NA", "4pt_1agree"
)

cat("Corrections to apply:\n")
print(corrections)

# Apply corrections
for (i in 1:nrow(corrections)) {
  concept <- corrections$concept[i]
  field <- corrections$field[i]
  new_val <- corrections$new_value[i]

  if (concept %in% master$concept) {
    old_val <- master[[field]][master$concept == concept]
    master[[field]][master$concept == concept] <- new_val
    cat(paste("  Updated", concept, field, ":", old_val, "->", new_val, "\n"))
  }
}

# =============================================================================
# PART 2: ADD W4 VARIABLES TO EXISTING CONCEPTS THAT ARE MISSING W4
# =============================================================================
cat("\n=================================================================\n")
cat("  PART 2: ADD W4 VARIABLES TO CONCEPTS MISSING W4\n")
cat("=================================================================\n\n")

# Some concepts added from W3 may also exist in W4
w4_additions <- tribble(
  ~concept, ~w4_var, ~w4_scale,

  # System support items (W4 has these at q83-q87)
  "system_solve_problems", "q83", "4pt_1agree",
  "system_pride", "q84", "4pt_1agree",
  "system_deserves_support", "q85", "4pt_1agree",
  "system_prefer_own", "q86", "4pt_1agree",
  "system_change_needed", "q87", "4pt_1fine",

  # Governance values (W4 has these at q79-q82)
  "govt_responsive_vs_expert", "q79", "binary_choice",
  "govt_employee_vs_parent", "q80", "binary_choice",
  "media_freedom_vs_control", "q81", "binary_choice",
  "leaders_elected_vs_merit", "q82", "binary_choice",

  # Political efficacy (W4 has these at q134-q136)
  "political_efficacy_ability", "q134", "4pt_1agree",
  "political_efficacy_understand_w3", "q135", "4pt_1agree",
  "political_efficacy_voice_w3", "q136", "4pt_1agree",

  # Authoritarian values (W4 has these at q139-q149)
  "women_politics_less", "q139", "4pt_1agree",
  "uneducated_equal_say", "q141", "4pt_1agree",
  "leaders_like_family_head", "q142", "4pt_1agree",
  "govt_control_ideas", "q143", "4pt_1agree",
  "many_groups_disrupt_harmony", "q144", "4pt_1agree",
  "judges_follow_executive", "q145", "4pt_1agree",
  "legislature_check_prevents_greatness", "q146", "4pt_1agree",
  "moral_leaders_decide_all", "q147", "4pt_1agree",
  "many_ideas_cause_chaos", "q148", "4pt_1agree",
  "emergency_disregard_law", "q149", "4pt_1agree",

  # International attitudes (W4 has these at q150-q153)
  "follow_international_news", "q150", "5pt_1high",
  "defend_way_of_life", "q151", "4pt_1agree",
  "protect_from_imports", "q152", "4pt_1agree",

  # Corruption (W4 has these at q117-q120)
  "corruption_local_govt_w3", "q117", "4pt_1low",
  "corruption_national_govt_w3", "q118", "4pt_1low",
  "govt_anticorruption_effort", "q119", "4pt_1best",

  # Trust media (W4 has q16=newspaper, q17=television)
  "trust_newspapers_w3", "q16", "4pt_1high",
  "trust_television_w3", "q17", "4pt_1high",

  # Interpersonal trust (W4 has q26-q28)
  "trust_relatives", "q26", "4pt_1high",
  "trust_neighbors", "q27", "4pt_1high",
  "trust_others_interact", "q28", "4pt_1high"
)

cat("Adding W4 variables to existing concepts:\n")
for (i in 1:nrow(w4_additions)) {
  concept <- w4_additions$concept[i]
  if (concept %in% master$concept) {
    current_w4 <- master$w4_var[master$concept == concept]
    if (is.na(current_w4) || current_w4 == "NA") {
      master$w4_var[master$concept == concept] <- w4_additions$w4_var[i]
      master$w4_scale[master$concept == concept] <- w4_additions$w4_scale[i]
      cat(paste("  Added W4:", concept, "->", w4_additions$w4_var[i], "\n"))
    } else {
      cat(paste("  Skipping (already has W4):", concept, "->", current_w4, "\n"))
    }
  } else {
    cat(paste("  Concept not found:", concept, "\n"))
  }
}

# =============================================================================
# PART 3: NEW CONCEPTS FROM W4 TO ADD
# =============================================================================
cat("\n=================================================================\n")
cat("  PART 3: NEW CONCEPTS FROM W4 TO ADD\n")
cat("=================================================================\n\n")

new_w4_concepts <- tribble(
  ~concept, ~domain, ~description, ~w4_var, ~w4_scale, ~notes,

  # Government service access (q39-q42)
  "access_id_document", "governance", "How easy to obtain identity document service", "q39", "4pt_1hard", "W4+ q39. 4pt (1=very difficult to 4=very easy). HIGHER=EASIER",
  "access_school", "governance", "How easy to obtain place in public primary school", "q40", "4pt_1hard", "W4+ q40. 4pt (1=very difficult to 4=very easy). HIGHER=EASIER",
  "access_medical", "governance", "How easy to obtain medical treatment at clinic", "q41", "4pt_1hard", "W4+ q41. 4pt (1=very difficult to 4=very easy). HIGHER=EASIER",
  "access_police_help", "governance", "How easy to obtain help from police", "q42", "4pt_1hard", "W4+ q42. 4pt (1=very difficult to 4=very easy). HIGHER=EASIER",

  # Safety perception (q43)
  "safety_neighborhood", "social", "How safe is living in this city/town/village", "q43", "4pt_1high", "W4+ q43. 4pt (1=very safe to 4=very unsafe). HIGHER=LESS safe",

  # Internet and social media (q47-q52)
  "social_media_use", "internet", "Currently use social media networks", "q50", "binary_1yes", "W4+ q50. Binary 1=yes 2=no",
  "internet_politics_info", "internet", "How often use internet/social media for political info", "q51", "6pt_1high", "W4+ q51. 6pt (1=everyday to 6=never). HIGHER=LESS",

  # Party closeness strength (q54)
  "party_closeness_strength", "partisanship", "How close feel to chosen party", "q54", "3pt_1high", "W4+ q54. 3pt (1=very close to 3=just a little). HIGHER=LESS close",

  # Democracy characteristics preferences (q88-q91)
  "democracy_char_1", "democracy", "Most essential characteristic of democracy (set 1)", "q88", "4opt", "W4+ q88. 4 options about democracy characteristics",
  "democracy_char_2", "democracy", "Most essential characteristic of democracy (set 2)", "q89", "4opt", "W4+ q89. 4 options about democracy characteristics",
  "democracy_char_3", "democracy", "Most essential characteristic of democracy (set 3)", "q90", "4opt", "W4+ q90. 4 options about democracy characteristics",
  "democracy_char_4", "democracy", "Most essential characteristic of democracy (set 4)", "q91", "4opt", "W4+ q91. 4 options about democracy characteristics",

  # Level of democracy assessment (q93)
  "democracy_assessment", "democracy", "How much of a democracy is country (4pt)", "q93", "4pt_1high", "W4+ q93. 4pt (1=full democracy to 4=not democracy). Different from 10pt scale",

  # Country problems (q99)
  "country_problem_main", "governance", "Most important problems facing country", "q99", "categorical", "W4+ q99. Multiple choice with 39 categories",

  # Government problem solving (q100)
  "govt_solve_problem_likely", "governance", "How likely govt will solve main problem in 5 years", "q100", "4pt_1high", "W4+ q100. 4pt (1=very likely to 4=not at all likely). HIGHER=LESS likely",

  # Democratic accountability (q101-q104)
  "people_change_govt", "democracy", "People have power to change government they don't like", "q101", "4pt_1agree", "W4+ q101. 4pt agree-disagree. Democratic belief",
  "parties_equal_media", "democracy", "Parties have equal access to media during elections", "q102", "4pt_1agree", "W4+ q102. 4pt agree-disagree. Electoral fairness perception",
  "between_elections_accountability", "democracy", "Between elections people can't hold govt responsible", "q103", "4pt_1agree", "W4+ q103. 4pt agree-disagree. REVERSED - agreement=less accountable",
  "courts_check_leaders", "democracy", "Courts can't do anything when leaders break laws", "q104", "4pt_1agree", "W4+ q104. 4pt agree-disagree. REVERSED - agreement=less accountable",

  # Equal treatment (q105-q106)
  "ethnic_equal_treatment", "governance", "All ethnic communities treated equally by government", "q105", "4pt_1agree", "W4+ q105. 4pt agree-disagree",
  "rich_poor_equal_treatment", "governance", "Rich and poor treated equally by government", "q106", "4pt_1agree", "W4+ q106. 4pt agree-disagree",

  # Basic necessities (q107)
  "basic_necessities_met", "governance", "People have basic necessities (food, clothes, shelter)", "q107", "4pt_1agree", "W4+ q107. 4pt agree-disagree",

  # Freedom perceptions (q108-q109)
  "freedom_speech", "democracy", "People free to speak what they think without fear", "q108", "4pt_1agree", "W4+ q108. 4pt agree-disagree. Freedom perception",
  "freedom_organization", "democracy", "People can join any organization without fear", "q109", "4pt_1agree", "W4+ q109. 4pt agree-disagree. Freedom perception",

  # Government accountability (q110-q112)
  "officials_unpunished", "corruption", "Officials who commit crimes go unpunished", "q110", "4pt_1always", "W4+ q110. 4pt (1=always to 4=rarely). HIGHER=LESS corruption",
  "govt_withhold_info", "corruption", "How often govt withholds important info from public", "q111", "4pt_1always", "W4+ q111. 4pt (1=always to 4=rarely). HIGHER=MORE transparent",
  "leaders_break_law", "corruption", "How often govt leaders break law or abuse power", "q112", "4pt_1always", "W4+ q112. 4pt (1=always to 4=rarely). HIGHER=LESS corruption",

  # Legislature capability (q114)
  "legislature_check_govt", "democracy", "Legislature capable of keeping govt leaders in check", "q114", "4pt_1high", "W4+ q114. 4pt (1=very capable to 4=not at all). HIGHER=LESS capable",

  # Government responsiveness (q115-q116)
  "govt_responsive_people", "governance", "How well govt responds to what people want", "q115", "4pt_1high", "W4+ q115. 4pt (1=very responsive to 4=not at all). HIGHER=LESS responsive",
  "elections_attention", "democracy", "Elections make govt pay attention to people", "q116", "4pt_1high", "W4+ q116. 4pt (1=a good deal to 4=not at all). HIGHER=LESS effect",

  # Corruption experience (q120)
  "corruption_witnessed", "corruption", "Personally witnessed corruption in past year", "q120", "5cat", "W4+ q120. 5 categories from personally witnessed to no one witnessed",

  # External democracy perceptions (q121-q124)
  "democracy_china", "international", "Where would place China on democracy scale", "q121", "10pt_1low", "W4+ q121. 10pt scale. Perception of Chinese democracy",
  "democracy_usa", "international", "Where would place USA on democracy scale", "q122", "10pt_1low", "W4+ q122. 10pt scale. Perception of US democracy",
  "democracy_japan", "international", "Where would place Japan on democracy scale", "q123", "10pt_1low", "W4+ q123. 10pt scale. Perception of Japanese democracy",
  "democracy_india", "international", "Where would place India on democracy scale", "q124", "10pt_1low", "W4+ q124. 10pt scale. Perception of Indian democracy",

  # Democracy capability (q126)
  "democracy_solve_problems", "democracy", "Democracy capable of solving society's problems", "q126", "binary", "W4+ q126. Binary choice",

  # Trade-offs (q127-q128)
  "democracy_vs_development", "democracy", "Choose between democracy and economic development", "q127", "5pt_compare", "W4+ q127. 5pt comparison scale with equally important option",
  "equality_vs_freedom", "democracy", "Choose between reducing inequality and protecting freedom", "q128", "5pt_compare", "W4+ q128. 5pt comparison scale",

  # Democracy best form (q129)
  "democracy_best_form", "democracy", "Democracy is best form despite problems", "q129", "4pt_1agree", "W4+ q129. 4pt agree-disagree. Pro-democracy attitude",

  # Trust in government do right (q137)
  "trust_govt_do_right", "trust", "Trust people who run govt to do what is right", "q137", "4pt_1agree", "W4+ q137. 4pt agree-disagree. Diffuse support",

  # Patriotism (q138)
  "citizen_loyalty", "nationalism", "Citizen should remain loyal to country regardless", "q138", "4pt_1agree", "W4+ q138. 4pt agree-disagree. Patriotism/nationalism",

  # Religious authorities (q140)
  "religious_authorities_laws", "traditionalism", "Govt should consult religious authorities on laws", "q140", "4pt_1agree", "W4+ q140. 4pt agree-disagree. Religious traditionalism",

  # Immigration (q153)
  "immigration_policy", "international", "Should govt increase or decrease immigrant inflow", "q153", "4pt_1increase", "W4+ q153. 4pt (1=increase to 4=no more). HIGHER=MORE restrictive",

  # Environment vs economy (q154)
  "environment_vs_economy", "governance", "Priority: environment protection vs economic growth", "q154", "binary", "W4+ q154. Binary choice",

  # Income fairness (q155-q156)
  "income_distribution_fair", "economic", "How fair is income distribution in country", "q155", "4pt_1high", "W4+ q155. 4pt (1=very fair to 4=very unfair). HIGHER=LESS fair",
  "govt_reduce_inequality", "economic", "Govt responsibility to reduce income differences", "q156", "4pt_1agree", "W4+ q156. 4pt agree-disagree. Redistributive preference",

  # Economic insecurity (q157-q159)
  "income_loss_concern", "economic", "Concerned about losing major income source next 12 months", "q157", "4pt_1low", "W4+ q157. 4pt (1=not at all to 4=very concerned). HIGHER=MORE concerned",
  "income_loss_impact", "economic", "How serious if lost main income source", "q158", "3pt_1serious", "W4+ q158. 3pt (1=serious difficulty to 3=manage fine). HIGHER=LESS serious",
  "income_fairness_personal", "economic", "Family income is fair given efforts", "q159", "4pt_1high", "W4+ q159. 4pt (1=very fair to 4=very unfair). HIGHER=LESS fair"
)

cat(paste("Adding", nrow(new_w4_concepts), "new concepts from W4 analysis\n\n"))

# Create rows for new concepts with all columns
for (i in 1:nrow(new_w4_concepts)) {
  concept <- new_w4_concepts$concept[i]

  # Check if concept already exists
  if (concept %in% master$concept) {
    cat(paste("  Skipping (exists):", concept, "\n"))
    next
  }

  # Create new row with NA for all columns
  new_row <- master[1, ]
  new_row[1, ] <- NA

  # Fill in the values we know
  new_row$concept <- concept
  new_row$domain <- new_w4_concepts$domain[i]
  new_row$description <- new_w4_concepts$description[i]
  new_row$w4_var <- new_w4_concepts$w4_var[i]
  new_row$w4_scale <- new_w4_concepts$w4_scale[i]
  new_row$notes <- new_w4_concepts$notes[i]
  new_row$source <- "w4_verification"

  master <- bind_rows(master, new_row)
  cat(paste("  Added:", concept, "(", new_w4_concepts$w4_var[i], ")\n"))
}

# =============================================================================
# SAVE UPDATED CROSSWALK
# =============================================================================
cat("\n=================================================================\n")
cat("  SAVING UPDATED CROSSWALK\n")
cat("=================================================================\n\n")

write_csv(master, here("abs_harmonization_crosswalk_MASTER.csv"))
cat(paste("  Saved: abs_harmonization_crosswalk_MASTER.csv (", nrow(master), " concepts)\n"))

# =============================================================================
# SUMMARY
# =============================================================================
cat("\n=================================================================\n")
cat("  W4 VERIFICATION & UPDATE COMPLETE\n")
cat("=================================================================\n\n")

cat("Final coverage summary:\n")
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

cat("\n\nW4 SCALE CODING NOTES:\n")
cat("----------------------\n")
cat("TRUST institutions (q7-q19): 4pt 1=Great deal -> 4=None. HIGHER=LESS trust\n")
cat("TRUST interpersonal (q26-q28): 4pt 1=Great deal -> 4=None. HIGHER=LESS trust\n")
cat("ECONOMIC (q1-q6): 5pt 1=Very good -> 5=Very bad. HIGHER=WORSE\n")
cat("  NOTE: W4 economic is SAME direction as W3! Both REVERSED from W2\n")
cat("INTEREST IN POLITICS (q44): 4pt 1=Very interested -> 4=Not at all. HIGHER=LESS\n")
cat("FOLLOW NEWS (q45): 5pt 1=Everyday -> 5=Practically never. HIGHER=LESS\n")
cat("DISCUSS POLITICS (q46): 3pt 1=Frequently -> 3=Never. HIGHER=LESS\n")
cat("PARTICIPATION (q69-q77): 3pt 1=More than once, 2=Once, 3=Never. HIGHER=LESS\n")
cat("  NOTE: W4 participation uses 1/2/3 coding like W2-W3, not 0/1/2\n")
cat("DEMOCRACY SCALES (q94-q97): 10pt 1=undemocratic -> 10=democratic. HIGHER=MORE\n")
cat("SATISFACTION DEMOCRACY (q92): 4pt 1=very satisfied -> 4=not at all. HIGHER=LESS\n")
cat("REGIME SUPPORT (q130-q133): 4pt agree-disagree. 1=agree authoritarian\n")
cat("TRADITIONALISM (q55-q68): 4pt agree-disagree. 1=agree (traditional)\n")
cat("EFFICACY (q134-q136): 4pt agree-disagree. Various directions\n")
cat("AUTHORITARIAN VALUES (q139-q149): 4pt agree-disagree. 1=agree (authoritarian)\n")
cat("\n")
