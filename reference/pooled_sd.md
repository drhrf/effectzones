# Pooled (residual) standard deviation of a model

Returns the residual standard deviation (the square root of the mean
squared error) used to convert standardised thresholds to the raw scale
of model contrasts.

## Usage

``` r
pooled_sd(model, ...)
```

## Arguments

- model:

  A fitted model.

- ...:

  Unused.

## Value

A single positive number.

## Details

- `lm`/`aov`: [`stats::sigma()`](https://rdrr.io/r/stats/sigma.html).

- `emmGrid` (from emmeans): the `sigma` stored with the reference grid,
  which emmeans takes from the model. Grids of contrasts (from
  `contrast()` or [`pairs()`](https://rdrr.io/r/graphics/pairs.html)) do
  not keep it; use the `emmeans()` grid or the model.

`pooled_sd()` always returns the residual SD of the model it is given.
In a one-way model it equals the pooled within-group SD, the usual
denominator of Cohen's d. With several terms it is the SD left after
removing all of them: right for manipulated (randomised) factors, too
small for measured factors and covariates. To get the generalized
standardizer (Olejnik & Algina 2003), give it a model refitted with only
the manipulated factors, e.g. `pooled_sd(update(model, . ~ treatment))`.
[`plot_contrasts()`](https://drhrf.github.io/effectzones/reference/plot_contrasts.md)
uses the residual SD automatically only for one-way models.

The residual SD is one defensible choice, not the only one. When the
thresholds were defined relative to another SD (e.g. the baseline SD of
the outcome in the target population), supply that value as `sd`
instead.

## Examples

``` r
fit <- aov(weight ~ group, data = PlantGrowth)
pooled_sd(fit)
#> [1] 0.6233746
```
