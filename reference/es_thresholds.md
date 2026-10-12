# Effect-size thresholds

Define the cut-points that separate effect-size magnitude zones
("negligible", "small", "medium", ...). The cut-points are positive
magnitudes and, by default, are applied symmetrically around the null: a
cut at `0.5` produces boundaries at `-0.5` and `+0.5` for additive
metrics, and at `1/c` and `c` for ratio metrics (`"or"`, `"rr"`). Use
`cuts_lower` when the two sides differ.

## Usage

``` r
es_thresholds(
  cuts,
  labels,
  metric = c("d", "r", "eta2", "f", "or", "rr", "raw"),
  source = NULL,
  cuts_lower = NULL
)
```

## Arguments

- cuts:

  Positive, strictly increasing magnitudes. For ratio metrics (`"or"`,
  `"rr"`) they must be greater than 1.

- labels:

  Character vector of zone names, one more than `cuts`. The first label
  names the zone between the null and the first cut (often
  "negligible"), the last names the zone beyond the last cut.

- metric:

  The effect-size metric the cuts are expressed in: `"d"` (standardised
  mean difference), `"r"` (correlation), `"eta2"` (eta-squared), `"f"`
  (Cohen's f), `"or"` (odds ratio), `"rr"` (risk ratio) or `"raw"`
  (unstandardised units of the outcome).

- source:

  Optional character string citing where the cuts come from. It is shown
  in the legend title, so keep it short or use the `title` argument of
  [`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md).

- cuts_lower:

  Optional magnitudes for the side below the null when it differs from
  the side above (same length as `cuts`, same labels). A value `c` is
  drawn at `null - c`, or at `null / c` for ratio metrics. Defaults to
  `cuts` (symmetric zones).

## Value

An object of class `es_thresholds`: a list with elements `cuts`,
`cuts_lower`, `labels`, `metric`, `source` and `title` (the short legend
title).

## Details

These objects contain no data and make no claim about any estimate. They
only describe where to draw background boundaries; see
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md).
For published benchmark sets use
[`es_benchmarks()`](https://drhrf.github.io/effectzones/reference/es_benchmarks.md).

## See also

[`es_benchmarks()`](https://drhrf.github.io/effectzones/reference/es_benchmarks.md),
[`to_plot_scale()`](https://drhrf.github.io/effectzones/reference/to_plot_scale.md),
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)

## Examples

``` r
es_thresholds(c(0.1, 0.3), c("trivial", "modest", "substantial"),
              metric = "d", source = "Pre-registered, protocol v2")
#> <es_thresholds> on the "d" scale
#> trivial: magnitude in [0, 0.1)
#> modest: magnitude in [0.1, 0.3)
#> substantial: magnitude in [0.3, Inf)
#> Source: Pre-registered, protocol v2
```
