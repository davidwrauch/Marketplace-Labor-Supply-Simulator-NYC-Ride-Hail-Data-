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
    ~scenario,                 ~worker_pay_per_trip, ~customer_price_per_trip, ~bonus_per_hour, ~surge_multiplier, ~peak_rider_surcharge, ~demand_price_elasticity,
    "baseline",                              8.0,                     14.0,              0.0,               1.00,                   0.0,                   -0.15,
    "higher_base_pay",                       9.5,                     14.0,              0.0,               1.00,                   0.0,                   -0.15,
    "peak_bonus",                            8.0,                     14.0,              4.0,               1.00,                   0.0,                   -0.15,
    "subsidized_peak_surge",                 8.0,                     14.0,              0.0,               1.20,                   0.0,                   -0.15,
    "surge_pricing",                         8.0,                     14.0,              0.0,               1.20,                   3.0,                   -0.25,
    "balanced_incentive",                    8.8,                     14.0,              2.0,               1.05,                   0.0,                   -0.18
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
    worker_pay_per_trip = c(8.0, 9.0, 10.0),
    bonus_per_hour = c(0, 2, 4),
    surge_multiplier = c(1.00, 1.10, 1.20),
    peak_rider_surcharge = c(0, 3)
  ) %>%
    dplyr::mutate(
      scenario = paste0(
        "pay_", worker_pay_per_trip,
        "_bonus_", bonus_per_hour,
        "_surge_", surge_multiplier,
        "_rider_", peak_rider_surcharge
      ),
      customer_price_per_trip = 14.0,
      demand_price_elasticity = dplyr::if_else(
        peak_rider_surcharge == 0,
        -0.15,
        -0.25
      )
    ) %>%
    dplyr::select(
      scenario,
      worker_pay_per_trip,
      bonus_per_hour,
      surge_multiplier,
      peak_rider_surcharge,
      customer_price_per_trip,
      demand_price_elasticity
    )
}
