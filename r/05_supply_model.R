# R/05_supply_model.R

simulate_worker_supply <- function(demand_orders,
                                   worker_params,
                                   scenario_row,
                                   active_workers_guess,
                                   is_peak = FALSE,
                                   participation_sensitivity = 0.28) {
  worker_pay_per_trip <- scenario_row$worker_pay_per_trip[[1]]
  bonus_per_hour <- scenario_row$bonus_per_hour[[1]]
  surge_multiplier <- scenario_row$surge_multiplier[[1]]
  
  effective_bonus <- ifelse(is_peak, bonus_per_hour, 0)
  
  # Rough market belief:
  # workers log on based on what they think an hour will look like.
  expected_trips_per_worker_raw <- demand_orders / max(active_workers_guess, 1)
  
  worker_params %>%
    mutate(
      expected_trips_per_worker = pmin(expected_trips_per_worker_raw, max_trips_per_hour),
      
      expected_hourly_earnings =
        (expected_trips_per_worker * worker_pay_per_trip * surge_multiplier) +
        effective_bonus,
      
      # No hard cliff here. As pay starts to look worth it, more people log on gradully.
      participation_linear_index =
        participation_intercept +
        participation_sensitivity * (expected_hourly_earnings - reservation_wage),
      
      participation_prob = logistic(participation_linear_index),
      
      active_workers = n_workers * participation_prob,
      
      worker_capacity = active_workers * max_trips_per_hour
    ) %>%
    select(
      worker_type,
      n_workers,
      reservation_wage,
      max_trips_per_hour,
      expected_trips_per_worker,
      expected_hourly_earnings,
      participation_prob,
      active_workers,
      worker_capacity
    )
}

solve_supply_equilibrium <- function(demand_orders,
                                     worker_params,
                                     scenario_row,
                                     is_peak = FALSE,
                                     initial_active_workers_guess = 350,
                                     participation_sensitivity = 0.28,
                                     max_iter = 30,
                                     tolerance = 2) {
  current_guess <- initial_active_workers_guess
  last_supply_df <- NULL
  
  for (iter in seq_len(max_iter)) {
    supply_df <- simulate_worker_supply(
      demand_orders = demand_orders,
      worker_params = worker_params,
      scenario_row = scenario_row,
      active_workers_guess = current_guess,
      is_peak = is_peak,
      participation_sensitivity = participation_sensitivity
    )
    
    new_guess <- sum(supply_df$active_workers, na.rm = TRUE)
    
    if (abs(new_guess - current_guess) <= tolerance) {
      last_supply_df <- supply_df %>%
        mutate(
          equilibrium_iteration = iter,
          equilibrium_converged = TRUE
        )
      break
    }
    
    current_guess <- new_guess
    last_supply_df <- supply_df %>%
      mutate(
        equilibrium_iteration = iter,
        equilibrium_converged = FALSE
      )
  }
  
  if (is.null(last_supply_df)) {
    stop("Supply equilibrium did not produce output.")
  }
  
  last_supply_df
}
