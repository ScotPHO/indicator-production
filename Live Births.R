#Incomplete script - still work in progress 

# ScotPHO indicators: Live births

## Part 1 - Format raw data ready for analysis functions 
## Part 2 - calling the analysis functions 
## Part 3 - Editing shiny data file to exclude data for regions where data is known to be incomplete

###############################################.
## Packages/Filepaths/Functions ----
###############################################.
source("1.indicator_analysis.R") #Normal indicator functions
source("2.deprivation_analysis.R") # deprivation function


live_births <- read_excel(paste0(data_folder, "Received Data/Live births by datazone_2011 - 2002-2016.xlsx"), 
                          sheet = "Births", range = cell_limits(c(1, 1), c(NA, 4))) %>%
  setNames(tolower(names(.))) %>%
  rename(year = calendar_year, datazone = datazone_2011, numerator = number) %>%
  mutate(datazone = case_when(is.na(datazone) ~ lag(datazone),
                               TRUE ~ datazone)) %>%
  #mutate(sex = if_else(sex == 1, "male", "female")) %>%
  filter(!is.na(datazone)) %>% # exclude rows with no datazone.
  group_by(year, datazone) %>% 
  summarise(numerator = sum(numerator, na.rm =T)) %>% ungroup()

saveRDS(live_births, file=paste0(data_folder, 'Prepared Data/live_births_raw.rds'))


###############################################.
## Part 2 - Run analysis functions ----
###############################################.

analyze_first(filename = "live_births", geography = "datazone11", measure = "crude", 
              yearstart = 2002, yearend = 2016, time_agg = 1, pop ='DZ11_pop_allages')

analyze_second(filename = "live_births", measure = "crude", time_agg = 1, crude_rate=1000,
               ind_id = 13106, year_type = "calendar", profile = "CP", min_opt = 251287)