# Convert thresholds to the scale of the plot axis

Thresholds are defined on the scale of an effect-size metric; estimates
are often plotted on another scale (raw mean differences, odds ratios).
`to_plot_scale()` converts thresholds to the axis on which the estimates
are drawn.
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)
and
[`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md)
call it for you; use it directly to inspect the boundaries that will be
drawn.

## Usage

``` r
to_plot_scale(thresholds, sd = NULL, scale = c("identity", "log"))
```

## Arguments

- thresholds:

  An
  [`es_thresholds()`](https://drhrf.github.io/effectzones/reference/es_thresholds.md)
  or
  [`mcid_thresholds()`](https://drhrf.github.io/effectzones/reference/mcid_thresholds.md)
  object.

- sd:

  Standard deviation used for conversion between standardised and raw
  units, or `NULL`.

- scale:

  `"identity"` (additive zones, `null +/- cut`) or `"log"`
  (multiplicative zones, `null * cut` and `null / cut`).

## Value

An object of the same class with converted thresholds. The `scale`
element records whether zones are additive or multiplicative and `note`
describes the conversion.

## Effect-size thresholds

- `d` with `sd`: cuts are multiplied by `sd` to give raw differences.
  Which SD to use is a substantive choice; for contrasts from a linear
  model the residual SD
  ([`pooled_sd()`](https://drhrf.github.io/effectzones/reference/pooled_sd.md))
  is the usual one, but a baseline or reference-population SD may be
  more appropriate.

- `d` with `scale = "log"`: cuts are converted to odds ratios with
  `log(OR) = d * pi / sqrt(3)` (Chinn 2000). This is an approximation
  that assumes an underlying logistic distribution; it is not the same
  mapping as
  [es_benchmarks("chen_or")](https://drhrf.github.io/effectzones/reference/es_benchmarks.md).

- `or`/`rr` with `scale = "log"`: zones are symmetric on the log scale
  around the null: a cut `c` gives boundaries `null / c` and `null * c`.
  Use with `null = 1` and a log axis (e.g.
  [`ggplot2::scale_x_log10()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)).

- `or`/`rr` with `scale = "identity"`: for an axis showing log ratios on
  a linear scale; cuts become `-log(c)` and `log(c)` around `null = 0`.

- `r`, `eta2`, `f`: drawn on their own scale only. There is no
  conversion to raw differences.

## MCID thresholds

MCIDs are already on the raw scale. If `sd` is given they are divided by
it, for an axis showing standardised differences.

## References

Chinn S (2000). A simple method for converting an odds ratio to effect
size for use in meta-analysis. *Statistics in Medicine*
19(22):3127-3131.

## Examples

``` r
to_plot_scale(es_benchmarks("cohen_d"), sd = 2)
#> <es_thresholds> on the "raw" scale
#> negligible: |effect| in [0, 0.4)
#> small: |effect| in [0.4, 1)
#> medium: |effect| in [1, 1.6)
#> large: |effect| in [1.6, Inf)
#> Source: Cohen J (1988). Statistical Power Analysis for the Behavioral Sciences,
#> 2nd ed. Hillsdale, NJ: Lawrence Erlbaum. Cohen offered these values as
#> conventions for use only when no better basis for judging magnitude is
#> available.
#> Note: d cut-points multiplied by SD = 2.
to_plot_scale(es_benchmarks("cohen_d"), scale = "log")
#> <es_thresholds> on the "or" scale
#> negligible: |effect| in [1, 1.44)
#> small: |effect| in [1.44, 2.48)
#> medium: |effect| in [2.48, 4.27)
#> large: |effect| in [4.27, Inf)
#> Source: Cohen J (1988). Statistical Power Analysis for the Behavioral Sciences,
#> 2nd ed. Hillsdale, NJ: Lawrence Erlbaum. Cohen offered these values as
#> conventions for use only when no better basis for judging magnitude is
#> available.
#> Note: Approximation: log(OR) = d * pi / sqrt(3) (Chinn 2000), which assumes a
#> logistic latent variable.
to_plot_scale(es_benchmarks("chen_or"), scale = "log")
#> <es_thresholds> on the "or" scale
#> negligible: |effect| in [1, 1.68)
#> small: |effect| in [1.68, 3.47)
#> medium: |effect| in [3.47, 6.71)
#> large: |effect| in [6.71, Inf)
#> Source: Chen H, Cohen P, Chen S (2010). How big is a big odds ratio?
#> Interpreting the magnitudes of odds ratios in epidemiological studies.
#> Communications in Statistics - Simulation and Computation 39(4):860-864. These
#> odds ratios correspond to d = 0.2, 0.5 and 0.8 only when the event rate in the
#> reference group is 1%; the equivalent odds ratios are smaller at higher
#> baseline risks.
#> Note: Zones symmetric on the log scale: boundaries at null / c and null * c.
```
