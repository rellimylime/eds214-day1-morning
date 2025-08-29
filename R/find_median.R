#' Find median of repeat values
#'
#' @param x vector of values from the same day, site, and compound
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