# R/03_prepare_demand_data.R

prepare_hvfhv_demand_data <- function(trips_df,
                                      pickup_col = "pickup_datetime",
                                      tz = "America/New_York") {
  if (!pickup_col %in% names(trips_df)) {
    stop(paste("Column not found:", pickup_col))
  }
  
  trips_df %>%
    add_time_features(datetime_col = pickup_col, tz = tz) %>%
    dplyr::group_by(date, hour, day_of_week, is_weekend) %>%
    dplyr::summarise(
      demand_orders = dplyr::n(),
      .groups = "drop"
    ) %>%
    dplyr::arrange(date, hour)
}

flag_peak_hours <- function(demand_df, peak_quantile = 0.80) {
  peak_threshold <- stats::quantile(
    demand_df$demand_orders,
    probs = peak_quantile,
    na.rm = TRUE
  )
  
  demand_df %>%
    dplyr::mutate(
      is_peak = demand_orders >= peak_threshold
    )
}

add_baseline_hour_profile <- function(demand_df) {
  demand_df %>%
    dplyr::group_by(hour, day_of_week, is_weekend) %>%
    dplyr::summarise(
      avg_hourly_demand = mean(demand_orders, na.rm = TRUE),
      p90_hourly_demand = stats::quantile(demand_orders, probs = 0.90, na.rm = TRUE),
      .groups = "drop"
    )
}

# Read one parquet file, keep only what we need, and collapse it right away.
# This avoids dragging tens of millions of trip rows into RAM for no reason.
prepare_single_hvfhv_file <- function(path,
                                      pickup_col = "pickup_datetime",
                                      tz = "America/New_York") {
  message("Reading and aggregating: ", basename(path))
  
  trips_df <- tryCatch(
    {
      arrow::read_parquet(path, col_select = pickup_col)
    },
    error = function(e) {
      stop(
        paste0(
          "Could not read ", basename(path), ". ",
          "Original error: ", e$message
        )
      )
    }
  )
  
  if (!pickup_col %in% names(trips_df)) {
    stop(
      paste0(
        "Column '", pickup_col, "' not found in ", basename(path), "."
      )
    )
  }
  
  prepare_hvfhv_demand_data(
    trips_df = trips_df,
    pickup_col = pickup_col,
    tz = tz
  ) %>%
    dplyr::mutate(source_file = basename(path))
}
