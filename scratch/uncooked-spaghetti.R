# Setup
library(tidyverse)
library(here)
library(lubridate)

source("R/util.R")

# Load data
BQ1_df <- read_csv(here("data", "raw_data", "QuebradaCuenca1-Bisley.csv")) %>%
  mutate(site = "BQ1")
BQ2_df <- read_csv(here("data", "raw_data", "QuebradaCuenca2-Bisley.csv")) %>%
  mutate(site = "BQ2")
BQ3_df <- read_csv(here("data", "raw_data", "QuebradaCuenca3-Bisley.csv")) %>%
  mutate(site = "BQ3")
PRM_df <- read_csv(here("data", "raw_data", "RioMameyesPuenteRoto.csv")) %>%
  mutate(site = "PRM")

# vectors to iterate through compounds and sites
compounds <- c("K", "NO3-N", "Mg", "Ca", "NH4-N")
sites <- c("BQ1", "BQ2", "BQ3", "PRM")

# bind dataframes
all_sites_df <- rbind(BQ1_df, BQ2_df, BQ3_df, PRM_df) %>%
  
  # Restrict the year to 1988 - 1994
  filter(year(Sample_Date) >= 1988, year(Sample_Date) <= 1994) %>%
  
  # convert the sample_date to posixct (seconds)
  mutate(date = as.POSIXct(ymd(Sample_Date), tz = "UTC")) %>%
  
  # Select the necessary columns
  select(date, site, "K", "NO3-N", "Mg", "Ca", "NH4-N") %>%
  
  # Order by site and date (ascending)
  arrange(site, date)


# Collapse values and calculate moving average
long <- all_sites_df %>%
  # Make a column named compound to hold the chemical name
  pivot_longer(cols = c(K, "NO3-N", Mg, Ca, "NH4-N"), names_to = "compound", values_to = "value") %>%
  
  # Make the compound and site column values categorical
  mutate(
    compound = factor(compound, levels = compounds),
    site = factor(site, levels = sites)
  ) %>% 
  
  # Group by site compound and date
  group_by(site, compound, date) %>%
  
  # Collapse multiple values with same date, site, compound by selecting the median value
  summarize(
    value = find_median(value)
  ) %>%
  
  # order by date within the site/compound groups
  arrange(date, .by_group = TRUE) %>%
  
  # Add column for the rolling means using the calc_moving_avg function
  mutate(rolling_means = calc_moving_avg(date, value))


# Make the plot
ggplot(long, aes(x = date, y = rolling_means, linetype = site, group = site)) +
  
  # Line plot of means over time
  geom_line(na.rm = TRUE) +
  
  # Specify the line types for each group category (site)
  scale_linetype_manual(
    values = c("solid", "dotted", "dashed", "dotdash")
  ) +
  
  # Add vertical line that represents the approx date of the hurricane
  geom_vline(xintercept = as.POSIXct("1989-09-22", tz = "America/New_York"), linetype = "longdash", color = "grey") +
  
  # Made a 1 column grid of plots for each compound, let the y axis scale automatically 
  facet_wrap(~compound, ncol = 1, scales = "free_y", strip.position = "left") +
  
  # 
  scale_x_datetime(date_breaks = "1 year", date_labels = "%Y") +
  
  labs(x = "Years", y = NULL) +
  
  theme_bw() +
  
  theme(
    panel.grid.minor = element_blank(),
    strip.background = element_blank(),
    #strip.text = element_text(hjust = 0),
    strip.text.y.left = element_text(),
    strip.placement = "outside",
    panel.spacing.y = unit(0, "lines"),
    legend.title = element_blank(),
    legend.position = c(0.89, 0.91)
  )
  
  ggsave(here("output","replica_plot.png"), width = 1560, height = 2167, units = "px")

  