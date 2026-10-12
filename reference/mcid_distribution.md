# Distribution-based (provisional) MCID

Compute a distribution-based MCID and return it as symmetric
[`mcid_thresholds()`](https://drhrf.github.io/effectzones/reference/mcid_thresholds.md)
marked `provisional = TRUE`. This is never done automatically: you must
call it explicitly.

## Usage

``` r
mcid_distribution(
  sd,
  method = c("half_sd", "sem", "one_fifth_sd"),
  reliability = NULL,
  direction = c("higher_better", "lower_better")
)
```

## Arguments

- sd:

  Standard deviation of the outcome (in the population the MCID should
  describe, usually baseline SD).

- method:

  `"half_sd"`, `"sem"` or `"one_fifth_sd"`.

- reliability:

  Reliability coefficient of the instrument (e.g. test-retest ICC),
  required for `method = "sem"`.

- direction:

  Passed to
  [`mcid_thresholds()`](https://drhrf.github.io/effectzones/reference/mcid_thresholds.md).

## Value

An
[`mcid_thresholds()`](https://drhrf.github.io/effectzones/reference/mcid_thresholds.md)
object with `provisional = TRUE`.

## Details

- `"half_sd"`: `0.5 * sd` (Norman, Sloan & Wyrwich 2003).

- `"one_fifth_sd"`: `0.2 * sd`, a convention equal to Cohen's "small" d.

- `"sem"`: one standard error of measurement,
  `sd * sqrt(1 - reliability)` (Wyrwich, Tierney & Wolinsky 1999);
  requires `reliability`.

## Why "provisional"

Distribution-based values describe the spread or the measurement error
of a score, not what patients regard as a worthwhile change. McGlothlin
& Lewis (2014) object that such values are not patient-derived and
should not be treated as an MCID in their own right; anchor-based
estimates are preferred. The legend of
[`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md)
is therefore titled "MCID (provisional, distribution-based)".

Note also that half an SD is exactly Cohen's "medium" standardised
difference (d = 0.5) and one fifth of an SD is his "small" (d = 0.2). A
distribution-based MCID therefore adds no clinical information beyond
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)
with
[es_benchmarks("cohen_d")](https://drhrf.github.io/effectzones/reference/es_benchmarks.md);
it only relabels effect-size zones in clinical language.

## References

Norman GR, Sloan JA, Wyrwich KW (2003). Interpretation of changes in
health-related quality of life: the remarkable universality of half a
standard deviation. *Medical Care* 41(5):582-592.
[doi:10.1097/01.mlr.0000062554.74615.4c](https://doi.org/10.1097/01.mlr.0000062554.74615.4c)

Wyrwich KW, Tierney WM, Wolinsky FD (1999). Further evidence supporting
an SEM-based criterion for identifying meaningful intra-individual
changes in health-related quality of life. *Journal of Clinical
Epidemiology* 52(9):861-873.
[doi:10.1016/s0895-4356(99)00071-2](https://doi.org/10.1016/s0895-4356%2899%2900071-2)

McGlothlin AE, Lewis RJ (2014). Minimal clinically important difference:
defining what really matters to patients. *JAMA* 312(13):1342-1343.
[doi:10.1001/jama.2014.13128](https://doi.org/10.1001/jama.2014.13128)

## Examples

``` r
mcid_distribution(sd = 10)
#> <mcid_thresholds> (higher_better)
#> harm: difference < -5
#> trivial: between -5 and 5
#> benefit: difference > 5
#> Provisional: not derived from patients' judgements.
#> Source: Half SD = 0.5 x 10 = 5. Norman GR, Sloan JA, Wyrwich KW (2003). Med
#> Care 41(5):582-592. doi:10.1097/01.mlr.0000062554.74615.4c. Equal to Cohen's
#> 'medium' d = 0.5. Distribution-based values are not patient-derived (McGlothlin
#> AE, Lewis RJ (2014). JAMA 312(13):1342-1343, doi:10.1001/jama.2014.13128) and
#> are provisional until an anchor-based MCID is available.
mcid_distribution(sd = 10, method = "sem", reliability = 0.84)
#> <mcid_thresholds> (higher_better)
#> harm: difference < -4
#> trivial: between -4 and 4
#> benefit: difference > 4
#> Provisional: not derived from patients' judgements.
#> Source: One SEM = SD x sqrt(1 - reliability) = 10 x sqrt(1 - 0.84) = 4.
#> SEM-based criterion: Wyrwich KW, Tierney WM, Wolinsky FD (1999). J Clin
#> Epidemiol 52(9):861-873. doi:10.1016/s0895-4356(99)00071-2. Distribution-based
#> values are not patient-derived (McGlothlin AE, Lewis RJ (2014). JAMA
#> 312(13):1342-1343, doi:10.1001/jama.2014.13128) and are provisional until an
#> anchor-based MCID is available.
```
