#==============================================================================
# Hurricane Evacuation and Exposure Data Merging Script
#==============================================================================
#
# PURPOSE:
# This script merges cleaned hurricane evacuation data with hurricane exposure 
# data and treatment effects to create a comprehensive dataset for analyzing 
# the health impacts of hurricane evacuations.
#
# DESCRIPTION:
# The script performs the following key operations:
# 1. Loads cleaned evacuation data from the previous processing step
# 2. Imports hurricane exposure data from the hurricaneexposuredata package
# 3. Merges evacuation and exposure data based on storm, county, and year
# 4. Incorporates treatment effects estimated by Nethery et al. (2023)
# 5. Creates final merged dataset for health impact analysis
#
# INPUTS:
# - evac_data_clean.Rdata: Cleaned evacuation dataset from script 1
#   Location: /data/evac_data_clean.Rdata
# - storm_winds: Hurricane exposure data from hurricaneexposuredata package
#   Contains: Wind speed data by county, storm, and date
# - trteffects.RData: Treatment effects from Nethery et al. (2023)
#   Location: /data/trteffects.RData
#   Reference: https://academic.oup.com/biostatistics/article/24/2/449/6485226
#
# OUTPUTS:
# - evac_merged_data.Rdata: Merged evacuation and exposure data
#   Location: /data/evac_merged_data.Rdata
#   Contains: Combined evacuation, exposure, and treatment effect data
#
# DEPENDENCIES:
# - readr: For data reading operations
# - dplyr: For data manipulation and joining
# - lubridate: For date handling
# - tidyr: For data reshaping
# - hurricaneexposuredata: For hurricane exposure data
#
# USAGE:
# 1. Ensure evac_data_clean.Rdata exists from running script 1
# 2. Ensure trteffects.RData is available in the data directory
# 3. Set working directory to project root
# 4. Run the entire script: source("2_merge_evac_exp.R")
#
# MERGING STRATEGY:
# - Uses inner joins to keep only storms present in both evacuation and exposure data
# - Matches on Storm name, County FIPS code, and Year
# - Filters exposure data to years present in evacuation data (2014-2022)
# - Incorporates treatment effects for health outcome analysis
#
# COVERED HURRICANES:
# The final dataset includes data for the following hurricanes:
# - Hurricane Arthur (2014)
# - Hurricane Hermine (2016)
# - Hurricane Matthew (2016)
# - Hurricane Harvey (2017)
# - Hurricane Irma (2017)
# - Hurricane Nate (2017)
# - Hurricane Florence (2018)
# - Hurricane Michael (2018)
#
# AUTHOR: Sofia Vega
# DATE CREATED: 4/17/2025
# LAST MODIFIED: 4/30/2025
#
# NOTES:
# - Treatment effects are only available for Hurricane Arthur in the current dataset
# - The script uses inner joins to ensure data quality and completeness
# - Storm names are standardized by removing "Hurricane" prefix for matching
#
#==============================================================================

# Script to merge hurricane evacuation data with hurricane exposure data
# And with treatment effect estimated from https://academic.oup.com/biostatistics/article/24/2/449/6485226
# Date created: 4/17/2025
# Last modified: 4/30/2025
# Author: Sofia Vega

# Load libraries
library(readr)
library(dplyr)
library(lubridate)
library(tidyr)

#########################
## Define file paths ##
#########################

# Get working directory
wd <- getwd()

# Define data paths
data_path <- file.path(wd, "data")
evac_data_file <- file.path(data_path, "evac_data_clean.Rdata")
trteffects_file <- file.path(data_path, "trteffects.RData")
output_file <- file.path(data_path, "evac_merged_data.Rdata")

# Create data directory if it doesn't exist
if (!dir.exists(data_path)) {
  dir.create(data_path, recursive = TRUE)
}

##########################
## Load evacuation data ##
##########################

# Read the cleaned evacuation data
load(evac_data_file)
head(evac_df)

names(evac_df)

########################
## Load Exposure data ##
########################

library(hurricaneexposuredata)
data("storm_winds")
head(storm_winds)

names(storm_winds)

# Separate year and hurricane in storm_id
storm_winds <- storm_winds %>%
  separate(storm_id, into = c("Storm", "Year"), sep = "-", remove = FALSE, convert = TRUE)

# Subset to years in evac data
exp_df <- storm_winds %>% filter(Year %in% c(unique(evac_df$Year)))

# Clean up to match evac_df
names(exp_df)[1] <- "County FIPS"
exp_df$Year <- as.double(exp_df$Year)

#######################################
## Explore the overlap of hurricanes ##
#######################################

# Which hurricanes in evac data
unique(evac_df$`Event Name`)
evac_df$Storm <- gsub("^Hurricane\\s+", "", evac_df$`Event Name`)

# Which hurricanes in exp data
unique(exp_df$storm_id)

#####################
## Merge data sets ##
######################
# Using inner join to keep only the storms in the evacuation data 
# that are also in the exposure data
merged_df <- inner_join(evac_df, exp_df, by = c("Storm", "County FIPS", "Year"))

# Save
save(merged_df, file = output_file)

# Hurricanes: "Hurricane Arthur"   "Hurricane Hermine"  "Hurricane Matthew" 
# "Hurricane Harvey"   "Hurricane Irma"     "Hurricane Nate"    
# "Hurricane Florence" "Hurricane Michael" 
##################################################################
## Load treatment effect estimated calculated by Nethery et al. ##
##################################################################

load(trteffects_file)

# Separate year and hurricane in storm_id
trteffects <- trteffects %>%
  separate(storm_id, into = c("Storm", "Year"), sep = "-", remove = FALSE, convert = TRUE)

# Explore trteffects
head(trteffects)
unique(trteffects$Year)
  
# Subset to years in evac data
trteffects <- trteffects %>% filter(Year %in% c(unique(evac_df$Year)))

# Clean up to match evac_df
names(trteffects)[1] <- "County FIPS"
trteffects$Year <- as.double(trteffects$Year)

# Merge with previously merged datasets 
merged_outcome_df <- inner_join(merged_df, trteffects, by = c("Storm", "County FIPS", "Year"))

# Hurricanes in this dataset: Hurricane Arthur

# Save
save(merged_df, file = output_file)


