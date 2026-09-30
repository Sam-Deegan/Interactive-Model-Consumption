# Changelog

All notable changes to this app. Versions follow [Semantic Versioning](https://semver.org/):
MAJOR for a change to the model or its notation, MINOR for new features
(a stage, a worked example, a figure), PATCH for fixes and wording.
Each release is tagged in git as `vX.Y.Z` and shown in the app footer.

## [1.0.8] - 2026-09-28

### App
- Figure titles are back, on the page: each figure's title (with its
  live numbers) is the card header and its subtitle sits above the image,
  so the PNG itself stays bare for slides with their own captions.
- The stage name and the Equations tabs sit on one line with no rule
  under them. The card opens folded, with the stage name drawn as the
  selected tab, so the worked examples and figures sit high on the page;
  a tab opens it and the stage name folds it again.
- Every figure box is 3:2 at any width, and the theme holds the image at
  3:2 inside it.

## [1.0.7] - 2026-09-28

### App
- The notes under the figures are rewritten as short plain prose: no bold
  lead-in sentences, one point per paragraph.

## [1.0.6] - 2026-09-28

### App
- Card headers in the blue used for headings, not body grey.

## [1.0.5] - 2026-09-28

### App
- Cards have no border or header rule: figures, equations and stories sit
  on the page separated by whitespace alone.

## [1.0.4] - 2026-09-28

### App
- Cards, panels, tiles and buttons are square with no shadow: they organise
  the page rather than decorate it.

## [1.0.3] - 2026-09-28

### App
- The QR code returns to the foot of the sidebar, with the name and site
  address, alongside the small one in the title bar.

## [1.0.2] - 2026-09-28

### App
- No figure carries a title or subtitle inside the image; the card header
  and the caption under it name and explain the figure (CONVENTIONS.md 6).
- Figures are drawn on a white ground, so the image sits flat in its card
  instead of showing as a tinted tile.
- The precautionary-saving figure is drawn at 3:2, not square.

## [1.0.1] - 2026-09-28

### App
- The In Words tab lays out its three columns at fixed widths, so an
  equation no longer collapses to one term per line beside its note.
- The preset card no longer doubles the word "Stage" in front of a stage
  name that already carries it.

## [1.0.0] - 2026-09-28

First public release as a standalone repository.

### Model
- A T-period consumer with CRRA utility: the Euler equation, the annuity
  factor, the MPC out of a windfall and its permanent income limit
  r/(1+r), following Romer (2019) ch. 8.
- An AR(1) income process and the random-walk pass-through
  r/(1 + r - phi); a debt-financed tax cut with the two switches that break
  Ricardian equivalence (Romer ch. 13).
- Precautionary saving under CARA utility: the drift alpha sigma^2/2 and
  the buffer alpha sigma^2/(2r), as in question 2 of the 2023 paper.
- The two-period diagram (budget line and indifference curves) is drawn
  from the same solution as the consumption plan.

### App
- Six stages that add one layer of the model at a time.
- Ten worked examples, each stage opening on its first.
- Equations, Notation and In Words tabs that track the model at each stage.
- Eight readout tiles, warnings when the calibration stops making sense,
  and narrative cards on Ricardian equivalence and certainty equivalence.
- Ghost curves showing the loaded worked example alongside the live sliders.
