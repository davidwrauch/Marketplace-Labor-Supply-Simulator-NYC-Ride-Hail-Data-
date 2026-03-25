# 🚕 Marketplace Labor Supply Simulator (NYC Ride-Hailing)

## Overview

This project simulates how a ride-hailing platform balances three competing goals:

- fulfilling rider demand  
- maintaining driver earnings  
- preserving platform margin  

Using NYC taxi demand data, I built a simplified simulation of a two-sided marketplace where driver supply responds to expected hourly earnings.

The goal isn’t to perfectly model Uber or Lyft — it’s to explore how different compensation strategies change system behavior.

---

## Why this matters

Ride-hailing platforms constantly make tradeoffs:

- Pay drivers more → better service, lower margins  
- Pay less → higher margins, worse fulfillment  
- Use surge/bonuses → target supply where it’s needed  

Running real-world experiments is expensive and risky, so simulation provides a way to explore these tradeoffs safely.

---

## Approach

### 1. Demand (observed)

- Hourly demand comes from NYC taxi data  
- Captures real temporal patterns (rush hour, weekends, etc.)

---

### 2. Supply (modeled)

Drivers decide whether to work based on expected hourly earnings:

- Earnings depend on:
  - trips per hour  
  - per-trip pay  
  - bonuses  
  - surge multipliers  

Participation is modeled using a smooth logistic response:

- higher earnings → more drivers log on  
- not all drivers respond equally  

---

### 3. Market equilibrium

Supply and demand interact:

- more drivers → fewer trips per driver  
- fewer drivers → higher earnings per driver  

The model iterates until it reaches a stable equilibrium.

---

### 4. Policies tested

- **Baseline**
- **Higher Base Pay**
- **Peak Bonus**
- **Surge Pricing**
- **Balanced Incentive**
- **Subsidized Peak Surge** (platform absorbs cost instead of riders)

---

### 5. Monte Carlo simulation

To test robustness, the model is re-run under different assumptions:

- participation sensitivity  
- demand variation  
- behavioral noise  

This produces distributions (P10–P90), not just single estimates.

---

### 6. Sensitivity analysis (key extension)

Instead of testing a few fixed policies, I ran a grid over:

- worker pay per trip  
- peak bonuses  
- surge multipliers  
- rider surcharges  

This reveals how outcomes change across the full policy space, not just a handful of scenarios.

---

## Key Findings

### 1. Driver supply responds non-linearly to pay

Increasing driver pay improves fulfillment, but only up to a point. Beyond that, additional compensation produces diminishing returns.

This suggests there is an interior “sweet spot” in compensation rather than a simple linear relationship.

---

### 2. Targeted incentives outperform blanket wage increases

Policies that concentrate incentives during peak periods (bonuses or surge) are more efficient than uniformly increasing base pay.

Higher base pay improves earnings but comes with a significant margin cost and relatively modest gains in fulfillment.

---

### 3. Surge pricing is powerful but volatile

Surge pricing generates the highest platform margins, but introduces variability in fulfillment depending on behavioral assumptions.

It performs well in deterministic scenarios but is less stable under uncertainty.

---

### 4. Balanced strategies deliver the most consistent outcomes

A mix of moderate base pay, targeted bonuses, and limited surge tends to produce strong fulfillment while maintaining reasonable margins.

This approach also performs well under Monte Carlo variation.

---

### 5. Rider price increases have limited impact in this model

Introducing rider surcharges has a relatively small effect on fulfillment compared to supply-side incentives.

This suggests improving driver participation is more impactful than suppressing demand under these assumptions.

---

### 6. Results depend on behavioral assumptions

Outcomes depend on how strongly drivers respond to earnings (participation sensitivity).

While exact values change under different assumptions, the overall shape of the tradeoffs remains consistent.

---

## Example Outputs

### Policy frontier (earnings vs margin)
![Policy Frontier](output/figures/policy_frontier.png)

### Fulfillment by scenario
![Fulfillment](output/figures/fulfillment_by_scenario.png)

### Monte Carlo robustness
![Monte Carlo](output/figures/monte_carlo_fulfillment.png)

### Sensitivity analysis (policy space)
![Sensitivity](output/figures/pay_sensitivity_curve.png)

---

## Limitations

This is a simplified model:

- unmet demand is inferred, not observed  
- no spatial modeling (all NYC treated as one market)  
- no long-term driver behavior or learning  
- demand elasticity is stylized  

Results should be interpreted as directional insights, not precise forecasts.

---

## Tech stack

- R (dplyr, ggplot2)
- simulation modeling
- Monte Carlo analysis
- scenario-based policy evaluation

---

## Repo structure
