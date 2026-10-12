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
  the MCID (the midpoint, for ranges), capped at 3x.
* **MCID default palette.** The specification listed `palette = "grey"` in
  the `geom_mcid_zones()` signature but described the default as a muted
  colourblind-safe diverging pair. The default is the diverging palette
  (`"diverging"`, blue/orange with a neutral centre); `"grey"` is available
  and documented with the recommendation to use `labels = TRUE`.
  **Open question:** confirm which default is wanted.
* **Zone labels** (`labels = TRUE`) are dropped at draw time when the text
  does not fit inside its zone, rather than overlapping.
* **`plot_contrasts()` and the SD.** `TukeyHSD` objects and data frames do
  not carry their model, so the SD comes from an explicit `model =`
  argument; `emmGrid` objects from `emmeans()` carry `sigma`, but grids from
  `contrast()`/`pairs()` do not, so they also need `model =` (the emmeans
  grid or the fit). The function never refits a model from a stored call.
* Extra arguments beyond the specification: `label_size`, `label_colour`,
  `n_slices`, `title`, `show.legend` on both layers; `mcid` (symmetric
  shorthand) on `mcid_thresholds()`; `direction` on `mcid_distribution()`;
  `which`, `model`, `null`, `xlab` on `plot_contrasts()` methods.

## Open questions

* Is the residual SD the right default for converting d over ANOVA
  contrasts, or should `plot_contrasts()` refuse to guess and require `sd`?
  Currently it uses `pooled_sd(model)` only when `model` is passed, and
  says so.
* Multiples for an uncertain (range) MCID use the midpoint. Alternatives:
  fade the multiples too, or omit multiples for ranges.
* Should zones outside the visible panel be dropped from the legend? They
  are kept so the legend always shows the full scheme in a fixed order.
* `"chen_or"` is tied to a 1% baseline risk. A function that returns the
  Chen et al. equivalents for other baseline risks would be more honest,
  but needs their method implemented and checked.
* Labels for the innermost zone ("negligible") are this package's
  convention, not the sources'. Some users may prefer "below small".

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
* DOIs are given only where they were verified against a bibliographic
  record (Funder & Ozer 2019; Gignac & Szodorai 2016; Jaeschke et al.
  1989). Other references are cited without DOIs.
