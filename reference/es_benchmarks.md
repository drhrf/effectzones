# Published effect-size benchmark sets

Look up a published set of effect-size cut-points and return it as an
[`es_thresholds()`](https://drhrf.github.io/effectzones/reference/es_thresholds.md)
object with a `source` citation. Call with no argument to list the
available sets.

## Usage

``` r
es_benchmarks(set)
```

## Arguments

- set:

  Name of the benchmark set. If missing, the available sets are printed
  and returned invisibly.

## Value

An
[`es_thresholds()`](https://drhrf.github.io/effectzones/reference/es_thresholds.md)
object, or (when `set` is missing) an invisible character vector of set
names.

## Details

|  |  |  |  |
|----|----|----|----|
| set | metric | cuts | source |
| `"cohen_d"` | d | 0.2, 0.5, 0.8 | Cohen (1988) |
| `"sawilowsky_d"` | d | 0.01, 0.2, 0.5, 0.8, 1.2, 2.0 | Sawilowsky (2009) |
| `"cohen_r"` | r | 0.1, 0.3, 0.5 | Cohen (1988) |
| `"funder_ozer_r"` | r | 0.05, 0.10, 0.20, 0.30, 0.40 | Funder & Ozer (2019) |
| `"gignac_szodorai_r"` | r | 0.10, 0.20, 0.30 | Gignac & Szodorai (2016) |
| `"cohen_eta2"` | eta2 | 0.01, 0.06, 0.14 | Cohen (1988) |
| `"cohen_f"` | f | 0.10, 0.25, 0.40 | Cohen (1988) |
| `"chen_or"` | or | 1.68, 3.47, 6.71 | Chen, Cohen & Chen (2010) |

## There is no default set

Benchmarks are field- and outcome-specific. Cohen (1988) presented his
values as a fallback for when nothing better is available, and later
sets (Funder & Ozer 2019; Gignac & Szodorai 2016) were derived from the
distribution of effects in particular literatures.
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)
therefore requires you to choose a set explicitly.

The cited sources define cut-points; the name of the zone below the
first cut ("negligible") is a convention of this package.

`"chen_or"` is tied to a 1% event rate in the reference group: Chen et
al. (2010) show that the odds ratio equivalent to a given d depends on
the baseline risk, and is smaller when the baseline risk is higher.

## References

Cohen J (1988). *Statistical Power Analysis for the Behavioral
Sciences*, 2nd ed. Hillsdale, NJ: Lawrence Erlbaum.

Sawilowsky SS (2009). New effect size rules of thumb. *Journal of Modern
Applied Statistical Methods* 8(2):597-599.

Funder DC, Ozer DJ (2019). Evaluating effect size in psychological
research: sense and nonsense. *Advances in Methods and Practices in
Psychological Science* 2(2):156-168.
[doi:10.1177/2515245919847202](https://doi.org/10.1177/2515245919847202)

Gignac GE, Szodorai ET (2016). Effect size guidelines for individual
differences researchers. *Personality and Individual Differences*
102:74-78.
[doi:10.1016/j.paid.2016.06.069](https://doi.org/10.1016/j.paid.2016.06.069)

Chen H, Cohen P, Chen S (2010). How big is a big odds ratio?
Interpreting the magnitudes of odds ratios in epidemiological studies.
*Communications in Statistics - Simulation and Computation*
39(4):860-864.

## See also

[`es_thresholds()`](https://drhrf.github.io/effectzones/reference/es_thresholds.md),
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)

## Examples

``` r
es_benchmarks()
#> "cohen_d": d, cuts 0.2, 0.5, and 0.8 (Cohen (1988), d)
#> "sawilowsky_d": d, cuts 0.01, 0.2, 0.5, 0.8, 1.2, and 2 (Sawilowsky (2009), d)
#> "cohen_r": r, cuts 0.1, 0.3, and 0.5 (Cohen (1988), r)
#> "funder_ozer_r": r, cuts 0.05, 0.1, 0.2, 0.3, and 0.4 (Funder & Ozer (2019), r)
#> "gignac_szodorai_r": r, cuts 0.1, 0.2, and 0.3 (Gignac & Szodorai (2016), r)
#> "cohen_eta2": eta2, cuts 0.01, 0.06, and 0.14 (Cohen (1988), η²)
#> "cohen_f": f, cuts 0.1, 0.25, and 0.4 (Cohen (1988), f)
#> "chen_or": or, cuts 1.68, 3.47, and 6.71 (Chen et al. (2010), OR at 1% baseline
#> risk)
es_benchmarks("cohen_d")
#> <es_thresholds> on the "d" scale
#> negligible: |effect| in [0, 0.2)
#> small: |effect| in [0.2, 0.5)
#> medium: |effect| in [0.5, 0.8)
#> large: |effect| in [0.8, Inf)
#> Source: Cohen J (1988). Statistical Power Analysis for the Behavioral Sciences,
#> 2nd ed. Hillsdale, NJ: Lawrence Erlbaum. Cohen offered these values as
#> conventions for use only when no better basis for judging magnitude is
#> available.
```
