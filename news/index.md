# Changelog

## effectzones 0.0.0.9000

- Initial prototype.
- [`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)
  draws effect-size magnitude zones;
  [`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md)
  draws harm / trivial / benefit zones from an MCID. Both share one
  engine, leave the axis limits alone by default, support soft
  boundaries, either axis orientation,
  [`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html),
  facets and transformed scales.
- Threshold objects:
  [`es_thresholds()`](https://drhrf.github.io/effectzones/reference/es_thresholds.md),
  [`es_benchmarks()`](https://drhrf.github.io/effectzones/reference/es_benchmarks.md),
  [`mcid_thresholds()`](https://drhrf.github.io/effectzones/reference/mcid_thresholds.md),
  [`mcid_distribution()`](https://drhrf.github.io/effectzones/reference/mcid_distribution.md);
  conversion with
  [`to_plot_scale()`](https://drhrf.github.io/effectzones/reference/to_plot_scale.md)
  and
  [`pooled_sd()`](https://drhrf.github.io/effectzones/reference/pooled_sd.md).
- [`plot_contrasts()`](https://drhrf.github.io/effectzones/reference/plot_contrasts.md)
  for `TukeyHSD`, emmeans contrasts and data frames.
- [`chen_or_thresholds()`](https://drhrf.github.io/effectzones/reference/chen_or_thresholds.md)
  computes the Chen, Cohen & Chen (2010) odds-ratio equivalents of d for
  any baseline risk. Under their method protective and harmful zones are
  not mirror images, so the zones below 1 are computed from negative d
  (also in `es_benchmarks("chen_or")`).
- [`es_thresholds()`](https://drhrf.github.io/effectzones/reference/es_thresholds.md)
  gains `cuts_lower` for asymmetric effect-size zones.
- Both layers gain `zone_labels` to rename zones (all at once or by
  name).
- The legend lists only the zones that appear in the plot.
- [`plot_contrasts()`](https://drhrf.github.io/effectzones/reference/plot_contrasts.md)
  accepts `aov` fits and emmeans grids of means directly, and recovers
  the model behind a `TukeyHSD` object (verified against the contrasts).
  The model’s residual SD is used automatically only for one-way models;
  otherwise `sd` must be given.
- `geom_mcid_zones(beyond = "multiples")` now requires point MCID
  thresholds; with a range MCID the multiples would be uncertain too, so
  the combination is an error.
- DOIs added for all cited references.
- When
  [`plot_contrasts()`](https://drhrf.github.io/effectzones/reference/plot_contrasts.md)
  cannot choose an SD for d (models with more than one term), the error
  now explains the rigorous procedure step by step, with a refit command
  tailored to the plotted term.
- Package website: flatly theme, hex logo, and a new article, *The
  mathematics behind effectzones*, with step-by-step interactive
  calculators for every calculation the package performs.
