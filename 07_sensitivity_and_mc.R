# R/07_sensitivity_and_mc.R

run_pay_sensitivity_analysis <- function(demand_df,
                                         worker_params,
                                         pay_grid,
                                         model_controls,
                                         seed = 500) {
  results <- purrr::map(
    seq_len(nrow(pay_grid)),
    ~run_scenario(
      demand_df = demand_df,
      worker_params = worker_params,
      scenario_row = pay_grid[.x, ],
      model_controls = model_controls,
      seed = seed + .x
    )$hourly_results
  )
  
  bind_rows(results)
}

sample_worker_params_for_mc <- function(worker_params) {
  worker_params %>%
    mutate(
      reservation_wage = reservation_wage + rnorm(n(), mean = 0, sd = 1.5),
      max_trips_per_hour = pmax(1.2, max_trips_per_hour + rnorm(n(), mean = 0, sd = 0.15))
    )
}

run_monte_carlo <- function(demand_df,
                            worker_params,
                            scenarios,
                            model_controls) {
  purrr::map_dfr(
    seq_len(model_controls$monte_carlo_runs),
    function(mc_run) {
      noisy_controls <- model_controls
      noisy_controls$participation_sensitivity <- rnorm(
        1,
        mean = model_controls$participation_sensitivity,
        sd = 0.03
      )
      
      sampled_worker_params <- sample_worker_params_for_mc(worker_params)
      
      sim <- run_all_scenarios(
        demand_df = demand_df,
        worker_params = sampled_worker_params,
        scenarios = scenarios,
        model_controls = noisy_controls,
        seed = 1000 + mc_run
      )
      
      sim$hourly_results %>%
        group_by(scenario) %>%
        summarise(
          mean_fulfillment_rate = mean(fulfillment_rate, na.rm = TRUE),
          mean_avg_worker_earnings = mean(avg_worker_earnings, na.rm = TRUE),
          total_platform_margin = sum(platform_margin, na.rm = TRUE),
          mean_service_quality_score = mean(service_quality_score, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(mc_run = mc_run)
    }
  )
}