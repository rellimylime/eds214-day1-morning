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
  # convert the sample_date to posixct (seconds)
  mutate(date = as.POSIXct(ymd(Sample_Date), tz = "UTC")) %>%
  # Restrict the year to 1988 - 1994
  filter(dplyr::between(year(date), 1988, 1994)) %>%
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
p <- ggplot(long, aes(x = date, y = rolling_means, linetype = site)) +
  # Draw the time series lines; drop rows with NA y values
  geom_line(na.rm = TRUE) +
  # Use specific line types for each site; keeps legend readable
  scale_linetype_manual(values = c("solid", "dotted", "dashed", "dotdash")) +
  # Add a vertical line for Hurricane Hugo (Sept 22, 1989)
  geom_vline(
    xintercept = as.POSIXct("1989-09-22", tz = "UTC"),
    linetype = "longdash",
    color = "grey"
  ) +
  # Make a panel per compound, one column, free y scales
  # Label strips on the left with readable text
  facet_wrap(
    ~compound,
    ncol = 1,
    scales = "free_y",
    strip.position = "left",
    labeller = as_labeller(c(
      "K"     = "Potassium\nconcentration\n(mg L^-1)",
      "NO3-N" = "Nitrate as nitrogen\nconcentration\n(ug N L^-1)",
      "Mg"    = "Magnesium\nconcentration\n(mg L^-1)",
      "Ca"    = "Calcium\nconcentration\n(mg L^-1)",
      "NH4-N" = "Ammonium as nitrogen\nconcentration\n(ug N L^-1)"
    ))
  ) +
  # Axis labels; y is NULL because each panel title carries units
  labs(x = "Years", y = NULL) +
  # Baseline black and white theme
  theme_bw() +
  # Tidy up grid and strip placement
  theme(
    panel.grid.minor = element_blank(),                # hide minor grid lines
    strip.background = element_blank(),                # remove strip background
    strip.text.y.left = element_text(),                # keep left strip text
    strip.placement = "outside",                       # place strips outside panel
    panel.spacing.y = grid::unit(0, "lines"),          # no vertical spacing between panels
    legend.title = element_blank(),                    # no legend title
    legend.position = c(0.89, 0.91)                    # place legend inside plot
  )

# Show the plot in the RStudio Plots pane when running via source()
print(p)

# Save to file; pass plot explicitly
ggsave(
  filename = here("output", "replica_plot.png"),
  plot = p,
  width = 1560, height = 2167, units = "px"
)