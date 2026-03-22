# scripts/05_run_monte_carlo.R

source("R/01_packages.R")
source("R/02_utils.R")
source("R/04_parameters.R")
source("R/05_supply_model.R")
source("R/06_market_model.R")
source("R/07_sensitivity_and_mc.R")
source("R/08_summarize_and_plot.R")

load_required_packages()

demand_df <- readr::read_csv("data/processed/hourly_demand.csv", show_col_types = FALSE)

set.seed(123)

# For Monte Carlo, we do not need every single hour from all 3 months.
# A few hundred sampled hours is enough to test whether the scenario ranking
# is robust when we perturb the behavioral parameters.
demand_df <- demand_df %>%
  dplyr::sample_n(400)

worker_params <- create_worker_params()
scenarios <- create_scenarios()
model_controls <- create_model_controls()

mc_results <- run_monte_carlo(
  demand_df = demand_df,
  worker_params = worker_params,
  scenarios = scenarios,
  model_controls = model_controls
)

mc_summary <- summarize_monte_carlo(mc_results)

readr::write_csv(mc_results, "output/tables/monte_carlo_results.csv")
readr::write_csv(mc_summary, "output/tables/monte_carlo_summary.csv")

message("Monte Carlo run complete.")
print(mc_summary)
