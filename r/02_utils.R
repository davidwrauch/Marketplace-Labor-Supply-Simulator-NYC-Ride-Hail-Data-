# R/02_utils.R

safe_divide <- function(x, y) {
  ifelse(y == 0 | is.na(y), NA_real_, x / y)
}

clamp <- function(x, lower, upper) {
  pmax(lower, pmin(x, upper))
}

logistic <- function(x) {
  1 / (1 + exp(-x))
}

add_time_features <- function(df, datetime_col, tz = "America/New_York") {
  df %>%
    mutate(
      event_datetime_utc = as.POSIXct(.data[[datetime_col]], tz = "UTC"),
      event_datetime_local = with_tz(event_datetime_utc, tzone = tz),
      date = as.Date(event_datetime_local),
      hour = lubridate::hour(event_datetime_local),
      day_of_week = lubridate::wday(event_datetime_local, label = TRUE, abbr = FALSE),
      is_weekend = day_of_week %in% c("Saturday", "Sunday")
    )
}
