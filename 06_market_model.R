# R/06_market_model.R

apply_demand_response <- function(base_demand_orders, scenario_row) {
  base_price <- 14.0
  scenario_price <- scenario_row$customer_price_per_trip[[1]] * scenario_row$surge_multiplier[[1]]
  elasticity <- scenario_row$demand_price_elasticity[[1]]
  
  pct_price_change <- safe_divide(scenario_price - base_price, base_price)
  
  adjusted_demand <- round(
    base_demand_orders * (1 + elasticity * pct_price_change)
  )
  
  pmax(adjusted_demand, 0)
}

match_market_hour <- function(demand_row,
                              supply_df,
                              scenario_row) {
  base_demand_orders <- demand_row$demand_orders[[1]]
  date <- demand_row$date[[1]]
  hour <- demand_row$hour[[1]]
  is_peak <- demand_row$is_peak[[1]]
  scenario_name <- scenario_row$scenario[[1]]
  
  worker_pay_per_trip <- scenario_row$worker_pay_per_trip[[1]]
  customer_price_per_trip <- scenario_row$customer_price_per_trip[[1]]
  bonus_per_hour <- scenario_row$bonus_per_hour[[1]]
  surge_multiplier <- scenario_row$surge_multiplier[[1]]
  
  effective_bonus <- ifelse(is_peak, bonus_per_hour, 0)
  
  demand_orders <- apply_demand_response(
    base_demand_orders = base_demand_orders,
    scenario_row = scenario_row
  )
  
  total_active_workers <- sum(supply_df$active_workers, na.rm = TRUE)
  total_capacity <- sum(supply_df$worker_capacity, na.rm = TRUE)
  
  fulfilled_orders <- min(demand_orders, total_capacity)
  unfilled_orders <- max(demand_orders - total_capacity, 0)
  
  fulfillment_rate <- safe_divide(fulfilled_orders, demand_orders)
  utilization <- safe_divide(fulfilled_orders, total_capacity)
  
  wait_pressure_index <- safe_divide(demand_orders, pmax(total_capacity, 1))
  service_quality_score <- clamp(1 - pmax(wait_pressure_index - 1, 0), 0, 1)
  
  supply_df <- supply_df %>%
    mutate(
      capacity_share = ifelse(total_capacity > 0, worker_capacity / total_capacity, 0),
      completed_trips = fulfilled_orders * capacity_share,
      avg_trips_per_active_worker = ifelse(active_workers > 0, completed_trips / active_workers, 0),
      avg_hourly_earnings =
        (avg_trips_per_active_worker * worker_pay_per_trip * surge_multiplier) +
        effective_bonus
    )
  
  avg_worker_earnings <- ifelse(
    total_active_workers > 0,
    weighted.mean(
      x = supply_df$avg_hourly_earnings,
      w = supply_df$active_workers,
      na.rm = TRUE
    ),
    NA_real_
  )
  
  total_bonus_cost <- total_active_workers * effective_bonus
  platform_revenue <- fulfilled_orders * customer_price_per_trip * surge_multiplier
  worker_cost <- (fulfilled_orders * worker_pay_per_trip * surge_multiplier) + total_bonus_cost
  platform_margin <- platform_revenue - worker_cost
  
  hourly_results <- tibble(
    scenario = scenario_name,
    date = date,
    hour = hour,
    is_peak = is_peak,
    base_demand_orders = base_demand_orders,
    demand_orders = demand_orders,
    active_workers = total_active_workers,
    total_capacity = total_capacity,
    fulfilled_orders = fulfilled_orders,
    unfilled_orders = unfilled_orders,
    fulfillment_rate = fulfillment_rate,
    utilization = utilization,
    wait_pressure_index = wait_pressure_index,
    service_quality_score = service_quality_score,
    avg_worker_earnings = avg_worker_earnings,
    platform_revenue = platform_revenue,
    worker_cost = worker_cost,
    platform_margin = platform_margin
  )
  
  list(
    hourly_results = hourly_results,
    worker_detail = supply_df %>%
      mutate(
        scenario = scenario_name,
        date = date,
        hour = hour,
        is_peak = is_peak
      )
  )
}

run_scenario <- function(demand_df,
                         worker_params,
                         scenario_row,
                         model_controls,
                         seed = 123) {
  set.seed(seed)
  
  hourly_results_list <- vector("list", nrow(demand_df))
  worker_detail_list <- vector("list", nrow(demand_df))
  
  for (i in seq_len(nrow(demand_df))) {
    demand_row <- demand_df[i, ]
    
    supply_df <- solve_supply_equilibrium(
      demand_orders = demand_row$demand_orders[[1]],
      worker_params = worker_params,
      scenario_row = scenario_row,
      is_peak = demand_row$is_peak[[1]],
      initial_active_workers_guess = model_controls$default_initial_active_workers_guess,
      participation_sensitivity = model_controls$participation_sensitivity,
      max_iter = model_controls$equilibrium_max_iter,
      tolerance = model_controls$equilibrium_tolerance
    )
    
    matched_hour <- match_market_hour(
      demand_row = demand_row,
      supply_df = supply_df,
      scenario_row = scenario_row
    )
    
    hourly_results_list[[i]] <- matched_hour$hourly_results
    worker_detail_list[[i]] <- matched_hour$worker_detail
  }
  
  list(
    hourly_results = bind_rows(hourly_results_list),
    worker_detail = bind_rows(worker_detail_list)
  )
}

run_all_scenarios <- function(demand_df,
                              worker_params,
                              scenarios,
                              model_controls,
                              seed = 123) {
  results <- purrr::map(
    seq_len(nrow(scenarios)),
    ~run_scenario(
      demand_df = demand_df,
      worker_params = worker_params,
      scenario_row = scenarios[.x, ],
      model_controls = model_controls,
      seed = seed + .x
    )
  )
  
  list(
    hourly_results = bind_rows(purrr::map(results, "hourly_results")),
    worker_detail = bind_rows(purrr::map(results, "worker_detail"))
  )
}