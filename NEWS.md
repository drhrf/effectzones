# effectzones 0.0.0.9000

* Initial prototype.
* `geom_es_zones()` draws effect-size magnitude zones; `geom_mcid_zones()`
  draws harm / trivial / benefit zones from an MCID. Both share one engine,
  leave the axis limits alone by default, support soft boundaries, either
  axis orientation, `coord_flip()`, facets and transformed scales.
* Threshold objects: `es_thresholds()`, `es_benchmarks()`,
  `mcid_thresholds()`, `mcid_distribution()`; conversion with
  `to_plot_scale()` and `pooled_sd()`.
* `plot_contrasts()` for `TukeyHSD`, emmeans contrasts and data frames.
