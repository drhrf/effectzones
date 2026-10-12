# Odds-ratio thresholds equivalent to d at a given baseline risk

Chen, Cohen & Chen (2010) translate Cohen's d into odds ratios by
placing both groups on a latent normal scale. If `p0` is the event risk
in the reference (unexposed) group, a standardised difference `d`
corresponds to an event risk in the exposed group of

## Usage

``` r
chen_or_thresholds(
  baseline_risk,
  d = c(0.2, 0.5, 0.8),
  labels = c("negligible", "small", "medium", "large")
)
```

## Arguments

- baseline_risk:

  Event risk in the reference group, strictly between 0 and 1.

- d:

  Positive standardised differences that define the cut-points.

- labels:

  Zone labels, one more than `d`.

## Value

An
[`es_thresholds()`](https://drhrf.github.io/effectzones/reference/es_thresholds.md)
object with `metric = "or"`, for use with
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)
and `scale = "log"`.

## Details

\$\$p_1 = \Phi(\Phi^{-1}(p_0) + d)\$\$

and the odds ratio is

\$\$OR = \frac{p_1 / (1 - p_1)}{p_0 / (1 - p_0)}.\$\$

This reproduces the published values: OR = 1.68, 3.47 and 6.71 for d =
0.2, 0.5 and 0.8 at p0 = 1%, and 1.52, 2.74 and 4.72 at p0 = 5%.

## Why the zones are asymmetric

Under this model the odds ratio for a protective effect (d \< 0) is not
the reciprocal of the odds ratio for the same harmful effect, except at
p0 = 0.5. At p0 = 1%, d = -0.8 corresponds to OR = 0.088 (1 / 11.4), not
1 / 6.71 = 0.149. `chen_or_thresholds()` therefore computes the
boundaries below 1 from d \< 0 directly (`cuts_lower` in
[`es_thresholds()`](https://drhrf.github.io/effectzones/reference/es_thresholds.md)),
rather than mirroring the boundaries above 1. Chen et al. tabulated only
odds ratios above 1; the boundaries below 1 apply their method to
negative d and are not published values.

`p0` must be the risk in the group in the denominator of the odds ratio
(the reference group of your estimates).

## References

Chen H, Cohen P, Chen S (2010). How big is a big odds ratio?
Interpreting the magnitudes of odds ratios in epidemiological studies.
*Communications in Statistics - Simulation and Computation*
39(4):860-864.
[doi:10.1080/03610911003650383](https://doi.org/10.1080/03610911003650383)

## See also

[`es_benchmarks()`](https://drhrf.github.io/effectzones/reference/es_benchmarks.md)
(`"chen_or"`, the published 1% values)

## Examples

``` r
chen_or_thresholds(0.01)
#> <es_thresholds> on the "or" scale
#> negligible (above null): magnitude in [1, 1.69)
#> small (above null): magnitude in [1.69, 3.47)
#> medium (above null): magnitude in [3.47, 6.71)
#> large (above null): magnitude in [6.71, Inf)
#> negligible (below null): magnitude in [1, 1.74)
#> small (below null): magnitude in [1.74, 4.28)
#> medium (below null): magnitude in [4.28, 11.4)
#> large (below null): magnitude in [11.4, Inf)
#> Source: Odds ratios equivalent to d = 0.2/0.5/0.8 at a 1% baseline risk, by the
#> method of Chen H, Cohen P, Chen S (2010). Commun Stat Simul Comput
#> 39(4):860-864, doi:10.1080/03610911003650383. Boundaries below 1 apply the
#> method to negative d.
chen_or_thresholds(0.20)
#> <es_thresholds> on the "or" scale
#> negligible (above null): magnitude in [1, 1.41)
#> small (above null): magnitude in [1.41, 2.31)
#> medium (above null): magnitude in [2.31, 3.74)
#> large (above null): magnitude in [3.74, Inf)
#> negligible (below null): magnitude in [1, 1.43)
#> small (below null): magnitude in [1.43, 2.53)
#> medium (below null): magnitude in [2.53, 4.72)
#> large (below null): magnitude in [4.72, Inf)
#> Source: Odds ratios equivalent to d = 0.2/0.5/0.8 at a 20% baseline risk, by
#> the method of Chen H, Cohen P, Chen S (2010). Commun Stat Simul Comput
#> 39(4):860-864, doi:10.1080/03610911003650383. Boundaries below 1 apply the
#> method to negative d.
```
