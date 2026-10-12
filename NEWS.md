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
* `chen_or_thresholds()` computes the Chen, Cohen & Chen (2010) odds-ratio
  equivalents of d for any baseline risk. Under their method protective
  and harmful zones are not mirror images, so the zones below 1 are computed
  from negative d (also in `es_benchmarks("chen_or")`).
* `es_thresholds()` gains `cuts_lower` for asymmetric effect-size zones.
* Both layers gain `zone_labels` to rename zones (all at once or by name).
* The legend lists only the zones that appear in the plot.
* `plot_contrasts()` accepts `aov` fits and emmeans grids of means directly,
  and recovers the model behind a `TukeyHSD` object (verified against the
  contrasts). The model's residual SD is used automatically only for one-way
  models; otherwise `sd` must be given.
* `geom_mcid_zones(beyond = "multiples")` now requires point MCID
  thresholds; with a range MCID the multiples would be uncertain too, so the
  combination is an error.
* DOIs added for all cited references.
