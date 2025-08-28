# Load required packages
library(here) 
library(tidyverse)

# Load data
BQ1_df <- read_csv(here("data", "raw_data", "QuebradaCuenca1-Bisley.csv")) %>%
  mutate(site = "BQ1")
BQ2_df <- read_csv(here("data", "raw_data", "QuebradaCuenca2-Bisley.csv")) %>%
  mutate(site = "BQ2")
BQ3_df <- read_csv(here("data", "raw_data", "QuebradaCuenca3-Bisley.csv")) %>%
  mutate(site = "BQ3")
PRM_df <- read_csv(here("data", "raw_data", "RioMameyesPuenteRoto.csv")) %>%
  mutate(site = "PRM")


