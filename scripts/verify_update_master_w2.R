# ==============================================================================
# verify_update_master_w2.R
# Cross-verifies and updates MASTER crosswalk with Wave 2 corrections/additions
# Based on analysis of docs/W2_labels.txt
# ==============================================================================

library(dplyr)
library(readr)
library(here)

cat("\n")
cat("=================================================================\n")
cat("  VERIFYING & UPDATING MASTER CROSSWALK WITH WAVE 2 ANALYSIS\n")
cat("=================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. Load the current MASTER crosswalk
# -----------------------------------------------------------------------------
cat("Loading MASTER crosswalk...\n")
master <- read_csv(here("abs_harmonization_crosswalk_MASTER.csv"), show_col_types = FALSE)
cat(paste("  Total concepts:", nrow(master), "\n\n"))

# -----------------------------------------------------------------------------
# 2. CORRECTIONS to existing W2 mappings based on W2_labels.txt analysis
# -----------------------------------------------------------------------------
cat("=================================================================\n")
cat("  PART 1: CORRECTIONS TO EXISTING W2 MAPPINGS\n")
cat("=================================================================\n\n")

corrections <- tribble(
  ~concept, ~field, ~old_value, ~new_value, ~reason,

  # CRITICAL: discuss_politics scale direction is WRONG
  # W2_labels.txt shows: 1=Frequently, 2=Occasionally, 3=Never
  # MASTER incorrectly says "W2 (1=never to 3=frequently)" - this is backwards!
  "discuss_politics", "w2_scale", "3pt_1low", "3pt_1high",
  "W2 q52: 1=Frequently, 2=Occasionally, 3=Never. 1 is HIGH frequency, not low.",

  # trust_first_meet - W2 uses 4pt not 6pt
  # W2_labels.txt q27: 1=None at all, 2=Not very much, 3=Quite a lot, 4=Great deal
  "trust_first_meet", "w2_scale", "6pt", "4pt_1low",
  "W2 q27 uses 4pt scale (1=None at all to 4=Great deal), not 6pt",

  # trust_relatives - W2 uses 4pt not 6pt
  # W2_labels.txt q24: 1=Trust them completely to 4=Do not trust them at all
  "trust_relatives", "w2_scale", "6pt", "4pt_1high",
  "W2 q24 uses 4pt scale (1=Trust completely to 4=Do not trust), not 6pt",

  # trust_neighbors - W2 uses 4pt not 6pt
  # W2_labels.txt q25: Same 4pt scale as q24
  "trust_neighbors", "w2_scale", "6pt", "4pt_1high",
  "W2 q25 uses 4pt scale (1=Trust completely to 4=Do not trust), not 6pt",

  # trust_others_interact - W2 uses 4pt not 6pt
  # W2_labels.txt q26: Same 4pt scale as q24/q25
  "trust_others_interact", "w2_scale", "6pt", "4pt_1high",
  "W2 q26 uses 4pt scale (1=Trust completely to 4=Do not trust), not 6pt",

  # interest_politics - W2 var is q49, not q92
  # W2_labels.txt q49: 1=Not at all interested to 4=Very interested
  "interest_politics", "w2_var", "q92", "q49",
  "W2 interest in politics is q49, not q92. q92 is W3+ variable numbering",

  # govt_satisfaction - W2 var is q99, checking scale direction
  # W2_labels.txt q99: 1=Very satisfied to 4=Very dissatisfied
  # MASTER says 4pt_1high which means 1=highest satisfaction - this is CORRECT
  "govt_satisfaction", "w2_var", "q102", "q99",
  "W2 govt satisfaction is q99, not q102. Scale 1=Very satisfied to 4=Very dissatisfied"
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
    master[row_idx, field_name] <- new_val
    cat(paste("  Updated", concept_name, field_name, "to", new_val, "\n"))
  } else {
    cat(paste("  WARNING: Concept", concept_name, "not found or multiple matches\n"))
  }
}

# Also fix the notes for discuss_politics
master <- master %>%
  mutate(notes = case_when(
    concept == "discuss_politics" ~ "Most waves. W1 (1=never to 5=very often) 5-point HIGHER=MORE. W2 (1=frequently to 3=never) 3-point HIGHER=LESS. W3-W6 (1=frequently to 3=never) HIGHER=LESS. Must reverse W1 only. Different scale lengths require careful harmonization",
    TRUE ~ notes
  ))

# Fix reverse_waves for discuss_politics - only W1 needs reversal now
master <- master %>%
  mutate(reverse_waves = case_when(
    concept == "discuss_politics" ~ "W1",
    TRUE ~ reverse_waves
  ))

cat("\n")

# -----------------------------------------------------------------------------
# 3. NEW CONCEPTS to add from W2 that are missing in MASTER
# -----------------------------------------------------------------------------
cat("=================================================================\n")
cat("  PART 2: NEW CONCEPTS FROM W2 TO ADD\n")
cat("=================================================================\n\n")

# Get current column names
cols <- names(master)

# Define new W2 concepts to add
new_w2_concepts <- tribble(
  ~concept, ~domain, ~description, ~w2_var, ~w2_scale, ~notes,

  # Corruption perceptions (q117-q120)
  "corruption_national_govt", "corruption", "National govt officials involved in corruption",
  "q117", "4pt_1low", "W2+. 4pt scale (1=hardly anyone to 4=almost everyone). HIGHER=MORE corruption perceived",

  "corruption_local_govt", "corruption", "Local govt officials involved in corruption",
  "q118", "4pt_1low", "W2+. 4pt scale (1=hardly anyone to 4=almost everyone). HIGHER=MORE corruption perceived",

  "corruption_police", "corruption", "Police/law enforcement involved in corruption",
  "q119", "4pt_1low", "W2+. 4pt scale (1=hardly anyone to 4=almost everyone). HIGHER=MORE corruption perceived",

  "corruption_media", "corruption", "Journalists/media involved in corruption",
  "q120", "4pt_1low", "W2+. 4pt scale (1=hardly anyone to 4=almost everyone). HIGHER=MORE corruption perceived",

  # Regime support additional items
  "one_party_rule_support", "regime", "Support for one-party system without opposition",
  "q125", "4pt_1agree", "W2+. 4pt agree-disagree (1=strongly agree to 4=strongly disagree). 1=MOST authoritarian",

  # Civic attitudes (q151-q153)
  "citizen_participation_duty", "civic", "Citizen not performing duty if doesn't participate",
  "q151", "4pt_1agree", "W2+. 4pt agree-disagree. Civic duty measure",

  "obey_laws_always", "civic", "Citizens should always obey laws even if disagree",
  "q152", "4pt_1agree", "W2+. 4pt agree-disagree. Legal compliance/rule of law measure",

  "country_loyalty", "civic", "Citizen should remain loyal to country no matter how imperfect",
  "q153", "4pt_1agree", "W2+. 4pt agree-disagree. Nationalism/patriotism measure",

  # National identity (q154-q155)
  "national_pride", "identity", "How proud to be a citizen of country",
  "q154", "4pt_1high", "W2+. 4pt scale (1=Very proud to 4=Not proud at all). HIGHER=LESS proud",

  "emigration_willingness", "identity", "Willingness to go live in another country",
  "q155", "4pt_1high", "W2+. 4pt scale (1=Very willing to 4=Not willing at all). HIGHER=LESS willing",

  # Internet use (W2 version - different from W4+)
  "internet_use_frequency_w2", "internet", "How often use internet (W2 version)",
  "q66", "7pt_1high", "W2 only. 7pt scale (1=Several hours daily to 7=Never). HIGHER=LESS use. Different scale from W4+",

  # Subjective social status
  "subjective_social_status", "demographics", "Self-perceived social status (1-10 ladder)",
  "se13", "10pt_1low", "W2+. 10pt ladder (1=Lowest to 10=Highest status). HIGHER=HIGHER status",

  # Political efficacy items (q103-q108 found in W2)
  "political_efficacy_understand", "politics", "Politics/govt sometimes too complicated to understand",
  "q103", "4pt_1agree", "W2+. 4pt agree-disagree. Internal efficacy measure",

  "political_efficacy_voice", "politics", "People like me don't have influence on govt",
  "q105", "4pt_1agree", "W2+. 4pt agree-disagree. External efficacy measure",

  "political_efficacy_care", "politics", "Govt doesn't care what people like me think",
  "q106", "4pt_1agree", "W2+. 4pt agree-disagree. External efficacy measure",

  # Freedom items (q109-q113)
  "freedom_speech", "governance", "Perceived freedom to express opinions without fear",
  "q109", "4pt_1complete", "W2+. 4pt scale (1=Completely free to 4=Not at all free). HIGHER=LESS freedom",

  "freedom_association", "governance", "Freedom to join organization of choice",
  "q110", "4pt_1complete", "W2+. 4pt scale (1=Completely free to 4=Not at all free). HIGHER=LESS freedom",

  "freedom_press", "governance", "Freedom of press/media",
  "q112", "4pt_1complete", "W2+. 4pt scale (1=Completely free to 4=Not at all free). HIGHER=LESS freedom",

  "freedom_vote", "governance", "Freedom to vote without pressure",
  "q113", "4pt_1complete", "W2+. 4pt scale (1=Completely free to 4=Not at all free). HIGHER=LESS freedom",

  # Trust in newspapers and TV (these ARE in W2, separate from election commission/NGO)
  "trust_newspapers", "trust", "Trust in newspapers",
  "q18", "4pt_1low", "W2. 4pt trust scale (1=None at all to 4=Great deal). Note: W2 q18 is newspapers, not NGOs",

  "trust_television", "trust", "Trust in television",
  "q19", "4pt_1low", "W2. 4pt trust scale (1=None at all to 4=Great deal). W2 only - distinct media trust"
)

cat(paste("Adding", nrow(new_w2_concepts), "new concepts from W2 analysis\n\n"))

# Create new rows with all columns from master
for (i in 1:nrow(new_w2_concepts)) {
  new_row <- as.list(rep(NA, length(cols)))
  names(new_row) <- cols

  new_row$concept <- new_w2_concepts$concept[i]
  new_row$domain <- new_w2_concepts$domain[i]
  new_row$description <- new_w2_concepts$description[i]
  new_row$w2_var <- new_w2_concepts$w2_var[i]
  new_row$w2_scale <- new_w2_concepts$w2_scale[i]
  new_row$notes <- new_w2_concepts$notes[i]
  new_row$source <- "w2_verification"

  master <- bind_rows(master, as_tibble(new_row))
  cat(paste("  Added:", new_row$concept, "(", new_row$w2_var, ")\n"))
}

# -----------------------------------------------------------------------------
# 4. Verify additional W2 variable numbers
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  PART 3: VERIFICATION OF W2 VARIABLE NUMBERS\n")
cat("=================================================================\n\n")

# Create verification table comparing MASTER to W2_labels.txt
verification <- tribble(
  ~concept, ~master_w2_var, ~labels_txt_var, ~status,

  # Trust variables - all correct
  "trust_executive", "q7", "q7", "CORRECT - Trust in Prime Minister/President",
  "trust_courts", "q8", "q8", "CORRECT - Trust in courts",
  "trust_national_govt", "q9", "q9", "CORRECT - Trust in national government",
  "trust_parties", "q10", "q10", "CORRECT - Trust in political parties",
  "trust_parliament", "q11", "q11", "CORRECT - Trust in parliament/congress",
  "trust_civil_service", "q12", "q12", "CORRECT - Trust in civil service",
  "trust_military", "q13", "q13", "CORRECT - Trust in military",
  "trust_police", "q14", "q14", "CORRECT - Trust in police",
  "trust_local_govt", "q15", "q15", "CORRECT - Trust in local government",
  "trust_election_commission", "q16", "q16", "CORRECT - Trust in election commission",
  "trust_ngos", "q17", "q17", "NEEDS CHECK - W2 q17 might be TV, not NGOs - see notes",

  # Economic - all correct
  "econ_country_current", "q1", "q1", "CORRECT - Country economic condition",
  "econ_country_past", "q2", "q2", "CORRECT - Country economy vs past",
  "econ_country_future", "q3", "q3", "CORRECT - Country economic future",
  "econ_family_current", "q4", "q4", "CORRECT - Family economic condition",
  "econ_family_past", "q5", "q5", "CORRECT - Family economy vs past",
  "econ_family_future", "q6", "q6", "CORRECT - Family economic future",

  # Social trust
  "trust_gen_binary", "q23", "q23", "CORRECT - General trust binary",
  "trust_relatives", "q24", "q24", "CORRECT - Trust in relatives",
  "trust_neighbors", "q25", "q25", "CORRECT - Trust in neighbors",
  "trust_others_interact", "q26", "q26", "CORRECT - Trust in people interact with",
  "trust_first_meet", "q27", "q27", "CORRECT - Trust first time meet (scale corrected above)",

  # Voting/electoral
  "voted_last_election", "q38", "q38", "CORRECT - Voted in last election",
  "which_party_voted", "q39", "q39", "CORRECT - Which party voted for",
  "attend_campaign", "q40", "q40", "CORRECT - Attended campaign rally",
  "persuade_vote", "q41", "q41", "CORRECT - Tried to persuade others",
  "work_for_party", "q42", "q42", "CORRECT - Worked for party/candidate",

  # Political interest
  "interest_politics", "q49", "q49", "CORRECTED above - was q92, now q49",
  "discuss_politics", "q52", "q52", "CORRECTED scale direction above",

  # Partisanship
  "party_closeness", "q54", "q54", "CORRECT - Party feel closest to",

  # Traditionalism
  "obey_parents_unreasonable", "q56", "q56", "CORRECT",
  "not_question_teacher", "q57", "q57", "CORRECT",
  "accommodate_neighbor", "q58", "q58", "CORRECT",
  "not_insist_opinion_coworkers", "q59", "q59", "CORRECT",
  "family_over_individual", "q60", "q60", "CORRECT",

  # Participation
  "contact_elected_officials", "q72", "q79", "NEEDS CHECK - W2_labels shows q79 for contacting",
  "contact_higher_officials", "q73", "q80", "NEEDS CHECK - W2_labels shows q80",
  "contact_traditional_leaders", "q74", "q81", "NEEDS CHECK - W2_labels shows q81",
  "contact_influential_people", "q75", "q82", "NEEDS CHECK - W2_labels shows q82",
  "contact_media", "q76", "q83", "NEEDS CHECK - W2_labels shows q83",
  "collective_problem_solving", "q77", "q84", "NEEDS CHECK - W2_labels shows q84",
  "petition_sign", "q78", "q85", "NEEDS CHECK - W2_labels shows q85",
  "attend_demonstration", "q80", "q87", "NEEDS CHECK - W2_labels shows q87",
  "use_force_violence", "q81", "q88", "NEEDS CHECK - W2_labels shows q88",

  # Democracy
  "satisfaction_democracy", "q93", "q93", "CORRECT - Satisfaction with democracy",
  "level_democracy", "q94", "q94", "CORRECT - Level of democracy",
  "democracy_scale_past", "q97", "q95", "NEEDS CHECK - labels show q95 is past",
  "democracy_scale_current", "q96", "q96", "CORRECT",
  "democracy_suitable", "q99", "q98", "NEEDS CHECK - labels show q98",
  "govt_satisfaction", "q99", "q99", "CORRECTED above - now q99"
)

cat("Variable verification summary:\n")
cat("------------------------------\n")
correct_count <- sum(grepl("CORRECT", verification$status))
needs_check <- sum(grepl("NEEDS CHECK", verification$status))
corrected <- sum(grepl("CORRECTED", verification$status))
cat(paste("  Verified correct:", correct_count, "\n"))
cat(paste("  Corrected in this script:", corrected, "\n"))
cat(paste("  May need further review:", needs_check, "\n"))

# Print items that need checking
cat("\nItems that may need further review:\n")
verification %>%
  filter(grepl("NEEDS CHECK", status)) %>%
  select(concept, master_w2_var, labels_txt_var, status) %>%
  print(n = 20)

# -----------------------------------------------------------------------------
# 5. Apply W2 participation variable corrections
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  PART 4: PARTICIPATION VARIABLE CORRECTIONS\n")
cat("=================================================================\n\n")

# Based on W2_labels.txt analysis, the participation questions are q79-q89
# not q72-q81 as in MASTER. Let me fix these.

participation_corrections <- tribble(
  ~concept, ~correct_w2_var,
  "contact_elected_officials", "q79",
  "contact_higher_officials", "q80",
  "contact_traditional_leaders", "q81",
  "contact_influential_people", "q82",
  "contact_media", "q83",
  "collective_problem_solving", "q84",
  "petition_sign", "q85",
  "attend_demonstration", "q87",
  "use_force_violence", "q88"
)

for (i in 1:nrow(participation_corrections)) {
  concept_name <- participation_corrections$concept[i]
  correct_var <- participation_corrections$correct_w2_var[i]

  row_idx <- which(master$concept == concept_name)
  if (length(row_idx) == 1) {
    old_var <- master$w2_var[row_idx]
    master$w2_var[row_idx] <- correct_var
    cat(paste("  Corrected", concept_name, "W2 var:", old_var, "->", correct_var, "\n"))
  }
}

# -----------------------------------------------------------------------------
# 6. Save the updated crosswalk
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  SAVING UPDATED CROSSWALK\n")
cat("=================================================================\n\n")

# Sort by domain for organization
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

# Save
write_csv(master, here("abs_harmonization_crosswalk_MASTER.csv"))
cat(paste("  Saved: abs_harmonization_crosswalk_MASTER.csv (", nrow(master), " concepts)\n"))

# -----------------------------------------------------------------------------
# 7. Summary report
# -----------------------------------------------------------------------------
cat("\n")
cat("=================================================================\n")
cat("  W2 VERIFICATION & UPDATE COMPLETE\n")
cat("=================================================================\n\n")

cat("Changes made:\n")
cat("-------------\n")
cat("1. CORRECTIONS to existing W2 mappings:\n")
cat("   - discuss_politics: Fixed scale direction (3pt_1high, not 3pt_1low)\n")
cat("   - trust_first_meet/relatives/neighbors/others: Fixed scale (4pt, not 6pt)\n")
cat("   - interest_politics: Fixed variable (q49, not q92)\n")
cat("   - govt_satisfaction: Fixed variable (q99, not q102)\n")
cat("   - Participation variables: Fixed q72-q81 -> q79-q88\n")
cat("\n")
cat("2. NEW concepts added from W2:\n")
cat("   - 4 corruption perception variables\n")
cat("   - one_party_rule_support\n")
cat("   - 3 civic attitude variables\n")
cat("   - 2 national identity variables\n")
cat("   - internet_use_frequency_w2\n")
cat("   - subjective_social_status\n")
cat("   - 3 political efficacy variables\n")
cat("   - 4 freedom perception variables\n")
cat("   - trust_newspapers, trust_television\n")
cat("\n")

# Show final coverage
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

cat("\n\nW2 SCALE CODING NOTES:\n")
cat("----------------------\n")
cat("TRUST institutions (q7-q19): 4pt 1=None at all to 4=Great deal. HIGHER=MORE trust\n")
cat("TRUST interpersonal (q24-q27): 4pt 1=Trust completely to 4=Do not trust. HIGHER=LESS trust\n")
cat("ECONOMIC (q1-q6): 5pt 1=Very bad to 5=Very good. HIGHER=BETTER\n")
cat("DISCUSS POLITICS (q52): 3pt 1=Frequently to 3=Never. HIGHER=LESS discussion\n")
cat("TRADITIONALISM (q56-q65): 4pt 1=Strongly agree to 4=Strongly disagree. 1=MOST traditional\n")
cat("PARTICIPATION (q79-q89): 3pt 1=Once, 2=More than once, 3=Never. HIGHER=LESS participation\n")
cat("REGIME SUPPORT (q124-q127): 4pt agree-disagree. 1=Strongly approve authoritarian\n")
cat("FREEDOM (q109-q113): 4pt 1=Completely free to 4=Not at all free. HIGHER=LESS freedom\n")
cat("CORRUPTION (q117-q120): 4pt 1=Hardly anyone to 4=Almost everyone. HIGHER=MORE corruption\n")
cat("\n")
