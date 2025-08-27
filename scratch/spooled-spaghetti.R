# Setup
library(tidyverse)
library(here)
library(lubridate)

rm(list = ls())

print("Hello")

# Time-series plots of rain inputs and streamwater concentrations are presented as 9-wk moving averages. This approach minimized rapid fluctuations
# caused by concentration-discharge interactions, made longer-term patterns
# more apparent, and permitted data from several streams and ions to be presented together. Stream concentration data are presented in two groups, the
# El Verde streams (QS, QT, QPA, QPB), and the Bisley streams (PRM, BQ1,
# BQ2, BQ3). Moving averages were not plotted where there were gaps in sampling or in particular chemical analyses.

# Load data
BQ1_df <- read_csv(here("data", "QuebradaCuenca1-Bisley.csv")) %>%
  mutate(site = "BQ1")
BQ2_df <- read_csv(here("data", "QuebradaCuenca2-Bisley.csv")) %>%
  mutate(site = "BQ2")
BQ3_df <- read_csv(here("data", "QuebradaCuenca3-Bisley.csv")) %>%
  mutate(site = "BQ3")
PRM_df <- read_csv(here("data", "RioMameyesPuenteRoto.csv")) %>%
  mutate(site = "PRM")

compounds <- c("K", "NO3-N", "Mg", "Ca", "NH4-N")
sites <- c("BQ1", "BQ2", "BQ3", "PRM")


# assign value in seconds of 4 week half-interval
week_sec <- 7 * 24 * 60 * 60


# Define function to calculate moving average
calc_moving_avg <- function(dates, values, half_interval = 4.5, min_valid_interval_points = 1, max_gap_weeks = 1000) {
  
  half_interval_sec <- half_interval * 7 * 24 * 60 * 60
  
  # date values in  numerical POSIXct
  date_sec <- as.numeric(dates)

  # generate empty vector to store rolled means
  rolled_means <- rep(NA_real_, length(values))

  # iterate along length of values
  for (i in seq_along(values)) {
    # identify interval values for each date
    interval_bool <- abs(date_sec - date_sec[i]) <= half_interval_sec

    # subset values and dates to those in the interval
    interval_vals <- values[interval_bool]
    dates <- date_sec[interval_bool]

    # remove NA values and dates
    non_na_elements <- !is.na(interval_vals)

    vals <- interval_vals[non_na_elements]
    dates <- dates[non_na_elements]

    if (length(vals) < min_valid_interval_points) {
      next
    } else if (is.finite(max_gap_weeks)) {
      # Time between observations
      gaps <- diff(sort(dates))
      # If the gap between data is greater than our max gap go to next iteration
      if ((length(dates) > 1) & (max(gaps) > max_gap_weeks * week_sec)) {
        next
      }

      rolled_means[i] <- mean(vals)
    }
  }
  return(rolled_means)
}

# Function to find median of list of values while accounting for NA
find_median <- function(x) {
  if (all(is.na(x))) {
    NA_real_
  } else {
    return(median(x, na.rm = TRUE))
  }
}
# Deal with duplicate date entries


all_sites_df <- rbind(BQ1_df, BQ2_df, BQ3_df, PRM_df) %>%
  mutate(date = as.POSIXct(ymd(Sample_Date), tz = "UTC")) %>%
  filter(year(date) >= 1988, year(date) <= 1994) %>%
  select(date, site, "K", "NO3-N", "Mg", "Ca", "NH4-N") %>%
  arrange(site, date)

# print(length(unique(all_sites_df$"NH4-N")))
# print(length(unique(all_sites_df$"K")))
# print(length(unique(all_sites_df$"NO3-N")))
# print(length(unique(all_sites_df$"Mg")))
# print(length(unique(all_sites_df$"Ca")))

long <- all_sites_df %>%
  pivot_longer(cols = c(K, "NO3-N", Mg, Ca, "NH4-N"), names_to = "compound", values_to = "value") %>%
  mutate(
    compound = factor(compound, levels = compounds),
    site = factor(site, levels = sites)
  ) %>% # make compound and site categorical
  group_by(site, compound, date) %>%
  summarize(
    value = find_median(value)
  )
# nh4_coverage <- all_sites_df %>%
#   transmute(site, year = year(date), nh4 = `NH4-N`) %>%
#   group_by(site, year) %>%
#   summarise(n_non_na = sum(!is.na(nh4)), .groups = "drop") %>%
#   arrange(site, year)
# print(nh4_coverage, n = 100)

long <- long %>%
  arrange(date, .by_group = TRUE) %>%
  mutate(rolling_means = calc_moving_avg(date, value))

# long_counts <- long %>%
#   group_by(site, compound, date) %>%
#   summarise(n = n()) #%>%
#   #uncount(n)
#
# out <-long_counts[[1]]
#
# find_median <- numeric(max(long_counts$n))
# print(class(find_median))
# for (i in seq_along(long_counts)) {
#   if (long_counts[i]$n > 1) {
#     long_counts <- long_counts %>%
#       mutate(rolling_means = median(fitler(long$date == long_counts[i]$date)))
#       #%>% group_by(site, compound, date)
#   }
# }

ggplot(long, aes(x = date, y = rolling_means, linetype = site, group = site)) +
  geom_line(na.rm = TRUE) +
  geom_vline(xintercept = as.POSIXct("1989-09-22", tz = "America/New_York"), linetype = "longdash", color = "grey") +
  facet_wrap(~compound, ncol = 1, scales = "free_y") +
  scale_linetype_manual(
    values = c("solid", "dotted", "dashed", "dotdash")
  ) +
  scale_x_datetime(date_breaks = "1 year", date_labels = "%Y") +
  labs(x = "Years", y = NULL) +
  theme_bw() +
  theme(
    panel.grid.minor = element_blank(),
    strip.background = element_blank(),
    strip.text = element_text(hjust = 0)
  )


vec <- c(1, 1, 2)
print(diff(vec))


# ggsave(here("figs","spooled-spaghetti-plot.png"), width = 6, height = 8)
