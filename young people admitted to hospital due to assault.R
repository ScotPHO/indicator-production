# Syntax to produce file for Children & Young People Profiles Indicators: admissions for assault 0-25.

###############################################.
## Packages/Filepaths/Functions ----
###############################################.
source("1.indicator_analysis.R") #Normal indicator functions
source("2.deprivation_analysis.R") # deprivation function

###############################################.
## Part 1 - Extract data from SMRA ----
###############################################.
# SMRA login information
channel <- suppressWarnings(dbConnect(odbc(),  dsn="SMRA",
                                      uid=.rs.askForPassword("SMRA Username:"), 
                                      pwd=.rs.askForPassword("SMRA Password:")))

# creates one record per CIS per financial year. Selects people between 15 and 25 with known sex.
young_assault <- tbl_df(dbGetQuery(channel, statement=
  "SELECT distinct link_no linkno, cis_marker cis, min(AGE_IN_YEARS) age, min(SEX) sex_grp, min(DR_POSTCODE) pc7,
  min(CASE WHEN extract(month from admission_date) > 3 
  THEN extract(year from admission_date)
  ELSE extract(year from admission_date) -1 END) as year
  FROM ANALYSIS.SMR01_PI z 
  WHERE admission_date between '1 April 2005' and '31 March 2018' 
   AND sex <> 0 
   AND (main_condition between 'X850' and 'Y099' or other_condition_1 between 'X850' and 'Y099'  or other_condition_2 between 'X850' and 'Y099'  or other_condition_3 between 'X850' and 'Y099' 
      or other_condition_4 between 'X850' and 'Y099'  or other_condition_5 between 'X850' and 'Y099')
   AND AGE_IN_YEARS between 15 and 25
   GROUP BY link_no, cis_marker" )) %>% 
  setNames(tolower(names(.)))  #variables to lower case

# recoding age; age standardisation uses specific age grouping.
young_assault <- young_assault %>% mutate(age_grp = case_when( 
  age >14 & age <20 ~ 4, age >19 & age <25 ~ 5, age >24 & age <26 ~ 6, 
  TRUE ~ as.numeric(age)
))

young_assault <- young_assault %>%
  arrange(linkno, cis, year, sex_grp, age_grp) %>% 
  group_by(linkno, cis, year, sex_grp, age_grp)


# Bringing council area info.
postcode_lookup <- readRDS('/conf/linkage/output/lookups/Unicode/Geography/Scottish Postcode Directory/Scottish_Postcode_Directory_2019_1.5.rds') %>% 
  setNames(tolower(names(.))) %>%   #variables to lower case
  select(pc7, ca2011)

# aggregate the data with healthboard info
young_assault <- left_join(young_assault, postcode_lookup, "pc7") %>% 
  subset(!(is.na(ca2011))) %>%  # exclude records with no ca2011 
  mutate_if(is.character, factor) # converting variables into factors

# save file
saveRDS(young_assault, file=paste0(data_folder, 'Prepared Data/young_assault_raw.rds'))

# group by year, ca2011, sex, age
youngassault_ca2011 <- young_assault %>% group_by(year, ca2011, sex_grp, age_grp) %>%  
  summarize(numerator = n()) %>% ungroup() %>% rename(ca = ca2011)

# save file
saveRDS(youngassault_ca2011, file=paste0(data_folder, 'Prepared Data/youngassault_ca2011_raw.rds'))

###############################################.
## - Run analysis functions ----
###############################################.


analyze_first(filename = "youngassault_ca2011", geography = "council", measure = "stdrate", 
              pop = "CA_pop_15to25", yearstart = 2005, yearend = 2018,
              time_agg = 3, epop_age = '15to25')

analyze_second(filename = "youngassault_ca2011", measure = "stdrate", time_agg = 3, 
               epop_total = 25400, ind_id = 13049, year_type = "financial", 
               profile = "CP", min_opt = 179196)

