# Setup
library(tidyverse)
library(here)
library(lubridate)

rm(list = ls())

print("Hi World")

# Time-series plots of rain inputs and streamwater concentrations are presented as 9-wk moving averages. This approach minimized rapid fluctuations
# caused by concentration-discharge interactions, made longer-term patterns
# more apparent, and permitted data from several streams and ions to be presented together. Stream concentration data are presented in two groups, the
# El Verde streams (QS, QT, QPA, QPB), and the Bisley streams (PRM, BQ1,
# BQ2, BQ3). Moving averages were not plotted where there were gaps in sampling or in particular chemical analyses.

# Load data
BQ1_df <- read_csv(here("knb-lter-luq.20.4923064","QuebradaCuenca1-Bisley.csv")) %>% 
  mutate(site = "BQ1")
BQ2_df <- read_csv(here("knb-lter-luq.20.4923064","QuebradaCuenca2-Bisley.csv")) %>% 
  mutate(site = "BQ2")
BQ3_df <- read_csv(here("knb-lter-luq.20.4923064","QuebradaCuenca3-Bisley.csv")) %>% 
  mutate(site = "BQ3")
PRM_df <- read_csv(here("knb-lter-luq.20.4923064","RioMameyesPuenteRoto.csv")) %>% 
  mutate(site = "PRM")

compounds <- c("K","NO3-N","NH4-N","Mg","Ca")
sites <- c("BQ1", "BQ2", "BQ3", "PRM")


# assign value in seconds of 4 week half-interval
half_interval_sec <- 4 * 7 * 24 * 60 * 60

#Define function to calculate moving average
calc_moving_avg <- function(dates, values, half_interval = 4, min_gap_size = 3) {
  
  # date values in  numerical POSIXct
  date_sec <-  as.numeric(dates)
  
  # generate empty vector to store rolled means
  rolled_means <- numeric(length(values))
  
  # iterate along length of values
  for (i in seq_along(values)) {
    # identify interval values for each date
    interval_elements <- abs(date_sec - date_sec[i]) <= half_interval_sec
    
    # subset values and dates to those in the interval
    interval_vals <- values[interval_elements]
    dates <- date_sec[interval_elements]
    
    # remove NA values and dates
    non_na_elements <- !is.na(interval_vals)
    vals <- interval_vals[non_na_elements]
    dates <- dates[non_na_elements]
    
    if (length(vals) < min_gap_size) {
      next
    } else {
      rolled_means[i] <- mean(vals)
    }
  }
  return(rolled_means)
}


# Deal with duplicate date entries


all_sites_df <- bind_rows(BQ1_df, BQ2_df, BQ3_df, PRM_df) %>%
  mutate(date = as.POSIXct(ymd(Sample_Date), tz = "UTC")) %>%
  filter(year(date) >= 1988, year(date) <= 1994) %>%
  select(date, site, "K", "NO3-N", "NH4-N", "Mg", "Ca") %>%
  arrange(site, date)


long <- all_sites_df %>%
  pivot_longer(cols = c(K, "NO3-N", "NH4-N", Mg, Ca), names_to = "compound", values_to = "value") %>% 
  mutate(compound = factor(compound, levels = compounds),
         site = factor(site, levels = sites)) %>%  # make compound and site categorical
  group_by(site, compound) %>% 
  arrange(date, .by_group = TRUE) %>%
  mutate(rolling_means = calc_moving_avg(date, value, half_interval = 4, min_gap_size = 3)) %>% 
  ungroup()

# plot different compound moving averages over time by site



ggplot(long, aes(x = date, y = rolling_means, linetype = site, group = site)) +
  geom_line(na.rm = TRUE) +
  geom_vline(xintercept = as.POSIXct("1990-01-01", tz = "UTC"), linetype = "longdash", color = "grey") +
  facet_wrap(~ compound, ncol = 1, scales = "free_y") +
  scale_linetype_manual(
    values = c("solid", "dotted", "dashed", "dotdash")
  ) +
  scale_x_datetime(date_breaks = "1 year", date_labels = "%Y") +
  labs(x = "Years", y = NULL) +
  theme_bw() +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(hjust = 0))

# ggsave(here("figs","spooled-spaghetti-plot.png"), width = 6, height = 8)