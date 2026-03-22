# scripts/02_build_demand_dataset.R

source("R/01_packages.R")
source("R/02_utils.R")
source("R/03_prepare_demand_data.R")

load_required_packages()

hvfhv_files <- list.files(
  "data/raw/hvfhv",
  pattern = "\\.parquet$",
  full.names = TRUE
)

if (length(hvfhv_files) == 0) {
  stop("No parquet files found in data/raw/hvfhv.")
}

message("Found parquet files:")
print(basename(hvfhv_files))

# Do the heavy lifting one file at a time.
# Much easier on memory, and honestly just a better workflow for big trip data.
hourly_by_file <- purrr::map_dfr(
  hvfhv_files,
  ~prepare_single_hvfhv_file(
    path = .x,
    pickup_col = "pickup_datetime",
    tz = "America/New_York"
  )
)

# Once each file is already shrunk down to hourly counts,
# we combine them and sum in case dates/hours span multiple files.
demand_df <- hourly_by_file %>%
  dplyr::group_by(date, hour, day_of_week, is_weekend) %>%
  dplyr::summarise(
    demand_orders = sum(demand_orders, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::arrange(date, hour) %>%
  flag_peak_hours(peak_quantile = 0.80)

readr::write_csv(demand_df, "data/processed/hourly_demand.csv")

message("Processed demand data saved to data/processed/hourly_demand.csv")
message("Rows in hourly demand dataset: ", nrow(demand_df))
print(utils::head(demand_df))