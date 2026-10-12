# Forest-style plot of contrasts over interpretive zones

Draws contrasts (rows) against their estimated difference (x axis) as
points with confidence-interval bars and a reference line at the null. A
zones layer from
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)
or
[`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md),
if given, is drawn first, behind everything else.

## Usage

``` r
plot_contrasts(x, zones = NULL, ...)

# S3 method for class 'data.frame'
plot_contrasts(
  x,
  zones = NULL,
  ...,
  model = NULL,
  null = 0,
  xlab = "Difference"
)

# S3 method for class 'aov'
plot_contrasts(
  x,
  zones = NULL,
  ...,
  which = NULL,
  conf.level = 0.95,
  xlab = NULL
)

# S3 method for class 'TukeyHSD'
plot_contrasts(x, zones = NULL, ..., which = NULL, model = NULL, xlab = NULL)

# S3 method for class 'emmGrid'
plot_contrasts(x, zones = NULL, ..., model = NULL, xlab = NULL)
```

## Arguments

- x:

  An `aov` fit, a `TukeyHSD` object, an `emmGrid` (of means or of
  contrasts), or a data frame with columns `term`, `estimate`, `lower`,
  `upper`.

- zones:

  A zones layer from
  [`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)
  or
  [`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md),
  or `NULL`.

- ...:

  Passed to methods. For `emmGrid`, passed to
  [`confint()`](https://rdrr.io/r/stats/confint.html) (e.g. `level`,
  `adjust`).

- model:

  A fitted model (or, for emmeans contrasts, the emmeans grid of means)
  used to fill a missing `sd` in `zones`.

- null:

  Position of the null (reference line). Defaults to 0, or 1 for ratios
  from emmeans.

- xlab:

  Axis title for the difference axis.

- which:

  For `aov` and `TukeyHSD`: the term(s) to plot. Default all; several
  terms are shown in separate panels.

- conf.level:

  For `aov`: family-wise confidence level of the Tukey intervals.

## Value

A ggplot object.

## Which SD converts d to the raw scale

Standardised (`"d"`) thresholds must be multiplied by an SD before they
can be drawn over raw differences. `plot_contrasts()` takes that SD from
the fitted model only when the choice is not an extra assumption:

- **One-way, fixed-effects, unweighted linear model** (e.g.
  `aov(y ~ group)`): the residual SD is the pooled within-group SD, the
  usual denominator of Cohen's d. It is the same quantity the ANOVA and
  the Tukey intervals already rely on (equal variances). It is used
  automatically and a message reports its value.

- **Anything else** (several factors, covariates, interactions, weights,
  GLMs): the residual SD has the variance of every other term removed.
  That is right for manipulated (randomised) factors and too small for
  measured factors and covariates, and the model does not record which
  is which. The function stops and explains the rigorous procedure: (1)
  decide what SD the benchmark refers to, before seeing results; (2)
  preferably use an external, pre-specified SD; (3) otherwise refit with
  only the manipulated factors and use that residual SD (Olejnik &
  Algina 2003), e.g. `sd = pooled_sd(update(model, . ~ treatment))`; if
  every term was manipulated, `sd = pooled_sd(model)`; (4) report the
  SD's own uncertainty.

## Where the model comes from

- `aov` fits: pass the fit itself; Tukey contrasts are computed from it.

- `TukeyHSD` objects store the call that fitted the model but not the
  model. When an SD is needed and `model` is not given, the call is
  re-evaluated in the calling environment, and the refitted model is
  used only if its Tukey contrasts reproduce `x` exactly; otherwise an
  error asks for `model`. A message says when this happens.

- `emmGrid` of estimated means (from `emmeans()`): pairwise contrasts
  are computed (`emmeans::contrast(method = "pairwise")`,
  Tukey-adjusted), and the grid's own residual SD is used.

- `emmGrid` of contrasts (from `contrast()` or
  [`pairs()`](https://rdrr.io/r/graphics/pairs.html)): emmeans does not
  keep the residual SD in contrast grids, so pass the means grid or the
  fit as `model`, or set `sd`.

## References

Olejnik S, Algina J (2003). Generalized eta and omega squared
statistics: measures of effect size for some common research designs.
*Psychological Methods* 8(4):434-447.
[doi:10.1037/1082-989X.8.4.434](https://doi.org/10.1037/1082-989X.8.4.434)

## See also

[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md),
[`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md),
[`pooled_sd()`](https://drhrf.github.io/effectzones/reference/pooled_sd.md)

## Examples

``` r
fit <- aov(weight ~ group, data = PlantGrowth)
plot_contrasts(fit)


# The residual SD of the one-way model converts d to raw differences
plot_contrasts(fit, zones = geom_es_zones(es_benchmarks("cohen_d")))
#> ℹ Converting d thresholds with the residual (pooled within-group) SD of the
#>   one-way model: 0.623.
#>   Set `sd` in the zones layer to use a different SD.


# A TukeyHSD object works too: its model is refitted and checked
tk <- TukeyHSD(fit)
plot_contrasts(tk, zones = geom_es_zones(es_benchmarks("cohen_d")))
#> ℹ Refitted `aov(formula = weight ~ group, data = PlantGrowth)` to get the
#>   model's SD; it reproduces these Tukey contrasts exactly.
#> ℹ Converting d thresholds with the residual (pooled within-group) SD of the
#>   one-way model: 0.623.
#>   Set `sd` in the zones layer to use a different SD.


plot_contrasts(fit,
               zones = geom_mcid_zones(mcid_thresholds(lower = -0.3,
                                                       upper = c(0.4, 0.6))))
```
