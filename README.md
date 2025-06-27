# Hurricane Health Impacts Analysis

## Overview

This repository contains R scripts for processing and analyzing hurricane evacuation data to study health impacts. The project focuses on cleaning hurricane evacuation order data, merging it with exposure data, and preparing it for health outcome analysis.

## Project Purpose

The goal of this project is to create a comprehensive dataset that combines:
- Hurricane evacuation order data (2014-2022)
- Hurricane exposure data (wind speeds, storm tracks)
- Treatment effects for health outcome analysis

This integrated dataset enables researchers to study the health impacts of hurricane evacuations and related emergency responses.

## Repository Structure

```
github/
├── README.md                    # This file
├── 1_import_hurricane_evac.R   # Data import and cleaning script
├── 2_merge_evac_exp.R          # Data merging script
└── data/                       # Data directory (not included in repo)
    ├── hurricane_evac/         # Raw evacuation data
    ├── evac_data_clean.Rdata   # Cleaned evacuation data
    ├── evac_merged_data.Rdata  # Final merged dataset
    └── trteffects.RData        # Treatment effects data
```

## Scripts

### 1. `1_import_hurricane_evac.R`

**Purpose**: Processes raw hurricane evacuation order data to create a clean, county-level dataset.

**Key Operations**:
- Imports HEvOD (Hurricane Evacuation Order Database) data (2014-2022)
- Creates individual rows for each hurricane-county-alert combination
- Handles complex county name variations and misspellings
- Expands state-level evacuation orders to include all affected counties
- Attaches FIPS codes for geographic identification
- Standardizes county names and removes inconsistencies

**Input**: `HEvOD_2014-2022.csv` (pipe-delimited CSV)
**Output**: `evac_data_clean.Rdata`

### 2. `2_merge_evac_exp.R`

**Purpose**: Merges cleaned evacuation data with hurricane exposure data and treatment effects.

**Key Operations**:
- Loads cleaned evacuation data from the previous step
- Imports hurricane exposure data from the `hurricaneexposuredata` package
- Merges evacuation and exposure data based on storm, county, and year
- Incorporates treatment effects estimated by Nethery et al. (2023)
- Creates final merged dataset for health impact analysis

**Input**: `evac_data_clean.Rdata`, `storm_winds` (package data), `trteffects.RData`
**Output**: `evac_merged_data.Rdata`

## Data Sources

### Hurricane Evacuation Order Database (HEvOD)
- **Source**: Hurricane Evacuation Order Database
- **Period**: 2014-2022
- **Content**: Evacuation orders by hurricane, county, and date

### Hurricane Exposure Data
- **Source**: `hurricaneexposuredata` R package
- **Period**: 1988-2018
- **Content**: Wind speed data by county, storm, and date

### Treatment Effects
- **Source**: Nethery et al. (2023)
- **Period**: 2006-2014
- **Content**: Estimated treatment effects for health outcome analysis
- **Reference**: https://academic.oup.com/biostatistics/article/24/2/449/6485226


## Covered Hurricanes

The final dataset includes data for the following hurricanes:
- Hurricane Arthur (2014)
- Hurricane Hermine (2016)
- Hurricane Matthew (2016)
- Hurricane Harvey (2017)
- Hurricane Irma (2017)
- Hurricane Nate (2017)
- Hurricane Florence (2018)
- Hurricane Michael (2018)

## Installation and Setup

### Prerequisites

1. **R** (version 4.0 or higher recommended)
2. **RStudio** (optional but recommended)

### Required R Packages

```r
# Install required packages
install.packages(c(
  "readr",
  "dplyr", 
  "tidyr",
  "stringr",
  "maps",
  "ggplot2",
  "tidycensus",
  "lubridate"
))

# Install hurricane exposure data package
install.packages("hurricaneexposuredata")
```

### Data Setup

1. Create a `data` directory in your project root
2. Place the raw evacuation data file (`HEvOD_2014-2022.csv`) in `data/hurricane_evac/Full Database/`
3. Ensure `trteffects.RData` is available in the `data` directory

## Usage

### Step 1: Data Import and Cleaning

```r
# Set working directory to project root
setwd("/path/to/your/project")

# Run the import and cleaning script
source("1_import_hurricane_evac.R")
```

### Step 2: Data Merging

```r
# Run the merging script
source("2_merge_evac_exp.R")
```

### Output Files

After running both scripts, you will have:
- `data/evac_data_clean.Rdata`: Cleaned evacuation dataset
- `data/evac_merged_data.Rdata`: Final merged dataset for analysis

## Data Cleaning Details

### County Name Standardization
- Standardizes separators (and, &, ; → comma)
- Removes invalid entries (empty strings, "92 counties", "108 counties")
- Fixes known misspellings (e.g., "Coma!" → "Comal")
- Removes "County" and "Parish" suffixes for consistency

### Geographic Handling
- Expands state-level orders to include all counties in affected states
- Attaches FIPS codes using `tidycensus` reference data
- Handles special cases for Louisiana parishes and Virginia cities
- Removes counties without valid FIPS codes

### Merging Strategy
- Uses inner joins to ensure data quality and completeness
- Matches on Storm name, County FIPS code, and Year
- Filters exposure data to years present in evacuation data (2014-2022)

## Notes and Limitations

- Some counties without FIPS codes are removed (e.g., "Long Island", "New York City", "Hudson Valley")
- State-level evacuation orders are assumed to apply to all counties in that state
- Treatment effects are currently only available for Hurricane Arthur
- Louisiana parishes and Virginia independent cities are handled as special cases

## Contact

- **Author**: Sofia Vega
- **Email**: sofialeighvega@gmail.com

