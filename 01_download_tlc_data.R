# scripts/01_download_tlc_data.R

source("R/01_packages.R")
install.packages(c("arrow", "ggplot2", "scales"))
load_required_packages()

# Replace these with the actual monthly HVFHV parquet links you choose from the TLC page
# plus the taxi zone lookup table link.
files_to_download <- tibble::tribble(
  ~url, ~dest,
  "https://d37ci6vzurychx.cloudfront.net/trip-data/fhvhv_tripdata_2025-02.parquet", "data/raw/hvfhv/fhvhv_tripdata_2025-02.parquet",
  "https://d37ci6vzurychx.cloudfront.net/trip-data/fhvhv_tripdata_2025-03.parquet", "data/raw/hvfhv/fhvhv_tripdata_2025-03.parquet",
  "https://d37ci6vzurychx.cloudfront.net/trip-data/fhvhv_tripdata_2025-04.parquet", "data/raw/hvfhv/fhvhv_tripdata_2025-04.parquet",
  
    "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv", "data/raw/reference/taxi_zone_lookup.csv"
)

purrr::walk2(
  files_to_download$url,
  files_to_download$dest,
  ~download.file(.x, .y, mode = "wb")
)

message("Downloads complete.")