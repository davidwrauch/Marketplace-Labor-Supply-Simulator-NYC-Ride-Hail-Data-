# R/01_packages.R

required_packages <- c(
  "arrow",
  "dplyr",
  "ggplot2",
  "ggrepel",
  "lubridate",
  "purrr",
  "readr",
  "scales",
  "stringr",
  "tibble",
  "tidyr"
)

load_required_packages <- function() {
  missing_packages <- required_packages[!required_packages %in% installed.packages()[, "Package"]]
  
  if (length(missing_packages) > 0) {
    stop(
      paste(
        "Install these packages first:",
        paste(missing_packages, collapse = ", ")
      )
    )
  }
  
  invisible(lapply(required_packages, library, character.only = TRUE))
}
