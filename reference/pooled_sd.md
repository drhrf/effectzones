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
