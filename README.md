# Interactive Model: Consumption

A Shiny app for teaching the theory of consumption: the Euler equation,
the permanent income hypothesis, the random walk, Ricardian equivalence and
precautionary saving. Built by [Sam Deegan](https://sam-deegan.com) for
ECON42550 Macroeconomics, University College Dublin.

**Try it in the browser (nothing to install):**
https://sam-deegan.com/toy-models/consumption/

Current version: **1.0.7** (see [CHANGELOG.md](CHANGELOG.md)). The version
is shown in the app footer; releases are tagged `vX.Y.Z`.

## What it does

The stage selector builds the model up one layer at a time:

| Stage | What is added |
|---|---|
| 1 | Two periods, the Euler equation, and a transfer today: the consumption plan and the two-period diagram |
| 2 | The windfall and the horizon: why the MPC falls as life lengthens |
| 3 | Permanent income: a temporary against a permanent change in income |
| 4 | Uncertainty: income shocks, the random walk, and how much of a shock passes through |
| 5 | Ricardian equivalence: a debt-financed tax cut, and the two things that break it |
| 6 | Precautionary saving: CARA utility, and why the variance of income suddenly matters |

Each stage opens on a worked example (the sample paper's two-period case,
a patient consumer, a long life, transitory and permanent income shocks, a
debt-financed tax cut, a calm and a risky environment). Every slider has a
box beside it for an exact value, and a faded ghost of the loaded example
stays on each figure once a slider moves. The Equations, Notation and In
Words tabs show the model as it stands at the chosen stage and flag what
that stage changed.

## Run it locally

1. Install [R](https://cran.r-project.org/) (4.1 or later) and, ideally,
   [RStudio](https://posit.co/download/rstudio-desktop/).
2. Install the three packages once:

   ```r
   install.packages(c("shiny", "bslib", "ggplot2"))
   ```

3. Open `app.R` in RStudio and click **Run App**, or from R in this folder:

   ```r
   shiny::runApp()
   ```

Equations are typeset with MathJax from a CDN, so they need an internet
connection; everything else runs offline.

## Files

```
app.R          the app: settings and text (section B), figures (D),
               interface (E), server (F)
R/model.R      the model: the consumer's problem, the plan, the MPC, the
               random walk, Ricardian equivalence, precautionary saving.
               Sources on its own, so slides can reuse it.
R/toolkit.R    layout and helpers shared with the other toy-model apps
README.md      this file
CHANGELOG.md   version history
CONVENTIONS.md how the figures and worked examples are laid out
LICENSE        CC BY-NC-ND 4.0
```

All text on screen (worked examples, prompts, equations, notation) is in
section `B_03` of `app.R`, so it can be edited without touching the rest.

## The model

The consumer of the life-cycle / permanent-income hypothesis: a household
that chooses a path of consumption to maximise lifetime utility subject to
a lifetime budget constraint, and so smooths consumption against income. It
is the model of Romer's *Advanced Macroeconomics* (chapter 8), with the
fiscal application of chapter 13 (Ricardian equivalence). Amounts are in
euro per period; `r` is the real interest rate as a decimal.

```
Problem:  max  sum_{t=0}^{T-1} beta^t u(C_t),   u(C) = (C^(1-rho) - 1)/(1 - rho)
BC:       sum_t C_t / (1+r)^t = A_0 + sum_t Y_t / (1+r)^t = W
Euler:    u'(C_t) = beta (1+r) u'(C_{t+1})   so   C_{t+1}/C_t = [beta (1+r)]^(1/rho) = g
Plan:     C_0 = W / S,   S = sum_{t=0}^{T-1} (g / (1+r))^t
Income:   y_t = ybar + phi (y_{t-1} - ybar) + eps_t
Random walk:   Delta C_t = r eps_t / (1 + r - phi)
Government:    a tax cut Delta T_0 today, repaid with interest at period k
CARA:     U(C) = -(1/alpha) exp(-alpha C),   alpha > 0
          E_t C_{t+1} = C_t + alpha sigma^2 / 2
          C_t = [r/(1+r)] W_t - alpha sigma^2 / (2r)
```

**The problem and the budget constraint** say the consumer cares about the
whole path of consumption and can borrow and lend freely at `r`, so only
the present value of income matters, not its timing. `beta` is the
discount factor, `rho` the curvature of utility (how badly the consumer
wants a smooth path), `A_0` the assets at the start of life and `T` the
periods of life remaining. `W` is lifetime resources.

**The Euler equation** says the consumer is indifferent at the margin
between a euro today and its proceeds tomorrow. With CRRA utility
consumption grows by the constant factor `g` each period: flat when
`beta (1+r) = 1`, rising when the interest rate beats impatience. In the
two-period diagram it is the tangency of an indifference curve with the
budget line of slope `-(1+r)`.

**The plan** divides lifetime resources by the annuity factor `S`, so the
marginal propensity to consume out of a one-off windfall `tau` is `1/S`.
Two periods with `r = 0` and `beta = 1` give one half; as life lengthens
the MPC falls to `r/(1+r)`, the permanent income limit.

**Income and the random walk** make income an AR(1) process with
persistence `phi` and shocks `eps_t` of standard deviation `sigma`. With
quadratic utility and `beta (1+r) = 1`, consumption changes only with news,
by the annuity value of that news: almost nothing at `phi = 0`, one for one
at `phi = 1`.

**The government** cuts taxes by `Delta T_0` today and raises them by the
same amount plus interest at period `k`. For a consumer alive at `k` the
present value of the two changes is zero, so consumption does not move. A
share `lambda` of income going to hand-to-mouth consumers, or a bill that
arrives after death (`k > T`), breaks the result.

**CARA utility** replaces quadratic utility at stage 6. Marginal utility is
now convex, so the consumer is prudent as well as risk averse: with
`beta (1+r) = 1` and normal shocks, consumption is expected to rise by
`alpha sigma^2 / 2` a period, and consumption today is held
`alpha sigma^2 / (2r)` below the certainty-equivalent level `[r/(1+r)] W`.
`alpha` is the coefficient of absolute risk aversion, which under CARA is
also the coefficient of absolute prudence.

The model is solved in closed form: the growth factor, the annuity factor
and the MPC are formulas, the income and consumption paths are simulated
from a fixed seed, and the Ricardian and CARA results are evaluated
directly. There is no numerical optimiser.

**What the six stages show with it**

- *1* The Euler equation as a tilt in the plan and as a tangency in the
  two-period diagram. With `r = 0` and `beta = 1` a transfer of `tau` raises
  consumption today by `tau / 2`: the sample paper's answer.
- *2* The MPC out of a windfall falls with the horizon, from one half at two
  periods towards `r/(1+r)`: a temporary transfer is spread over the whole
  of life, so fiscal transfers have little power to stimulate.
- *3* A permanent rise in income is consumed as it arrives; a one-off rise
  barely moves consumption. Only the news changed, not the consumer.
- *4* Consumption is a random walk: its level wanders but its changes are
  unforecastable, and how much of a shock passes through is set by `phi`.
- *5* A debt-financed tax cut does nothing to a forward-looking consumer who
  expects to pay the bill. Hand-to-mouth income and a bill arriving after
  death each break the result; together they do nearly all the work.
- *6* Under quadratic utility the variance of income does nothing to the
  level of consumption (certainty equivalence). Under CARA the same
  uncertainty lowers consumption today and tilts the path upwards, and
  setting `alpha` to zero closes the gap: prudence, not risk, does the work.

**Where it departs from the textbook.** Stages 1 to 3 use CRRA utility so
the tilt of the plan can be shown; the random walk of stage 4 is the
quadratic-utility result, evaluated with the annuity-value pass-through
rather than re-solved. The Ricardian block is a present-value accounting
identity with two switches, not a model of overlapping generations. Stage 6
takes income shocks to be permanent, so `sigma` is the standard deviation
of the news in consumption itself, and the consumer there lives for ever,
so `r` must be above zero. The model has no credit constraints, no labour
supply, no durable goods and no general equilibrium: `r` is given.

## References

- Romer, D. (2019). *Advanced Macroeconomics*, 5th ed. Chapters 8 and 13.
- Whelan, K. (2023). *Lecture Notes on Macroeconomics*. Figures 11.2 and
  11.3.
- Hall, R. E. (1978). Stochastic implications of the life cycle-permanent
  income hypothesis: theory and evidence. *Journal of Political Economy*
  86(6).
- Campbell, J. Y. and Mankiw, N. G. (1989). Consumption, income and
  interest rates: reinterpreting the time series evidence. *NBER
  Macroeconomics Annual* 4.
- ECON42550 Part 2 sample paper (question 3) and 2023 paper (question 2).

## Licence

© Sam Deegan. Released under
[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/):
free to use and share for teaching with attribution; not for commercial use
or redistribution in modified form.
