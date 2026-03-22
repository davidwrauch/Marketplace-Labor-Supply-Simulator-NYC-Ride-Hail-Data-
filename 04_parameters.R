# R/04_parameters.R

create_worker_params <- function() {
  tibble::tribble(
    ~worker_type,    ~n_workers, ~reservation_wage, ~max_trips_per_hour, ~participation_intercept,
    "full_time",          18000,               20,                  2.3,                     0.8,
    "part_time",          14000,               25,                  1.8,                    -0.2,
    "surge_chaser",        8000,               30,                  2.6,                    -0.8
  )
}

create_scenarios <- function() {
  tibble::tribble(
    ~scenario,               ~worker_pay_per_trip, ~customer_price_per_trip, ~bonus_per_hour, ~surge_multiplier, ~demand_price_elasticity,
    "baseline",                              8.0,                     14.0,              0.0,               1.0,                   -0.15,
    "higher_base_pay",                       9.5,                     14.5,              0.0,               1.0,                   -0.15,
    "peak_bonus",                            8.0,                     14.0,              4.0,               1.0,                   -0.15,
    "surge_pricing",                         9.5,                     17.0,              0.0,               1.2,                   -0.25,
    "balanced_incentive",                    8.8,                     14.8,              2.0,               1.05,                  -0.18
  )
}

create_model_controls <- function() {
  list(
    timezone = "America/New_York",
    participation_sensitivity = 0.28,
    equilibrium_max_iter = 12,
    equilibrium_tolerance = 10,
    default_initial_active_workers_guess = 12000,
    service_target_utilization = 0.85,
    monte_carlo_runs = 25
  )
}

create_pay_sensitivity_grid <- function() {
  tidyr::crossing(
    worker_pay_per_trip = seq(7.0, 11.5, by = 0.5),
    bonus_per_hour = c(0, 2, 4),
    surge_multiplier = c(1.0, 1.1, 1.2)
  ) %>%
    mutate(
      scenario = paste0(
        "pay_", worker_pay_per_trip,
        "_bonus_", bonus_per_hour,
        "_surge_", surge_multiplier
      ),
      customer_price_per_trip = worker_pay_per_trip + 6.0,
      "demand_price_elasticity", -0.4
    ) %>%
    relocate(scenario)
}
