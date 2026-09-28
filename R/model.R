################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## Consumption: Euler, Permanent Income and Ricardian Equivalence: Model      ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Sourced automatically by app.R. Can be sourced alone from a lecture
##   .qmd so slide figures come from the same model:
##     source("R/model.R")
##
## Inputs:
##   None. Every function is a pure function of a parameter list "par"
##   built by the app.
##
## Outputs:
##   C_01_* functions: the consumer's problem, the plan, the MPC, the
##   random walk, Ricardian equivalence, readouts. C_02_* functions:
##   precautionary saving under CARA utility.
##
## The model (notation of the Part 2 exam questions; Romer 2019, ch. 8):
##   A consumer lives T periods and maximises
##       sum_{t=0}^{T-1} beta^t u(C_t),     u(C) = (C^(1-rho) - 1)/(1 - rho)
##   subject to
##       sum_t C_t / (1+r)^t = A_0 + sum_t Y_t / (1+r)^t  =  W.
##   Euler:  u'(C_t) = beta (1+r) u'(C_{t+1}), so for CRRA consumption grows
##           by g = (beta (1+r))^(1/rho) each period.
##   Plan:   C_0 = W / S,  S = sum_{t=0}^{T-1} (g/(1+r))^t; the MPC out of a
##           windfall is 1/S. Two periods with r = 0 and beta = 1 give 1/2
##           (part (c) of question 3 on the sample paper); as T grows with
##           beta(1+r) = 1 it tends to r/(1+r), the permanent income limit.
##   Income: y_t = ybar + phi (y_{t-1} - ybar) + e_t. With quadratic utility
##           and beta(1+r) = 1 consumption is a random walk and moves by the
##           annuity value of the news, r e_t / (1 + r - phi).
##   Fiscal: a tax cut today repaid with interest at period k leaves W
##           unchanged for a consumer alive at k: Ricardian equivalence.
##   CARA:   U(C) = -(1/alpha) exp(-alpha C), alpha > 0, in section C_02.
##           Uncertainty then lowers consumption today by alpha sigma^2/(2r)
##           and makes it drift up by alpha sigma^2/2 a period: precautionary
##           saving, question 2 of the 2023 paper.
##
## Parameter list (par) elements:
##   rate, beta, rho, income, assets, horizon, windfall, persist, sd_income,
##   n_periods, cut, repay, hand_share, prudence, stage

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: C_01 and C_02 hold the model; app.R holds sections B, D, E, F and G.
#
#   C: Model
#     C_01  The consumer's problem
#       C_01_01  Utility
#       C_01_02  Consumption growth
#       C_01_03  The annuity factor
#       C_01_04  Marginal propensity to consume
#       C_01_05  Lifetime resources
#       C_01_06  The consumption path
#       C_01_07  The MPC against the horizon
#       C_01_08  Temporary against permanent
#       C_01_09  An income path and its consumption
#       C_01_10  How much smoothing
#       C_01_11  Ricardian equivalence
#       C_01_12  Why equivalence fails
#       C_01_13  Readouts
#       C_01_14  Problems with the calibration
#       C_01_15  Inverse utility
#       C_01_16  An indifference curve
#       C_01_17  The two-period choice
#     C_02  Precautionary saving
#       C_02_01  CARA utility
#       C_02_02  The precautionary drift
#       C_02_03  Lifetime resources, infinite horizon
#       C_02_04  Consumption today under CARA
#       C_02_05  Two paths, one sequence of shocks
#       C_02_06  Consumption today against uncertainty
#       C_02_07  Readouts

################################################################################
## C: Model ####################################################################
################################################################################
# Note: Pure functions. Nothing here touches Shiny.

#### C_01: The Consumer's Problem ##############################################
# Note: The Euler equation, the budget constraint and what they imply for
#   the response of consumption to income.

###### C_01_01: Utility ########################################################
# Note: CRRA, with log as the limiting case at rho = 1.

C_01_01_util_fn <- function(c, rho) {
  c <- pmax(c, 1e-12)
  if (abs(rho - 1) < 1e-9) log(c) else (c^(1 - rho) - 1) / (1 - rho)
}

###### C_01_02: Consumption Growth #############################################
# Note: g = (beta (1+r))^(1/rho) from the Euler equation. Above one the path
#   rises, because the interest rate beats impatience.

C_01_02_growth_fn <- function(par) {
  (par$beta * (1 + par$rate))^(1 / par$rho)
}

###### C_01_03: The Annuity Factor #############################################
# Note: The present value of one unit of consumption in every period of life,
#   growing at g. Dividing lifetime resources by it gives consumption today.

C_01_03_factor_fn <- function(par, horizon = NULL) {
  t_end <- if (is.null(horizon)) par$horizon else horizon
  ratio <- C_01_02_growth_fn(par) / (1 + par$rate)
  if (abs(ratio - 1) < 1e-12) t_end else (1 - ratio^t_end) / (1 - ratio)
}

###### C_01_04: Marginal Propensity to Consume #################################
# Note: Out of a one-off windfall: one over the annuity factor, since the
#   windfall is spread over the rest of life.

C_01_04_mpc_fn <- function(par, horizon = NULL) {
  1 / C_01_03_factor_fn(par, horizon)
}

###### C_01_05: Lifetime Resources #############################################
# Note: Assets plus the present value of income. Income is flat at ybar
#   unless the app is showing a path.

C_01_05_wealth_fn <- function(par, windfall = 0) {
  t_seq <- seq_len(par$horizon) - 1
  par$assets + windfall + sum(par$income / (1 + par$rate)^t_seq)
}

###### C_01_06: The Consumption Path ###########################################
# Note: Consumption in every period of life and the income it smooths.
#   Saving is the gap between them.

C_01_06_plan_fn <- function(par, windfall = 0) {
  g     <- C_01_02_growth_fn(par)
  t_seq <- seq_len(par$horizon) - 1
  c0    <- C_01_05_wealth_fn(par, windfall) * C_01_04_mpc_fn(par)
  cons  <- c0 * g^t_seq
  inc   <- rep(par$income, par$horizon)
  inc[1] <- inc[1] + windfall

  data.frame(
    period      = t_seq + 1,
    income      = inc,
    consumption = cons,
    saving      = inc - cons
  )
}

###### C_01_07: The MPC Against the Horizon ####################################
# Note: How much of a windfall is spent today, for every length of life. The
#   two-period case is one half; the long-horizon limit is r/(1+r).

C_01_07_horizon_fn <- function(par, max_t = 60) {
  t_grid <- seq_len(max_t)
  data.frame(
    horizon = t_grid,
    mpc     = vapply(t_grid, function(t) C_01_04_mpc_fn(par, t), 0)
  )
}

###### C_01_08: Temporary Against Permanent ####################################
# Note: A one-period rise in income is spread over the whole of life; a rise
#   that lasts is consumed as it arrives (Romer 2019, ch. 8).

C_01_08_response_fn <- function(par, size = 1) {
  t_seq <- seq_len(par$horizon) - 1
  pv_temp <- size
  pv_perm <- size * sum(1 / (1 + par$rate)^t_seq)
  mpc     <- C_01_04_mpc_fn(par)

  data.frame(
    kind     = c("A One-Off Windfall", "A Permanent Rise in Income"),
    pv       = c(pv_temp, pv_perm),
    response = c(mpc * pv_temp, mpc * pv_perm),
    stringsAsFactors = FALSE
  )
}

###### C_01_09: An Income Path and Its Consumption #############################
# Note: The random walk, simulated. Income is AR(1) with parameter phi and
#   each shock raises consumption by its annuity value, r e / (1 + r - phi).

C_01_09_path_fn <- function(par) {
  n     <- par$n_periods
  shock <- stats::rnorm(n, 0, par$sd_income)

  y <- numeric(n)
  y[1] <- par$income + shock[1]
  for (t in seq_len(n)[-1]) {
    y[t] <- par$income + par$persist * (y[t - 1] - par$income) + shock[t]
  }

  # The annuity value of the news in each shock
  weight <- par$rate / (1 + par$rate - par$persist)
  cons   <- numeric(n)
  cons[1] <- par$income + weight * shock[1]
  for (t in seq_len(n)[-1]) {
    cons[t] <- cons[t - 1] + weight * shock[t]
  }

  data.frame(period = seq_len(n), income = y, consumption = cons,
             saving = y - cons)
}

###### C_01_10: How Much Smoothing #############################################
# Note: How much of a one-unit income shock passes into consumption: near
#   zero for transitory shocks, one for permanent ones.

C_01_10_smooth_fn <- function(par) {
  weight <- par$rate / (1 + par$rate - par$persist)
  list(weight = weight, ratio = weight)
}

###### C_01_11: Ricardian Equivalence ##########################################
# Note: Taxes fall by "cut" today and rise by the same amount plus interest
#   at period "repay". For a consumer alive at "repay" the present value of
#   the two changes is zero, so consumption does not move (Romer 2019,
#   ch. 13). Two things break it: dying first, and income going to
#   hand-to-mouth consumers. hand_share is that income share in the
#   Campbell and Mankiw (1989) sense, not a headcount: constrained
#   households earn less than average, so the headcount is higher.

C_01_11_ricardian_fn <- function(par) {
  alive   <- par$repay <= par$horizon
  pv_gain <- if (alive) 0 else par$cut
  mpc     <- C_01_04_mpc_fn(par)

  smoother  <- mpc * pv_gain
  hand      <- par$cut
  aggregate <- par$hand_share * hand + (1 - par$hand_share) * smoother

  list(
    alive      = alive,
    pv_gain    = pv_gain,
    smoother   = smoother,
    hand       = hand,
    aggregate  = aggregate,
    ricardian  = abs(aggregate) < 1e-12,
    multiplier = if (par$cut != 0) aggregate / par$cut else 0
  )
}

###### C_01_12: Why Equivalence Fails ##########################################
# Note: The response to the same tax cut under each standard objection,
#   for the figure. Each row switches on one thing.

C_01_12_breaks_fn <- function(par) {
  base <- modifyList(par, list(hand_share = 0, repay = min(par$repay,
                                                           par$horizon)))
  rows <- list(
    list(label = "Ricardian consumers", par = base),
    list(label = "Some income is hand to mouth",
         par = modifyList(base, list(hand_share = par$hand_share))),
    list(label = "The bill arrives after they die",
         par = modifyList(base, list(repay = par$horizon + 1))),
    list(label = "Both at once",
         par = modifyList(base, list(hand_share = par$hand_share,
                                     repay = par$horizon + 1)))
  )
  out <- lapply(rows, function(r) {
    data.frame(label = r$label,
               response = C_01_11_ricardian_fn(r$par)$aggregate,
               stringsAsFactors = FALSE)
  })
  df <- do.call(rbind, out)
  df$share <- if (par$cut != 0) df$response / par$cut else 0
  df
}

###### C_01_13: Readouts #######################################################
# Note: The numbers shown in the tiles above the figures.

C_01_13_diagnostics_fn <- function(par) {
  plan <- C_01_06_plan_fn(par)
  ric  <- C_01_11_ricardian_fn(par)
  sm   <- C_01_10_smooth_fn(par)

  list(
    growth     = C_01_02_growth_fn(par),
    mpc        = C_01_04_mpc_fn(par),
    mpc_long   = C_01_04_mpc_fn(par, 200),
    wealth     = C_01_05_wealth_fn(par),
    c_now      = plan$consumption[1],
    c_next     = if (par$horizon >= 2) plan$consumption[2] else NA_real_,
    save_now   = plan$saving[1],
    flat       = abs(C_01_02_growth_fn(par) - 1) < 1e-6,
    smooth     = sm$ratio,
    ric_effect = ric$aggregate,
    ric_share  = ric$multiplier,
    ricardian  = ric$ricardian,
    problems   = C_01_14_problems_fn(par)
  )
}

###### C_01_14: Problems with the Calibration ##################################
# Note: Warnings shown above the figures when the numbers stop making
#   sense.

C_01_14_problems_fn <- function(par) {
  out <- character(0)

  if (par$rate <= -0.99) {
    out <- c(out, "The interest rate is below minus one, which has no meaning.")
  }
  if (C_01_02_growth_fn(par) / (1 + par$rate) >= 1 && par$horizon > 150) {
    out <- c(out, paste(
      "With this much patience and a long life, planned consumption grows",
      "faster than it can be discounted, so lifetime resources will not",
      "cover the plan. Lower the discount factor or the horizon."
    ))
  }
  if (C_01_05_wealth_fn(par) <= 0) {
    out <- c(out, paste(
      "Lifetime resources are zero or negative, so there is nothing to",
      "consume. Raise income or assets."
    ))
  }
  if (!is.null(par$stage) && par$stage >= 6 && par$rate <= 0) {
    out <- c(out, paste(
      "Stage 6 solves an infinitely lived consumer, so lifetime resources",
      "only add up to a finite number when the interest rate is above zero.",
      "Raise r above 0."
    ))
  }
  out
}

###### C_01_15: Inverse Utility ################################################
# Note: The consumption that delivers a given utility. CRRA with rho > 1 is
#   bounded above, so an unreachable level returns NA for the caller to drop.

C_01_15_invutil_fn <- function(u, rho) {
  if (abs(rho - 1) < 1e-9) return(exp(u))
  base <- (1 - rho) * u + 1
  ifelse(base > 0, pmax(base, 1e-12)^(1 / (1 - rho)), NA_real_)
}

###### C_01_16: An Indifference Curve ##########################################
# Note: The bundles ranked equally with (c1_ref, c2_ref) under
#   u(C_1) + beta u(C_2), solved for C_2. Points past the asymptote are dropped.

C_01_16_indiff_fn <- function(par, c1_ref, c2_ref, c1_grid) {
  level <- C_01_01_util_fn(c1_ref, par$rho) +
    par$beta * C_01_01_util_fn(c2_ref, par$rho)
  left  <- (level - C_01_01_util_fn(c1_grid, par$rho)) / par$beta
  c2    <- C_01_15_invutil_fn(left, par$rho)
  keep  <- is.finite(c2) & c2 > 0
  data.frame(c1 = c1_grid[keep], c2 = c2[keep], level = level)
}

###### C_01_17: The Two-Period Choice ##########################################
# Note: Endowment, budget line of slope -(1+r) and optimum for the diagram.
#   The horizon is forced to two; the optimum is the plan of C_01_06.

C_01_17_two_period_fn <- function(par) {
  two  <- modifyList(par, list(horizon = 2))
  plan <- C_01_06_plan_fn(two, windfall = two$windfall)

  e1 <- two$assets + two$income + two$windfall
  e2 <- two$income

  list(
    e1     = e1,
    e2     = e2,
    c1     = plan$consumption[1],
    c2     = plan$consumption[2],
    wealth = C_01_05_wealth_fn(two, two$windfall),
    slope  = -(1 + two$rate),
    saving = e1 - plan$consumption[1]
  )
}

#### C_02: Precautionary Saving ################################################
# Note: Question 2 of the 2023 paper: an infinitely lived consumer with CARA
#   utility and beta(1+r) = 1, so only the shape of marginal utility changes.

###### C_02_01: CARA Utility ###################################################
# Note: U(C) = -(1/alpha) exp(-alpha C), alpha > 0. Absolute risk aversion
#   and absolute prudence both equal alpha, so the buffer is linear in it.

C_02_01_cara_fn <- function(c, alpha) {
  alpha <- max(alpha, 1e-9)
  -(1 / alpha) * exp(-alpha * c)
}

###### C_02_02: The Precautionary Drift ########################################
# Note: With beta(1+r) = 1 the CARA Euler equation is
#       exp(-alpha C_t) = E_t[exp(-alpha C_{t+1})].
#   For normal C_{t+1} with variance sigma^2, E[exp(X)] = exp(mu + s^2/2)
#   gives, after logs,
#       E_t C_{t+1} = C_t + alpha sigma^2 / 2,
#   so consumption is expected to rise and is not a random walk
#   (question 2 of the 2023 paper; Romer 2019, ch. 8). sigma is the
#   standard deviation of the news in consumption: stage 6 takes income
#   shocks to be permanent, so it equals the income shock. With transitory
#   shocks the annuity value r sigma / (1 + r - phi) takes its place.

C_02_02_drift_fn <- function(par) {
  par$prudence * par$sd_income^2 / 2
}

###### C_02_03: Lifetime Resources, Infinite Horizon ###########################
# Note: Assets plus the present value of a flat income stream that never
#   ends: A_0 + Y (1+r)/r. Only finite for r > 0, which C_01_14 warns about.

C_02_03_wealth_fn <- function(par) {
  r <- max(par$rate, 1e-6)
  par$assets + par$income * (1 + r) / r
}

###### C_02_04: Consumption Today Under CARA ###################################
# Note: Iterating the drift, E_t C_{t+k} = C_t + k alpha sigma^2 / 2. In the
#   expected lifetime budget constraint
#       sum_{k>=0} E_t C_{t+k} / (1+r)^k = W_t
#   the first sum is (1+r)/r and the second is the 2023 paper's hint,
#   sum_{k>=1} k/(1+r)^k = (1+r)/r^2, so
#       C_t = [r/(1+r)] W_t - alpha sigma^2 / (2 r).
#   The first term is the permanent income answer, which is all quadratic
#   utility gives; the second is the precautionary saving, larger the more
#   prudent the consumer, the more uncertain the income and the lower the
#   interest rate (Romer 2019, ch. 8).

C_02_04_level_fn <- function(par) {
  r       <- max(par$rate, 1e-6)
  wealth  <- C_02_03_wealth_fn(par)
  certain <- r / (1 + r) * wealth
  buffer  <- par$prudence * par$sd_income^2 / (2 * r)

  list(certain = certain, buffer = buffer, cara = certain - buffer)
}

###### C_02_05: Two Paths, One Sequence of Shocks ##############################
# Note: The same draws under both utilities. Quadratic gives a random walk
#   at the certainty-equivalent level; CARA starts the buffer below and drifts.

C_02_05_paths_fn <- function(par) {
  n     <- par$n_periods
  drift <- C_02_02_drift_fn(par)
  lvl   <- C_02_04_level_fn(par)

  shock    <- stats::rnorm(n, 0, par$sd_income)
  shock[1] <- 0
  innov    <- cumsum(shock)
  step     <- seq_len(n) - 1

  data.frame(
    period    = seq_len(n),
    income    = par$income + innov,
    quadratic = lvl$certain + innov,
    cara      = lvl$cara + drift * step + innov
  )
}

###### C_02_06: Consumption Today Against Uncertainty ##########################
# Note: Consumption today against sigma. Flat under quadratic utility; a
#   falling parabola under CARA, because the buffer is alpha sigma^2 / (2r).

C_02_06_buffer_fn <- function(par, max_sd = NULL) {
  top  <- if (is.null(max_sd)) max(par$sd_income * 1.6, 20) else max_sd
  grid <- seq(0, top, length.out = 80)

  rows <- lapply(grid, function(s) {
    lvl <- C_02_04_level_fn(modifyList(par, list(sd_income = s)))
    data.frame(sd = s, quadratic = lvl$certain, cara = lvl$cara)
  })
  do.call(rbind, rows)
}

###### C_02_07: Readouts #######################################################
# Note: The stage 6 tiles, and the numbers the captions quote.

C_02_07_diagnostics_fn <- function(par) {
  lvl <- C_02_04_level_fn(par)

  list(
    drift   = C_02_02_drift_fn(par),
    certain = lvl$certain,
    cara    = lvl$cara,
    buffer  = lvl$buffer,
    share   = if (abs(lvl$certain) > 1e-9) lvl$buffer / lvl$certain else
      NA_real_
  )
}
