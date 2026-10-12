es_metrics <- c("d", "r", "eta2", "f", "or", "rr", "raw")
ratio_metrics <- c("or", "rr")

#' Effect-size thresholds
#'
#' Define the cut-points that separate effect-size magnitude zones
#' ("negligible", "small", "medium", ...). The cut-points are positive
#' magnitudes and, by default, are applied symmetrically around the null: a
#' cut at `0.5` produces boundaries at `-0.5` and `+0.5` for additive
#' metrics, and at `1/c` and `c` for ratio metrics (`"or"`, `"rr"`). Use
#' `cuts_lower` when the two sides differ.
#'
#' These objects contain no data and make no claim about any estimate. They
#' only describe where to draw background boundaries; see
#' [geom_es_zones()]. For published benchmark sets use [es_benchmarks()].
#'
#' @param cuts Positive, strictly increasing magnitudes. For ratio metrics
#'   (`"or"`, `"rr"`) they must be greater than 1.
#' @param labels Character vector of zone names, one more than `cuts`. The
#'   first label names the zone between the null and the first cut (often
#'   "negligible"), the last names the zone beyond the last cut.
#' @param metric The effect-size metric the cuts are expressed in: `"d"`
#'   (standardised mean difference), `"r"` (correlation), `"eta2"`
#'   (eta-squared), `"f"` (Cohen's f), `"or"` (odds ratio), `"rr"` (risk
#'   ratio) or `"raw"` (unstandardised units of the outcome).
#' @param source Optional character string citing where the cuts come from.
#'   It is shown in the legend title, so keep it short or use the `title`
#'   argument of [geom_es_zones()].
#' @param cuts_lower Optional magnitudes for the side below the null when it
#'   differs from the side above (same length as `cuts`, same labels). A
#'   value `c` is drawn at `null - c`, or at `null / c` for ratio metrics.
#'   Defaults to `cuts` (symmetric zones).
#'
#' @return An object of class `es_thresholds`: a list with elements `cuts`,
#'   `cuts_lower`, `labels`, `metric`, `source` and `title` (the short legend
#'   title).
#' @seealso [es_benchmarks()], [to_plot_scale()], [geom_es_zones()]
#' @export
#' @examples
#' es_thresholds(c(0.1, 0.3), c("trivial", "modest", "substantial"),
#'               metric = "d", source = "Pre-registered, protocol v2")
es_thresholds <- function(cuts, labels, metric = c("d", "r", "eta2", "f", "or", "rr", "raw"),
                          source = NULL, cuts_lower = NULL) {
  metric <- rlang::arg_match(metric)
  check_cuts(cuts, metric)
  if (!is.null(cuts_lower)) {
    check_cuts(cuts_lower, metric, arg = "cuts_lower")
    if (length(cuts_lower) != length(cuts)) {
      cli::cli_abort("{.arg cuts_lower} must have the same length as {.arg cuts}.")
    }
  }
  if (!is.character(labels) || anyNA(labels)) {
    cli::cli_abort("{.arg labels} must be a character vector without missing values.")
  }
  if (length(labels) != length(cuts) + 1) {
    cli::cli_abort(c(
      "{.arg labels} must have one more element than {.arg cuts}.",
      "x" = "{length(cuts)} cut{?s} need{?s/} {length(cuts) + 1} labels, not {length(labels)}.",
      "i" = "The first label names the zone between the null and the first cut."
    ))
  }
  if (anyDuplicated(labels)) {
    cli::cli_abort("{.arg labels} must be unique.")
  }
  if (!is.null(source) && (!is.character(source) || length(source) != 1)) {
    cli::cli_abort("{.arg source} must be a single string or {.code NULL}.")
  }
  new_es_thresholds(cuts, labels, metric, source, title = source,
                    cuts_lower = cuts_lower)
}

check_cuts <- function(cuts, metric, arg = "cuts", call = rlang::caller_env()) {
  if (!is.numeric(cuts) || length(cuts) < 1 || anyNA(cuts) || any(!is.finite(cuts))) {
    cli::cli_abort("{.arg {arg}} must be a non-empty numeric vector of finite values.",
                   call = call)
  }
  if (any(cuts <= 0)) {
    cli::cli_abort(c(
      "{.arg {arg}} must be positive magnitudes.",
      "i" = "Give magnitudes only; their side of the null is implied."
    ), call = call)
  }
  if (metric %in% ratio_metrics && any(cuts <= 1)) {
    cli::cli_abort(c(
      "For ratio metrics ({.val {metric}}) {.arg {arg}} must be greater than 1.",
      "i" = "A magnitude {.val c} is drawn at {.code null * c} above and {.code null / c} below the null."
    ), call = call)
  }
  if (is.unsorted(cuts, strictly = TRUE)) {
    cli::cli_abort("{.arg {arg}} must be strictly increasing.", call = call)
  }
  invisible(cuts)
}

new_es_thresholds <- function(cuts, labels, metric, source, title = NULL,
                              scale = "identity", note = NULL,
                              cuts_lower = NULL) {
  structure(
    list(cuts = as.numeric(cuts),
         cuts_lower = as.numeric(cuts_lower %||% cuts),
         labels = labels, metric = metric,
         source = source, title = title, scale = scale, note = note),
    class = "es_thresholds"
  )
}

es_is_symmetric <- function(x) isTRUE(all.equal(x$cuts, x$cuts_lower))

#' @export
print.es_thresholds <- function(x, ...) {
  cli::cli_text("{.cls es_thresholds} on the {.val {x$metric}} scale")
  ratio <- x$metric %in% ratio_metrics || identical(x$scale, "log")
  show <- function(cuts, side) {
    bounds <- c(if (ratio) 1 else 0, cuts, Inf)
    for (i in seq_along(x$labels)) {
      lo <- fmt_num(bounds[i])
      hi <- if (is.finite(bounds[i + 1])) fmt_num(bounds[i + 1]) else "Inf"
      cli::cli_text("{.strong {x$labels[i]}}{side}: magnitude in [{lo}, {hi})")
    }
  }
  if (es_is_symmetric(x)) {
    show(x$cuts, "")
  } else {
    show(x$cuts, " (above null)")
    show(x$cuts_lower, " (below null)")
  }
  if (!is.null(x$source)) cli::cli_text("Source: {x$source}")
  if (!is.null(x$note)) cli::cli_text("Note: {x$note}")
  invisible(x)
}

benchmark_sets <- list(
  cohen_d = list(
    cuts = c(0.2, 0.5, 0.8),
    labels = c("negligible", "small", "medium", "large"),
    metric = "d",
    title = "Cohen (1988), d",
    source = paste(
      "Cohen J (1988). Statistical Power Analysis for the Behavioral Sciences,",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum. doi:10.4324/9780203771587. Cohen",
      "offered these values as",
      "conventions for use only when no better basis for judging magnitude is",
      "available."
    )
  ),
  sawilowsky_d = list(
    cuts = c(0.01, 0.2, 0.5, 0.8, 1.2, 2.0),
    labels = c("negligible", "very small", "small", "medium", "large",
               "very large", "huge"),
    metric = "d",
    title = "Sawilowsky (2009), d",
    source = paste(
      "Sawilowsky SS (2009). New effect size rules of thumb. Journal of Modern",
      "Applied Statistical Methods 8(2):597-599. doi:10.22237/jmasm/1257035100."
    )
  ),
  cohen_r = list(
    cuts = c(0.1, 0.3, 0.5),
    labels = c("negligible", "small", "medium", "large"),
    metric = "r",
    title = "Cohen (1988), r",
    source = paste(
      "Cohen J (1988). Statistical Power Analysis for the Behavioral Sciences,",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum. doi:10.4324/9780203771587."
    )
  ),
  funder_ozer_r = list(
    cuts = c(0.05, 0.10, 0.20, 0.30, 0.40),
    labels = c("negligible", "very small", "small", "medium", "large",
               "very large"),
    metric = "r",
    title = "Funder & Ozer (2019), r",
    source = paste(
      "Funder DC, Ozer DJ (2019). Evaluating effect size in psychological",
      "research: sense and nonsense. Advances in Methods and Practices in",
      "Psychological Science 2(2):156-168. doi:10.1177/2515245919847202."
    )
  ),
  gignac_szodorai_r = list(
    cuts = c(0.10, 0.20, 0.30),
    labels = c("negligible", "relatively small", "typical", "relatively large"),
    metric = "r",
    title = "Gignac & Szodorai (2016), r",
    source = paste(
      "Gignac GE, Szodorai ET (2016). Effect size guidelines for individual",
      "differences researchers. Personality and Individual Differences",
      "102:74-78. doi:10.1016/j.paid.2016.06.069. Derived from the",
      "distribution of published correlations in individual-differences",
      "research."
    )
  ),
  cohen_eta2 = list(
    cuts = c(0.01, 0.06, 0.14),
    labels = c("negligible", "small", "medium", "large"),
    metric = "eta2",
    title = "Cohen (1988), \u{03b7}\u{00b2}",
    source = paste(
      "Cohen J (1988). Statistical Power Analysis for the Behavioral Sciences,",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum. doi:10.4324/9780203771587."
    )
  ),
  cohen_f = list(
    cuts = c(0.10, 0.25, 0.40),
    labels = c("negligible", "small", "medium", "large"),
    metric = "f",
    title = "Cohen (1988), f",
    source = paste(
      "Cohen J (1988). Statistical Power Analysis for the Behavioral Sciences,",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum. doi:10.4324/9780203771587."
    )
  ),
  chen_or = list(
    cuts = c(1.68, 3.47, 6.71),
    # Not published: Chen et al.'s method applied to d = -0.2/-0.5/-0.8 at
    # 1% baseline risk (see chen_or_thresholds()), rounded like the
    # published values.
    cuts_lower = c(1.74, 4.28, 11.40),
    labels = c("negligible", "small", "medium", "large"),
    metric = "or",
    title = "Chen et al. (2010), OR at 1% baseline risk",
    source = paste(
      "Chen H, Cohen P, Chen S (2010). How big is a big odds ratio?",
      "Interpreting the magnitudes of odds ratios in epidemiological studies.",
      "Communications in Statistics - Simulation and Computation",
      "39(4):860-864. doi:10.1080/03610911003650383. These odds ratios",
      "correspond to d = 0.2, 0.5 and 0.8",
      "only when the event rate in the reference group is 1%; the equivalent",
      "odds ratios are smaller at higher baseline risks. The published values",
      "are for OR > 1; the boundaries below 1 (1/1.74, 1/4.28, 1/11.40) apply",
      "the same method to negative d. Use chen_or_thresholds() for other",
      "baseline risks."
    )
  )
)

#' Published effect-size benchmark sets
#'
#' Look up a published set of effect-size cut-points and return it as an
#' [es_thresholds()] object with a `source` citation. Call with no argument
#' to list the available sets.
#'
#' | set | metric | cuts | source |
#' |---|---|---|---|
#' | `"cohen_d"` | d | 0.2, 0.5, 0.8 | Cohen (1988) |
#' | `"sawilowsky_d"` | d | 0.01, 0.2, 0.5, 0.8, 1.2, 2.0 | Sawilowsky (2009) |
#' | `"cohen_r"` | r | 0.1, 0.3, 0.5 | Cohen (1988) |
#' | `"funder_ozer_r"` | r | 0.05, 0.10, 0.20, 0.30, 0.40 | Funder & Ozer (2019) |
#' | `"gignac_szodorai_r"` | r | 0.10, 0.20, 0.30 | Gignac & Szodorai (2016) |
#' | `"cohen_eta2"` | eta2 | 0.01, 0.06, 0.14 | Cohen (1988) |
#' | `"cohen_f"` | f | 0.10, 0.25, 0.40 | Cohen (1988) |
#' | `"chen_or"` | or | 1.68, 3.47, 6.71 | Chen, Cohen & Chen (2010) |
#'
#' @section There is no default set:
#' Benchmarks are field- and outcome-specific. Cohen (1988) presented his
#' values as a fallback for when nothing better is available, and later
#' sets (Funder & Ozer 2019; Gignac & Szodorai 2016) were derived from the
#' distribution of effects in particular literatures. [geom_es_zones()]
#' therefore requires you to choose a set explicitly.
#'
#' The cited sources define cut-points; the name of the zone below the first
#' cut ("negligible") is a convention of this package.
#'
#' `"chen_or"` is tied to a 1% event rate in the reference group: Chen et
#' al. (2010) show that the odds ratio equivalent to a given d depends on
#' the baseline risk, and is smaller when the baseline risk is higher. Use
#' [chen_or_thresholds()] for other baseline risks. Under their method the
#' zones are not symmetric on the log scale: the published values are the
#' boundaries above 1, and the boundaries below 1 (1/1.74, 1/4.28, 1/11.40)
#' are computed by applying the method to negative d.
#'
#' @param set Name of the benchmark set. If missing, the available sets are
#'   printed and returned invisibly.
#' @return An [es_thresholds()] object, or (when `set` is missing) an
#'   invisible character vector of set names.
#' @references
#' Cohen J (1988). *Statistical Power Analysis for the Behavioral Sciences*,
#' 2nd ed. Hillsdale, NJ: Lawrence Erlbaum. \doi{10.4324/9780203771587}
#'
#' Sawilowsky SS (2009). New effect size rules of thumb. *Journal of Modern
#' Applied Statistical Methods* 8(2):597-599. \doi{10.22237/jmasm/1257035100}
#'
#' Funder DC, Ozer DJ (2019). Evaluating effect size in psychological
#' research: sense and nonsense. *Advances in Methods and Practices in
#' Psychological Science* 2(2):156-168. \doi{10.1177/2515245919847202}
#'
#' Gignac GE, Szodorai ET (2016). Effect size guidelines for individual
#' differences researchers. *Personality and Individual Differences*
#' 102:74-78. \doi{10.1016/j.paid.2016.06.069}
#'
#' Chen H, Cohen P, Chen S (2010). How big is a big odds ratio? Interpreting
#' the magnitudes of odds ratios in epidemiological studies. *Communications
#' in Statistics - Simulation and Computation* 39(4):860-864. \doi{10.1080/03610911003650383}
#' @seealso [es_thresholds()], [geom_es_zones()]
#' @export
#' @examples
#' es_benchmarks()
#' es_benchmarks("cohen_d")
es_benchmarks <- function(set) {
  if (missing(set)) {
    sets <- names(benchmark_sets)
    for (s in sets) {
      b <- benchmark_sets[[s]]
      cli::cli_text("{.val {s}}: {b$metric}, cuts {fmt_num(b$cuts)} ({b$title})")
    }
    return(invisible(sets))
  }
  set <- rlang::arg_match(set, names(benchmark_sets))
  b <- benchmark_sets[[set]]
  new_es_thresholds(b$cuts, b$labels, b$metric, b$source, title = b$title,
                    cuts_lower = b$cuts_lower)
}
