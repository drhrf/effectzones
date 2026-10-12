#' Effect-size magnitude zones
#'
#' Draws background bands for effect-size magnitude zones ("negligible",
#' "small", "medium", ...) around the null (symmetric unless the thresholds
#' set `cuts_lower`), behind estimates and
#' confidence intervals. The layer draws a reference background only: it
#' does not look at, classify or test any estimate.
#'
#' Add the layer **before** points, error bars and reference lines so that
#' they are drawn on top of the zones.
#'
#' @section Choosing thresholds:
#' There is no default benchmark set; `thresholds` must be supplied. Cohen
#' (1988) described his d = 0.2/0.5/0.8 as a fallback for when no better
#' basis exists. Prefer thresholds grounded in your field (see
#' [es_benchmarks()] for published sets, or build your own with
#' [es_thresholds()]).
#'
#' @section Scales and axes:
#' The thresholds are converted with [to_plot_scale()] to the axis on which
#' the estimates are drawn:
#' * Standardised (`"d"`) thresholds over raw mean differences: supply `sd`
#'   (e.g. [pooled_sd()] of the model). Which SD is appropriate is a
#'   substantive decision.
#' * Odds or risk ratios: use `scale = "log"` with `null = 1` and a log axis
#'   such as [ggplot2::scale_x_log10()]. With `"d"` thresholds and
#'   `scale = "log"`, cut-points are converted to odds ratios by the Chinn
#'   (2000) approximation.
#'
#' Zone positions are layer parameters, not data: with `expand = FALSE` (the
#' default) they do not change the axis limits, and the outermost zones
#' extend to the panel edges. With `expand = TRUE` every boundary is added
#' to the scale range so all cut-points are visible.
#'
#' @section Appearance:
#' Fills are low-saturation and semi-transparent (`alpha`). The sequential
#' ramp is lightest at the null and darkest in the largest zone, mirrored on
#' both sides: direction carries no meaning in this mode. Boundaries are
#' drawn as gradual transitions spanning `softness` times each threshold
#' (`softness = 0` gives hard edges), as a reminder that the cut-points are
#' conventions, not natural discontinuities.
#'
#' @param thresholds An [es_thresholds()] object, typically from
#'   [es_benchmarks()]. Required.
#' @param sd Standard deviation used to convert standardised thresholds to
#'   the raw scale of the axis (see [to_plot_scale()]).
#' @param scale `"identity"` for additive zones (`null +/- cut`), `"log"` for
#'   multiplicative zones around `null` (ratios on a log axis).
#' @param null Position of the null on the axis: `0` for differences, `1`
#'   for ratios.
#' @param softness Width of each soft transition as a fraction of the
#'   threshold it surrounds (on the log scale for multiplicative zones).
#'   `0` gives hard edges.
#' @param palette `"grey"` (default, print-safe), `"blue"` (single hue), or
#'   a vector of colours: one per zone (lightest first) or two to interpolate
#'   between.
#' @param alpha Opacity of the fills.
#' @param orientation The axis that shows the effect: `"x"` (default, as in
#'   forest plots) or `"y"`.
#' @param expand If `TRUE`, all zone boundaries train the position scale.
#' @param labels If `TRUE`, zone names are printed inside the panel, near the
#'   top (effect on the horizontal axis) or the right edge (vertical axis).
#' @param label_size,label_colour Size (mm) and colour of zone labels.
#' @param n_slices Number of thin rectangles used to draw each soft
#'   transition.
#' @param zone_labels Optional new names for the zones, for example
#'   `"below small"` instead of `"negligible"`. Either a character vector
#'   (or list) with one name per zone, from the null outwards
#'   (`c("below small", "small", "medium", "large")`), or a named vector
#'   that renames only some zones (`c(negligible = "below small")`).
#' @param title Legend title. Defaults to the short source of the thresholds.
#' @param show.legend Should the zone legend be shown?
#' @param ... Other arguments passed to [ggplot2::layer()].
#' @return An object that can be added to a ggplot with `+`.
#' @references
#' Cohen J (1988). *Statistical Power Analysis for the Behavioral Sciences*,
#' 2nd ed. Hillsdale, NJ: Lawrence Erlbaum. \doi{10.4324/9780203771587}
#'
#' Chinn S (2000). A simple method for converting an odds ratio to effect
#' size for use in meta-analysis. *Statistics in Medicine*
#' 19(22):3127-3131. \doi{10.1002/1097-0258(20001130)19:22<3127::AID-SIM784>3.0.CO;2-M}
#' @seealso [geom_mcid_zones()], [plot_contrasts()]
#' @export
#' @examples
#' library(ggplot2)
#' fit <- aov(weight ~ group, data = PlantGrowth)
#' tk <- TukeyHSD(fit)$group
#' df <- data.frame(term = rownames(tk), estimate = tk[, "diff"],
#'                  lower = tk[, "lwr"], upper = tk[, "upr"])
#'
#' ggplot(df, aes(estimate, term)) +
#'   geom_es_zones(es_benchmarks("cohen_d"), sd = pooled_sd(fit)) +
#'   geom_vline(xintercept = 0, linetype = 2) +
#'   geom_errorbar(aes(xmin = lower, xmax = upper), width = 0.2) +
#'   geom_point() +
#'   theme_minimal()
#'
#' # Odds ratios on a log axis
#' or <- data.frame(term = c("A", "B", "C"), estimate = c(0.8, 1.9, 3.2),
#'                  lower = c(0.5, 1.2, 1.6), upper = c(1.3, 3.0, 6.4))
#' ggplot(or, aes(estimate, term)) +
#'   geom_es_zones(es_benchmarks("chen_or"), scale = "log", null = 1) +
#'   geom_errorbar(aes(xmin = lower, xmax = upper), width = 0.2) +
#'   geom_point() +
#'   scale_x_log10()
geom_es_zones <- function(thresholds, sd = NULL, scale = "identity", null = 0,
                          softness = 0.1, palette = "grey", alpha = 0.35,
                          orientation = "x", expand = FALSE, labels = FALSE,
                          label_size = 3, label_colour = "grey20",
                          n_slices = 40, zone_labels = NULL, title = NULL,
                          show.legend = NA, ...) {
  if (missing(thresholds) || is.null(thresholds)) {
    cli::cli_abort(c(
      "{.arg thresholds} is required: there is no default benchmark set.",
      "i" = "Cohen (1988) offered his d = 0.2/0.5/0.8 only as a fallback; choose thresholds that suit your field.",
      "i" = "Published sets: {.or {.val {names(benchmark_sets)}}}, e.g. {.code thresholds = es_benchmarks(\"cohen_d\")}.",
      "i" = "Or define your own with {.fn es_thresholds}."
    ))
  }
  if (!inherits(thresholds, "es_thresholds")) {
    hint <- if (inherits(thresholds, "mcid_thresholds")) {
      "For MCID thresholds use {.fn geom_mcid_zones}."
    } else {
      "Use {.fn es_benchmarks} or {.fn es_thresholds}."
    }
    cli::cli_abort(c("{.arg thresholds} must be an {.cls es_thresholds} object.",
                     "i" = hint))
  }
  scale <- rlang::arg_match(scale, c("identity", "log"))
  orientation <- rlang::arg_match(orientation, c("x", "y"))
  check_null(null)
  check_softness(softness)
  check_common_args(orientation, alpha, expand, labels, label_size, n_slices)
  if (scale == "log" && null <= 0) {
    cli::cli_abort(c(
      "With {.code scale = \"log\"} the null must be positive.",
      "i" = "For ratios use {.code null = 1}."
    ))
  }
  if (scale == "identity" && thresholds$metric %in% ratio_metrics && null != 0) {
    cli::cli_abort(c(
      "With {.code scale = \"identity\"}, ratio thresholds are drawn on the log-ratio scale, where the null is 0.",
      "i" = "For ratios on a log axis use {.code scale = \"log\", null = 1}."
    ))
  }
  thresholds$labels <- resolve_zone_labels(zone_labels, thresholds$labels)
  # Fail early on impossible conversions.
  to_plot_scale(thresholds, sd = sd, scale = scale)
  es_palette(palette, length(thresholds$labels))
  new_zones("es", list(
    thresholds = thresholds, sd = sd, scale = scale, null = null,
    softness = softness, palette = palette, alpha = alpha,
    orientation = orientation, expand = expand, labels = labels,
    label_size = label_size, label_colour = label_colour,
    n_slices = n_slices, title = title, show.legend = show.legend,
    dots = list(...)
  ))
}
