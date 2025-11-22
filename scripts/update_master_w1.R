# ==============================================================================
# update_master_w1.R
# Updates the MASTER crosswalk with Wave 1 variable mappings from W1_labels.txt
# ==============================================================================

library(dplyr)
library(readr)
library(here)

cat("\n")
cat("=================================================================\n")
cat("  UPDATING MASTER CROSSWALK WITH WAVE 1 VARIABLES\n")
cat("=================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. Load the current MASTER crosswalk
# -----------------------------------------------------------------------------
cat("Loading MASTER crosswalk...\n")
master <- read_csv(here("abs_harmonization_crosswalk_MASTER.csv"), show_col_types = FALSE)
cat(paste("  Total concepts:", nrow(master), "\n"))

# Count current W1 coverage
w1_coverage_before <- sum(!is.na(master$w1_var) & master$w1_var != "NA")
cat(paste("  W1 variables before update:", w1_coverage_before, "\n\n"))

# -----------------------------------------------------------------------------
# 2. Define W1 variable mappings based on W1_labels.txt analysis
# Wave 1 uses different variable naming (q001 vs q1) and different scales
# -----------------------------------------------------------------------------
cat("Defining W1 variable mappings...\n")

# Create mapping dataframe: concept -> w1_var, w1_scale, w1_label
# Based on thorough analysis of docs/W1_labels.txt
w1_mappings <- tribble(
  ~concept, ~w1_var, ~w1_scale, ~w1_label,

  # TRUST VARIABLES (q007-q018 in W1, all 5pt scales 0-4)
  # W1 trust scale: 0=No trust at all, 1=Not very much, 2=Quite a lot, 3=Great deal, 4=DK
  # This is effectively 4pt (0-3) with DK=4
  "trust_courts", "q007", "4pt_0low", "Trust in courts",
  "trust_national_govt", "q008", "4pt_0low", "Trust in national government",
  "trust_parties", "q009", "4pt_0low", "Trust in political parties",
  "trust_parliament", "q010", "4pt_0low", "Trust in parliament",
  "trust_civil_service", "q011", "4pt_0low", "Trust in civil service",
  "trust_military", "q012", "4pt_0low", "Trust in military",
  "trust_police", "q013", "4pt_0low", "Trust in police",
  "trust_local_govt", "q014", "4pt_0low", "Trust in local government",
  # q015 = newspapers, q016 = TV - not in MASTER as trust_newspapers/trust_tv
  "trust_election_commission", "q017", "4pt_0low", "Trust in election commission",
  "trust_ngos", "q018", "4pt_0low", "Trust in NGOs",

  # ECONOMIC PERCEPTIONS (q001-q006 in W1)
  # W1 uses 5pt scale: 1=Very Bad/Much Worse to 5=Very Good/Much Better
  # This is OPPOSITE to W4 polarity (W4 has 1=Very Good)
  "econ_country_current", "q001", "5pt_1bad", "Country economic condition now (1=Very bad to 5=Very good)",
  "econ_country_past", "q002", "5pt_1worse", "Country economic change past (1=Much worse to 5=Much better)",
  "econ_country_future", "q003", "5pt_1worse", "Country economic future (1=Much worse to 5=Much better)",
  "econ_family_current", "q004", "5pt_1bad", "Family economic condition now",
  "econ_family_past", "q005", "5pt_1worse", "Family economic change past",
  "econ_family_future", "q006", "5pt_1worse", "Family economic future",

  # POLITICAL INTEREST/NEWS
  # q056: Interest in politics (4pt: 1=Not at all to 4=Very interested) - HIGHER=MORE
  "interest_politics", "q056", "4pt_1low", "Interest in politics (1=Not at all to 4=Very interested)",
  # q057: Follow news (6pt: 2=Practically never to 6=Everyday) - HIGHER=MORE
  "follow_news", "q057", "6pt_2low", "Follow political news (2=Practically never to 6=Everyday)",

  # DISCUSS POLITICS (q023 in W1)
  # 5pt: 1=Never to 5=Very often - HIGHER=MORE discussion
  "discuss_politics", "q023", "5pt_1low", "Discuss political matters (1=Never to 5=Very often)",

  # GENERALIZED TRUST (q024 in W1)
  # 3 options: 1=Most people can be trusted, 2=Must be very careful, 3=Both/it depends
  "trust_gen_binary", "q024", "3opt", "Most people can be trusted (trichotomous)",

  # TRADITIONALISM (q064-q072 in W1)
  # All 4pt scales: 1=Strongly agree to 4=Strongly disagree
  # For traditional items, agreement=traditional, so 1=most traditional
  "obey_parents_unreasonable", "q064", "4pt_1trad", "Children obey parents even if unreasonable",
  "hire_relatives_over_qualified", "q065", "4pt_1trad", "Hire relatives over qualified stranger",
  "accommodate_neighbor", "q066", "4pt_1trad", "Accommodate neighbor in conflict",
  "fate_determines_success", "q067", "4pt_1trad", "Fate determines wealth and success",
  "not_insist_opinion_coworkers", "q068", "4pt_1trad", "Not insist on own opinion if coworkers disagree",
  "family_over_individual", "q069", "4pt_1trad", "Put family interests before individual",
  "man_lose_face_female_boss", "q070", "4pt_1trad", "Man loses face working under female supervisor",
  "elder_resolve_dispute", "q071", "4pt_1trad", "Ask elder to resolve quarrels",
  "mother_in_law_conflict", "q072", "4pt_1trad", "Husband should side with mother-in-law over wife",

  # POLITICAL PARTICIPATION (q073-q095 in W1)
  # Coded: 1=Once, 2=More than once, 9=Never done
  # Need to recode: 9->3 for consistent 3pt scale (1=more than once, 2=once, 3=never)
  # W1 coding is REVERSED from other waves conceptually
  "contact_elected_officials", "q073", "3pt_w1code", "Contacted elected officials (1=Once, 2=More than once, 9=Never)",
  "contact_higher_officials", "q074", "3pt_w1code", "Contacted higher government officials",
  # q075 = lodge complaint to ombudsman - not in MASTER
  # q076-q079 = not clear mappings, skip
  "contact_media", "q080", "3pt_w1code", "Contacted news media",
  # q081-q083 = not clear mappings
  "petition_sign", "q084", "3pt_w1code", "Sign petition or raise issue",
  # q085-q086 = not clear
  "attend_demonstration", "q087", "3pt_w1code", "Attended demonstration or protest",
  # q088-q094 = various participation items
  "use_force_violence", "q095", "3pt_w1code", "Used force or violence for political cause",

  # ELECTORAL PARTICIPATION (q027-q031 in W1)
  # q027: Voted in last election (1=Yes, 2=No)
  "voted_last_election", "q027", "binary_1yes", "Voted in last national election",
  # q028: Which party voted for (country-specific codes)
  "which_party_voted", "q028", "categorical", "Which party voted for",
  # q029-q031: Campaign activities (1=No, 2=Yes) - NOTE: reversed from W3+
  "attend_campaign", "q029", "binary_2yes", "Attended campaign meeting/rally (1=No, 2=Yes)",
  "persuade_vote", "q030", "binary_2yes", "Tried to persuade others to vote (1=No, 2=Yes)",
  "work_for_party", "q031", "binary_2yes", "Worked for party/candidate (1=No, 2=Yes)",

  # PARTY CLOSENESS (q062 in W1)
  "party_closeness", "q062", "categorical", "Which party feel closest to",

  # DEMOCRACY/REGIME VARIABLES
  # q098: Satisfaction with democracy (4pt: 1=Not at all to 4=Very satisfied)
  "satisfaction_democracy", "q098", "4pt_1low", "Satisfaction with democracy (1=Not at all to 4=Very)",
  # q099: Democracy scale past (1-10, 1=Complete dictatorship to 10=Complete democracy)
  "democracy_scale_past", "q099", "10pt_1low", "Democracy scale past regime (1-10)",
  # q100: Democracy scale current
  "democracy_scale_current", "q100", "10pt_1low", "Democracy scale current (1-10)",
  # q101: How democratic should country be now (desire scale)
  # Note: This is not exactly democracy_scale_future but desire for democracy
  # q102: Democracy scale 5 years from now
  "democracy_scale_future", "q102", "10pt_1low", "Democracy scale future 5 years (1-10)",
  # q103: Democracy suitable (1-10)
  "democracy_suitable", "q103", "10pt_1low", "Democracy suitable for country (1-10)",
  # q104: Government satisfaction (4pt with 5=half-half special code)
  "govt_satisfaction", "q104", "4pt_1low", "Satisfaction with government (1=Very dissatisfied to 4=Very satisfied)",
  # q117: Democracy preferable (3 options)
  "democracy_preferable", "q117", "3opt", "Democracy preferable to other regimes",
  # q121: Strong leader support (4pt agree-disagree)
  "strong_leader_support", "q121", "4pt_1agree", "Support for strong leader without elections",
  # q123: Army rule support (4pt)
  "army_rule_support", "q123", "4pt_1agree", "Support for army rule",
  # q124: Expert decide support (4pt)
  "expert_decide_support", "q124", "4pt_1agree", "Support for experts making decisions",

  # SOCIAL CAPITAL
  # fgnum: Number of formal groups (count 0-3)
  "org_count_formal", "fgnum", "count_0to3", "Number of formal groups belong to",
  # pgnum: Number of private groups (count 0-3)
  "org_count_private", "pgnum", "count_0to3", "Number of private groups belong to",

  # DEMOGRAPHICS
  "gender", "se002", "binary", "Gender (1=Male, 2=Female)",
  "age", "se003a", "continuous", "Age in years",
  "education", "se005", "ordinal", "Education level",
  "income", "se009", "ordinal", "Income level",
  "urban_rural", "level3", "binary", "Urban/rural (1=Urban, 2=Rural)",
  "country", "country", "categorical", "Country code",
  "respondent_id", "idnumber", "id", "Respondent ID number"
)

cat(paste("  Defined", nrow(w1_mappings), "W1 variable mappings\n\n"))

# -----------------------------------------------------------------------------
# 3. Update the MASTER crosswalk with W1 mappings
# -----------------------------------------------------------------------------
cat("Updating MASTER crosswalk...\n")

# Create lookup for quick matching
w1_lookup <- w1_mappings %>%
  select(concept, w1_var, w1_scale, w1_label) %>%
  rename(new_w1_var = w1_var, new_w1_scale = w1_scale, new_w1_label = w1_label)

# Join and update
master_updated <- master %>%
  left_join(w1_lookup, by = "concept") %>%
  mutate(
    # Update w1_var if we have a mapping and current value is NA or "NA"
    w1_var = case_when(
      !is.na(new_w1_var) ~ new_w1_var,
      TRUE ~ w1_var
    ),
    # Update w1_scale
    w1_scale = case_when(
      !is.na(new_w1_scale) ~ new_w1_scale,
      TRUE ~ w1_scale
    ),
    # Update w1_label
    w1_label = case_when(
      !is.na(new_w1_label) ~ new_w1_label,
      TRUE ~ w1_label
    )
  ) %>%
  select(-new_w1_var, -new_w1_scale, -new_w1_label)

# -----------------------------------------------------------------------------
# 4. Verify the updates
# -----------------------------------------------------------------------------
cat("\nVerifying updates...\n")

w1_coverage_after <- sum(!is.na(master_updated$w1_var) & master_updated$w1_var != "NA")
cat(paste("  W1 variables before:", w1_coverage_before, "\n"))
cat(paste("  W1 variables after:", w1_coverage_after, "\n"))
cat(paste("  New W1 variables added:", w1_coverage_after - w1_coverage_before, "\n"))

# Show which concepts were updated
updated_concepts <- master_updated %>%
  filter(!is.na(w1_var) & w1_var != "NA") %>%
  select(concept, domain, w1_var, w1_scale) %>%
  arrange(domain, concept)

cat("\nW1 variables by domain:\n")
updated_concepts %>%
  count(domain) %>%
  arrange(desc(n)) %>%
  mutate(msg = paste("  ", domain, ":", n, "concepts")) %>%
  pull(msg) %>%
  cat(sep = "\n")

# -----------------------------------------------------------------------------
# 5. Save the updated crosswalk
# -----------------------------------------------------------------------------
cat("\n\nSaving updated crosswalk...\n")

write_csv(master_updated, here("abs_harmonization_crosswalk_MASTER.csv"))
cat("  Saved: abs_harmonization_crosswalk_MASTER.csv\n")

# Also save a detailed W1 mapping report
w1_report <- master_updated %>%
  filter(!is.na(w1_var) & w1_var != "NA") %>%
  select(concept, domain, w1_var, w1_scale, w1_label, w2_var, w2_scale, notes) %>%
  arrange(domain, concept)

write_csv(w1_report, here("docs/w1_variable_mappings.csv"))
cat("  Saved: docs/w1_variable_mappings.csv\n")

# -----------------------------------------------------------------------------
# 6. Summary
# -----------------------------------------------------------------------------
cat("\n=================================================================\n")
cat("  W1 UPDATE COMPLETE\n")
cat("=================================================================\n\n")

cat("Coverage summary:\n")
master_updated %>%
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

cat("\n\nSCALE CODING NOTES FOR W1:\n")
cat("---------------------------\n")
cat("TRUST (q007-q018): 4pt scale 0-3 (0=No trust, 3=Great deal), HIGHER=MORE trust\n")
cat("ECONOMIC (q001-q006): 5pt scale 1-5 (1=Bad/Worse, 5=Good/Better), HIGHER=BETTER\n")
cat("  NOTE: This is SAME polarity as W2-W3/W5-W6 but OPPOSITE to W4\n")
cat("INTEREST (q056): 4pt 1-4 (1=Not at all, 4=Very interested), HIGHER=MORE\n")
cat("FOLLOW NEWS (q057): 6pt 2-6 (2=Practically never, 6=Everyday), HIGHER=MORE\n")
cat("TRADITIONALISM (q064-q072): 4pt 1-4 (1=Strongly agree, 4=Strongly disagree)\n")
cat("  Agreement with traditional items = more traditional, so 1=MOST traditional\n")
cat("PARTICIPATION (q073-q095): Special coding 1=Once, 2=More than once, 9=Never\n")
cat("  Need recoding: 9->3 for consistent scale where HIGHER=LESS participation\n")
cat("ELECTORAL (q029-q031): Binary 1=No, 2=Yes - REVERSED from W3+ (1=Yes, 2=No)\n")
cat("DEMOCRACY SCALES (q098-q103): Mostly 10pt 1-10 (1=dictatorship, 10=democracy)\n")
cat("REGIME SUPPORT (q121-q124): 4pt agree-disagree (1=Strongly agree)\n")
cat("  Agreement = support for authoritarianism, so 1=MOST authoritarian\n")
cat("\n")
