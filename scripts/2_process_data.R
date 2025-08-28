# Load libraries
library(here)
library(tidyverse)
library(lubridate)

# Source loaded data
source("scripts/1_load_data.R")

# bind dataframes
all_sites_df <- rbind(BQ1_df, BQ2_df, BQ3_df, PRM_df) %>%
  
  # convert the sample_date to posixct (seconds)
  mutate(date = as.POSIXct(ymd(Sample_Date), tz = "UTC")) %>%
  
  # Restrict the year to 1988 - 1994
  filter(year(date) >= 1988, year(date) <= 1994) %>%
  
  # Select the necessary columns
  select(date, site, "K", "NO3-N", "Mg", "Ca", "NH4-N") %>%
  
  # Order by site and date (ascending)
  arrange(site, date)

# Save merged and cleaned dataframe
write_csv(all_sites_df, here("data", "processed_data", "cleaned_data.csv"))