# scripts/04_run_sensitivity_analysis.R

source("R/01_packages.R")
source("R/02_utils.R")
source("R/04_parameters.R")
source("R/05_supply_model.R")
source("R/06_market_model.R")
source("R/07_sensitivity_and_mc.R")
source("R/08_summarize_and_plot.R")

load_required_packages()

demand_df <- readr::read_csv("data/processed/hourly_demand.csv", show_col_types = FALSE)
worker_params <- create_worker_params()
pay_grid <- create_pay_sensitivity_grid()
model_controls <- create_model_controls()

sensitivity_hourly <- run_pay_sensitivity_analysis(
  demand_df = demand_df,
  worker_params = worker_params,
  pay_grid = pay_grid,
  model_controls = model_controls,
  seed = 500
)

sensitivity_summary <- sensitivity_hourly %>%
  dplyr::group_by(scenario) %>%
  dplyr::summarise(
    worker_pay_per_trip = dplyr::first(stringr::str_extract(scenario, "(?<=pay_)[0-9.]+") |> as.numeric()),
    bonus_per_hour = dplyr::first(stringr::str_extract(scenario, "(?<=bonus_)[0-9.]+") |> as.numeric()),
    surge_multiplier = dplyr::first(stringr::str_extract(scenario, "(?<=surge_)[0-9.]+") |> as.numeric()),
    overall_fulfillment_rate = sum(fulfilled_orders, na.rm = TRUE) / sum(demand_orders, na.rm = TRUE),
    avg_worker_earnings = mean(avg_worker_earnings, na.rm = TRUE),
    total_platform_margin = sum(platform_margin, na.rm = TRUE),
    avg_service_quality = mean(service_quality_score, na.rm = TRUE),
    .groups = "drop"
  )

readr::write_csv(sensitivity_hourly, "output/tables/pay_sensitivity_hourly.csv")
readr::write_csv(sensitivity_summary, "output/tables/pay_sensitivity_summary.csv")

p1 <- plot_pay_sensitivity_curve(sensitivity_summary)
ggplot2::ggsave("output/figures/pay_sensitivity_curve.png", p1, width = 10, height = 6, dpi = 300)

message("Sensitivity analysis complete.")