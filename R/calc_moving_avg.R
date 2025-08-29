#' Calculate Moving Mean
#'
#' @param dates vector of POSIXct dates
#' @param values vector of sample values 
#' @param half_interval length of half of the desired interval (in weeks)
#' @param min_valid_interval_points integer 1-9 setting the minimum number of valid values wihtin an 
#' #' interval, default value is 1
#' @param max_gap_weeks integer > 0 setting the maximum number of weeks to allow between samples
#'
#' @returns 
#' @export
#'
#' @examples
#' long <- long %>%
#' arrange(date, .by_group = TRUE) %>%
#' mutate(rolling_means = calc_moving_avg(date, 
#'                                        value))
#'   
#' Alternatively to adjust the defaults, e.g. to assert at least 5 valid samples within the desired 
#' interval and 
#' ensure that the intervals only contain samples collected within 3 week intervals
#' 
#' long <- long %>% 
#' arrange(date, .group_by = TRUE) %>% 
#' mutate(rolling_means = calc_moving_avg(date, 
#'                                        value, 
#'                                        half_interval = 4.5, 
#'                                        min_valid_interval_points = 5,
#'                                        max_gap_weeks = 3))  
#'   
#'   
#'   
calc_moving_avg <- function(dates, 
                            values,
                            half_interval = 4.5, 
                            min_valid_interval_points = 1, 
                            max_gap_weeks = 1000) {
  
  # assign a variable with the legnth of 1/2 interval and 1 week in seconds
  half_interval_sec <- half_interval * 7 * 24 * 60 * 60
  week_sec <- 7 * 24 * 60 * 60
  
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