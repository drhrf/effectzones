# Minimal clinically important difference (MCID) thresholds

Define the boundaries of a "trivial" zone around the null, flanked by a
"benefit" zone and a "harm" zone, for use with
[`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md).

## Usage

``` r
mcid_thresholds(
  lower = NULL,
  upper = NULL,
  direction = c("higher_better", "lower_better"),
  source = NULL,
  provisional = FALSE,
  mcid = NULL
)
```

## Arguments

- lower, upper:

  Thresholds on the difference scale: `lower < 0 < upper`. Each is a
  number or a length-2 range.

- direction:

  Whether higher (`"higher_better"`) or lower (`"lower_better"`) values
  of the outcome are desirable.

- source:

  Optional citation for the thresholds, shown in the legend title.

- provisional:

  `TRUE` when the thresholds are not patient-derived (e.g.
  distribution-based, see
  [`mcid_distribution()`](https://drhrf.github.io/effectzones/reference/mcid_distribution.md)).
  The legend title then says so.

- mcid:

  Symmetric shorthand: a positive number (or length-2 positive range)
  used for both sides. Cannot be combined with `lower`/`upper`.

## Value

An object of class `mcid_thresholds`.

## Details

`lower` and `upper` are positions on the difference scale, relative to
the null: `lower` must be negative and `upper` positive. Which of them
is the improvement threshold depends on `direction`:

- `"higher_better"`: differences above `upper` are benefit, below
  `lower` are harm (deterioration).

- `"lower_better"`: differences below `lower` are benefit, above `upper`
  are harm.

The two thresholds need not be equal in size (asymmetric MCIDs are
common, for example when deterioration is felt at a smaller change than
improvement). Each may be a single value or a length-2 range, which
expresses uncertainty about where the threshold lies (for example, two
anchor-based studies that disagree).
[`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md)
draws a range as a gradual transition rather than a line.

A single positive value `mcid = x` is shorthand for
`lower = -x, upper = x`. A length-2 positive `mcid` gives a symmetric
range.

## References

Jaeschke R, Singer J, Guyatt GH (1989). Measurement of health status:
ascertaining the minimal clinically important difference. *Controlled
Clinical Trials* 10(4):407-415.
[doi:10.1016/0197-2456(89)90005-6](https://doi.org/10.1016/0197-2456%2889%2990005-6)

McGlothlin AE, Lewis RJ (2014). Minimal clinically important difference:
defining what really matters to patients. *JAMA* 312(13):1342-1343.

## See also

[`mcid_distribution()`](https://drhrf.github.io/effectzones/reference/mcid_distribution.md),
[`geom_mcid_zones()`](https://drhrf.github.io/effectzones/reference/geom_mcid_zones.md)

## Examples

``` r
# Symmetric: +/- 10 points
mcid_thresholds(mcid = 10)
#> <mcid_thresholds> (higher_better)
#> harm: difference < -10
#> trivial: between -10 and 10
#> benefit: difference > 10

# Asymmetric, with an uncertain improvement threshold
mcid_thresholds(lower = -5, upper = c(8, 12),
                source = "Anchor-based (two studies)")
#> <mcid_thresholds> (higher_better)
#> harm: difference < -5
#> trivial: between -5 and [8, 12]
#> benefit: difference > [8, 12]
#> Source: Anchor-based (two studies)

# Pain score: lower is better
mcid_thresholds(lower = -1.5, upper = 1, direction = "lower_better")
#> <mcid_thresholds> (lower_better)
#> benefit: difference < -1.5
#> trivial: between -1.5 and 1
#> harm: difference > 1
```
