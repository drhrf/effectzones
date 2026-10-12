# The mathematics behind effectzones

effectzones draws backgrounds; it never tests or classifies an estimate.
But drawing a background still involves arithmetic: converting
standardised thresholds to the scale of the data, choosing the right
standard deviation, translating effect sizes into odds ratios, placing
soft boundaries and fitting them into a panel. This article works
through every one of those calculations.

Each **calculator** below starts from a concrete example. Press **Next
step** to reveal one step at a time, **Back** to go back, or **Show
all**. The numbers are computed by R with effectzones itself when this
page is built, so they are exactly what the package uses.

## 1. The pooled within-group SD

Most effect-size benchmarks are standardised: a “medium” d of 0.5 means
a difference of half a standard deviation. To draw it behind contrasts
in the outcome’s own units we need that SD. In a one-way ANOVA with k
groups the residual standard deviation is the pooled within-group SD,

s_p = \sqrt{\mathrm{MSE}} = \sqrt{\frac{\sum\_{i=1}^{k} (n_i - 1)\\
s_i^2}{N - k}},

the usual denominator of Cohen’s d. It is the same quantity the ANOVA F
test and the Tukey intervals rely on, under the same equal-variance
assumption, so
[`plot_contrasts()`](https://drhrf.github.io/effectzones/reference/plot_contrasts.md)
takes it from a one-way model automatically.

Pooled SD of the PlantGrowth one-way ANOVA

Given plant dry weight in three groups ( `k = 3` ).

1.  Start from the size and SD of each group:
    | group | `n_i` | `s_i`  |
    |-------|-------|--------|
    | ctrl  | 10    | 0.5831 |
    | trt1  | 10    | 0.7937 |
    | trt2  | 10    | 0.4426 |

2.  Weight each group's variance by its degrees of freedom and add them
    up: the within-group sum of squares.

    `\textstyle\sum (n_i - 1)s_i^2 = 9 \times 0.5831^2 + 9 \times 0.7937^2 + 9 \times 0.4426^2`

    = 10.492

3.  Divide by the residual degrees of freedom to get the mean squared
    error.

    `\mathrm{MSE} = \frac{10.492}{N - k} = \frac{10.492}{30 - 3} = 0.3886`

4.  Take the square root: this is the pooled within-group SD.

    `s_p = \sqrt{0.3886} = 0.6234`

    It equals the residual SD of the fitted model, sigma(fit).

In R

    fit <- aov(weight ~ group, data = PlantGrowth)
    pooled_sd(fit)

← Back

Next step →

Show all

Start over

## 2. From standardised thresholds to boundaries on the data scale

A standardised cut-point c becomes a pair of boundaries around the null,
\text{null} \pm c \cdot \mathrm{SD}. Effect sizes on the correlation,
\eta^2 or f scale are drawn on their own scale only; there is no
conversion from them to raw differences.

Cohen's d benchmarks behind the PlantGrowth contrasts

Given cut-points `d = 0.2,\ 0.5,\ 0.8` (Cohen 1988) and `s_p = 0.6234`
from calculator 1.

1.  Multiply each cut-point by the SD.

    `0.2 \times 0.6234 = 0.1247,\quad 0.5 \times 0.6234 = 0.3117,\quad 0.8 \times 0.6234 = 0.4987`

2.  Place a boundary on each side of the null (0 for a difference).

    `\pm 0.1247,\quad \pm 0.3117,\quad \pm 0.4987`

3.  Read off the zones (in kg of dry weight). A contrast whose interval
    lies between −0.1247 and 0.1247 kg sits in the *negligible* zone;
    beyond 0.4987 kg in either direction it reaches the *large* zone.

    `\underbrace{|x| < 0.1247}_{\text{negligible}}\;\;\underbrace{0.1247 \le |x| < 0.3117}_{\text{small}}\;\;\underbrace{0.3117 \le |x| < 0.4987}_{\text{medium}}\;\;\underbrace{|x| \ge 0.4987}_{\text{large}}`

In R

    to_plot_scale(es_benchmarks("cohen_d"), sd = pooled_sd(fit))

← Back

Next step →

Show all

Start over

## 3. Which SD when the model has several terms

With more than one term the residual SD has the variance of *every other
term* removed. That is right for factors the experimenter manipulated
(their variation does not exist in the population) and too small for
factors that were only measured (sex, age, site, baseline covariates),
which are ordinary differences between people. The generalized
standardizer (Olejnik & Algina 2003) keeps measured variation in the SD:
refit the model with **only the manipulated factors** and use its
residual SD. Whether a factor was manipulated or measured is a fact
about the design, not the data, which is why
[`plot_contrasts()`](https://drhrf.github.io/effectzones/reference/plot_contrasts.md)
asks instead of guessing.

Chilling (manipulated) and plant origin (measured) in the CO2 data

Given CO₂ uptake of 12 plants at the highest concentration; `Treatment`
(chilled or not) was assigned, `Type` (Quebec or Mississippi) is the
plants' origin.

1.  Fit the model with both terms. Its residual SD has the large
    difference between origins removed.

    `s_{\text{residual}} = \sqrt{\mathrm{MSE}_{\text{Treatment + Type}}} = 4.335 \quad (9\ \text{df})`

2.  Refit with the manipulated factor only. Origin is ordinary variation
    between plants, so it goes back into the error term.

    `s_{\text{gen}} = \sqrt{\mathrm{MSE}_{\text{Treatment}}} = 10.1 \quad (10\ \text{df})`

3.  Compare. Using the residual SD would shrink every zone by this
    factor.

    `\frac{s_{\text{gen}}}{s_{\text{residual}}} = \frac{10.1}{4.335} = 2.33`

4.  Translate a "medium" d = 0.5 into each scale.

    `0.5 \times 4.335 = 2.167 \ \mu\text{mol/m}^2\text{s} \quad\text{vs.}\quad 0.5 \times 10.1 = 5.048`

    Only the second matches what "half a standard deviation between
    plants" means.

In R

    fit <- aov(uptake ~ Treatment + Type, data = subset(CO2, conc == 1000))
    plot_contrasts(fit, which = "Treatment",
      zones = geom_es_zones(es_benchmarks("cohen_d"),
                            sd = pooled_sd(update(fit, . ~ Treatment))))

← Back

Next step →

Show all

Start over

The same logic applies to a randomised ANCOVA. Adjusting for a baseline
covariate with pooled within-group correlation r removes a fraction r^2
of the outcome variance, so the adjusted residual SD relates to the
unadjusted within-group SD approximately as

s\_{\text{adj}} \approx s\_{\text{unadj}} \sqrt{1 - r^2}
\quad\Longrightarrow\quad s\_{\text{unadj}} \approx
\frac{s\_{\text{adj}}}{\sqrt{1 - r^2}},

(ignoring the one degree of freedom spent on the slope). The
standardizer for d is s\_{\text{unadj}}: the covariate improves
precision, but people still differ by that much.

## 4. The SD is an estimate too

The SD used to place the boundaries has sampling error. Under normality,
(\nu\\ s^2)/\sigma^2 \sim \chi^2\_\nu with \nu residual degrees of
freedom, which gives a confidence interval for \sigma:

\left\[\\ s\sqrt{\frac{\nu}{\chi^2\_{\nu,\\1-\alpha/2}}},\\
s\sqrt{\frac{\nu}{\chi^2\_{\nu,\\\alpha/2}}} \\\right\].

Each boundary d \cdot s inherits that interval. effectzones does not yet
draw this uncertainty, so report it alongside the plot.

95% confidence interval for the PlantGrowth SD

Given `s_p = 0.6234` with `\nu = 27` residual degrees of freedom
(calculator 1).

1.  Look up the chi-square quantiles that cut off 2.5% in each tail.

    `\chi^2_{27,\,0.975} = 43.19, \qquad \chi^2_{27,\,0.025} = 14.57`

2.  Lower limit: divide by the larger quantile.

    `0.6234 \sqrt{\tfrac{27}{43.19}} = 0.4929`

3.  Upper limit: divide by the smaller quantile.

    `0.6234 \sqrt{\tfrac{27}{14.57}} = 0.8485`

4.  Carry it to a boundary. The "medium" boundary 0.5 SD could plausibly
    lie anywhere in

    `0.5 \times [0.4929,\ 0.8485] = [0.2464,\ 0.4242]\ \text{kg}`

    A point boundary at 0.3117 kg hides that spread.

In R

    s <- pooled_sd(fit); nu <- fit$df.residual
    s * sqrt(nu / qchisq(c(0.975, 0.025), nu))

← Back

Next step →

Show all

Start over

## 5. Soft boundaries

Benchmarks are conventions, not natural discontinuities, so by default
[`geom_es_zones()`](https://drhrf.github.io/effectzones/reference/geom_es_zones.md)
fades from one zone into the next. For a boundary at distance c from the
null, with `softness` = \lambda (default 0.1), the transition spans

\left\[\\ c - \tfrac{\lambda c}{2},\\ c + \tfrac{\lambda c}{2}
\\\right\],

drawn as n thin rectangles (`n_slices`, default 40). Slice j is coloured
at the fraction t_j = (j - \tfrac12)/n of the way between the two zone
colours, interpolated in the perceptually uniform CIELAB space. If two
neighbouring transitions would overlap they are both cut back to the
midpoint between their boundaries. For ratio zones the same arithmetic
is done on the log scale.

The soft boundary between "small" and "medium" (PlantGrowth, d = 0.5)

Given `c = 0.5 \times 0.6234 = 0.3117` kg, `\lambda = 0.1` , `n = 40`
slices, grey palette.

1.  Width of the transition: a tenth of the threshold.

    `\lambda c = 0.1 \times 0.3117 = 0.03117`

2.  Centre it on the threshold.

    `[\,0.3117 - 0.01558,\; 0.3117 + 0.01558\,] = [\,0.2961,\; 0.3273\,]`

3.  Cut it into 40 slices and give each one a mixing fraction, e.g.
    slices 1, 20 and 40:

    `t_1 = \tfrac{0.5}{40} = 0.0125,\quad t_{20} = \tfrac{19.5}{40} = 0.4875,\quad t_{40} = \tfrac{39.5}{40} = 0.9875`

4.  Mix the two zone colours (`#BBBBBB` small, `#7A7A7A` medium) at
    those fractions in CIELAB:  
    slice 1`#BABABA`   slice 20`#9B9B9B`   slice 40`#7B7B7B`

    Each slice is then drawn with the layer's alpha (0.35 by default),
    so the gridlines and estimates stay visible.

In R

    geom_es_zones(es_benchmarks("cohen_d"), sd = pooled_sd(fit),
                  softness = 0.1, n_slices = 40)

← Back

Next step →

Show all

Start over

## 6. Ratios: zones on the log scale

Odds ratios and risk ratios are multiplicative, so their zones are
placed around 1 on the log scale. A magnitude c gives boundaries 1/c and
c (symmetric in \log), unless the thresholds specify a different
magnitude below the null (`cuts_lower`). On a
[`scale_x_log10()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
axis, ggplot2 works in \log\_{10} units, and the boundaries are
transformed the same way as the data.

Placing the first Chen et al. odds-ratio boundary on a log axis

Given `c = 1.68` (the "small" odds ratio at a 1% baseline risk), null
`= 1` , axis `\log_{10}` .

1.  Above the null: multiply.

    `1 \times 1.68 = 1.68`

2.  Below the null (symmetric case): divide.

    `1 / 1.68 = 0.5952`

3.  On the log scale the two are mirror images of each other.

    `\log(1.68) = 0.5188, \qquad \log(0.5952) = -0.5188`

4.  ggplot2 places them at their log10 positions, exactly like the data.

    `\log_{10}(0.5952) = -0.2253, \qquad \log_{10}(1.68) = 0.2253`

    Section 8 shows why, under Chen et al.'s own model, the lower
    boundary is not exactly 1/c.

In R

    geom_es_zones(es_thresholds(c(1.68, 3.47, 6.71), c("negligible", "small", "medium", "large"),
                                metric = "or"), scale = "log", null = 1) +
      scale_x_log10()

← Back

Next step →

Show all

Start over

## 7. From d to an odds ratio: Chinn’s approximation

If a binary outcome arises from dichotomising a latent variable with a
logistic distribution, a shift of d standard deviations corresponds to

\log(\mathrm{OR}) = d \cdot \frac{\pi}{\sqrt{3}} \approx 1.814\\ d

(Chinn 2000). This is what `to_plot_scale(…, scale = "log")` uses for d
thresholds. It does not depend on the baseline risk, which is exactly
where it differs from Chen et al.

A "medium" d = 0.5 as an odds ratio (Chinn 2000)

Given `d = 0.5`

1.  The scale factor of the logistic distribution.

    `\pi/\sqrt{3} = 1.8138`

2.  Multiply.

    `\log(\mathrm{OR}) = 0.5 \times 1.8138 = 0.9069`

3.  Exponentiate.

    `\mathrm{OR} = e^{0.9069} = 2.477`

    Compare Chen et al. at a 1% baseline: 3.47 (next section).

In R

    to_plot_scale(es_benchmarks("cohen_d"), scale = "log")$cuts

← Back

Next step →

Show all

Start over

## 8. From d to an odds ratio at a given baseline risk: Chen et al.

Chen, Cohen & Chen (2010) place both groups on a latent normal scale.
With event risk p_0 in the reference group, a shift d gives the exposed
group’s risk and the odds ratio

p_1 = \Phi\\\left(\Phi^{-1}(p_0) + d\right), \qquad \mathrm{OR} =
\frac{p_1/(1-p_1)}{p_0/(1-p_0)} .

This reproduces their published values (1.68, 3.47 and 6.71 at p_0 =
1\\; 1.52, 2.74 and 4.72 at 5\\). Applied to a protective shift -d it
does **not** give 1/\mathrm{OR}, except at p_0 = 0.5, so effectzones
computes the boundaries below 1 from -d directly.

The "large" boundaries (d = ±0.8) at a 1% baseline risk

Given `p_0 = 0.01` in the reference group, `d = 0.8` .

1.  Move the baseline risk to the latent normal scale.

    `z_0 = \Phi^{-1}(0.01) = -2.3263`

2.  Harmful direction: shift by +d and return to a risk.

    `p_1 = \Phi(-2.3263 + 0.8) = \Phi(-1.5263) = 0.06346`

3.  Odds ratio for the harmful direction (the published value, 6.71).

    `\mathrm{OR} = \frac{0.06346/(1-0.06346)}{0.01/0.99} = 6.708`

4.  Protective direction: shift by −d instead.

    `p_1 = \Phi(-2.3263 - 0.8) = \Phi(-3.1263) = 0.000885`

5.  Odds ratio for the protective direction.

    `\mathrm{OR} = \frac{0.000885/(1-0.000885)}{0.01/0.99} = 0.08769 = 1/11.4`

    Mirroring would have put this boundary at 1/6.708 = 0.1491, so the
    protective "large" zone would start too close to 1.

In R

    chen_or_thresholds(0.01)   # any baseline risk: chen_or_thresholds(0.2)

← Back

Next step →

Show all

Start over

## 9. Distribution-based (provisional) MCIDs

A distribution-based MCID describes the spread or the measurement error
of a score, not what patients consider worthwhile, so effectzones marks
it provisional. Two rules are offered:

\text{half SD} = 0.5\\ s, \qquad \text{SEM} = s\sqrt{1 - r\_{xx}},

where r\_{xx} is the instrument’s reliability (Norman, Sloan & Wyrwich
2003; Wyrwich, Tierney & Wolinsky 1999). Half an SD is exactly Cohen’s
“medium” d = 0.5, which is why a distribution-based MCID adds no
clinical information beyond the effect-size zones.

Half-SD and SEM for a score with SD 10 and reliability 0.84

Given `s = 10` , `r_{xx} = 0.84` .

1.  Half an SD.

    `0.5 \times 10 = 5`

2.  The unreliable fraction of the variance.

    `1 - 0.84 = 0.16`

3.  One standard error of measurement.

    `10 \times \sqrt{0.16} = 10 \times 0.4 = 4`

4.  Either value becomes a symmetric, provisional MCID.

    `\text{harm} < -4 \le \text{trivial} \le 4 < \text{benefit}`

    The legend then reads "MCID (provisional, distribution-based)".

In R

    mcid_distribution(sd = 10, method = "sem", reliability = 0.84)

← Back

Next step →

Show all

Start over

## 10. MCID zones: asymmetry, direction, ranges and multiples

An MCID defines a trivial zone \[\ell, u\] around the null, with \ell \<
0 \< u allowed to differ in size. Which side is benefit depends on
`direction`. A range for either threshold (an uncertain MCID) is drawn
as a fade across the range, using the same slicing as section 5. With
`beyond = "multiples"`, extra boundaries at 2\ell, 3\ell and 2u, 3u
deepen the colour; this requires point thresholds, because multiples of
an uncertain MCID would be uncertain too.

Zones for an asymmetric MCID (−0.25 / +0.3, higher is better)

Given `\ell = -0.25` , `u = 0.3` , `direction = "higher_better"`.

1.  Three zones, with hard edges at the thresholds.

    `\underbrace{x < -0.25}_{\text{harm}} \quad \underbrace{-0.25 \le x \le 0.3}_{\text{trivial}} \quad \underbrace{x > 0.3}_{\text{benefit}}`

2.  If lower values were better (`direction = "lower_better"`), the same
    boundaries would label the sides the other way round.

    `\underbrace{x < -0.25}_{\text{benefit}} \quad \underbrace{-0.25 \le x \le 0.3}_{\text{trivial}} \quad \underbrace{x > 0.3}_{\text{harm}}`

3.  With `beyond = "multiples"`, add boundaries at 2 and 3 times each
    threshold.

    `-0.75,\ -0.5,\ -0.25,\ 0.3,\ 0.6,\ 0.9`

4.  If the improvement threshold were uncertain, say between 0.3 and
    0.5, the trivial zone fades into benefit across that range instead
    of switching at one point.

    `0.3 \le x \le 0.5:\ \text{trivial} \rightarrow \text{benefit}`

    Multiples are then refused: "2×" could be anywhere from 0.6 to 1.0.

In R

    geom_mcid_zones(mcid_thresholds(lower = -0.25, upper = 0.3), beyond = "multiples")
    geom_mcid_zones(mcid_thresholds(lower = -0.25, upper = c(0.3, 0.5)))

← Back

Next step →

Show all

Start over

## 11. Where the intervals come from: Tukey’s HSD

effectzones does not compute intervals;
[`plot_contrasts()`](https://drhrf.github.io/effectzones/reference/plot_contrasts.md)
draws the ones your analysis produced. For Tukey post-hoc comparisons
(computed by
[`stats::TukeyHSD()`](https://rdrr.io/r/stats/TukeyHSD.html)), the
family-wise interval for groups i and j is

(\bar y_i - \bar y_j) \pm \frac{q\_{1-\alpha;\\k,\\\nu}}{\sqrt 2}
\sqrt{\mathrm{MSE}\left(\frac{1}{n_i} + \frac{1}{n_j}\right)},

where q is a quantile of the studentized range distribution.

The trt2 − trt1 interval in PlantGrowth

Given `\bar y_{\text{trt2}} = 5.526,\ \bar y_{\text{trt1}} = 4.661` ,
`n = 10` per group, `\mathrm{MSE} = 0.3886` , `k = 3,\ \nu = 27` .

1.  Difference in means.

    `5.526 - 4.661 = 0.865`

2.  Studentized range quantile for 95% family-wise coverage.

    `q_{0.95;\,3,\,27} = 3.506`

3.  Half-width of the interval.

    `\frac{3.506}{\sqrt 2}\sqrt{0.3886\left(\tfrac{1}{10} + \tfrac{1}{10}\right)} = 0.6912`

4.  The interval drawn by
    [`plot_contrasts()`](https://drhrf.github.io/effectzones/reference/plot_contrasts.md),
    identical to [`TukeyHSD()`](https://rdrr.io/r/stats/TukeyHSD.html).

    `0.865 \pm 0.6912 = [\,0.1738,\ 1.556\,]`

    Against the d zones of calculator 2 (boundaries at ±0.1247, ±0.3117,
    ±0.4987 kg), this interval runs from the small zone into the large
    zone.

In R

    plot_contrasts(fit, zones = geom_es_zones(es_benchmarks("cohen_d")))

← Back

Next step →

Show all

Start over

## 12. Fitting zones into the panel

Zone boundaries are layer parameters, not data, so by default they never
change the axis limits. The layer works out what is visible in three
steps: transform the boundaries like the data, keep the zones that reach
the visible range, and clip them to the panel. The visible range is the
data range expanded by ggplot2’s default 5% on each side. (Zooming with
[`coord_cartesian()`](https://ggplot2.tidyverse.org/reference/coord_cartesian.html)
is applied only at drawing time, so the legend can still list a zone
that the zoom cuts away.)

Which Cohen's d zones appear in the PlantGrowth Tukey plot

Given the three Tukey intervals and the boundaries from calculator 2.

1.  The data span the lowest and highest interval limits.

    `[\,-1.062,\ 1.556\,]`

2.  Expand by 5% of the width on each side to get the visible range.

    `[\,-1.062 - 0.1309,\ 1.556 + 0.1309\,] = [\,-1.193,\ 1.687\,]`

3.  Keep a zone if it overlaps the visible range: its upper end is above
    the left edge and its lower end below the right edge.

    `\text{keep} \iff \text{hi} > \text{left} \ \text{and}\ \text{lo} < \text{right}`

4.  Result: ✔ large, ✔ medium, ✔ small, ✔ negligible, ✔ small, ✔ medium,
    ✔ large. Every zone reaches the visible range, so all four labels
    appear in the legend; the outermost ones are clipped at the panel
    edges.

5.  Now suppose the benchmark's SD were 3 kg. The boundaries move to
    ±0.6, ±1.5, ±2.4 kg. Result: ✘ large, ✘ medium, ✔ small, ✔
    negligible, ✔ small, ✔ medium, ✘ large. The *large* zones begin
    beyond the visible range on both sides, so *large* is left out of
    the legend.

In R

    plot_contrasts(fit, zones = geom_es_zones(es_benchmarks("cohen_d"))) # expand = FALSE
    plot_contrasts(fit, zones = geom_es_zones(es_benchmarks("cohen_d"), expand = TRUE))

← Back

Next step →

Show all

Start over

With `expand = TRUE` the finite boundaries are added to the scale’s
range instead, so every cut-point is visible and every zone is listed.

## References

Chen H, Cohen P, Chen S (2010). How big is a big odds ratio?
Interpreting the magnitudes of odds ratios in epidemiological studies.
*Communications in Statistics - Simulation and Computation*
39(4):860-864. <doi:10.1080/03610911003650383>

Chinn S (2000). A simple method for converting an odds ratio to effect
size for use in meta-analysis. *Statistics in Medicine*
19(22):3127-3131.
[doi:10.1002/1097-0258(20001130)19:22\<3127::AID-SIM784\>3.0.CO;2-M](https://doi.org/10.1002/1097-0258(20001130)19:22%3C3127::AID-SIM784%3E3.0.CO;2-M)

Cohen J (1988). *Statistical Power Analysis for the Behavioral
Sciences*, 2nd ed. Hillsdale, NJ: Lawrence Erlbaum.
<doi:10.4324/9780203771587>

Norman GR, Sloan JA, Wyrwich KW (2003). Interpretation of changes in
health-related quality of life: the remarkable universality of half a
standard deviation. *Medical Care* 41(5):582-592.
<doi:10.1097/01.mlr.0000062554.74615.4c>

Olejnik S, Algina J (2003). Generalized eta and omega squared
statistics: measures of effect size for some common research designs.
*Psychological Methods* 8(4):434-447. <doi:10.1037/1082-989X.8.4.434>

Wyrwich KW, Tierney WM, Wolinsky FD (1999). Further evidence supporting
an SEM-based criterion for identifying meaningful intra-individual
changes in health-related quality of life. *Journal of Clinical
Epidemiology* 52(9):861-873. <doi:10.1016/s0895-4356(99)00071-2>
