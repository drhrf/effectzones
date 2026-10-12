#' Odds-ratio thresholds equivalent to d at a given baseline risk
#'
#' Chen, Cohen & Chen (2010) translate Cohen's d into odds ratios by placing
#' both groups on a latent normal scale. If `p0` is the event risk in the
#' reference (unexposed) group, a standardised difference `d` corresponds
#' to an event risk in the exposed group of
#'
#' \deqn{p_1 = \Phi(\Phi^{-1}(p_0) + d)}
#'
#' and the odds ratio is
#'
#' \deqn{OR = \frac{p_1 / (1 - p_1)}{p_0 / (1 - p_0)}.}
#'
#' This reproduces the published values: OR = 1.68, 3.47 and 6.71 for d =
#' 0.2, 0.5 and 0.8 at p0 = 1%, and 1.52, 2.74 and 4.72 at p0 = 5%.
#'
#' @section Why the zones are asymmetric:
#' Under this model the odds ratio for a protective effect (d < 0) is not
#' the reciprocal of the odds ratio for the same harmful effect, except at
#' p0 = 0.5. At p0 = 1%, d = -0.8 corresponds to OR = 0.088 (1 / 11.4), not
#' 1 / 6.71 = 0.149. `chen_or_thresholds()` therefore computes the boundaries
#' below 1 from d < 0 directly (`cuts_lower` in [es_thresholds()]), rather
#' than mirroring the boundaries above 1. Chen et al. tabulated only
#' odds ratios above 1; the boundaries below 1 apply their method to
#' negative d and are not published values.
#'
#' `p0` must be the risk in the group in the denominator of the odds ratio
#' (the reference group of your estimates).
#'
#' @param baseline_risk Event risk in the reference group, strictly between
#'   0 and 1.
#' @param d Positive standardised differences that define the cut-points.
#' @param labels Zone labels, one more than `d`.
#' @return An [es_thresholds()] object with `metric = "or"`, for use with
#'   [geom_es_zones()] and `scale = "log"`.
#' @references
#' Chen H, Cohen P, Chen S (2010). How big is a big odds ratio? Interpreting
#' the magnitudes of odds ratios in epidemiological studies. *Communications
#' in Statistics - Simulation and Computation* 39(4):860-864.
#' @seealso [es_benchmarks()] (`"chen_or"`, the published 1% values)
#' @export
#' @examples
#' chen_or_thresholds(0.01)
#' chen_or_thresholds(0.20)
chen_or_thresholds <- function(baseline_risk, d = c(0.2, 0.5, 0.8),
                               labels = c("negligible", "small", "medium", "large")) {
  if (!is.numeric(baseline_risk) || length(baseline_risk) != 1 ||
      !is.finite(baseline_risk) || baseline_risk <= 0 || baseline_risk >= 1) {
    cli::cli_abort("{.arg baseline_risk} must be a single number strictly between 0 and 1.")
  }
  check_cuts(d, "d", arg = "d")
  upper <- or_from_d(d, baseline_risk)
  lower <- 1 / or_from_d(-d, baseline_risk)
  pct <- paste0(fmt_num(100 * baseline_risk), "%")
  out <- es_thresholds(
    cuts = upper, labels = labels, metric = "or", cuts_lower = lower,
    source = paste0(
      "Odds ratios equivalent to d = ", paste(fmt_num(d), collapse = "/"),
      " at a ", pct, " baseline risk, by the method of Chen H, Cohen P, Chen S",
      " (2010). Commun Stat Simul Comput 39(4):860-864. Boundaries below 1",
      " apply the method to negative d."
    )
  )
  out$title <- paste0("Chen et al. (2010) method, OR at ", pct, " baseline risk")
  out$baseline_risk <- baseline_risk
  out
}

# Odds ratio corresponding to a latent-normal shift d at baseline risk p0
# (Chen, Cohen & Chen 2010).
or_from_d <- function(d, p0) {
  p1 <- stats::pnorm(stats::qnorm(p0) + d)
  (p1 / (1 - p1)) / (p0 / (1 - p0))
}
