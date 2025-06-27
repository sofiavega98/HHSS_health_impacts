#==============================================================================
# Hurricane Evacuation Data Import and Cleaning Script
#==============================================================================
#
# PURPOSE:
# This script processes raw hurricane evacuation order data from the Hurricane 
# Evacuation Order Database (HEvOD) to create a clean, county-level dataset 
# suitable for merging with exposure and health outcome data.
#
# DESCRIPTION:
# The script performs the following key operations:
# 1. Imports raw HEvOD data (2014-2022) with pipe-delimited format
# 2. Creates individual rows for each hurricane-county-alert combination
# 3. Handles complex county name variations and misspellings
# 4. Expands state-level evacuation orders to include all affected counties
# 5. Attaches FIPS codes for geographic identification
# 6. Standardizes county names and removes inconsistencies
#
# INPUTS:
# - HEvOD_2014-2022.csv: Raw hurricane evacuation order data
#   Expected location: /data/hurricane_evac/Full Database/
#   Format: Pipe-delimited CSV with UTF-8 encoding
#
# OUTPUTS:
# - evac_data_clean.Rdata: Cleaned evacuation dataset
#   Location: ~/Library/Mobile Documents/com~apple~CloudDocs/Harvard/HHSS_health_impacts/data/
#   Contains: One row per hurricane-county-alert combination with standardized names and FIPS codes
#
# DEPENDENCIES:
# - readr: For reading CSV files
# - dplyr: For data manipulation
# - tidyr: For data reshaping
# - stringr: For string operations
# - maps: For county reference data
# - ggplot2: For data visualization
# - tidycensus: For FIPS code reference
#
# USAGE:
# 1. Ensure the raw data file is in the expected location
# 2. Set working directory to project root
# 3. Run the entire script: source("1_import_hurricane_evac.R")
#
# DATA CLEANING STEPS:
# - Standardizes county name separators (and, &, ; -> comma)
# - Removes invalid entries (empty strings, "92 counties", "108 counties")
# - Fixes known misspellings (e.g., "Coma!" -> "Comal")
# - Expands state-level orders to include all counties in affected states
# - Removes "County" and "Parish" suffixes for consistency
# - Attaches FIPS codes using tidycensus reference data
# - Handles special cases for Louisiana parishes and Virginia cities
#
# AUTHOR: Sofia Vega
# DATE CREATED: 4/22/2025
# LAST MODIFIED: [Add date when last modified]
#
# NOTES:
# - Some counties without FIPS codes are removed (e.g., "Long Island", "New York City")
# - The script assumes state-level evacuation orders apply to all counties in that state
# - Louisiana parishes and Virginia independent cities are handled as special cases
#
#==============================================================================

# This script imports the hurricane evacuation data,
# creates a row for each hurricane-county-alert combination,
# corrects any misspellings in county names,
# attaches FIPS codes, and saves the cleaned data set for merging.
# Author: Sofia Vega
# Date created: 4/22/2025

library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(maps)
library(ggplot2)
library(tidycensus)

#########################
## Define file paths ##
#########################

# Get working directory
wd <- getwd()

# Define data paths
data_path <- file.path(wd, "data")
hurricane_evac_path <- file.path(data_path, "hurricane_evac", "Full Database")
input_file <- file.path(hurricane_evac_path, "HEvOD_2014-2022.csv")
output_file <- file.path(data_path, "evac_data_clean.Rdata")

# Create data directory if it doesn't exist
if (!dir.exists(data_path)) {
  dir.create(data_path, recursive = TRUE)
}

#################
## Import data ##
#################

# Read the CSV file
df <- read_delim(input_file, delim = '|', col_types = cols(`County FIPS` = col_character()), quote = '"', locale = locale(encoding = "UTF-8"))

# Print the first few rows of the dataframe
print(head(df))

# Print columns and datatypes
print(str(df))

#################################################################
## 2. Create a row for each hurricane-county-alert combination ##
#################################################################

unique(df$County)
# If an alert effects one county, "County" is in the name
# Some alerts effect multiple counties and are listed in a string
# Some use oxford comma with "and", some don't, some use "&".
# When an alert occurs in an entire state there is "Entire State"
# or "all counties", "All","All 67 counties"   .
# Idk what this refers to: "92 counties"  "108 counties"  
# "East of I-95 in Bryan, Camden, Chatham, Glynn, Liberty, and McIntosh Counties"

####################################
## Separate county lists by comma ##
####################################

# First, replace connectors like " and " with a comma.
# This standardizes the separator in the County field.
df_clean <- df %>%
  # 1. Protect "King and Queen" by substituting a unique placeholder.
  mutate(County = str_replace_all(County, fixed("King and Queen"), "KING_AND_QUEEN")) %>%
  # 2. Replace connectors with commas.
  mutate(County = str_replace_all(County, "\\s+and\\s+", ", ")) %>%
  mutate(County = str_replace_all(County, "\\s*&\\s*", ", ")) %>%
  mutate(County = str_replace_all(County, "\\s*;\\s*", ", ")) %>%
  # 3. Split the county string into separate rows on commas.
  separate_rows(County, sep = ",\\s*") %>%
  # 4. Trim white space and then restore the protected county name.
  mutate(County = str_trim(County),
         County = str_replace_all(County, "KING_AND_QUEEN", "King And Queen"))

##################################
## General county name cleaning ##
##################################

# Exploration: LA calls counties parishes
#df_clean %>% filter(State == "LA") %>% View()

# Exploration: GA has 159 counties. 
# No way to know which 92 counties these are referring to on 10/9/2018
# GA does expand the state of emergency to other counties on 10/10/2018
# State of emergency extended to "108 counties" 11/6/2018
# Assumption: Remove "92 counties" and "108 counties"
#df_clean %>% filter(County == "92 counties") %>% View()
#df_clean %>% filter(State == "GA" & `Event Name` == "Hurricane Michael") %>% View()
df_clean <- df_clean %>%
  filter(!(County %in% c("92 counties", "108 counties")))

# Exploration: Where is "Coma!"? Texas -> this should be "Comal"
#df_clean %>% filter(County == "Coma!") %>% View()
df_clean <- df_clean %>%
  mutate(County = str_replace_all(County, "Coma!", "Comal"))

# Separate "McIntosh Meriwether"   
df_clean <- df_clean %>%
  # Replace "McIntosh Meriwether" with "McIntosh, Meriwether" in the County column
  mutate(County = str_replace_all(County, "McIntosh Meriwether", "McIntosh, Meriwether")) %>%
  # Split rows on commas (if there are still any un-split county strings)
  separate_rows(County, sep = ",\\s*") %>%
  # Trim any extra whitespace that may have been introduced
  mutate(County = str_trim(County))


# Assumption: "East of I-95 in Bryan" -> "Bryan"
df_clean <- df_clean %>%
  mutate(County = str_replace_all(County, "East of I-95 in Bryan", "Bryan"))

# Assumption: "Yadkin (\"the Emergency Area\")" -> "Yadkin"
df_clean <- df_clean %>%
  mutate(County = str_replace_all(County, "Yadkin \\(\"the Emergency Area\"\\)", "Yadkin"))

# Exploration: "" was a result of the oxford comma
df_clean <- df_clean %>%
  filter(!(County %in% c("")))

# Exploration: County = NA 
# These are state of emergencies 
# Assuming this occurs in all counties in each state
# df_clean %>% filter(is.na(County)) %>% View()

# Remove trailing periods: "Worth.", "Washington County.", "Citrus.", "Washington."  
df_clean <- df_clean %>%
  mutate(County = str_remove(County, "\\.$"))

#######################################################
## Add all county rows when entire states referenced ##
#######################################################
# Named "Entire State", "All counties", "All Parishes", "All", "Statewide", "Entire parish", NA 

# Extract county map data and get distinct state-county pairs.
county_ref <- map_data("county") %>%
  distinct(region, subregion) %>%        # Get unique state-county combinations
  rename(State_full = region, County = subregion) %>% 
  mutate(
    State_full = str_to_title(State_full),         # Convert state names to title case
    County = str_to_title(County)          # Convert county names to title case
  )

# Examine the first few rows of county_ref
head(county_ref) # uses full state names

# Convert State_full column from abbreviations.
df_clean <- df_clean %>%
  mutate(State_full = state.name[match(State, state.abb)])

# Define state-level keywords
state_specials <- c("Entire State", "All counties", "All Parishes", "All", "Statewide", 
                    "Entire parish", "Entire state", "All 67 counties", "Entire Parish", "Entire County")

# Separate rows that already have a specific county from those at the state level:
df_counties <- df_clean %>%
  filter(!(County %in% state_specials | is.na(County)))

# Join 
df_states <- df_clean %>%
  filter(County %in% state_specials | is.na(County)) %>%
  select(-County) %>%
  left_join(county_ref, by = "State_full", relationship = "many-to-many") 

# Combine the two sets of rows
# df_final should now have a row for each county
df_final <- bind_rows(df_counties, df_states)

################################
## Remove county/parish words ##
################################
# County, Counties, counties, Parish, parish
df_final <- df_final %>%
  mutate(County = str_remove(County, "\\s*counties?$")) %>%
  mutate(County = str_remove(County, "\\s*Counties?$")) %>%
  mutate(County = str_remove(County, "\\s*county?$")) %>%
  mutate(County = str_remove(County, "\\s*County?$")) %>%
  mutate(County = str_remove(County, "\\s*counties?$")) %>%
  mutate(County = str_remove(County, "\\s*Parish?$")) %>%
  mutate(County = str_remove(County, "\\s*parish?$"))


##################################
## Join FIPS codes when missing ##
##################################

# Get FIPS codes from tidycensus
data("fips_codes")

county_fips_ref <- fips_codes %>%
  transmute(
    State = state,                             # two-letter state abbreviation
    County = str_to_title(county),             # county name in title case (without "County")
    refFIPS = paste0(state_code, county_code)       # full FIPS code; e.g. "06" + "001" -> "06001"
  )

# Inspect the first few rows
head(county_fips_ref)

# Remove "County" and "Parish to match df_final
county_fips_ref <- county_fips_ref %>%
  mutate(County = str_remove(County, "\\s*County?$")) %>%
  mutate(County = str_remove(County, "\\s*Parish?$"))

# Join FIPS where `County FIPS` is missing based on `State` and `County`
df_final <- df_final %>%
  left_join(
    county_fips_ref %>% select(State, County, refFIPS),
    by = c("State", "County")
  ) %>%
  # Use coalesce() to update missing FIPS values with refFIPS from the reference table.
  mutate(`County FIPS` = coalesce(`County FIPS`, refFIPS)) %>%
  select(-refFIPS)  # remove the temporary column

# Check if there are still any missing FIPS (547 rows)
FIPS_missing <- df_final %>% filter(is.na(`County FIPS`)) 

unique(FIPS_missing$County)


# Fix misspellings in data
df_final <- df_final %>%
  mutate(
    # Replace known misspellings or spacing issues using fixed() if no regex is needed:
    County = str_replace_all(County, fixed("Miami-Dale"), "Miami-Dade"),
    County = str_replace_all(County, fixed("Miami Dade"), "Miami-Dade"),
    County = str_replace_all(County, fixed("Caidwell"), "Caldwell"),
    County = str_replace_all(County, fixed("Berkely"), "Berkeley"),
    County = str_replace_all(County, fixed("Bradroed"), "Bradford"),
    County = str_replace_all(County, fixed("Olaloosa"), "Okaloosa"),
    County = str_replace_all(County, fixed("Momoe"), "Monroe"),
    County = str_replace_all(County, fixed("Wailer"), "Waller"),
    
    # Ensure that abbreviations starting with "St" have a period.
    # This pattern looks for "St" at a word boundary followed by a space (and then a capital letter)
    # and replaces it with "St. " (only if the period is missing).
    County = str_replace_all(County, "\\bSt(\\s)(?=[A-Z])", "St. "),
    
    # Handle specific cases where the name doesnt match the FIPS table
    # For example, fix "St Marys" if the intended value is "St. Mary's" in MD.
    
    County = case_when(
      State == "LA" & str_detect(County, regex("^St\\.?\\s*Mary", ignore_case = TRUE)) ~ "St. Mary", 
      State == "MD" & str_detect(County, regex("^St\\.?\\s*Mary'?s?", ignore_case = TRUE)) ~ "St. Mary's",
      State == "VA" & str_detect(County, regex("Suffolk", ignore_case = TRUE)) ~ "Suffolk City",
      State == "VA" & str_detect(County, regex("Norfolk", ignore_case = TRUE)) ~ "Norfolk City",
      State == "VA" & str_detect(County, regex("Hampton", ignore_case = TRUE)) ~ "Hampton City",
      State == "VA" & str_detect(County, regex("Newport News", ignore_case = TRUE)) ~ "Newport News City",
      State == "VA" & str_detect(County, regex("Virginia Beach", ignore_case = TRUE)) ~ "Virginia Beach City",
      TRUE ~ County ),
   
    
    # Also standardize spacing for variants like "De Soto" which should match how the FIPS table spells it.
    County = str_replace_all(County, fixed("De Soto"), "Desoto"),
    County = str_replace_all(County, fixed("DeSoto"), "Desoto"),
    County = str_replace_all(County, fixed("DeWitt"), "Dewitt"),
    County = str_replace_all(County, fixed("De Kalb"), "Dekalb"),
    County = str_replace_all(County, fixed("McIntosh"), "Mcintosh"),
    County = str_replace_all(County, fixed("McDuffie"), "Mcduffie"),
    County = str_replace_all(County, fixed("McDowell"), "Mcdowell"),
    County = str_replace_all(County, fixed("McMullen"), "Mcmullen"),
    County = str_replace_all(County, fixed("McIntosh"), "Mcintosh"),
    County = str_replace_all(County, fixed("Isle of Wight"), "Isle Of Wight"),
    County = str_replace_all(County, fixed("Mainland of Bryan"), "Bryan"),
    County = str_replace_all(County, fixed("Prince Georges"), "Prince George's"),
    County = str_replace_all(County, fixed("Queen Annes"), "Queen Anne's")
    
    
  )

# Again, Join FIPS where `County FIPS` is missing based on `State` and `County`
df_final <- df_final %>%
  left_join(
    county_fips_ref %>% select(State, County, refFIPS),
    by = c("State", "County")
  ) %>%
  # Use coalesce() to update missing FIPS values with refFIPS from the reference table.
  mutate(`County FIPS` = coalesce(`County FIPS`, refFIPS)) %>%
  select(-refFIPS)  # remove the temporary column

# Check if there are still any missing FIPS (547 rows)
FIPS_missing_v2 <- df_final %>% filter(is.na(`County FIPS`)) 

unique(FIPS_missing_v2$County)

# The remaining without a FIPS code are: "Long Island"   "New York City" "Hudson Valley"

# For now, remove "Long Island"   "New York City" "Hudson Valley"
evac_df <- df_final %>% filter(!is.na(`County FIPS`))

# Save data
save(evac_df, file = output_file)
