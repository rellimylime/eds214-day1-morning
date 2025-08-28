#' Find median of repeat values
#'
#' @param x 
#'
#' @returns
#' @export
#'
#' @examples
#' long <- all_sites_df %>%
#' pivot_longer(cols = c(K, "NO3-N", Mg, Ca, "NH4-N"), names_to = "compound", values_to = "value") %>%
#'  mutate(
#'     compound = factor(compound, levels = compounds),
#'     site = factor(site, levels = sites)
#'   ) %>% # make compound and site categorical
#'   group_by(site, compound, date) %>%
#'   summarize(
#'     value = find_median(value)
#'   )
find_median <- function(x) {
  if (all(is.na(x))) {
    return(NA_real_)
  } else {
    return(median(x, na.rm = TRUE))
  }
}

#' Calculate Moving Mean
#'
#' @param dates vector of 
#' @param values 
#' @param half_interval 
#' @param min_valid_interval_points 
#' @param max_gap_weeks 
#'
#' @returns 
#' @export
#'
#' @examples
#' long <- long %>%
#' arrange(date, .by_group = TRUE) %>%
#'   mutate(rolling_means = calc_moving_avg(date, value))
calc_moving_avg <- function(dates, 
                            values,
                            half_interval = 4.5, 
                            min_valid_interval_points = 1, 
                            max_gap_weeks = 1000) {
  
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
    
    # use the non NA values to mask the vals and dates vectors
    vals <- interval_vals[non_na_elements]
    dates <- dates[non_na_elements]
    
    # check the number of valid values in the interval as well as the date gaps
    if (length(vals) < min_valid_interval_points) {
      next
    } else if (is.finite(max_gap_weeks)) {
      # Time between observations
      gaps <- diff(sort(dates))
      # If the gap between data is greater than our max gap go to next iteration
      if ((length(dates) > 1) & (max(gaps) > max_gap_weeks * week_sec)) {
        next
      }
      # store the mean in the corresponding index of the rolled_vector
      rolled_means[i] <- mean(vals)
    }
  }
  return(rolled_means)
}