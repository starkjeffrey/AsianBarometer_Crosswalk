# ==============================================================================
# verify_update_master_w3.R
# Cross-verifies and updates MASTER crosswalk with Wave 3 corrections/additions
# Based on analysis of docs/W3_labels.txt
# ==============================================================================

library(dplyr)
library(readr)
library(here)

cat("\n")
cat("=================================================================\n")
cat("  VERIFYING & UPDATING MASTER CROSSWALK WITH WAVE 3 ANALYSIS\n")
cat("=================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. Load the current MASTER crosswalk
# -----------------------------------------------------------------------------
cat("Loading MASTER crosswalk...\n")
master <- read_csv(here("abs_harmonization_crosswalk_MASTER.csv"), show_col_types = FALSE)
cat(paste("  Total concepts:", nrow(master), "\n\n"))

# Count current W3 coverage
w3_coverage_before <- sum(!is.na(master$w3_var) & master$w3_var != "NA")
cat(paste("  W3 variables before update:", w3_coverage_before, "\n\n"))

# -----------------------------------------------------------------------------
# 2. CRITICAL SCALE DIRECTION NOTES FOR W3
# -----------------------------------------------------------------------------
cat("=================================================================\n")
cat("  W3 SCALE DIRECTION ANALYSIS\n")
cat("=================================================================\n\n")

cat("CRITICAL FINDINGS FROM W3_labels.txt:\n")
cat("--------------------------------------\n")
cat("TRUST (q7-q19): 4pt scale 1=Great deal of trust → 4=None at all\n")
cat("  W3 direction: HIGHER = LESS trust (REVERSED from typical)\n")
cat("  MASTER currently says '6pt' for W3 - NEEDS CORRECTION to 4pt\n\n")

cat("ECONOMIC (q1-q6): 5pt scale 1=Very good → 5=Very bad\n")
cat("  W3 direction: HIGHER = WORSE (REVERSED from W2)\n")
cat("  This is SAME as W4 direction - W3 and W4 need reversal together\n\n")

cat("PARTICIPATION (q64-q72): 3pt scale 0=Never, 1=Once, 2=More than once\n")
cat("  W3 direction: HIGHER = MORE participation\n")
cat("  Different coding from W2 (W2 uses 1,2,3 not 0,1,2)\n\n")

cat("DISCUSS POLITICS (q46): 3pt 1=Frequently → 3=Never\n")
cat("  W3 direction: HIGHER = LESS discussion\n\n")

cat("INTEREST IN POLITICS (q43): 4pt 1=Very interested → 4=Not at all\n")
cat("  W3 direction: HIGHER = LESS interest (REVERSED from W2)\n\n")

# -----------------------------------------------------------------------------
# 3. CORRECTIONS to existing W3 mappings
# -----------------------------------------------------------------------------
cat("=================================================================\n")
cat("  PART 1: CORRECTIONS TO EXISTING W3 MAPPINGS\n")
cat("=================================================================\n\n")

# Key corrections needed based on W3_labels.txt analysis
corrections <- tribble(
  ~concept, ~field, ~old_value, ~new_value, ~reason,

  # Trust variables - W3 uses 4pt not 6pt!
  # W3_labels.txt shows q7-q19 all have 1=Great deal, 2=Quite a lot, 3=Not very much, 4=None at all
  "trust_executive", "w3_scale", "6pt", "4pt_1high",
  "W3 q7: 4pt scale (1=Great deal to 4=None). HIGHER=LESS trust",

  "trust_courts", "w3_scale", "6pt", "4pt_1high",
  "W3 q8: 4pt scale. HIGHER=LESS trust",

  "trust_national_govt", "w3_scale", "6pt", "4pt_1high",
  "W3 q9: 4pt scale. HIGHER=LESS trust",

  "trust_parties", "w3_scale", "6pt", "4pt_1high",
  "W3 q10: 4pt scale. HIGHER=LESS trust",

  "trust_parliament", "w3_scale", "6pt", "4pt_1high",
  "W3 q11: 4pt scale. HIGHER=LESS trust",

  "trust_civil_service", "w3_scale", "6pt", "4pt_1high",
  "W3 q12: 4pt scale. HIGHER=LESS trust",

  "trust_military", "w3_scale", "6pt", "4pt_1high",
  "W3 q13: 4pt scale. HIGHER=LESS trust",

  "trust_police", "w3_scale", "6pt", "4pt_1high",
  "W3 q14: 4pt scale. HIGHER=LESS trust",

  "trust_local_govt", "w3_scale", "6pt", "4pt_1high",
  "W3 q15: 4pt scale. HIGHER=LESS trust",

  "trust_election_commission", "w3_scale", "6pt", "4pt_1high",
  "W3 q18: 4pt scale. HIGHER=LESS trust",

  "trust_ngos", "w3_scale", "6pt", "4pt_1high",
  "W3 q19: 4pt scale. HIGHER=LESS trust",

  # Interpersonal trust - W3 uses 4pt not 6pt
  "trust_relatives", "w3_scale", "6pt", "4pt_1high",
  "W3 q25: 4pt (1=Great deal to 4=None). HIGHER=LESS trust",

  "trust_neighbors", "w3_scale", "6pt", "4pt_1high",
  "W3 q26: 4pt scale. HIGHER=LESS trust",

  "trust_others_interact", "w3_scale", "6pt", "4pt_1high",
  "W3 q27: 4pt scale. HIGHER=LESS trust",

  # Interest in politics - W3 is q43, not q88
  "interest_politics", "w3_var", "q88", "q43",
  "W3 interest in politics is q43. q88 is democracy meaning question",

  # Interest scale is reversed in W3 (1=Very interested, 4=Not at all)
  "interest_politics", "w3_scale", "4pt", "4pt_1high",
  "W3 q43: 4pt (1=Very interested to 4=Not at all). HIGHER=LESS interest",

  # Follow news - correct variable is q44
  "follow_news", "w3_var", "q91", "q44",
  "W3 follow news is q44. q91 is democracy scale current",

  # Discuss politics - correct variable is q46
  "discuss_politics", "w3_var", "q46", "q46",
  "W3 discuss politics is q46 (confirmed correct)",

  # Democracy satisfaction - correct
  "satisfaction_democracy", "w3_var", "q89", "q89",
  "W3 satisfaction with democracy is q89 (confirmed correct)",

  # Level of democracy - W3 q90
  "level_democracy", "w3_var", "q90", "q90",
  "W3 level of democracy is q90 (confirmed correct)",

  # Democracy scale current is q91 (not same as q92)
  "democracy_scale_current", "w3_var", "q92", "q91",
  "W3 democracy scale CURRENT is q91 (present government)",

  # Democracy scale past is q92 (not q93)
  "democracy_scale_past", "w3_var", "q93", "q92",
  "W3 democracy scale PAST is q92 (ten years ago)",

  # Democracy scale future is q93 (want in future)
  "democracy_scale_future", "w3_var", "q94", "q93",
  "W3 democracy scale FUTURE is q93 (want in future)",

  # Democracy suitable is q94
  "democracy_suitable", "w3_var", "q95", "q94",
  "W3 democracy suitable is q94",

  # Govt satisfaction is q95
  "govt_satisfaction", "w3_var", "q98", "q95",
  "W3 govt satisfaction is q95"
)

cat("Corrections to apply:\n")
print(corrections %>% select(concept, field, old_value, new_value))

# Apply corrections
for (i in 1:nrow(corrections)) {
  concept_name <- corrections$concept[i]
  field_name <- corrections$field[i]
  new_val <- corrections$new_value[i]

  row_idx <- which(master$concept == concept_name)
  if (length(row_idx) == 1) {
    old_val <- master[[field_name]][row_idx]
    if (!is.na(old_val) && old_val != new_val) {
      master[row_idx, field_name] <- new_val
      cat(paste("  Updated", concept_name, field_name, ":", old_val, "->", new_val, "\n"))
    }
  } else {
    cat(paste("  WARNING: Concept", concept_name, "not found or multiple matches\n"))
  }
}

# -----------------------------------------------------------------------------
# 4. Fix W3 participation variable numbers
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  PART 2: W3 PARTICIPATION VARIABLE CORRECTIONS\n")
cat("=================================================================\n\n")

# W3 participation variables are q64-q72
participation_corrections <- tribble(
  ~concept, ~w3_var,
  "contact_elected_officials", "q64",
  "contact_higher_officials", "q65",
  "contact_traditional_leaders", "q66",
  "contact_influential_people", "q67",
  "contact_media", "q68",
  "collective_problem_solving", "q69",
  "petition_sign", "q70",
  "attend_demonstration", "q71",
  "use_force_violence", "q72"
)

for (i in 1:nrow(participation_corrections)) {
  concept_name <- participation_corrections$concept[i]
  correct_var <- participation_corrections$w3_var[i]

  row_idx <- which(master$concept == concept_name)
  if (length(row_idx) == 1) {
    old_var <- master$w3_var[row_idx]
    if (!is.na(old_var) && old_var != correct_var) {
      master$w3_var[row_idx] <- correct_var
      cat(paste("  Corrected", concept_name, "W3 var:", old_var, "->", correct_var, "\n"))
    }
  }
}

# Also update W3 participation scale coding
# W3 uses 0=Never, 1=Once, 2=More than once (different from W2's 1,2,3)
master <- master %>%
  mutate(w3_scale = case_when(
    concept %in% c("contact_elected_officials", "contact_higher_officials",
                   "contact_traditional_leaders", "contact_influential_people",
                   "contact_media", "collective_problem_solving", "petition_sign",
                   "attend_demonstration", "use_force_violence") ~ "3pt_0never",
    TRUE ~ w3_scale
  ))

cat("  Updated participation scale coding to 3pt_0never\n")

# -----------------------------------------------------------------------------
# 5. NEW CONCEPTS from W3 to add
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  PART 3: NEW CONCEPTS FROM W3 TO ADD\n")
cat("=================================================================\n\n")

cols <- names(master)

new_w3_concepts <- tribble(
  ~concept, ~domain, ~description, ~w3_var, ~w3_scale, ~notes,

  # Trust in newspapers and TV (W3 has separate items)
  "trust_newspapers_w3", "trust", "Trust in newspapers (W3 specific)",
  "q16", "4pt_1high", "W3 q16. 4pt (1=Great deal to 4=None). W3-only - other waves have different media items",

  "trust_television_w3", "trust", "Trust in television (W3 specific)",
  "q17", "4pt_1high", "W3 q17. 4pt (1=Great deal to 4=None). W3-only - other waves have different media items",

  # Social capital: people try to be fair
  "trust_fairness_w3", "social_capital", "Do people try to take advantage or be fair",
  "q24", "binary", "W3 q24. Binary (1=take advantage, 2=be fair). New in W3",

  # Internet use frequency
  "internet_use_frequency_w3", "internet", "How often use internet (W3 version)",
  "q45", "6pt_1high", "W3 q45. 6pt (1=Almost daily to 6=Never). HIGHER=LESS use",

  # Voting pattern
  "voting_frequency_pattern", "participation", "How often voted since eligible",
  "q73", "4pt_1high", "W3+ q73. 4pt (1=every election to 4=hardly ever). HIGHER=LESS",

  # Government values questions (q74-q79)
  "govt_responsive_vs_expert", "governance", "Govt should do what voters want vs what experts think best",
  "q74", "binary", "W3+ q74. Statement 1=responsive, 2=expert knows best",

  "govt_employee_vs_parent", "governance", "Govt is employee of people vs parent who decides",
  "q75", "binary", "W3+ q75. Statement 1=employee, 2=parent",

  "media_freedom_vs_control", "governance", "Media free to publish vs govt controls",
  "q76", "binary", "W3+ q76. Statement 1=media free, 2=govt controls",

  "individual_vs_govt_welfare", "governance", "Individual responsibility vs govt welfare",
  "q77", "binary", "W3+ q77. Statement 1=individual, 2=govt responsible",

  "leaders_elected_vs_merit", "governance", "Leaders chosen by election vs merit",
  "q78", "binary", "W3+ q78. Statement 1=elected, 2=merit-based",

  "multiparty_vs_oneparty", "governance", "Multiple parties vs one party represents all",
  "q79", "binary", "W3+ q79. Statement 1=multiparty, 2=one party",

  # System support items (q80-q84)
  "system_solve_problems", "regime", "System capable of solving country's problems",
  "q80", "4pt_1agree", "W3+ q80. 4pt agree-disagree. System efficacy",

  "system_pride", "regime", "Proud of system of government",
  "q81", "4pt_1agree", "W3+ q81. 4pt agree-disagree. System pride",

  "system_deserves_support", "regime", "System deserves people's support despite problems",
  "q82", "4pt_1agree", "W3+ q82. 4pt agree-disagree. System legitimacy",

  "system_prefer_own", "regime", "Prefer own system to any other",
  "q83", "4pt_1agree", "W3+ q83. 4pt agree-disagree. System preference",

  "system_change_needed", "regime", "System works fine vs needs change vs should be replaced",
  "q84", "4pt_1fine", "W3+ q84. 4pt (1=fine to 4=replace). HIGHER=MORE change wanted",

  # Corruption - local and national
  "corruption_local_govt_w3", "corruption", "Corruption in local government (W3 version)",
  "q116", "4pt_1low", "W3 q116. 4pt (1=hardly anyone to 4=almost everyone). HIGHER=MORE",

  "corruption_national_govt_w3", "corruption", "Corruption in national government (W3 version)",
  "q117", "4pt_1low", "W3 q117. 4pt (1=hardly anyone to 4=almost everyone). HIGHER=MORE",

  "govt_anticorruption_effort", "corruption", "Is government working to crack down on corruption",
  "q118", "4pt_1best", "W3+ q118. 4pt (1=doing best to 4=nothing). HIGHER=LESS effort",

  # Political efficacy (W3 versions)
  "political_efficacy_ability", "politics", "I have ability to participate in politics",
  "q133", "4pt_1agree", "W3+ q133. 4pt agree-disagree. Internal efficacy",

  "political_efficacy_understand_w3", "politics", "Politics too complicated to understand (W3)",
  "q134", "4pt_1agree", "W3+ q134. 4pt agree-disagree. Internal efficacy (low)",

  "political_efficacy_voice_w3", "politics", "People like me don't have influence (W3)",
  "q135", "4pt_1agree", "W3+ q135. 4pt agree-disagree. External efficacy (low)",

  # Authoritarian values
  "women_politics_less", "traditionalism", "Women should not be involved in politics as much as men",
  "q139", "4pt_1agree", "W3+ q139. 4pt agree-disagree. Gender attitudes",

  "uneducated_equal_say", "democracy", "Uneducated should have equal say in politics",
  "q140", "4pt_1agree", "W3+ q140. 4pt agree-disagree. Egalitarian attitudes",

  "leaders_like_family_head", "regime", "Govt leaders like family head, should follow",
  "q141", "4pt_1agree", "W3+ q141. 4pt agree-disagree. Paternalism/authoritarianism",

  "govt_control_ideas", "regime", "Govt should decide what ideas allowed",
  "q142", "4pt_1agree", "W3+ q142. 4pt agree-disagree. Authoritarianism",

  "many_groups_disrupt_harmony", "traditionalism", "Many groups disrupt community harmony",
  "q143", "4pt_1agree", "W3+ q143. 4pt agree-disagree. Anti-pluralism",

  "judges_follow_executive", "regime", "Judges should accept executive view",
  "q144", "4pt_1agree", "W3+ q144. 4pt agree-disagree. Authoritarianism",

  "legislature_check_prevents_greatness", "regime", "Legislative oversight prevents great things",
  "q145", "4pt_1agree", "W3+ q145. 4pt agree-disagree. Authoritarianism",

  "moral_leaders_decide_all", "regime", "Morally upright leaders can decide everything",
  "q146", "4pt_1agree", "W3+ q146. 4pt agree-disagree. Authoritarianism",

  "many_ideas_cause_chaos", "traditionalism", "Too many ways of thinking causes chaos",
  "q147", "4pt_1agree", "W3+ q147. 4pt agree-disagree. Anti-pluralism",

  "emergency_disregard_law", "regime", "OK for govt to disregard law in emergencies",
  "q148", "4pt_1agree", "W3+ q148. 4pt agree-disagree. Emergency authoritarianism",

  # International attitudes
  "follow_international_news", "politics", "How closely follow major events in foreign countries",
  "q149", "5pt_1high", "W3+ q149. 5pt (1=very closely to 5=not at all). HIGHER=LESS",

  "watch_foreign_media", "politics", "How often watch foreign programs",
  "q150", "6pt_1high", "W3+ q150. 6pt (1=almost daily to 6=never). HIGHER=LESS",

  # National identity items
  "defend_way_of_life", "identity", "Country should defend way of life vs become like others",
  "q151", "4pt_1agree", "W3+ q151. 4pt agree-disagree. Nationalism",

  "protect_from_imports", "identity", "Protect workers by limiting imports",
  "q152", "4pt_1agree", "W3+ q152. 4pt agree-disagree. Economic nationalism",

  "foreign_goods_harm", "identity", "Foreign goods hurt local community",
  "q153", "4pt_1agree", "W3+ q153. 4pt agree-disagree. Economic nationalism",

  # National pride and emigration (already added from W2, but verify W3 vars)
  "national_pride_w3", "identity", "How proud to be citizen (W3 version)",
  "q154", "4pt_1high", "W3 q154. 4pt (1=very proud to 4=not at all). HIGHER=LESS proud",

  "emigration_willingness_w3", "identity", "Willingness to live in another country (W3)",
  "q155", "4pt_1high", "W3 q155. 4pt (1=very willing to 4=not at all). HIGHER=LESS willing"
)

cat(paste("Adding", nrow(new_w3_concepts), "new concepts from W3 analysis\n\n"))

for (i in 1:nrow(new_w3_concepts)) {
  # Check if concept already exists
  if (new_w3_concepts$concept[i] %in% master$concept) {
    cat(paste("  Skipping (exists):", new_w3_concepts$concept[i], "\n"))
    next
  }

  new_row <- as.list(rep(NA, length(cols)))
  names(new_row) <- cols

  new_row$concept <- new_w3_concepts$concept[i]
  new_row$domain <- new_w3_concepts$domain[i]
  new_row$description <- new_w3_concepts$description[i]
  new_row$w3_var <- new_w3_concepts$w3_var[i]
  new_row$w3_scale <- new_w3_concepts$w3_scale[i]
  new_row$notes <- new_w3_concepts$notes[i]
  new_row$source <- "w3_verification"

  master <- bind_rows(master, as_tibble(new_row))
  cat(paste("  Added:", new_row$concept, "(", new_row$w3_var, ")\n"))
}

# -----------------------------------------------------------------------------
# 6. Update existing concepts with correct W3 variable numbers
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  PART 4: UPDATE EXISTING CONCEPTS WITH W3 VARIABLES\n")
cat("=================================================================\n\n")

# Update national_pride and emigration_willingness with W3 vars if missing
master <- master %>%
  mutate(
    w3_var = case_when(
      concept == "national_pride" & (is.na(w3_var) | w3_var == "NA") ~ "q154",
      concept == "emigration_willingness" & (is.na(w3_var) | w3_var == "NA") ~ "q155",
      TRUE ~ w3_var
    ),
    w3_scale = case_when(
      concept == "national_pride" & (is.na(w3_scale) | w3_scale == "NA") ~ "4pt_1high",
      concept == "emigration_willingness" & (is.na(w3_scale) | w3_scale == "NA") ~ "4pt_1high",
      TRUE ~ w3_scale
    )
  )

cat("  Updated national_pride and emigration_willingness with W3 variables\n")

# -----------------------------------------------------------------------------
# 7. Save the updated crosswalk
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  SAVING UPDATED CROSSWALK\n")
cat("=================================================================\n\n")

# Sort by domain
domain_order <- c(
  "trust", "economic", "democracy", "regime", "politics", "political_interest",
  "participation", "electoral", "partisanship", "traditionalism", "social_capital",
  "internet", "social", "civic", "governance", "corruption", "identity",
  "covid", "demographics", "identifiers", "other"
)

master <- master %>%
  mutate(domain_order = match(domain, domain_order)) %>%
  mutate(domain_order = ifelse(is.na(domain_order), 999, domain_order)) %>%
  arrange(domain_order, concept) %>%
  select(-domain_order)

# Remove duplicates
master <- master %>% distinct(concept, .keep_all = TRUE)

write_csv(master, here("abs_harmonization_crosswalk_MASTER.csv"))
cat(paste("  Saved: abs_harmonization_crosswalk_MASTER.csv (", nrow(master), " concepts)\n"))

# -----------------------------------------------------------------------------
# 8. Summary report
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  W3 VERIFICATION & UPDATE COMPLETE\n")
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

cat("\n\nW3 SCALE CODING NOTES:\n")
cat("----------------------\n")
cat("TRUST institutions (q7-q19): 4pt 1=Great deal → 4=None. HIGHER=LESS trust\n")
cat("TRUST interpersonal (q25-q27): 4pt 1=Great deal → 4=None. HIGHER=LESS trust\n")
cat("ECONOMIC (q1-q6): 5pt 1=Very good → 5=Very bad. HIGHER=WORSE\n")
cat("  NOTE: W3 economic is REVERSED from W2! W3 matches W4 direction\n")
cat("INTEREST IN POLITICS (q43): 4pt 1=Very interested → 4=Not at all. HIGHER=LESS\n")
cat("FOLLOW NEWS (q44): 5pt 1=Everyday → 5=Practically never. HIGHER=LESS\n")
cat("DISCUSS POLITICS (q46): 3pt 1=Frequently → 3=Never. HIGHER=LESS\n")
cat("PARTICIPATION (q64-q72): 3pt 0=Never, 1=Once, 2=More than once. HIGHER=MORE\n")
cat("DEMOCRACY SCALES (q91-q94): 10pt 1=undemocratic → 10=democratic. HIGHER=MORE\n")
cat("REGIME SUPPORT (q129-q132): 4pt approve-disapprove. 1=approve authoritarian\n")
cat("TRADITIONALISM (q50-q63): 4pt agree-disagree. 1=agree (traditional)\n")
cat("\n")
