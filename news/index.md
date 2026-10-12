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
