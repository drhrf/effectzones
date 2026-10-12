# effectzones: design notes

Prototype, version 0.0.0.9000. This file records scope decisions, open
questions and unfinished work.

## Principle

The package draws a background; it never looks at the estimates. Where a
choice has interpretive consequences the conservative option is
implemented and documented.

## Scope decisions

### Deliberately out of scope

* **No classification of estimates or intervals.** There is no function
  that assigns an estimate or a CI to a zone, labels results as
  "meaningful" or "likely beneficial", or computes the probability that an
  effect lies in a zone. That is magnitude-based inference (Batterham &
  Hopkins 2006), criticised by Welsh & Knight (2015) and Sainani (2018).
  The vignette explains this to users.
* **No combined ES + MCID background** in v0.1. Two backgrounds in one
  panel would be unreadable and invite reading one scale through the
  other. Use facets or two plots.
* **No default benchmark set** in `geom_es_zones()`: calling it without
  `thresholds` is an error listing `es_benchmarks()` options. Cohen called
  his values a fallback.
* **No automatic MCID.** A distribution-based value requires an explicit
  `mcid_distribution()` call and is marked provisional in the legend.

### Implementation choices

* **Zones are layer parameters, not aesthetics.** A stat computes the zone
  rectangles per panel in the scale's transformed space and returns them
  in columns ggplot2 does not treat as positions, so the scales are not
  trained (`expand = FALSE`). With `expand = TRUE` the same rectangles are
  returned as `xmin`/`xmax` (or `ymin`/`ymax`), so every finite boundary
  trains the scale. The geom clips to the panel range from
  `coord$backtransform_range()` and delegates drawing to `GeomRect`, which
  handles `coord_flip()`, facets and coord limits.
* **Lazy layer construction.** `geom_es_zones()`/`geom_mcid_zones()` return
  an `effectzones_zones` object that becomes a layer plus a manual scale in
  `ggplot_add()`. This lets `plot_contrasts()` fill a missing `sd` from the
  model before the layer is built.
* **Legend through private aesthetics** (`es_zone`, `mcid_zone`) with a
  manual scale, so the zones never interfere with a `fill` scale used by
  other layers. Zone colours (including interpolated transition slices) are
  carried in a non-aesthetic column.
* **Soft boundaries** are `n_slices` rectangles interpolated in CIELAB
  (`scales::colour_ramp()`). Transition width is `softness` times the
  threshold (on the log scale for ratio zones), centred on the threshold.
  Neighbouring transitions that would overlap are shrunk to the midpoint.
* **MCID thresholds** are positions on the difference scale relative to
  the null (`lower < 0 < upper`); `direction` decides which side is
  benefit. A length-2 value is an uncertain threshold, drawn as a fade
  across the range. `beyond = "multiples"` deepens the colour at 2x and 3x
  the MCID, capped at 3x. It requires point thresholds: with a range MCID
  the multiples would be uncertain as well, and sharp lines at 2x/3x would
  overstate precision, so the combination is an error (decided by the
  author over fading the multiples, which overlap for wide ranges).
* **MCID default palette:** the muted blue/orange diverging palette
  (`"diverging"`), confirmed by the author; `"grey"` remains available with
  `labels = TRUE` recommended.
* **Zone labels** (`labels = TRUE`) are dropped at draw time when the text
  does not fit inside its zone, rather than overlapping.
* **`plot_contrasts()` and the SD.** Standardised thresholds over raw
  differences need an SD. The model's residual SD is used automatically
  only for a one-way, fixed-effects, unweighted linear model, where it is
  the pooled within-group SD (the conventional denominator of d, under the
  same equal-variance assumption as the ANOVA and Tukey intervals). With
  more terms the residual SD has every other term's variance removed:
  right for manipulated factors, too small for measured factors and
  covariates, and the model does not record which is which. The function
  stops with an error that teaches the procedure: decide what SD the
  benchmark refers to; prefer an external pre-specified SD; otherwise refit
  with only the manipulated factors (Olejnik & Algina 2003 generalized
  standardizer); report the SD's sampling uncertainty. The model can come
  from an `aov` fit, an emmeans grid of
  means (which carries `sigma`), or a `TukeyHSD` object: its stored call is
  re-evaluated in the calling environment and the refit is accepted only if
  it reproduces the Tukey contrasts exactly. emmeans contrast grids drop
  `sigma`, so they need `model =` or `sd`.
* **Chen et al. odds ratios.** `chen_or_thresholds(baseline_risk)`
  implements p1 = Phi(Phi^-1(p0) + d) and OR = odds(p1) / odds(p0); it
  reproduces the published 1% and 5% rows. Under this model the protective
  side is not the reciprocal of the harmful side (except at p0 = 0.5), so
  the boundaries below 1 are computed from negative d (`cuts_lower`). The
  published values cover only OR > 1; the lower side in
  `es_benchmarks("chen_or")` (1.74, 4.28, 11.40, rounded) is computed, not
  published, and the source text says so.
* **Legend shows only visible zones.** The stat drops zones that lie
  entirely outside the axis range trained so far (including the scale's
  expansion). Coordinate limits (`coord_cartesian(xlim)`) and ranges
  created later by other layers' stats are not known at that stage, so in
  those cases the legend can list a zone that is clipped away.
* **Renaming zones:** `zone_labels` on both layers, either a full unnamed
  vector/list or a named partial mapping.
* Extra arguments beyond the specification: `label_size`, `label_colour`,
  `n_slices`, `zone_labels`, `title`, `show.legend` on both layers;
  `cuts_lower` on `es_thresholds()`; `chen_or_thresholds()`; `mcid` (symmetric
  shorthand) on `mcid_thresholds()`; `direction` on `mcid_distribution()`;
  `which`, `model`, `null`, `xlab`, `conf.level` on `plot_contrasts()`
  methods, and an `aov` method.

## Open questions

* **Drawing the SD's sampling uncertainty** (step 4 of the SD procedure).
  The boundaries d x SD could fade across d x [lower, upper] of the SD's
  confidence interval (chi-square interval on the residual df), reusing the
  range-MCID fade. Not implemented; the error message and vignette tell
  users to report it.
* **A `measured =` helper**, e.g. `pooled_sd(model, measured = "sex")`,
  that refits without the named terms. Currently users call
  `pooled_sd(update(model, . ~ treatment))` themselves.

* Some users may prefer that `chen_or_thresholds()` also accept the
  baseline risk of the exposed group (i.e. odds ratios expressed the other
  way round); currently `baseline_risk` must refer to the reference
  (denominator) group.

## Unfinished / known limitations

* **Development environment.** The prototype was built in a sandbox whose
  R package mirror was unavailable; the system packages provided ggplot2
  3.4.4, below the declared `ggplot2 (>= 3.5.0)`. Local `R CMD check
  --as-cran` and tests were run against 3.4.4 with the floor temporarily
  relaxed in a scratch copy; GitHub Actions checks against current CRAN
  releases.
* **vdiffr snapshots are per ggplot2 version** (`_snaps/ggplot2-X.Y/`).
  References exist for ggplot2 3.4 (recorded in the development sandbox)
  and 4.0 (recorded on GitHub Actions, ubuntu-latest, R 4.6.1, then
  reviewed). Snapshot tests are skipped when no reference exists for the
  installed version; to add one, run the tests with
  `EFFECTZONES_RECORD_SNAPSHOTS=true` (and `CI=false`, since recent
  testthat fails on new snapshots on CI) and review with
  `testthat::snapshot_review()`.
* Non-linear coordinate systems (`coord_polar()`, `coord_trans()`) are not
  tested.
* Seams between transition slices: with semi-transparent fills, some PDF
  viewers may show hairlines between adjacent slices at extreme zoom.
* DOIs for all cited references are included. Funder & Ozer (2019),
  Gignac & Szodorai (2016) and Jaeschke et al. (1989) were verified against
  bibliographic records during development; the others were supplied by
  the author.
