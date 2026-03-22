# scripts/03_run_main_scenarios.R

# This is the main "run the model" script.
# It loads processed demand, applies all scenarios,
# and saves outputs for analysis and charts.

source("R/01_packages.R")
source("R/02_utils.R")
source("R/04_parameters.R")
source("R/05_supply_model.R")
source("R/06_market_model.R")
source("R/08_summarize_and_plot.R")

load_required_packages()

# Load processed demand (this should already exist from the build script)
demand_df <- readr::read_csv(
  "data/processed/hourly_demand.csv",
  show_col_types = FALSE
)

# Create model inputs
worker_params <- create_worker_params()
scenarios <- create_scenarios()
model_controls <- create_model_controls()

message("Running all scenarios...")

sim_results <- run_all_scenarios(
  demand_df = demand_df,
  worker_params = worker_params,
  scenarios = scenarios,
  model_controls = model_controls,
  seed = 123
)

# Summarize results at scenario level
summary_df <- summarize_scenarios(sim_results$hourly_results)

# Save outputs
readr::write_csv(
  sim_results$hourly_results,
  "output/tables/hourly_results.csv"
)

readr::write_csv(
  sim_results$worker_detail,
  "output/tables/worker_detail.csv"
)

readr::write_csv(
  summary_df,
  "output/tables/scenario_summary.csv"
)

# Make main chart
p <- plot_policy_frontier(summary_df)

ggplot2::ggsave(
  "output/figures/policy_frontier.png",
  p,
  width = 10,
  height = 6,
  dpi = 300
)

message("Main scenario run complete.")
print(summary_df)

summary_df %>%
  dplyr::select(scenario, total_platform_margin)
