################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## Consumption: Interactive Shiny App                                         ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Open app.R in RStudio and click Run App, or from this folder:
##     shiny::runApp()
##   Needs R 4.1 or later with shiny, bslib and ggplot2 installed. A hosted
##   copy runs in the browser at https://sam-deegan.com/toy-models/consumption/
##   The stage selector builds the model up one layer at a time:
##     1  two periods, the Euler equation, and a transfer today
##     2  the windfall and the horizon: why the MPC falls as life lengthens
##     3  permanent income: temporary against permanent changes
##     4  uncertainty: the random walk, and how much smoothing there is
##     5  Ricardian equivalence, and the two things that break it
##     6  precautionary saving: CARA utility, and why sigma^2 matters
##   All text (scenarios, prompts, equations, notation) lives in B_03.
##
## Inputs:
##   R/model.R (the model) and R/toolkit.R (shared layout and helpers),
##   both sourced automatically by Shiny.
##
## Version:
##   B_03_13_version_chr; history in CHANGELOG.md; git tag vX.Y.Z.
##
## Outputs:
##   None. The app is interactive only.
##
## Packages:
##   shiny, bslib, ggplot2.
##
## References:
##   Romer, D. (2019). Advanced Macroeconomics, 5th ed. Ch. 8 (consumption)
##     and ch. 13 (Ricardian equivalence).
##   Whelan, K. (2023). Lecture Notes on Macroeconomics. Figs 11.2 and 11.3
##     for the two-period diagram.
##   Hall, R. (1978), JPE, for the random-walk test.
##   Campbell, J. and Mankiw, N. G. (1989), NBER Macroeconomics Annual, for
##     the hand-to-mouth income share.
##   ECON42550 Part 2 sample paper, question 3, and the 2023 paper,
##     question 2.

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: C (the model) is in R/model.R and T (the toolkit) in R/toolkit.R.
#
#   B: Setup
#     B_01  Packages
#     B_02  Settings
#     B_03  Soft-coded objects
#     B_04  Paths
#   C: Model (R/model.R)
#   T: Toolkit (R/toolkit.R)
#   D: Plots
#     D_01  The plan and the horizon
#     D_02  Permanent income and the random walk
#     D_03  Ricardian equivalence
#     D_04  Precautionary saving
#   E: User Interface
#   F: Server
#   G: Run

################################################################################
## B: Setup ####################################################################
################################################################################
# Note: Packages, options and every soft-coded value.

#### B_01: Packages ############################################################
# Note: Shiny for the app, bslib for the look, ggplot2 for the figures.

###### B_01_01: Load Packages ##################################################
# Note: All three run under shinylive.

library(shiny)
library(bslib)
library(ggplot2)

###### B_01_02: Load the Model #################################################
# Note: Shiny sources R/ itself; this covers sourcing app.R by hand.

if (!exists("C_01_06_plan_fn")) {
  source(file.path("R", "model.R"))
}

###### B_01_03: Load the Toolkit ###############################################
# Note: The shared palette, plot theme, CSS and builders.

if (!exists("T_01_01_palette_vec")) {
  source(file.path("R", "toolkit.R"))
}

#### B_02: Settings ############################################################
# Note: Standard options.

###### B_02_01: Global Options #################################################
# Note: No scientific notation; three significant digits in the console.

options(scipen = 999, digits = 3)

###### B_02_02: Seed ###########################################################
# Note: The simulated income paths reset the seed before each draw; this
#   covers anything else.

set.seed(42)

#### B_03: Soft-Coded Objects ##################################################
# Note: Calibration, stages, scenarios, controls, equations, text, version.

###### B_03_01: Input Defaults #################################################
# Note: Starting value of every control; Reset returns here. Two periods to
#   start (the sample paper's setting); alpha = rho/C = 0.02 matches rho = 2.

B_03_01_defaults_lst <- list(
  rate       = 0.04,  # real interest rate
  beta       = 0.96,  # discount factor
  rho        = 2,     # risk aversion / curvature of utility
  income     = 100,   # income each period
  assets     = 0,     # assets at the start of life
  horizon    = 2,     # periods of life remaining
  windfall   = 0,     # a one-off transfer today
  persist    = 0,     # persistence of income shocks
  sd_income  = 8,     # size of income shocks
  n_periods  = 40,    # periods drawn in the simulated path
  cut        = 10,    # the debt-financed tax cut
  repay      = 10,    # the period in which it is repaid
  hand_share = 0.3,   # share of income going to hand-to-mouth consumers
  prudence   = 0.02   # absolute risk aversion / prudence under CARA
)

###### B_03_02: Stages #########################################################
# Note: One layer of the model each, all within lecture 2.2.

B_03_02_stages_vec <- c(
  "Stage 1: Two Periods"                = "1",
  "Stage 2: The Windfall and the Horizon" = "2",
  "Stage 3: Permanent Income"           = "3",
  "Stage 4: Uncertainty and the Random Walk" = "4",
  "Stage 5: Ricardian Equivalence"      = "5",
  "Stage 6: Precautionary Saving"       = "6"
)

###### B_03_03: Scenarios ######################################################
# Note: Worked examples. Each sets a stage and overrides some defaults;
#   unlisted controls return to B_03_01. Every stage opens on its first one.

B_03_03_scenarios_lst <- list(
  paper = list(
    label  = "The Sample Paper: r = 0, β = 1",
    stage  = "1",
    values = list(rate = 0, beta = 1, horizon = 2, windfall = 10),
    story  = paste(
      "A one-off transfer (&tau; = 10) arrives in the first of two periods,",
      "with the real interest rate (r) set to 0 and the discount factor",
      "(&beta;) to 1, so &beta;(1+r) = 1 and the Euler equation asks for the",
      "same consumption at both dates. Lifetime resources (W) rise by the",
      "whole transfer and the flat path lifts at both dates together: the",
      "plan puts the period of life on the horizontal axis and the amount on",
      "the vertical, so the income bar jumps by 10 in period 1 alone while",
      "consumption (C<sub>1</sub> and C<sub>2</sub>) each step up by 5.",
      "How far C<sub>1</sub> moves is one over the annuity factor (S), which",
      "is exactly 2 when the path is flat over two periods, so half the",
      "transfer is spent now and half is saved to pay for period 2."
    ),
    prompt = paste(
      "Check the arithmetic: consumption today rises by exactly half the",
      "transfer. The paper's conclusion follows — under this theory,",
      "temporary government transfers have little power to stimulate."
    )
  ),
  patient = list(
    label  = "A Patient Consumer",
    stage  = "1",
    values = list(beta = 1, rate = 0.08),
    story  = paste(
      "The consumer is made perfectly patient (&beta; = 1) while the real",
      "interest rate is raised to r = 0.08, so &beta;(1+r) now exceeds one",
      "and the Euler equation asks for a rising path: the growth factor",
      "g = [&beta;(1+r)]<sup>1/&rho;</sup> moves above one. On the plan the",
      "horizontal axis is the period of life and the vertical axis the",
      "amount, so consumption (C<sub>t</sub>) starts below income (Y) and",
      "ends above it, and the gap in the first period is saving. How steep",
      "the tilt is depends on the curvature of utility (&rho;): a larger",
      "&rho; makes the consumer less willing to substitute across dates, so",
      "the same interest rate buys a flatter path."
    ),
    prompt = paste(
      "Raise risk aversion ρ and watch the tilt flatten. Why does wanting a",
      "smooth path make the consumer less willing to exploit a high interest",
      "rate?"
    )
  ),
  long_life = list(
    label  = "A Long Life",
    stage  = "2",
    values = list(horizon = 40, windfall = 10),
    story  = paste(
      "The same one-off transfer (&tau; = 10), but the consumer now has",
      "T = 40 periods of life left rather than two, so the annuity factor",
      "(S) that divides lifetime resources (W) is far larger and the",
      "marginal propensity to consume, 1/S, collapses. The second figure",
      "puts periods of life remaining on the horizontal axis and the MPC on",
      "the vertical: the curve falls steeply at first, then flattens onto",
      "the dashed limit r/(1+r), and the marked point slides down it as T",
      "rises. Where it settles is set by the real interest rate (r): a",
      "higher r discounts distant consumption more heavily, holds S down and",
      "leaves the limit further above zero."
    ),
    prompt = paste(
      "Drag the horizon from 2 up to 40 and watch the MPC fall along the",
      "curve. At what horizon does it stop moving much, and why?"
    )
  ),
  permanent = list(
    label  = "Temporary Against Permanent",
    stage  = "3",
    values = list(horizon = 40),
    story  = paste(
      "The news changes, not the consumer: one extra euro of income (Y)",
      "arriving once, against one extra euro arriving in every one of the",
      "T = 40 periods that remain. Both are valued the same way, by",
      "multiplying their present value by the marginal propensity to consume",
      "1/S, but the permanent stream has a present value of roughly the",
      "annuity factor (S) itself, so it survives that division almost",
      "intact. The response figure holds the two kinds of news on the",
      "horizontal axis and the rise in consumption today (C<sub>t</sub>) on",
      "the vertical: the one-off bar is a sliver and the permanent bar",
      "stands about twenty-five times higher. What sets the ratio is the",
      "horizon (T) and the real interest rate (r) — shorten life or raise r",
      "and the two bars converge."
    ),
    prompt = paste(
      "The two bars differ by a factor of about twenty-five here. Which one",
      "does a temporary VAT cut look like, and which one a permanent rise",
      "in the tax-free allowance?"
    )
  ),
  transitory = list(
    label  = "Transitory Income Shocks",
    stage  = "4",
    values = list(horizon = 40, persist = 0, sd_income = 10),
    story  = paste(
      "Income (Y) becomes random and every shock dies at once: persistence",
      "is set to &phi; = 0, so the news &epsilon;<sub>t</sub> raises",
      "E<sub>t</sub> of income in this period only. Consumption moves by the",
      "annuity value of that news,",
      "&Delta;C<sub>t</sub> = r&epsilon;<sub>t</sub>",
      "/(1 + r &minus; &phi;), which at &phi; = 0 is r/(1+r) and so is close",
      "to nothing. On the path figure the horizontal axis is the period and",
      "the vertical axis the amount: the income line jumps about in a band",
      "set by the size of the shocks (&sigma; = 10) while the consumption",
      "line only wanders slowly beneath it. How far the two separate is",
      "decided by &phi; and by the real interest rate (r), and the wandering",
      "never stops because no period's news is ever undone: that is the",
      "random walk."
    ),
    prompt = paste(
      "Look at how flat consumption is against income. Now ask the empirical",
      "question: in the data, does consumption really respond this little to",
      "income that everybody knows is temporary?"
    )
  ),
  permanent_shocks = list(
    label  = "Permanent Income Shocks",
    stage  = "4",
    values = list(horizon = 40, persist = 1, sd_income = 10),
    story  = paste(
      "Persistence is raised to &phi; = 1, so income (Y) is itself a random",
      "walk and each innovation &epsilon;<sub>t</sub> is permanent: it raises",
      "E<sub>t</sub> of income at every future date by the same amount. The",
      "pass-through r/(1 + r &minus; &phi;) is then exactly one, so there is",
      "nothing left for the consumer to smooth. On the path figure, with the",
      "period on the horizontal axis and the amount on the vertical, the",
      "consumption line (C<sub>t</sub>) stops being flatter than income and",
      "lies on top of it, both moving by the full &epsilon;<sub>t</sub> at",
      "every date. Only &phi; decides how much of a shock passes through;",
      "the size of the shocks (&sigma; = 10) sets how far the pair wander",
      "together, not how far apart they lie."
    ),
    prompt = paste(
      "Slide persistence back down from 1 and watch the two lines separate.",
      "The gap between them is the whole content of consumption smoothing."
    )
  ),
  ricardo = list(
    label  = "A Debt-Financed Tax Cut",
    stage  = "5",
    values = list(horizon = 40, cut = 10, repay = 10, hand_share = 0),
    story  = paste(
      "The government cuts taxes by &Delta;T<sub>0</sub> = 10 today and",
      "borrows, then raises taxes by that amount plus interest at k = 10,",
      "well inside the T = 40 periods this consumer has left. The two",
      "changes have the same present value, so lifetime resources (W) do not",
      "move and neither does the consumption path: the whole cut goes into",
      "saving to meet the future bill. The tax-cut figure lists the cases",
      "down the vertical axis and measures the rise in consumption today",
      "(C<sub>t</sub>) along the horizontal, so the Ricardian bar has no",
      "length at all while the bars beneath it, which switch on an",
      "objection, do. What holds the result is the two assumptions set here:",
      "the bill arrives before death (k &le; T) and no income goes to",
      "hand-to-mouth consumers (&lambda; = 0)."
    ),
    prompt = paste(
      "Now push the repayment date past the end of life, or raise the",
      "hand-to-mouth income share. Either one breaks the result. Which do",
      "you think",
      "matters more in the data?"
    )
  ),
  broken = list(
    label  = "Why It Fails in Practice",
    stage  = "5",
    values = list(horizon = 40, cut = 10, repay = 60, hand_share = 0.4),
    story  = paste(
      "Both assumptions are switched off at once: a share &lambda; = 0.4 of",
      "aggregate income goes to consumers who spend whatever arrives, and",
      "the bill is repaid at k = 60, after the T = 40 periods of life are",
      "over. Nobody now faces the offsetting tax rise in present value, so",
      "the same cut of &Delta;T<sub>0</sub> = 10 raises lifetime resources",
      "(W) for the forward-looking part of the economy and is simply spent",
      "by the rest. On the figure the four cases run down the vertical axis",
      "and the rise in consumption today (C<sub>t</sub>) along the",
      "horizontal: the Ricardian bar stays at zero, each objection on its",
      "own gives a bar, and the two together give the longest. How much is",
      "spent is &lambda; plus (1 &minus; &lambda;) times the marginal",
      "propensity to consume 1/S, so at a long horizon (T) the",
      "hand-to-mouth share does nearly all of the work."
    ),
    prompt = paste(
      "Compare the four bars. Then go back to the Keynesian multiplier app:",
      "the hand-to-mouth income share here is the ω there, and the two",
      "models are telling the same story from opposite ends."
    )
  ),
  calm = list(
    label  = "Little Uncertainty",
    stage  = "6",
    values = list(horizon = 40, n_periods = 40, rate = 0.04,
                  sd_income = 3, prudence = 0.02),
    story  = paste(
      "Utility becomes CARA, so marginal utility is convex and the consumer",
      "is prudent (&alpha; = 0.02) as well as averse to risk, in an",
      "environment where the news is small: &sigma; = 3. Consumption today",
      "(C<sub>t</sub>) is pushed below the certainty-equivalent level by the",
      "buffer &alpha;&sigma;<sup>2</sup>/(2r) and is then expected to climb,",
      "E<sub>t</sub>C<sub>t+1</sub> = C<sub>t</sub> +",
      "&alpha;&sigma;<sup>2</sup>/2.",
      "On the paths figure the horizontal axis is the period and the",
      "vertical the amount, and the navy CARA line sits barely under the",
      "dashed quadratic one and tilts up almost imperceptibly; on the second",
      "figure, &sigma; horizontal and consumption today vertical, the two",
      "lines have hardly parted this close to the origin. Both the buffer",
      "and the drift go with &sigma;<sup>2</sup>, and the buffer also with",
      "one over the real interest rate (r = 0.04), so small risks move very",
      "little and certainty equivalence is a good local approximation."
    ),
    prompt = paste(
      "Note how close the two consumption paths are. Small risks are almost",
      "irrelevant, which is the sense in which certainty equivalence is a",
      "good local approximation."
    )
  ),
  risky = list(
    label  = "A Risky Environment",
    stage  = "6",
    values = list(horizon = 40, n_periods = 40, rate = 0.04,
                  sd_income = 12, prudence = 0.02),
    story  = paste(
      "The same prudent consumer (&alpha; = 0.02) meets four times the",
      "income risk, &sigma; = 12. The buffer &alpha;&sigma;<sup>2</sup>/(2r)",
      "is quadratic in &sigma;, so sixteen times as much consumption",
      "(C<sub>t</sub>) is held back today, and the expected rise",
      "&alpha;&sigma;<sup>2</sup>/2 a period grows in the same proportion.",
      "On the paths figure &mdash; period horizontally, amount vertically",
      "&mdash; the navy CARA line now starts well below the dashed quadratic",
      "one and climbs towards it; on the buffer figure, &sigma; horizontal",
      "and consumption today vertical, the marked point has slid far down",
      "the falling parabola while the quadratic line stays flat. Quadratic",
      "utility has u''' = 0 and so no precautionary motive at all &mdash;",
      "the consumer has not stopped disliking risk, it is only that",
      "&sigma;<sup>2</sup> cannot enter the consumption function &mdash; so",
      "the whole gap between the lines is prudence, and setting &alpha; to 0",
      "closes it."
    ),
    prompt = paste(
      "Read the second figure: the green line is flat, so under quadratic",
      "utility this extra risk would have changed consumption by exactly",
      "nothing. The whole gap between the two lines is prudence."
    )
  )
)

###### B_03_04: Controls #######################################################
# Note: One entry per numeric control: label (HTML), slider range and step,
#   and the stage from which it appears.

B_03_04_controls_lst <- list(
  rate       = list(label = "Real Interest Rate (r)",
                    min = 0, max = 0.15, step = 0.01, from = 1),
  beta       = list(label = "Discount Factor (β)",
                    min = 0.8, max = 1, step = 0.01, from = 1),
  rho        = list(label = "Curvature of Utility (ρ)",
                    min = 0.5, max = 5, step = 0.25, from = 1),
  income     = list(label = "Income Each Period (Y)",
                    min = 20, max = 200, step = 10, from = 1),
  assets     = list(label = "Assets at the Start (A<sub>0</sub>)",
                    min = -100, max = 200, step = 10, from = 1),
  horizon    = list(label = "Periods of Life Remaining (T)",
                    min = 2, max = 60, step = 1, from = 1),
  windfall   = list(label = "A Transfer Today (τ)",
                    min = -40, max = 40, step = 5, from = 1),
  persist    = list(label = "Persistence of Income Shocks (φ)",
                    min = 0, max = 1, step = 0.05, from = 4),
  sd_income  = list(label = "Size of Income Shocks (σ)",
                    min = 1, max = 25, step = 1, from = 4),
  n_periods  = list(label = "Periods Drawn",
                    min = 20, max = 120, step = 10, from = 4),
  cut        = list(label = "The Tax Cut Today",
                    min = 0, max = 40, step = 5, from = 5),
  repay      = list(label = "Repaid in Period",
                    min = 1, max = 80, step = 1, from = 5),
  hand_share = list(label = paste("Share of Income Going to Hand-to-Mouth",
                                  "Consumers (λ)"),
                    min = 0, max = 1, step = 0.05, from = 5),
  prudence   = list(label = "Absolute Risk Aversion and Prudence (α)",
                    min = 0, max = 0.05, step = 0.01, from = 6)
)

###### B_03_05: Parameter Explanations #########################################
# Note: Tooltip text: what each control is and what raising it does.

B_03_05_help_lst <- list(
  rate = paste(
    "The return on saving. It does two things at once: it makes future",
    "consumption cheaper, which tilts the path up, and it makes the",
    "consumer richer if they are a saver. The exam question asks which",
    "effect dominates."
  ),
  beta = paste(
    "How much the consumer values next period against this one. β = 1 is",
    "perfect patience. When β(1+r) = 1 the two forces cancel and the",
    "consumption path is flat."
  ),
  rho = paste(
    "The curvature of utility: how badly the consumer wants a smooth path.",
    "Higher ρ means a flatter path whatever the interest rate does, because",
    "the consumer is less willing to substitute across time."
  ),
  income = "Income in each period of life, before any windfall.",
  assets = paste(
    "What the consumer starts with. Negative means they start in debt. It",
    "enters lifetime resources exactly like a windfall."
  ),
  horizon = paste(
    "How many periods of life are left. The single most important number",
    "for the MPC: a windfall is spread over whatever life remains, so a",
    "longer horizon means less is spent today."
  ),
  windfall = paste(
    "A one-off transfer arriving today, the τ in part (c) of the sample",
    "question. Raising it shifts the whole consumption path up a little,",
    "not today's consumption by the whole amount."
  ),
  persist = paste(
    "How much of an income shock is still there next period. At 0 the shock",
    "is gone at once and consumption barely moves; at 1 income is a random",
    "walk and consumption moves with it one for one."
  ),
  sd_income = paste(
    "How large the income shocks are. Under quadratic utility this changes",
    "how bumpy the picture looks and nothing else: the level of consumption",
    "does not depend on it at all. At stage 6 it becomes the single most",
    "important number in the model."
  ),
  n_periods = "How many periods of the simulated path are drawn.",
  cut = paste(
    "How much the government hands back today, borrowing to pay for it."
  ),
  repay = paste(
    "The period in which the debt is repaid out of higher taxes. If it is",
    "after the end of life, the consumer never pays and the cut is a",
    "windfall after all."
  ),
  hand_share = paste(
    "The share of aggregate INCOME accruing to consumers who simply spend",
    "whatever arrives: credit constrained, or not looking ahead. Campbell",
    "and Mankiw's λ ≈ 0.5 is an income share, not a headcount. Because",
    "constrained households earn less than average, the share of PEOPLE",
    "behaving this way is higher than λ. This is the same parameter as the",
    "income share of high-MPC households in the Keynesian multiplier app."
  ),
  prudence = paste(
    "The coefficient of absolute risk aversion under CARA utility, which is",
    "also the coefficient of absolute prudence, which is why the buffer is",
    "linear in it. It has units of one over consumption, so with consumption",
    "near 100 the value comparable to ρ = 2 is α ≈ ρ/C = 0.02. At α = 0",
    "there is no prudence and CARA collapses back onto the certainty",
    "equivalence of stages 4 and 5. Push α and σ high together and the",
    "buffer can exceed income, so consumption goes negative: CARA is",
    "defined for every level of consumption, which is its convenience and",
    "its main defect as a description of anybody real."
  )
)

###### B_03_06: Prompts ########################################################
# Note: One "what to try" prompt per stage, shown above the figures.

B_03_06_prompts_lst <- list(
  "1" = paste(
    "Set the interest rate to 0 and the discount factor to 1 to get the",
    "sample paper's case exactly. A transfer of 10 raises consumption today",
    "by 5. Now raise the interest rate: which way does the path tilt, and",
    "why?"
  ),
  "2" = paste(
    "Drag the horizon from 2 up to 40 and watch the MPC slide down the",
    "curve towards r/(1+r). The consumer is not becoming meaner; they have",
    "more years to spread the same windfall over."
  ),
  "3" = paste(
    "Compare the two bars. The same euro is worth twenty-five times more to",
    "today's consumption if it arrives every year than if it arrives once.",
    "Nothing about the consumer changed: only the news did."
  ),
  "4" = paste(
    "Slide persistence from 0 to 1 and watch consumption go from a flat",
    "line to a copy of income. At φ = 0 the level of consumption still",
    "wanders: it is a random walk, which is the testable prediction."
  ),
  "5" = paste(
    "Start with no income going to hand-to-mouth consumers and the debt",
    "repaid within life: the",
    "tax cut does nothing at all. Then break it one way at a time. The",
    "theory is not wrong, it is just resting on two assumptions that the",
    "data do not support."
  ),
  "6" = paste(
    "Leave everything alone and slide the size of the income shocks σ up and",
    "down. Under the quadratic utility of stage 4 the green line would not",
    "move at all — that is certainty equivalence. Under CARA the navy path",
    "drops away from it and tilts upwards. Now set α to 0 and watch the two",
    "lines snap back together: prudence, not risk, is what does the work.",
    "Stage 6 takes income shocks to be permanent, so σ is the standard",
    "deviation of the news in consumption itself. The consumer here lives",
    "for ever, so r has to be above zero for lifetime resources to add up to",
    "a finite number; if you arrived from a scenario with r = 0 it has been",
    "put back to its default for you."
  )
)

###### B_03_07: The Model, Stage by Stage ######################################
# Note: The equations panel. "versions" maps the stage a form first applies
#   from to its LaTeX; "notes" holds the In Words text for each.

B_03_07_equations_lst <- list(

  # --- The model's equations --------------------------------------------------
  list(
    group = "model", label = "The Problem",
    versions = list(
      "1" = "\\max\\; u(C_1) + \\beta u(C_2)",
      "2" = "\\max\\; \\sum_{t=0}^{T-1} \\beta^t u(C_t)"
    ),
    notes = list(
      "1" = "Two periods, and a taste for smoothing across them.",
      "2" = "The same problem over however many periods of life remain."
    )
  ),
  list(
    group = "model", label = "Utility",
    versions = list(
      "1" = "u(C) = \\frac{C^{1-\\rho} - 1}{1 - \\rho}",
      "6" = "U(C) = -\\tfrac{1}{\\alpha}\\,e^{-\\alpha C},\\quad \\alpha > 0"
    ),
    notes = list(
      "1" = paste("Concave, so the consumer would rather have the same",
                  "amount every period than a lot now and little later."),
      "6" = paste("Constant absolute risk aversion. Marginal utility",
                  "e^(-αC) is not just falling but convex, and it is that",
                  "convexity, not the concavity of u, that makes",
                  "uncertainty change the level of consumption. Absolute",
                  "risk aversion is α at every level of consumption, so a",
                  "richer consumer holds the same buffer in euro.")
    )
  ),
  list(
    group = "model", label = "Budget Constraint (BC)",
    versions = list(
      "1" = "C_1 + \\frac{C_2}{1+r} = Y_1 + \\frac{Y_2}{1+r}",
      "2" = paste0("\\sum_t \\frac{C_t}{(1+r)^t} = A_0 + \\sum_t",
                   " \\frac{Y_t}{(1+r)^t} \\equiv W")
    ),
    notes = list(
      "1" = paste("What matters is the present value of the whole income",
                  "stream, not its timing."),
      "2" = paste("Lifetime resources W: assets plus human wealth. The",
                  "consumer can borrow and lend freely at r.")
    )
  ),
  list(
    group = "model", label = "Income",
    versions = list(
      "4" = paste0("y_t = \\bar{y} + \\phi(y_{t-1} - \\bar{y}) +",
                   " \\varepsilon_t")
    ),
    notes = list(
      "4" = paste("Income is now random. φ says how much of a shock",
                  "survives into next period: 0 is purely transitory, 1 is",
                  "a random walk.")
    )
  ),
  list(
    group = "model", label = "The Government",
    versions = list("5" = paste0("\\text{cut } \\Delta T_0 \\text{ today},",
                                 "\\ \\text{repaid at } k \\text{ with",
                                 " interest}")),
    notes = list(
      "5" = paste("The government's own budget must balance in present",
                  "value, which is the whole reason the consumer is not",
                  "better off.")
    )
  ),

  # --- Assumptions ------------------------------------------------------------
  list(
    group = "assumption", label = "Perfect Capital Markets",
    versions = list("1" = "\\text{borrow and lend freely at } r"),
    notes = list(
      "1" = paste("No credit constraints. Drop this and a consumer who",
                  "wants to borrow cannot smooth, so they spend what",
                  "arrives.")
    )
  ),
  list(
    group = "assumption", label = "Known Income",
    versions = list(
      "1" = "Y_t \\text{ known}",
      "4" = "E_t Y_{t+s} \\text{ with rational expectations}",
      "6" = "\\varepsilon_t \\sim N(0, \\sigma^2)"
    ),
    notes = list(
      "1" = "Certainty, so the plan can be made once and followed.",
      "4" = paste("Income is uncertain but not systematically",
                  "mis-forecast. Consumption then responds only to news."),
      "6" = paste("Normality is what lets the Euler equation be solved in",
                  "closed form: E[e^X] = e^(μ + σ²/2) for a normal X. Take",
                  "it away and the drift is still positive, but it no",
                  "longer has a one-line expression.")
    )
  ),
  list(
    group = "assumption", label = "The Shape of Marginal Utility",
    versions = list(
      "4" = "u'(C) \\text{ linear},\\ u''' = 0",
      "6" = "u'''(C) > 0 \\quad (\\text{prudence})"
    ),
    notes = list(
      "4" = paste("Quadratic utility, needed for the exact random walk. It",
                  "has no third derivative, so uncertainty cannot change",
                  "the level of consumption: certainty equivalence."),
      "6" = paste("CARA has u''' > 0, so E[u'(C)] > u'(E C) by Jensen's",
                  "inequality: expected marginal utility next period is",
                  "raised by risk, and the consumer answers by saving. This",
                  "single change is the whole of stage 6.")
    )
  ),
  list(
    group = "assumption", label = "Long Enough Life",
    versions = list("5" = "k \\le T"),
    notes = list(
      "5" = paste("The consumer is still alive when the bill arrives. If",
                  "not, the tax cut is a transfer from the unborn.")
    )
  ),

  # --- Solved forms -----------------------------------------------------------
  list(
    group = "solved", label = "Euler Equation",
    versions = list(
      "1" = "u'(C_t) = \\beta(1+r)\\,u'(C_{t+1})",
      "6" = "e^{-\\alpha C_t} = E_t\\!\\left[e^{-\\alpha C_{t+1}}\\right]"
    ),
    notes = list(
      "1" = paste("The consumer is indifferent at the margin between a euro",
                  "today and its proceeds tomorrow. Everything else follows",
                  "from this and the budget constraint."),
      "6" = paste("The same condition with CARA marginal utility and",
                  "β(1+r) = 1. The expectation is on the right hand side,",
                  "so the convexity of e^(-αC) is what breaks certainty",
                  "equivalence.")
    )
  ),
  list(
    group = "solved", label = "Indifference Curve (IC)",
    versions = list("1" = "u(C_1) + \\beta u(C_2) = \\bar{U}"),
    notes = list(
      "1" = paste("Every bundle the consumer ranks equally. Its slope is",
                  "−u'(C_1)/βu'(C_2), the marginal rate of",
                  "substitution, and",
                  "setting that equal to the slope of the budget line,",
                  "−(1+r), is the Euler equation drawn as a tangency.")
    )
  ),
  list(
    group = "solved", label = "Consumption Growth",
    versions = list("1" = paste0("\\frac{C_{t+1}}{C_t} = \\big[\\beta(1+r)",
                                 "\\big]^{1/\\rho}")),
    notes = list(
      "1" = paste("For CRRA utility. Flat when β(1+r) = 1; rising when the",
                  "interest rate beats impatience.")
    )
  ),
  list(
    group = "solved", label = "Consumption Today",
    versions = list(
      "1" = "C_1 = \\frac{W}{1 + g/(1+r)}",
      "2" = paste0("C_0 = \\frac{W}{S},\\quad S = \\sum_{t=0}^{T-1}",
                   " \\left(\\frac{g}{1+r}\\right)^t"),
      "6" = paste0("C_t = \\frac{r}{1+r}W_t - \\frac{\\alpha\\sigma^2}",
                   "{2r}")
    ),
    notes = list(
      "1" = paste("With r = 0 and β = 1 this is (Y1 + Y2)/2: the sample",
                  "paper's answer."),
      "2" = paste("Lifetime resources divided by an annuity factor. The",
                  "longer the life, the larger S and the smaller C today."),
      "6" = paste("Substitute E_t C_{t+k} = C_t + kασ²/2 into the lifetime",
                  "budget constraint and use Σ(1+r)^(-k) = (1+r)/r and the",
                  "hint Σ k/(1+r)^k = (1+r)/r². The first term is the",
                  "permanent income answer, which is all quadratic utility",
                  "ever gives. The second is the precautionary saving: it",
                  "rises with prudence and with σ², and it is LARGER the",
                  "lower the interest rate, because a buffer has to be",
                  "carried further when it earns less.")
    )
  ),
  list(
    group = "solved", label = "Marginal Propensity to Consume",
    versions = list(
      "1" = "\\frac{\\partial C_1}{\\partial \\tau} = \\tfrac{1}{2}",
      "2" = "\\frac{\\partial C_0}{\\partial \\tau} = \\frac{1}{S}",
      "3" = "\\frac{\\partial C_0}{\\partial \\tau} \\to \\frac{r}{1+r}"
    ),
    notes = list(
      "1" = paste("Two periods, no interest, no discounting. Half the",
                  "windfall is saved."),
      "2" = "One over the annuity factor, whatever the horizon.",
      "3" = paste("As life lengthens the MPC out of a one-off windfall",
                  "collapses to the interest rate's annuity value. This is",
                  "the permanent income hypothesis.")
    )
  ),
  list(
    group = "solved", label = "Permanent Income",
    versions = list("3" = paste0("C_t = \\frac{r}{1+r}\\Big[A_t + \\sum_s",
                                 " \\frac{E_t Y_{t+s}}{(1+r)^s}\\Big]")),
    notes = list(
      "3" = paste("Consumption is the annuity value of lifetime resources.",
                  "A permanent rise in income raises it one for one; a",
                  "one-off rise barely moves it.")
    )
  ),
  list(
    group = "solved", label = "The Random Walk",
    versions = list("4" = "C_{t+1} = C_t + \\varepsilon^C_{t+1}"),
    notes = list(
      "4" = paste("With quadratic utility and β(1+r) = 1, consumption",
                  "changes only with news. Anything already known should",
                  "not forecast the change: that is the testable",
                  "prediction, and Hall's test of it.")
    )
  ),
  list(
    group = "solved", label = "How Much Passes Through",
    versions = list("4" = paste0("\\Delta C_t = \\frac{r}{1 + r - \\phi}",
                                 "\\,\\varepsilon_t")),
    notes = list(
      "4" = paste("The annuity value of the news. At φ = 0 this is",
                  "r/(1+r), almost nothing; at φ = 1 it is one.")
    )
  ),
  list(
    group = "solved", label = "The Precautionary Drift",
    versions = list("6" = paste0("E_t C_{t+1} = C_t + \\frac{\\alpha",
                                 "\\sigma^2}{2}")),
    notes = list(
      "6" = paste("Take logs of the CARA Euler equation after applying",
                  "E[e^X] = e^(μ + σ²/2) to X = -αC_{t+1}. Consumption is",
                  "expected to RISE, so it is no longer a random walk: its",
                  "change is forecastable from α and σ² alone. The consumer",
                  "holds consumption down today and lets it climb as the",
                  "risk is survived. α enters linearly because it is the",
                  "coefficient of absolute prudence -u'''/u'' as well as of",
                  "absolute risk aversion. At σ = 0 the drift is zero and",
                  "the flat path of stage 1 returns.")
    )
  ),
  list(
    group = "solved", label = "Ricardian Equivalence",
    versions = list("5" = paste0("\\Delta W = \\Delta T_0 - ",
                                 "\\frac{\\Delta T_0 (1+r)^k}{(1+r)^k}",
                                 " = 0")),
    notes = list(
      "5" = paste("The cut and its repayment have the same present value,",
                  "so lifetime resources do not change and neither does",
                  "consumption. The consumer saves the whole cut to pay the",
                  "future bill.")
    )
  ),

  # --- Descriptors ------------------------------------------------------------
  list(
    group = "descriptor", label = "Two Effects of the Interest Rate",
    versions = list("1" = paste0("\\text{substitution} \\uparrow,\\quad",
                                 " \\text{income} \\updownarrow")),
    notes = list(
      "1" = paste("A higher rate makes future consumption cheaper, which",
                  "lowers consumption today, but makes a saver richer,",
                  "which raises it. The exam question asks which wins; the",
                  "evidence says the effects roughly cancel.")
    )
  ),
  list(
    group = "descriptor", label = "Why Fiscal Policy Is Weak Here",
    versions = list("2" = "\\text{MPC} = 1/S \\ll 1"),
    notes = list(
      "2" = paste("A temporary transfer is spread over the whole of life,",
                  "so almost none of it is spent now. This is the theory",
                  "the Keynesian multiplier's low-MPC household is",
                  "standing in for.")
    )
  ),
  list(
    group = "descriptor", label = "What Breaks Equivalence",
    versions = list("5" = "\\lambda > 0 \\ \\text{ or } \\ k > T"),
    notes = list(
      "5" = paste("Income going to hand-to-mouth consumers, or a bill that",
                  "arrives after the consumer has died. Note that λ is an",
                  "income share: since constrained households earn less",
                  "than average, the share of people behaving this way is",
                  "higher than λ. Add credit constraints and distortionary",
                  "taxes and little of the result survives.")
    )
  ),
  list(
    group = "descriptor", label = "Certainty Equivalence Against Prudence",
    versions = list("6" = paste0("\\frac{\\partial C_t}{\\partial \\sigma^2}",
                                 " = 0 \\ \\text{ vs } \\ -\\frac{\\alpha}",
                                 "{2r} < 0")),
    notes = list(
      "6" = paste("The same uncertainty, two opposite predictions. Under",
                  "quadratic utility σ² does not appear in the consumption",
                  "function at all; under CARA it lowers consumption today",
                  "and tilts the whole path upwards. Nothing about the",
                  "consumer's risk has changed — only the third derivative",
                  "of their utility function.")
    )
  )
)

###### B_03_08: Equation Group Titles ##########################################
# Note: Group headings in the equations tabs.

B_03_08_groups_vec <- c(
  model      = "Model Equations",
  assumption = "Assumptions",
  solved     = "Solved Forms",
  descriptor = "Descriptors"
)

###### B_03_09: Notation Key ###################################################
# Note: Notation tab. Groups: var, par, flw (policy flows); "from" is the
#   first stage a symbol appears at.

B_03_09_notation_lst <- list(
  list(grp = "var", sym = "C_t", txt = "consumption", from = 1),
  list(grp = "var", sym = "Y_t", txt = "income", from = 1),
  # Ybar is drawn on two panels, so it belongs in the key
  list(grp = "par", sym = "\\bar{Y}",
       txt = "income in every period, before any shock", from = 1),
  list(grp = "var", sym = "W", txt = "lifetime resources", from = 1),
  list(grp = "var", sym = "\\bar{U}",
       txt = "the utility level an indifference curve draws", from = 1),
  list(grp = "par", sym = "r", txt = "real interest rate", from = 1),
  list(grp = "par", sym = "\\beta", txt = "discount factor", from = 1),
  list(grp = "par", sym = "\\rho", txt = "curvature of utility", from = 1),
  list(grp = "par", sym = "A_0", txt = "assets at the start of life",
       from = 1),
  list(grp = "flw", sym = "\\tau", txt = "a one-off transfer", from = 1),
  list(grp = "par", sym = "T", txt = "periods of life remaining", from = 2),
  list(grp = "par", sym = "g", txt = "growth factor of consumption", from = 2),
  list(grp = "par", sym = "S", txt = "annuity factor", from = 2),
  list(grp = "par", sym = "\\phi", txt = "persistence of income shocks",
       from = 4),
  list(grp = "var", sym = "\\varepsilon_t", txt = "news about income",
       from = 4),
  list(grp = "par", sym = "\\sigma", txt = "standard deviation of the news",
       from = 4),
  list(grp = "flw", sym = "\\Delta T_0", txt = "the tax cut today", from = 5),
  list(grp = "flw", sym = "k", txt = "when the debt is repaid", from = 5),
  list(grp = "par", sym = "\\lambda",
       txt = "share of income going to hand-to-mouth consumers", from = 5),
  list(grp = "par", sym = "\\alpha",
       txt = "absolute risk aversion, and absolute prudence", from = 6),
  list(grp = "par", sym = "\\alpha\\sigma^2/(2r)",
       txt = "precautionary saving: how much consumption is held back",
       from = 6)
)

###### B_03_10: Notation Columns ###############################################
# Note: How the notation tab is split into columns.

B_03_10_nota_cols_lst <- list(
  "Variables"  = "var",
  "Parameters" = "par",
  "Policy"     = "flw"
)

###### B_03_11: Figure Heights #################################################
# Note: Height of the main figures in the browser.

B_03_11_tall_chr <- "420px"

###### B_03_12: Recalculation Delay ############################################
# Note: Milliseconds to wait for further changes before recalculating.

B_03_12_debounce_ms_int <- 250L

###### B_03_13: Version ########################################################
# Note: Semantic version, shown in the footer; CHANGELOG.md has the history.

B_03_13_version_chr <- "1.0.8"

###### B_03_14: Source Repository ##############################################
# Note: The GitHub repo, linked from the footer.

B_03_14_repo_chr <- paste0("https://github.com/Sam-Deegan/",
                        "Interactive-Model-Consumption")

#### B_04: Paths ###############################################################
# Note: The QR code only.

###### B_04_01: QR Code Source #################################################
# Note: The toolkit embeds it as a data URI, so nothing is served from www/.

B_04_01_qr_src_chr <- T_07_04_qr_fn()

################################################################################
## D: Plots ####################################################################
################################################################################
# Note: Builders only; each returns a ggplot for the server to draw. Figure
#   conventions follow CONVENTIONS.md 6.

#### D_01: The Plan and the Horizon ############################################
# Note: What the consumer does with the income they have.

###### D_01_01: The Consumption Plan ###########################################
# Note: Income and consumption over the remaining life; the gap is saving.
#   Ybar is the resting point. The ghost is drawn in the line variant only.

D_01_01_plan_fn <- function(par, ref = NULL) {
  plan <- C_01_06_plan_fn(par, windfall = par$windfall)
  base <- C_01_06_plan_fn(par, windfall = 0)

  long <- rbind(
    data.frame(period = plan$period, value = plan$income, line = "Income"),
    data.frame(period = plan$period, value = plan$consumption,
               line = "Consumption")
  )
  long$line <- factor(long$line, levels = c("Income", "Consumption"))

  # Short lives read better as bars, long ones as lines
  pal <- c("Income"      = T_01_02_series_vec[["compare"]],
           "Consumption" = T_01_02_series_vec[["main"]])

  p <- if (par$horizon <= 12) {
    ggplot(long, aes(x = period, y = value, fill = line)) +
      T_02_02_rest_fn(h = par$income) +
      geom_col(position = position_dodge(width = 0.7), width = 0.6) +
      scale_fill_manual(values = pal) +
      scale_x_continuous(breaks = seq_len(par$horizon))
  } else {
    ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
      gp <- C_01_06_plan_fn(ref, windfall = ref$windfall)
      list(
        T_02_03a_ghost_path_fn(
          data.frame(x = gp$period, y = gp$income), aes(x = x, y = y),
          colour = pal[["Income"]], linewidth = 1.1),
        T_02_03a_ghost_path_fn(
          data.frame(x = gp$period, y = gp$consumption), aes(x = x, y = y),
          colour = pal[["Consumption"]], linewidth = 1.1)
      )
    }
    ggplot(long, aes(x = period, y = value, colour = line)) +
      T_02_02_rest_fn(h = par$income) +
      ghost_lyr +
      geom_line(linewidth = 1.1) +
      scale_colour_manual(values = pal) +
      scale_x_continuous(breaks = D_01_02_breaks_fn(par$horizon))
  }

  p +
    T_02_02_mark_y_fn(par$income, expression(bar(Y))) +
    labs(
      title = if (abs(par$windfall) > 1e-9) {
        paste0("A transfer of ", T_02_05_num_fn(par$windfall, 0),
               " raises consumption today by ",
               T_02_05_num_fn(plan$consumption[1] - base$consumption[1], 2))
      } else {
        paste0("The consumption plan: consumption today is ",
               T_02_05_num_fn(plan$consumption[1], 2))
      },
      x = expression(bold("Period (" * t * ")")),
      y = expression(bold("Income and consumption (" * Y[t] * ", " *
                            C[t] * ")")),
      caption = paste0(
        "Consumption grows at ", T_02_05_num_fn(C_01_02_growth_fn(par), 3),
        " a period, whatever income does. The gap is saving."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_01_02: Break Points for Long Horizons #################################
# Note: Period-axis breaks that stay readable when life is long.

D_01_02_breaks_fn <- function(horizon) {
  step <- max(1, round(horizon / 8))
  seq(1, horizon, by = step)
}

###### D_01_03: The MPC Against the Horizon ####################################
# Note: How much of a windfall is spent today, for every length of life. The
#   two-period case is a half; the limit is r/(1+r).

D_01_03_horizon_fn <- function(par, ref = NULL) {
  df    <- C_01_07_horizon_fn(par, 60)
  limit <- par$rate / (1 + par$rate)
  now   <- C_01_04_mpc_fn(par)

  # Ghost: the curve at the reference rate and the point at the reference T
  gdf <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    C_01_07_horizon_fn(ref, 60)
  }
  ghost_lyr <- if (is.null(gdf)) NULL else {
    list(
      T_02_03a_ghost_line_fn(
        data.frame(x = gdf$horizon, y = gdf$mpc), aes(x = x, y = y),
        colour = T_01_02_series_vec[["main"]], linewidth = 1.1),
      T_02_03a_ghost_point_fn(ref$horizon, C_01_04_mpc_fn(ref),
                              colour = T_01_02_series_vec[["main"]])
    )
  }
  y_top <- max(c(df$mpc, gdf$mpc, now)) * 1.08

  # Resting points: the limit r/(1+r) and the current horizon T
  ggplot(df, aes(x = horizon, y = mpc)) +
    T_02_02_rest_fn(h = limit, v = par$horizon) +
    ghost_lyr +
    geom_line(colour = T_01_02_series_vec[["main"]], linewidth = 1.1) +
    T_02_03_point_fn(par$horizon, now) +
    T_02_02_mark_y_fn(limit, expression(r / (1 + r))) +
    T_02_02_mark_x_fn(par$horizon, expression(T)) +
    coord_cartesian(ylim = c(0, y_top)) +
    labs(
      title = paste0("With ", par$horizon,
                     " periods left, ", T_02_06_pct_fn(now, 1),
                     " of a windfall is spent today"),
      x = expression(bold("Periods of life remaining (" * T * ")")),
      y = expression(bold("Marginal propensity to consume (" * 1 / S * ")")),
      caption = paste(
        "The consumer is not becoming meaner as life lengthens: they have",
        "more years to spread the same windfall over."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_01_04: The Two-Period Choice, Drawn ###################################
# Note: Budget line through the endowment, slope -(1+r), and two indifference
#   curves; names at the ends of the lines (Whelan figs 11.2, 11.3). No ghost.

D_01_04_two_period_fn <- function(par) {
  two <- modifyList(par, list(horizon = 2))
  geo <- C_01_17_two_period_fn(two)

  # The whole budget line, with room past C_1 = W for its name
  x_lim <- c(0, geo$wealth * 1.30)
  y_lim <- c(0, geo$wealth * (1 + two$rate) * 1.08)

  grid <- seq(x_lim[1] + diff(x_lim) / 400, x_lim[2], length.out = 400)
  line <- data.frame(c1 = grid,
                     c2 = geo$e2 + geo$slope * (grid - geo$e1))

  # The optimum's curve and a dilation of it; CRRA is homothetic
  ic_fn <- function(k) {
    out <- C_01_16_indiff_fn(two, k * geo$c1, k * geo$c2, grid)
    out$which <- if (abs(k - 1) < 1e-9) "optimum" else "other"
    out
  }
  curves <- rbind(ic_fn(1.15), ic_fn(1))
  best   <- curves[curves$which == "optimum", ]
  other  <- curves[curves$which == "other", ]

  # Each name sits at the end of its own line, in clear space
  end_fn   <- function(d) d$c2[which.max(d$c1)]
  x_right  <- x_lim[2] * 0.99
  lift_num <- diff(y_lim) * 0.075

  i_top <- which.min(abs(other$c2 - y_lim[2] * 0.88))

  x_bc <- geo$wealth + diff(x_lim) * 0.015
  y_bc <- diff(y_lim) * 0.055

  ggplot(line, aes(x = c1, y = c2)) +
    # Optimum and endowment are resting points, named on the opposite axes
    T_02_02_rest_fn(h = c(geo$c2, geo$e2), v = c(geo$c1, geo$e1)) +
    geom_line(data = curves,
              aes(x = c1, y = c2, group = interaction(level, which),
                  colour = which, linewidth = which)) +
    geom_line(colour = T_01_02_series_vec[["main"]], linewidth = 1.1) +
    scale_colour_manual(values = c(optimum = T_01_02_series_vec[["third"]],
                                   other   = T_01_02_series_vec[["band"]]),
                        guide = "none") +
    scale_linewidth_manual(values = c(optimum = 1.1, other = 0.8),
                           guide = "none") +
    T_02_03_point_fn(geo$c1, geo$c2) +
    T_02_03_point_fn(geo$e1, geo$e2,
                     colour = T_01_02_series_vec[["compare"]]) +
    annotate("text", x = geo$e1, y = geo$e2, label = "endowment",
             hjust = 1.15, vjust = 1.9, size = 3.2,
             colour = T_01_01_palette_vec[["muted"]]) +
    T_02_02_mark_x_fn(c(geo$c1, geo$e1), expression(C[1], Y[1])) +
    T_02_02_mark_y_fn(c(geo$c2, geo$e2), expression(C[2], Y[2])) +
    coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
    # hjust = 0: the name runs rightwards from where the line meets the axis
    annotate("text", x = x_bc, y = y_bc, label = "Budget constraint",
             size = 3.2, hjust = 0, vjust = 0.5,
             colour = T_01_01_palette_vec[["muted"]]) +
    # A label, not text, so it blanks the dotted lines behind it
    annotate("label", x = other$c1[i_top] + diff(x_lim) * 0.02,
             y = other$c2[i_top],
             label = "'IC ('*bar(U) > bar(U)^'*'*')'",
             parse = TRUE, size = 3.0, hjust = 0, vjust = 0.5,
             colour = T_01_01_palette_vec[["muted"]],
             fill = T_01_01_palette_vec[["wash"]], label.size = 0,
             label.padding = grid::unit(0.12, "lines")) +
    annotate("text", x = x_right, y = end_fn(best) - lift_num,
             label = "'IC ('*bar(U)^'*'*')'",
             parse = TRUE, size = 3.0, hjust = 1, vjust = 0.5,
             colour = T_01_01_palette_vec[["muted"]]) +
    labs(
      title = paste("Budget Constraint (BC) and",
                    "\nIndifference Curves (IC)"),
      x = expression(bold("Consumption today (" * C[1] * ")")),
      y = expression(bold("Consumption next period (" * C[2] * ")")),
      caption = paste0(
        "The consumer is handed the endowment and trades along the line at ",
        T_02_06_pct_fn(two$rate), ", saving ",
        T_02_05_num_fn(geo$saving, 1),
        " of it. The tangency is where the marginal rate of substitution",
        " equals 1 + r, which is the Euler equation."
      )
    ) +
    T_02_01_theme_fn(grid = "none") 
}

#### D_02: Permanent Income and the Random Walk ################################
# Note: What the theory predicts, and what a path of it looks like.

###### D_02_01: Temporary Against Permanent ####################################
# Note: The same euro, arriving once or arriving for ever. No ghost: faded
#   bars behind live ones would read as extra categories.

D_02_01_response_fn <- function(par) {
  df <- C_01_08_response_fn(par, size = 1)
  df$kind <- factor(df$kind, levels = df$kind)

  # One-for-one is the resting point the permanent bar is read against
  ggplot(df, aes(x = kind, y = response, fill = kind)) +
    T_02_02_rest_fn(h = 1) +
    geom_col(width = 0.55) +
    geom_text(aes(label = T_02_05_num_fn(response, 3)), vjust = -0.5,
              size = 4.4, colour = T_01_01_palette_vec[["navy"]]) +
    scale_fill_manual(values = stats::setNames(
      c(T_01_02_series_vec[["band"]], T_01_02_series_vec[["main"]]),
      levels(df$kind))) +
    T_02_02_mark_y_fn(1, expression(Delta * Y[t])) +
    coord_cartesian(ylim = c(0, max(c(df$response, 1)) * 1.18)) +
    labs(
      title = "The Consumption Response to One Euro",
      x = NULL,
      y = expression(bold("Rise in consumption today (" * Delta * C[t] * ")")),
      caption = paste0(
        "Over ", par$horizon, " periods at ", T_02_06_pct_fn(par$rate),
        ", a permanent rise is worth ",
        T_02_05_num_fn(df$response[2] / max(df$response[1], 1e-9), 0),
        " times as much to today's consumption as a one-off."
      )
    ) +
    T_02_01_theme_fn() +
    theme(legend.position = "none")
}

###### D_02_02: An Income Path and Its Consumption #############################
# Note: The random walk, drawn. Income jumps; consumption drifts.

D_02_02_path_fn <- function(par, ref = NULL) {
  set.seed(42)
  path <- C_01_09_path_fn(par)
  sm   <- C_01_10_smooth_fn(par)

  # Ghost: the same run at the reference settings, from the same seed
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    set.seed(42)
    gp <- C_01_09_path_fn(ref)
    list(
      T_02_03a_ghost_path_fn(
        data.frame(x = gp$period, y = gp$income), aes(x = x, y = y),
        colour = T_01_02_series_vec[["compare"]], linewidth = 1.0),
      T_02_03a_ghost_path_fn(
        data.frame(x = gp$period, y = gp$consumption), aes(x = x, y = y),
        colour = T_01_02_series_vec[["main"]], linewidth = 1.0)
    )
  }

  long <- rbind(
    data.frame(period = path$period, value = path$income, line = "Income"),
    data.frame(period = path$period, value = path$consumption,
               line = "Consumption")
  )
  long$line <- factor(long$line, levels = c("Income", "Consumption"))

  # Ybar is the resting point; expand_limits keeps it in the panel
  ggplot(long, aes(x = period, y = value, colour = line, linetype = line)) +
    T_02_02_rest_fn(h = par$income) +
    ghost_lyr +
    geom_line(linewidth = 1.0) +
    scale_colour_manual(values = c(
      "Income"      = T_01_02_series_vec[["compare"]],
      "Consumption" = T_01_02_series_vec[["main"]]
    )) +
    scale_linetype_manual(values = c("Income" = "22",
                                     "Consumption" = "solid")) +
    T_02_02_mark_y_fn(par$income, expression(bar(Y))) +
    expand_limits(y = par$income) +
    labs(
      title = paste0("A shock to income raises consumption by ",
                     T_02_05_num_fn(sm$ratio, 3), " of itself"),
      x = expression(bold("Period (" * t * ")")),
      y = expression(bold("Income and consumption (" * Y[t] * ", " *
                            C[t] * ")")),
      caption = paste0(
        "Persistence φ = ", T_02_05_num_fn(par$persist, 2),
        ". Consumption is a random walk: its level wanders, but its changes",
        " are small and unforecastable."
      )
    ) +
    T_02_01_theme_fn()
}

#### D_03: Ricardian Equivalence ###############################################
# Note: What the tax cut does, and what has to be true for it to do nothing.

###### D_03_01: What Breaks Equivalence ########################################
# Note: The response of consumption to the same tax cut under each
#   objection. No ghost, as in D_02_01.

D_03_01_breaks_fn <- function(par) {
  df <- C_01_12_breaks_fn(par)
  df$label <- factor(df$label, levels = rev(df$label))
  df$kind  <- ifelse(abs(df$response) < 1e-12, "No Effect", "Consumption Rises")

  # The cut is the resting point; gridlines off under coord_flip
  ggplot(df, aes(x = label, y = response, fill = kind)) +
    T_02_02_rest_fn(h = par$cut) +
    geom_col(width = 0.62) +
    geom_text(aes(label = ifelse(abs(response) < 1e-12, "nothing",
                                 paste0("+", T_02_05_num_fn(response, 2)))),
              hjust = -0.15, size = 4,
              colour = T_01_01_palette_vec[["navy"]]) +
    coord_flip(ylim = c(0, max(c(df$response, par$cut), 1e-3) * 1.15)) +
    scale_fill_manual(values = c(
      "Consumption Rises" = T_01_01_palette_vec[["navy"]],
      "No Effect"         = T_01_01_palette_vec[["muted"]]
    )) +
    T_02_02_mark_y_fn(par$cut, expression(Delta * T[0])) +
    labs(
      title = paste0("A tax cut of ", T_02_05_num_fn(par$cut, 0),
                     ", financed by borrowing"),
      x = NULL,
      y = expression(bold("Rise in consumption today (" * Delta * C[t] * ")")),
      caption = paste(
        "Equivalence needs forward-looking consumers who expect to pay the",
        "bill. Take away either and the cut works like any other transfer."
      )
    ) +
    T_02_01_theme_fn(grid = "none")
}

#### D_04: Precautionary Saving ################################################
# Note: The stage 6 contrast: the same shocks and consumer, two shapes of
#   marginal utility.

###### D_04_01: Two Utilities, One Sequence of Shocks ##########################
# Note: Both consumption paths on the same axes and the same draws, so every
#   difference between the lines is prudence.

D_04_01_prec_path_fn <- function(par, ref = NULL) {
  set.seed(42)
  paths <- C_02_05_paths_fn(par)
  d     <- C_02_07_diagnostics_fn(par)

  quad_lab <- "Quadratic Utility: A Random Walk"
  cara_lab <- "CARA Utility: A Precautionary Buffer"

  # Ghost: both paths at the reference settings, from the same seed
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    set.seed(42)
    gp <- C_02_05_paths_fn(ref)
    list(
      T_02_03a_ghost_path_fn(
        data.frame(x = gp$period, y = gp$quadratic), aes(x = x, y = y),
        colour = T_01_02_series_vec[["compare"]], linewidth = 1.1),
      T_02_03a_ghost_path_fn(
        data.frame(x = gp$period, y = gp$cara), aes(x = x, y = y),
        colour = T_01_02_series_vec[["main"]], linewidth = 1.1)
    )
  }

  long <- rbind(
    data.frame(period = paths$period, value = paths$quadratic,
               line = quad_lab),
    data.frame(period = paths$period, value = paths$cara, line = cara_lab)
  )
  long$line <- factor(long$line, levels = c(quad_lab, cara_lab))

  # The certainty-equivalent level r/(1+r)W is the resting point
  ggplot(long, aes(x = period, y = value, colour = line, linetype = line)) +
    T_02_02_rest_fn(h = d$certain) +
    ghost_lyr +
    geom_line(linewidth = 1.1) +
    scale_colour_manual(values = stats::setNames(
      c(T_01_02_series_vec[["compare"]], T_01_02_series_vec[["main"]]),
      c(quad_lab, cara_lab))) +
    scale_linetype_manual(values = stats::setNames(
      c("22", "solid"), c(quad_lab, cara_lab))) +
    scale_x_continuous(breaks = D_01_02_breaks_fn(par$n_periods)) +
    T_02_02_mark_y_fn(d$certain, expression(r / (1 + r) * W)) +
    expand_limits(y = d$certain) +
    labs(
      title = paste0("Prudence holds consumption ",
                     T_02_05_num_fn(d$buffer, 2),
                     " below the certainty-equivalent level"),
      x = expression(bold("Period (" * t * ")")),
      y = expression(bold("Consumption (" * C[t] * ")")),
      caption = paste0(
        "The same draws under both. The gap starts at the buffer and ",
        "closes by ", T_02_05_num_fn(d$drift, 3), " a period."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_04_02: Consumption Today Against Uncertainty ##########################
# Note: Certainty equivalence and its failure in one picture: flat in sigma
#   under quadratic utility, a falling parabola under CARA.

D_04_02_buffer_fn <- function(par, ref = NULL) {
  # One sigma grid wide enough for both the live and the reference settings
  ghost_on <- !T_02_03b_ghost_off_fn(par, ref)
  top <- max(par$sd_income * 1.6, 20,
             if (ghost_on) ref$sd_income * 1.6 else 0)

  df <- C_02_06_buffer_fn(par, max_sd = top)
  d  <- C_02_07_diagnostics_fn(par)

  quad_lab <- "Quadratic Utility"
  cara_lab <- "CARA Utility"

  long <- rbind(
    data.frame(sd = df$sd, value = df$quadratic, line = quad_lab),
    data.frame(sd = df$sd, value = df$cara, line = cara_lab)
  )
  long$line <- factor(long$line, levels = c(quad_lab, cara_lab))

  # Ghost: both curves and the operating point at the reference settings
  gdf <- if (ghost_on) C_02_06_buffer_fn(ref, max_sd = top) else NULL
  gd  <- if (ghost_on) C_02_07_diagnostics_fn(ref) else NULL
  ghost_lyr <- if (is.null(gdf)) NULL else {
    list(
      T_02_03a_ghost_line_fn(
        data.frame(x = gdf$sd, y = gdf$quadratic), aes(x = x, y = y),
        colour = T_01_02_series_vec[["compare"]], linewidth = 1.1),
      T_02_03a_ghost_line_fn(
        data.frame(x = gdf$sd, y = gdf$cara), aes(x = x, y = y),
        colour = T_01_02_series_vec[["main"]], linewidth = 1.1),
      T_02_03a_ghost_point_fn(ref$sd_income, gd$cara,
                              colour = T_01_02_series_vec[["main"]])
    )
  }

  # The span is floored so the panel has height when the lines coincide
  x_lim <- range(long$sd)
  y_bot <- min(c(long$value, gdf$cara, gdf$quadratic))
  y_ref <- max(c(d$certain, gd$certain))
  span  <- max(y_ref - y_bot, abs(y_ref) * 0.1, 1)
  # Headroom for the name hung from the top of the panel
  y_lim <- c(min(y_bot, y_ref - 0.05 * span), y_ref + 0.22 * span)

  ggplot(long, aes(x = sd, y = value, colour = line, linetype = line)) +
    T_02_02_rest_fn(h = d$certain, v = par$sd_income) +
    ghost_lyr +
    geom_line(linewidth = 1.1) +
    scale_colour_manual(values = stats::setNames(
      c(T_01_02_series_vec[["compare"]], T_01_02_series_vec[["main"]]),
      c(quad_lab, cara_lab))) +
    scale_linetype_manual(values = stats::setNames(
      c("22", "solid"), c(quad_lab, cara_lab))) +
    T_02_03_point_fn(par$sd_income, d$cara) +
    T_02_02_mark_y_fn(d$certain, expression(r / (1 + r) * W)) +
    T_02_02_mark_x_fn(par$sd_income, expression(sigma)) +
    coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
    annotate("text", x = x_lim[2], y = y_lim[2], label = "Quadratic utility",
             size = 3.2, hjust = 1, vjust = 1.5,
             colour = T_01_01_palette_vec[["muted"]]) +
    labs(
      title = paste0("At σ = ", T_02_05_num_fn(par$sd_income, 1),
                     " precautionary saving is ",
                     T_02_05_num_fn(d$buffer, 2)),
      x = expression(bold("Standard deviation of the news (" * sigma * ")")),
      y = expression(bold("Consumption today (" * C[t] * ")")),
      caption = paste(
        "Flat under quadratic utility: certainty equivalence.",
        "At α = 0 the lines meet."
      )
    ) +
    T_02_01_theme_fn() +
    theme(aspect.ratio = 2 / 3)
}

################################################################################
## E: User Interface ###########################################################
################################################################################
# Note: bslib page: controls in a sidebar, figures in cards.

#### E_01: Sidebar #############################################################
# Note: Stage selector and the controls. The sidebar chooses the model; the
#   main window chooses what to run in it.

###### E_01_01: Control Shorthand ##############################################
# Note: Saves passing the same three lists at every call.

E_01_01_ctl_fn <- function(id) {
  T_03_01_control_fn(id, B_03_04_controls_lst, B_03_05_help_lst,
                     B_03_01_defaults_lst)
}

###### E_01_02: Sidebar ########################################################
# Note: conditionalPanel reveals controls as the stages add layers.

E_01_02_sidebar_lst <- sidebar(
  width = 380,
  radioButtons("stage", "Stage of the Model",
               choices = B_03_02_stages_vec, selected = "1"),
  T_03_05_note_fn(paste(
    "Each stage adds one piece to the model and leaves the rest",
    "alone. Start at the top; the equations panel marks what is new.")),
  accordion(
    open = c("The Consumer"),
    accordion_panel(
      "The Consumer",
      E_01_01_ctl_fn("horizon"),
      E_01_01_ctl_fn("windfall"),
      tags$h6("Preferences"),
      E_01_01_ctl_fn("beta"),
      E_01_01_ctl_fn("rho"),
      tags$h6("Resources"),
      E_01_01_ctl_fn("rate"),
      E_01_01_ctl_fn("income"),
      E_01_01_ctl_fn("assets")
    ),
    accordion_panel(
      "Income Risk",
      conditionalPanel(
        "parseFloat(input.stage) >= 4",
        E_01_01_ctl_fn("persist"),
        E_01_01_ctl_fn("sd_income"),
        E_01_01_ctl_fn("n_periods")
      ),
      conditionalPanel("parseFloat(input.stage) < 4",
                       tags$p(class = "stat-caption",
                              "Uncertainty appears at stage 4.")),
      conditionalPanel(
        "parseFloat(input.stage) >= 6",
        tags$h6("Prudence"),
        E_01_01_ctl_fn("prudence")
      )
    ),
    accordion_panel(
      "The Tax Cut",
      conditionalPanel(
        "parseFloat(input.stage) >= 5",
        E_01_01_ctl_fn("cut"),
        E_01_01_ctl_fn("repay"),
        E_01_01_ctl_fn("hand_share")
      ),
      conditionalPanel("parseFloat(input.stage) < 5",
                       tags$p(class = "stat-caption",
                              "Ricardian equivalence appears at stage 5."))
    )
  ),
  actionButton("reset", "Reset Everything",
               class = "btn-outline-secondary btn-sm w-100"),
  T_07_10b_sidebarqr_fn(B_04_01_qr_src_chr)
)

#### E_02: Main Panel ##########################################################
# Note: Equations, worked examples, prompt, readouts, then the figures.

###### E_02_01: Worked-Example Presets #########################################
# Note: The worked-example buttons for the stage on screen. The machinery is
#   T_05_04 to T_05_07 in the toolkit; this is the wiring.

E_02_01_presets_lst <- T_05_04_presets_fn(
  B_03_03_scenarios_lst, B_03_02_stages_vec, stage_word = "Stage"
)

###### E_02_02: Page ###########################################################
# Note: The full UI object passed to shinyApp().

E_02_02_app_ui_lst <- tagList(
  T_07_08b_nav_fn(),
  page_sidebar(
  title        = T_07_09_title_fn("The Life-Cycle/Permanent-Income Hypothesis",
                                  B_04_01_qr_src_chr),
  window_title = paste("Life-Cycle/Permanent Income ·", T_07_01_author_chr),
  fillable     = FALSE,
  theme        = T_07_05_theme_fn(),
  sidebar      = E_01_02_sidebar_lst,
  T_07_08_head_fn(),
  tags$head(
    tags$style(HTML(T_05_07_preset_css_chr)),
    tags$script(HTML(T_05_05_preset_js_chr))
  ),
  navset_card_tab(
    title = textOutput("eq_title", inline = TRUE),
    nav_panel("Equations", uiOutput("eq_model")),
    nav_panel("Notation", uiOutput("eq_notation")),
    nav_panel("In Words", uiOutput("eq_explain"))
  ),
  E_02_01_presets_lst,
  uiOutput("prompt"),
  uiOutput("problems"),
  uiOutput("tiles"),
  # The diagram has one axis per period, so it needs a horizon of two
  conditionalPanel(
    "parseFloat(input.stage) <= 2 && parseFloat(input.horizon) == 2",
    T_07_07c_figcard_fn("two_period", "The Two-Period Choice",
                        B_03_11_tall_chr)
  ),
  conditionalPanel(
    "parseFloat(input.stage) <= 2 && parseFloat(input.horizon) != 2",
    tags$p(class = "stat-caption",
           paste("The two-period diagram has one axis per period, so it is",
                 "drawn when the horizon is 2."))
  ),
  layout_columns(
    col_widths = breakpoints(sm = 12, xl = c(6, 6)),
    T_07_07c_figcard_fn("plan", "The Consumption Plan",
                          B_03_11_tall_chr),
    T_07_07c_figcard_fn("horizon", "The Windfall and the Horizon",
                          B_03_11_tall_chr)
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 3",
    layout_columns(
      col_widths = breakpoints(sm = 12, xl = c(5, 7)),
      T_07_07c_figcard_fn("response", "Temporary Against Permanent",
                          B_03_11_tall_chr),
      conditionalPanel(
        "parseFloat(input.stage) >= 4",
        T_07_07c_figcard_fn("path", "Income and Consumption Over Time",
                          B_03_11_tall_chr)
      )
    )
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 5",
    card(
      card_header("A Debt-Financed Tax Cut"),
      plotOutput("breaks", height = B_03_11_tall_chr),
      uiOutput("ric_note")
    )
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 6",
    layout_columns(
      col_widths = breakpoints(sm = 12, xl = c(7, 5)),
      T_07_07c_figcard_fn("prec_path",
                          "Quadratic Against CARA, Same Shocks",
                          B_03_11_tall_chr),
      T_07_07c_figcard_fn("prec_buffer",
                          "Consumption Today Against Uncertainty",
                          B_03_11_tall_chr)
    ),
    card(
      card_header("Why Uncertainty Suddenly Matters"),
      uiOutput("prec_note")
    )
  ),
  T_07_11_footer_fn(paste0("Notation follows the Part 2 exam questions.",
                           " Version ", B_03_13_version_chr, "."),
                    repo = B_03_14_repo_chr),
))

################################################################################
## F: Server ###################################################################
################################################################################
# Note: Assembles the stage's parameters, solves the model, draws.

#### F_01: Server Function #####################################################
# Note: Everything reactive lives here.

###### F_01_01: Server #########################################################
# Note: Local objects are plain snake_case.

F_01_01_app_server_fn <- function(input, output, session) {

  # --- Figure captions --------------------------------------------------------
  # T_02_01c_draw_fn lifts each caption out of the device; this prints it
  T_07_07d_cap_fn(output)

  # --- Stage as a number ------------------------------------------------------
  stage_num <- reactive(as.numeric(input$stage))

  # --- Controls ---------------------------------------------------------------
  val <- function(id) T_03_04_val_fn(input, id)
  T_03_02_sync_fn(input, session, B_03_04_controls_lst)

  set_control <- function(id, value) {
    T_03_03_set_fn(session, B_03_04_controls_lst, id, value)
  }

  # --- Worked-example presets -------------------------------------------------
  # One observer per preset; set_scenario_fn is the only place that sets the
  # loaded preset, so the button marker and card header cannot drift apart.
  scenario <- reactiveVal(names(B_03_03_scenarios_lst)[1])

  # One guarded lookup of the loaded scenario for the header, story and prompt
  scn_now <- reactive({
    k <- scenario()
    if (is.null(k) || !k %in% names(B_03_03_scenarios_lst)) NULL
    else B_03_03_scenarios_lst[[k]]
  })

  set_scenario_fn <- function(key) {
    scenario(if (is.null(key)) "custom" else key)
    session$sendCustomMessage("dgPreset", if (is.null(key)) "" else key)
    invisible(NULL)
  }

  load_preset_fn <- function(key) {
    if (is.null(key) || !key %in% names(B_03_03_scenarios_lst)) {
      return(invisible(NULL))
    }
    scn <- B_03_03_scenarios_lst[[key]]
    set_scenario_fn(key)
    for (id in names(B_03_04_controls_lst)) {
      set_control(id, if (!is.null(scn$values[[id]])) scn$values[[id]]
                  else B_03_01_defaults_lst[[id]])
    }
    invisible(NULL)
  }

  lapply(names(B_03_03_scenarios_lst), function(key) {
    observeEvent(input[[paste0("preset_", key)]],
                 load_preset_fn(key), ignoreInit = TRUE)
  })

  # NULL when a stage has no examples
  first_preset_fn <- function(stage) {
    hits <- names(B_03_03_scenarios_lst)[vapply(
      B_03_03_scenarios_lst, function(x) identical(x$stage, stage), TRUE)]
    if (length(hits) == 0L) NULL else hits[[1L]]
  }

  # --- Changing stage ---------------------------------------------------------
  # Every stage opens on its first worked example, which also moves the
  # ghost's reference. Stage 6 solves an infinitely lived consumer, so a
  # zero rate is lifted to its default first; the stage 6 prompt says so.
  observeEvent(input$stage, {
    if (stage_num() >= 6 && !is.null(input$rate) && val("rate") <= 0) {
      set_control("rate", B_03_01_defaults_lst$rate)
    }
    first <- first_preset_fn(input$stage)
    if (is.null(first)) set_scenario_fn(NULL) else load_preset_fn(first)
  })

  output$preset_title <- renderUI({
    T_05_06_preset_title_fn(scn_now(), input$stage, B_03_02_stages_vec,
                            stage_word = "")
  })

  # --- Reset ------------------------------------------------------------------
  observeEvent(input$reset, {
    for (id in names(B_03_04_controls_lst)) {
      set_control(id, B_03_01_defaults_lst[[id]])
    }
    set_scenario_fn(NULL)
  })

  # --- Parameters in force at this stage --------------------------------------
  # Controls hidden at earlier stages are switched off whatever their value:
  # no income risk before 4, no tax cut before 5, no prudence before 6. A
  # pure function of the control values and the stage, so the ghost can be
  # assembled the same way.
  assemble_fn <- function(v, s) {
    list(
      stage      = s,
      rate       = v$rate,
      beta       = v$beta,
      rho        = v$rho,
      income     = v$income,
      assets     = v$assets,
      horizon    = round(v$horizon),
      windfall   = v$windfall,
      persist    = if (s >= 4) v$persist else 0,
      sd_income  = if (s >= 4) v$sd_income else 0,
      n_periods  = round(v$n_periods),
      cut        = if (s >= 5) v$cut else 0,
      repay      = round(v$repay),
      hand_share = if (s >= 5) v$hand_share else 0,
      prudence   = if (s >= 6) v$prudence else 0
    )
  }

  par_raw <- reactive({
    req(!is.null(input$rate))
    vals <- stats::setNames(lapply(names(B_03_01_defaults_lst), val),
                            names(B_03_01_defaults_lst))
    assemble_fn(vals, stage_num())
  })

  par_now  <- debounce(par_raw, B_03_12_debounce_ms_int)
  diag_now <- reactive(C_01_13_diagnostics_fn(par_now()))
  prec_now <- reactive(C_02_07_diagnostics_fn(par_now()))
  ok_now   <- reactive(length(diag_now()$problems) == 0)

  # --- The ghost: every figure at the worked example's own settings ----------
  # Reference values are the loaded preset's, or the defaults when none is
  # loaded. The ghost is NULL while live and reference agree, and when the
  # reference itself would not solve.
  ref_vals <- reactive({
    key <- scenario()
    if (is.null(key) || !key %in% names(B_03_03_scenarios_lst)) {
      return(B_03_01_defaults_lst)
    }
    utils::modifyList(B_03_01_defaults_lst,
                      B_03_03_scenarios_lst[[key]]$values)
  })

  ref_par <- reactive(assemble_fn(ref_vals(), stage_num()))

  ghost_par <- reactive({
    ref <- ref_par()
    if (is.null(ref) || T_02_03b_ghost_off_fn(par_now(), ref)) return(NULL)
    if (length(C_01_14_problems_fn(ref)) > 0) return(NULL)
    ref
  })

  # --- Scenario story ---------------------------------------------------------
  output$scenario_story <- renderUI({
    T_05_02_story_fn(scn_now(), B_03_04_controls_lst, B_03_05_help_lst)
  })

  # --- The model so far -------------------------------------------------------
  output$eq_title <- renderText({
    T_05_04_stage_name_fn(B_03_02_stages_vec, input$stage)
  })

  eq_items <- reactive(T_06_03_items_fn(B_03_07_equations_lst, stage_num()))

  output$eq_model <- renderUI({
    T_06_04_model_fn(eq_items(), B_03_08_groups_vec,
                     "These appear as the later stages add to the model.")
  })

  output$eq_notation <- renderUI({
    T_06_05_notation_fn(B_03_09_notation_lst, stage_num(),
                        B_03_10_nota_cols_lst, first_stage = 1)
  })

  output$eq_explain <- renderUI({
    T_06_06_explain_fn(eq_items(), B_03_08_groups_vec)
  })

  # --- Prompt and problems ----------------------------------------------------
  output$prompt <- renderUI({
    T_07_12_prompt_fn(scn_now(), input$stage, B_03_06_prompts_lst)
  })

  output$problems <- renderUI(T_07_13_problems_fn(diag_now()$problems))

  # --- Readouts ---------------------------------------------------------------
  output$tiles <- renderUI({
    d <- diag_now()
    s <- stage_num()
    T_04_03_row_fn(
      T_04_01_tile_fn(
        "MPC out of a windfall", T_02_05_num_fn(d$mpc, 3),
        paste0("Over ", par_now()$horizon, " periods of life")
      ),
      T_04_01_tile_fn(
        "Consumption today", T_02_05_num_fn(d$c_now, 2),
        paste0("Lifetime resources ", T_02_05_num_fn(d$wealth, 0))
      ),
      T_04_01_tile_fn(
        "Consumption growth", T_02_05_num_fn(d$growth, 4),
        if (d$flat) "Flat: β(1+r) = 1" else
          if (d$growth > 1) "Tilted towards the future" else
            "Tilted towards the present",
        class = if (d$flat) "good" else ""
      ),
      if (s >= 3) {
        T_04_01_tile_fn(
          "Permanent income limit", T_02_05_num_fn(d$mpc_long, 3),
          "r/(1+r), as life grows long"
        )
      },
      if (s >= 4) {
        T_04_01_tile_fn(
          "Pass-through of a shock", T_02_05_num_fn(d$smooth, 3),
          paste0("At persistence ", T_02_05_num_fn(par_now()$persist, 2))
        )
      },
      if (s >= 5) {
        T_04_01_tile_fn(
          "Effect of the tax cut", T_02_05_num_fn(d$ric_effect, 2),
          if (d$ricardian) "Ricardian equivalence holds" else
            paste0(T_02_06_pct_fn(d$ric_share, 0), " of the cut is spent"),
          class = if (d$ricardian) "good" else "bad"
        )
      },
      if (s >= 6) {
        T_04_01_tile_fn(
          "Precautionary saving", T_02_05_num_fn(prec_now()$buffer, 2),
          paste0("ασ²/(2r): ", T_02_06_pct_fn(prec_now()$share, 1),
                 " of consumption held back")
        )
      },
      if (s >= 6) {
        T_04_01_tile_fn(
          "Expected rise in consumption",
          T_02_05_num_fn(prec_now()$drift, 3),
          if (prec_now()$drift > 1e-9) "ασ²/2 a period: not a random walk"
            else "Zero: certainty equivalence is back",
          class = if (prec_now()$drift > 1e-9) "bad" else "good"
        )
      }
    )
  })

  # --- Figures ----------------------------------------------------------------
  output$two_period <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() <= 2, par_now()$horizon == 2)
    D_01_04_two_period_fn(par_now())
  }) })

  output$plan <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_01_plan_fn(par_now(), ref = ghost_par())
  }) })

  output$horizon <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_03_horizon_fn(par_now(), ref = ghost_par())
  }) })

  output$response <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 3)
    D_02_01_response_fn(par_now())
  }) })

  output$path <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 4)
    D_02_02_path_fn(par_now(), ref = ghost_par())
  }) })

  output$breaks <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 5)
    D_03_01_breaks_fn(par_now())
  }) })

  output$prec_path <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 6)
    D_04_01_prec_path_fn(par_now(), ref = ghost_par())
  }) })

  output$prec_buffer <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 6)
    D_04_02_buffer_fn(par_now(), ref = ghost_par())
  }) })

  output$prec_note <- renderUI({
    req(stage_num() >= 6)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "Certainty Equivalence and Its Failure"),
      tags$p(HTML(paste(
        "The only thing that changed between stage 4 and here is the third",
        "derivative of utility. Quadratic utility has u''' = 0, so",
        "&sigma;<sup>2</sup> cannot enter the consumption function: that is",
        "certainty equivalence, and it is what makes the random walk exact.",
        "CARA has u''' &gt; 0. The same &sigma;<sup>2</sup> now lowers",
        "consumption today by &alpha;&sigma;<sup>2</sup>/(2r) and makes it",
        "drift up by &alpha;&sigma;<sup>2</sup>/2 a period."
      ))),
      tags$p(HTML(paste(
        "The buffer is linear in &alpha; because under CARA absolute",
        "prudence, &minus;u'''/u'', and absolute risk aversion,",
        "&minus;u''/u', are both equal to &alpha;. Risk aversion is how much",
        "the consumer dislikes the risk; prudence is how much they do about",
        "it. CARA collapses the two into one number, which is why the exam",
        "question uses it."
      ))),
      tags$p(HTML(paste(
        "So the random walk is a prediction of the permanent income",
        "hypothesis plus quadratic utility, not of the hypothesis alone.",
        "Any utility with convex marginal utility predicts that consumption",
        "rises in expectation, and by more where income risk is larger.",
        "That is testable, and it is much of why buffer stock models",
        "replaced the pure random walk."
      )))
    )
  })

  output$ric_note <- renderUI({
    req(stage_num() >= 5)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "Testing Ricardian Equivalence"),
      tags$p(HTML(paste(
        "Government debt is not net wealth. A tax cut today is a tax rise",
        "tomorrow of the same present value, so a forward-looking consumer",
        "saves the whole thing and private saving rises one for one with",
        "public dissaving."
      ))),
      tags$p(HTML(paste(
        "The test is a tax change announced in advance, so the news and",
        "the money arrive at different times. If consumption moves when the",
        "money arrives rather than when the news does, the theory fails.",
        "The same design tests the random walk in stage 4."
      ))),
      tags$p(HTML(paste(
        "Consumption does respond to predictable income, and by more than",
        "the theory allows. The usual reading is that a large share of",
        "income goes to households that are credit constrained or not",
        "looking far ahead: the &lambda; on the left, and the high-MPC",
        "households in the Keynesian multiplier app. Campbell and Mankiw's",
        "&lambda; &asymp; 0.5 is an income share, and those households earn",
        "less than average, so the share of households behaving this way is",
        "higher still."
      )))
    )
  })
}

################################################################################
## G: Run ######################################################################
################################################################################
# Note: Launch.

#### G_01: Launch ##############################################################
# Note: Returns the app object.

###### G_01_01: The App ########################################################
# Note: UI from E, server from F.

G_01_01_app_lst <- shinyApp(E_02_02_app_ui_lst, F_01_01_app_server_fn)

G_01_01_app_lst
