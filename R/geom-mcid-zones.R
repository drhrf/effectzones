#' Clinical relevance (MCID) zones
#'
#' Draws "harm", "trivial" and "benefit" background zones defined by a
#' minimal clinically important difference (MCID) behind estimates and
#' confidence intervals. The thresholds may be asymmetric and uncertain
#' (given as ranges). The layer draws a reference background only: it does
#' not classify estimates or compute the probability that an effect is
#' beneficial.
#'
#' Add the layer **before** points, error bars and reference lines so that
#' they are drawn on top of the zones.
#'
#' @section Where the MCID comes from:
#' An MCID should come from patients' judgements (anchor-based methods;
#' Jaeschke, Singer & Guyatt 1989). Distribution-based values, created only
#' through an explicit call to [mcid_distribution()], are marked
#' provisional and the legend says so. There is no automatic MCID.
#'
#' The MCID is usually defined for change within a patient, whereas
#' contrasts between groups are differences in mean outcome. Reading group
#' differences against an MCID is common but contested; see
#' `vignette("effectzones")`.
#'
#' @section Boundaries:
#' With `softness = NULL` (default) boundaries are hard edges, except where
#' the MCID was given as a range: the background then fades from one zone to
#' the next across that range, showing where the threshold is uncertain. A
#' number gives soft transitions spanning that fraction of each point
#' threshold.
#'
#' With `beyond = "multiples"` the colour keeps deepening at 2 and 3 times
#' the MCID (capped at 3), so that an estimate at 1.2 x MCID and one at 4 x
#' MCID sit on visibly different backgrounds. Multiples are of the midpoint
#' when the MCID is a range.
#'
#' @section Palettes:
#' The default `"diverging"` palette uses muted blue (benefit) and orange
#' (harm), which remain distinguishable under the common colour-vision
#' deficiencies, around a neutral centre. The `"grey"` palette uses white
#' for trivial and two clearly different greys for benefit and harm. Grey
#' levels carry no natural direction, so use `labels = TRUE` with it (or
#' make sure the legend is printed) so readers can tell which side is
#' which. A custom palette is three colours named `harm`, `trivial`,
#' `benefit`.
#'
#' @param mcid An [mcid_thresholds()] object, or a bare positive number
#'   (symmetric shorthand for `mcid_thresholds(mcid = x)`, with higher values
#'   better).
#' @param sd If given, thresholds are divided by `sd`, for an axis that shows
#'   standardised differences.
#' @param null Position of the null on the axis.
#' @param softness `NULL` (hard edges unless the MCID is a range) or a
#'   fraction of each point threshold over which to fade.
#' @param beyond `"flat"` (default): one colour beyond the MCID.
#'   `"multiples"`: deepening colour at 2x and 3x the MCID.
#' @param palette `"diverging"` (default), `"grey"`, or three colours.
#' @inheritParams geom_es_zones
#' @return An object that can be added to a ggplot with `+`.
#' @references
#' Jaeschke R, Singer J, Guyatt GH (1989). Measurement of health status:
#' ascertaining the minimal clinically important difference. *Controlled
#' Clinical Trials* 10(4):407-415. \doi{10.1016/0197-2456(89)90005-6}
#'
#' McGlothlin AE, Lewis RJ (2014). Minimal clinically important difference:
#' defining what really matters to patients. *JAMA* 312(13):1342-1343.
#' @seealso [mcid_thresholds()], [mcid_distribution()], [geom_es_zones()]
#' @export
#' @examples
#' library(ggplot2)
#' df <- data.frame(term = c("Dose 1", "Dose 2", "Dose 3"),
#'                  estimate = c(2, 6, 11), lower = c(-3, 1, 5),
#'                  upper = c(7, 11, 17))
#'
#' ggplot(df, aes(estimate, term)) +
#'   geom_mcid_zones(mcid_thresholds(lower = -4, upper = c(5, 8))) +
#'   geom_vline(xintercept = 0, linetype = 2) +
#'   geom_errorbar(aes(xmin = lower, xmax = upper), width = 0.2) +
#'   geom_point() +
#'   theme_minimal()
#'
#' # Grey palette: label the zones
#' ggplot(df, aes(estimate, term)) +
#'   geom_mcid_zones(5, palette = "grey", labels = TRUE) +
#'   geom_errorbar(aes(xmin = lower, xmax = upper), width = 0.2) +
#'   geom_point()
geom_mcid_zones <- function(mcid, sd = NULL, null = 0, softness = NULL,
                            beyond = c("flat", "multiples"),
                            palette = "diverging", alpha = 0.35,
                            orientation = "x", expand = FALSE, labels = FALSE,
                            label_size = 3, label_colour = "grey20",
                            n_slices = 40, title = NULL, show.legend = NA, ...) {
  if (missing(mcid) || is.null(mcid)) {
    cli::cli_abort(c(
      "{.arg mcid} is required: there is no automatic MCID.",
      "i" = "Supply an anchor-based value with {.fn mcid_thresholds}, or a distribution-based (provisional) one with {.fn mcid_distribution}."
    ))
  }
  if (is.numeric(mcid)) {
    mcid <- mcid_thresholds(mcid = mcid)
  }
  if (!inherits(mcid, "mcid_thresholds")) {
    cli::cli_abort("{.arg mcid} must be an {.cls mcid_thresholds} object or a positive number.")
  }
  beyond <- rlang::arg_match(beyond)
  orientation <- rlang::arg_match(orientation, c("x", "y"))
  check_null(null)
  check_softness(softness, allow_null = TRUE)
  check_common_args(orientation, alpha, expand, labels, label_size, n_slices)
  to_plot_scale(mcid, sd = sd)
  mcid_palette(palette)
  new_zones("mcid", list(
    mcid = mcid, sd = sd, null = null, softness = softness, beyond = beyond,
    palette = palette, alpha = alpha, orientation = orientation,
    expand = expand, labels = labels, label_size = label_size,
    label_colour = label_colour, n_slices = n_slices, title = title,
    show.legend = show.legend, dots = list(...)
  ))
}
