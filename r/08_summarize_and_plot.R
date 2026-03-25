# R/08_summarize_and_plot.R
library('dplyr')

graphics.off()

summarize_scenarios <- function(hourly_results_df) {
  hourly_results_df %>%
    dplyr::group_by(scenario) %>%
    dplyr::summarise(
      total_demand = sum(demand_orders, na.rm = TRUE),
      total_fulfilled = sum(fulfilled_orders, na.rm = TRUE),
      total_unfilled = sum(unfilled_orders, na.rm = TRUE),
      overall_fulfillment_rate = safe_divide(
        sum(fulfilled_orders, na.rm = TRUE),
        sum(demand_orders, na.rm = TRUE)
      ),
      avg_worker_earnings = mean(avg_worker_earnings, na.rm = TRUE),
      avg_service_quality = mean(service_quality_score, na.rm = TRUE),
      total_platform_margin = sum(platform_margin, na.rm = TRUE),
      avg_utilization = mean(utilization, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(total_platform_margin))
}

summarize_monte_carlo <- function(mc_results_df) {
  mc_results_df %>%
    dplyr::group_by(scenario) %>%
    dplyr::summarise(
      fulfillment_median = median(mean_fulfillment_rate, na.rm = TRUE),
      fulfillment_p10 = quantile(mean_fulfillment_rate, 0.10, na.rm = TRUE),
      fulfillment_p90 = quantile(mean_fulfillment_rate, 0.90, na.rm = TRUE),
      earnings_median = median(mean_avg_worker_earnings, na.rm = TRUE),
      margin_median = median(total_platform_margin, na.rm = TRUE),
      service_median = median(mean_service_quality_score, na.rm = TRUE),
      .groups = "drop"
    )
}

# Clean scenario names once so charts do not look like variable names
make_pretty_scenario_names <- function(df) {
  df %>%
    dplyr::mutate(
      scenario = dplyr::recode(
        scenario,
        "baseline" = "Baseline",
        "higher_base_pay" = "Higher Base Pay",
        "peak_bonus" = "Peak Bonus",
        "surge_pricing" = "Surge Pricing",
        "balanced_incentive" = "Balanced Incentive"
      )
    )
}

plot_policy_frontier <- function(summary_df) {
  summary_df <- make_pretty_scenario_names(summary_df)
  
  ggplot2::ggplot(
    summary_df,
    ggplot2::aes(
      x = avg_worker_earnings,
      y = total_platform_margin,
      label = scenario,
      color = scenario
    )
  ) +
    ggplot2::geom_point(size = 4.5) +
    ggrepel::geom_text_repel(
      size = 3.8,
      box.padding = 0.55,
      point.padding = 0.35,
      segment.color = "grey55",
      segment.size = 0.4,
      min.segment.length = 0,
      seed = 123,
      show.legend = FALSE
    ) +
    ggplot2::scale_y_continuous(labels = scales::dollar) +
    ggplot2::scale_color_brewer(palette = "Set2") +
    ggplot2::labs(
      title = "Policy Frontier: Worker Earnings vs Platform Margin",
      subtitle = "Tradeoffs across compensation strategies in a simulated NYC marketplace",
      x = "Average Worker Earnings ($/hour)",
      y = "Total Platform Margin ($)"
    ) +
    ggplot2::guides(color = "none") +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey30"),
      panel.grid.minor = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(10, 50, 10, 10)
    )
}

plot_fulfillment_by_scenario <- function(summary_df) {
  summary_df <- make_pretty_scenario_names(summary_df) %>%
    dplyr::mutate(
      scenario = reorder(scenario, overall_fulfillment_rate)
    )
  
  ggplot2::ggplot(
    summary_df,
    ggplot2::aes(
      x = scenario,
      y = overall_fulfillment_rate,
      fill = scenario == "Balanced Incentive"
    )
  ) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(accuracy = 1)
    ) +
    ggplot2::scale_fill_manual(
      values = c("TRUE" = "#2C7FB8", "FALSE" = "grey70")
    ) +
    ggplot2::labs(
      title = "Fulfillment Rate by Scenario",
      subtitle = "Balanced incentives produce the highest overall fulfillment",
      x = "Scenario",
      y = "Fulfillment Rate"
    ) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey30"),
      panel.grid.minor = ggplot2::element_blank()
    )
}

plot_monte_carlo_fulfillment <- function(mc_summary) {
  mc_summary <- make_pretty_scenario_names(mc_summary) %>%
    dplyr::mutate(
      scenario = reorder(scenario, fulfillment_median)
    )
  
  ggplot2::ggplot(
    mc_summary,
    ggplot2::aes(
      x = fulfillment_median,
      y = scenario
    )
  ) +
    ggplot2::geom_errorbarh(
      ggplot2::aes(xmin = fulfillment_p10, xmax = fulfillment_p90),
      height = 0.25,
      linewidth = 0.5
    ) +
    ggplot2::geom_point(size = 3.2) +
    ggplot2::scale_x_continuous(
      labels = scales::percent_format(accuracy = 1)
    ) +
    ggplot2::labs(
      title = "Fulfillment Robustness Across Scenarios (Monte Carlo)",
      subtitle = "Points show medians; horizontal bars show P10–P90 ranges",
      x = "Fulfillment Rate (Median with P10–P90 Range)",
      y = "Scenario"
    ) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey30"),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )
}


plot_pay_sensitivity_curve <- function(sensitivity_summary_df) {
  ggplot2::ggplot(
    sensitivity_summary_df,
    ggplot2::aes(
      x = worker_pay_per_trip,
      y = overall_fulfillment_rate,
      group = interaction(bonus_per_hour, peak_rider_surcharge),
      linetype = factor(peak_rider_surcharge)
    )
  ) +
    ggplot2::geom_line() +
    ggplot2::facet_grid(
      rows = ggplot2::vars(bonus_per_hour),
      cols = ggplot2::vars(surge_multiplier)
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(
      title = "Fulfillment Response to Worker Pay",
      subtitle = "Rows = peak bonus, columns = surge multiplier, line type = rider surcharge",
      x = "Worker Pay per Trip",
      y = "Fulfillment Rate",
      linetype = "Peak Rider Surcharge"
    ) +
    ggplot2::theme_minimal(base_size = 14)
}


# Make sure the folder exists before trying to save anything
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# Policy frontier
p1 <- plot_policy_frontier(summary_df)

ggplot2::ggsave(
  filename = "output/figures/policy_frontier.png",
  plot = p1,
  width = 10,
  height = 6,
  dpi = 300
)

# Fulfillment by scenario
p2 <- plot_fulfillment_by_scenario(summary_df)
print(p2)
ggplot2::ggsave(
  filename = "output/figures/fulfillment_by_scenario.png",
  plot = p2,
  width = 10,
  height = 6,
  dpi = 300
)

# Monte Carlo robustness
p3 <- plot_monte_carlo_fulfillment(mc_summary)
print(p3)
ggplot2::ggsave(
  filename = "output/figures/monte_carlo_fulfillment.png",
  plot = p3,
  width = 10,
  height = 6,
  dpi = 300
)