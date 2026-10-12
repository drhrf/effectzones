#' Forest-style plot of contrasts over interpretive zones
#'
#' Draws contrasts (rows) against their estimated difference (x axis) as
#' points with confidence-interval bars and a reference line at the null.
#' A zones layer from [geom_es_zones()] or [geom_mcid_zones()], if given, is
#' drawn first, behind everything else.
#'
#' If the zones need an SD (standardised `"d"` thresholds drawn over raw
#' differences) and none was given, it is taken from the model:
#' [pooled_sd()] of `model`, or of `x` itself for `emmGrid` objects. A
#' message says so. Without a model, an error asks for `sd`.
#'
#' @param x A `TukeyHSD` object, an `emmGrid` of contrasts (e.g. from
#'   `emmeans::contrast()` or `pairs()`), or a data frame with columns
#'   `term`, `estimate`, `lower`, `upper`.
#' @param zones A zones layer from [geom_es_zones()] or [geom_mcid_zones()],
#'   or `NULL`.
#' @param ... Passed to methods. For `emmGrid`, passed to `confint()` (e.g.
#'   `level`, `adjust`).
#' @param which For `TukeyHSD`: the term(s) to plot. Default all; several
#'   terms are shown in separate panels.
#' @param model A fitted model used to fill a missing `sd` in `zones`
#'   (`TukeyHSD` objects and data frames do not carry their model).
#' @param null Position of the null (reference line). Defaults to 0, or 1 for
#'   ratios from emmeans.
#' @param xlab Axis title for the difference axis.
#' @return A ggplot object.
#' @seealso [geom_es_zones()], [geom_mcid_zones()]
#' @export
#' @examples
#' fit <- aov(weight ~ group, data = PlantGrowth)
#' plot_contrasts(TukeyHSD(fit))
#'
#' plot_contrasts(TukeyHSD(fit),
#'                zones = geom_es_zones(es_benchmarks("cohen_d")),
#'                model = fit)
#'
#' plot_contrasts(TukeyHSD(fit),
#'                zones = geom_mcid_zones(mcid_thresholds(lower = -0.3,
#'                                                        upper = c(0.4, 0.6))))
plot_contrasts <- function(x, zones = NULL, ...) {
  UseMethod("plot_contrasts")
}

#' @export
plot_contrasts.default <- function(x, zones = NULL, ...) {
  cli::cli_abort(c(
    "Can't plot contrasts from {.obj_type_friendly {x}}.",
    "i" = "Use a {.cls TukeyHSD} object, an {.cls emmGrid} of contrasts, or a data frame with columns {.field term}, {.field estimate}, {.field lower}, {.field upper}."
  ))
}

#' @rdname plot_contrasts
#' @export
plot_contrasts.data.frame <- function(x, zones = NULL, ..., model = NULL,
                                      null = 0, xlab = "Difference") {
  needed <- c("term", "estimate", "lower", "upper")
  missing_cols <- setdiff(needed, names(x))
  if (length(missing_cols)) {
    cli::cli_abort("{.arg x} is missing column{?s} {.field {missing_cols}}.")
  }
  for (col in needed[-1]) {
    if (!is.numeric(x[[col]])) cli::cli_abort("Column {.field {col}} must be numeric.")
  }
  build_contrast_plot(x, zones = zones, model = model, null = null,
                      xlab = xlab, log = FALSE)
}

#' @rdname plot_contrasts
#' @export
plot_contrasts.TukeyHSD <- function(x, zones = NULL, ..., which = NULL,
                                    model = NULL, xlab = NULL) {
  which <- which %||% names(x)
  bad <- setdiff(which, names(x))
  if (length(bad)) {
    cli::cli_abort(c("Unknown term{?s} in {.arg which}: {.val {bad}}.",
                     "i" = "Available: {.val {names(x)}}."))
  }
  df <- do.call(rbind, lapply(which, function(w) {
    m <- x[[w]]
    data.frame(term = rownames(m), estimate = m[, "diff"], lower = m[, "lwr"],
               upper = m[, "upr"], .panel = w, stringsAsFactors = FALSE)
  }))
  rownames(df) <- NULL
  level <- attr(x, "conf.level") %||% 0.95
  xlab <- xlab %||% paste0("Difference (", format(100 * level), "% family-wise CI, Tukey)")
  build_contrast_plot(df, zones = zones, model = model, null = 0, xlab = xlab,
                      log = FALSE, facet = length(which) > 1)
}

#' @rdname plot_contrasts
#' @export
plot_contrasts.emmGrid <- function(x, zones = NULL, ..., model = NULL,
                                   xlab = NULL) {
  rlang::check_installed("emmeans", "to plot emmeans contrasts.")
  ci <- as.data.frame(stats::confint(x, ...))
  est_col <- intersect(c("estimate", "ratio", "odds.ratio"), names(ci))[1]
  if (is.na(est_col)) {
    cli::cli_abort(c(
      "{.arg x} does not look like a set of contrasts.",
      "i" = "Use {.code emmeans::contrast()} or {.code pairs()} on the emmeans first."
    ))
  }
  lo_col <- intersect(c("lower.CL", "asymp.LCL"), names(ci))[1]
  hi_col <- intersect(c("upper.CL", "asymp.UCL"), names(ci))[1]
  term_col <- intersect(c("contrast", "term"), names(ci))[1]
  if (is.na(lo_col) || is.na(hi_col) || is.na(term_col)) {
    cli::cli_abort("Could not find contrast labels and confidence limits in {.code confint(x)}.")
  }
  by_vars <- x@misc$by.vars
  term <- as.character(ci[[term_col]])
  if (length(by_vars)) {
    by_lab <- do.call(paste, c(lapply(by_vars, function(v) paste0(v, " = ", ci[[v]])), sep = ", "))
    term <- paste0(term, " | ", by_lab)
  }
  df <- data.frame(term = term, estimate = ci[[est_col]], lower = ci[[lo_col]],
                   upper = ci[[hi_col]], stringsAsFactors = FALSE)
  ratio <- est_col != "estimate"
  level <- attr(ci, "level") %||% 0.95
  xlab <- xlab %||% paste0(if (ratio) "Ratio" else "Difference", " (",
                           format(100 * level), "% CI)")
  # emmGrid carries its residual SD.
  model <- model %||% tryCatch({ pooled_sd(x); x }, error = function(e) NULL)
  build_contrast_plot(df, zones = zones, model = model,
                      null = if (ratio) 1 else 0, xlab = xlab, log = ratio)
}

build_contrast_plot <- function(df, zones, model, null, xlab, log, facet = FALSE) {
  if (!is.null(zones) && !inherits(zones, "effectzones_zones")) {
    cli::cli_abort("{.arg zones} must come from {.fn geom_es_zones} or {.fn geom_mcid_zones}.")
  }
  if (!is.null(zones)) zones <- fill_zone_sd(zones, model)
  df$term <- factor(df$term, levels = rev(unique(df$term)))
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$estimate, y = .data$term))
  if (!is.null(zones)) p <- p + zones
  p <- p +
    ggplot2::geom_vline(xintercept = null, linetype = "dashed", colour = "grey30") +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$lower, xmax = .data$upper),
                           width = 0.2, orientation = "y") +
    ggplot2::geom_point(size = 2) +
    ggplot2::labs(x = xlab, y = NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank())
  if (log) p <- p + ggplot2::scale_x_log10()
  if (facet) {
    p <- p + ggplot2::facet_grid(rows = ggplot2::vars(.data$.panel),
                                 scales = "free_y", space = "free_y")
  }
  p
}

# Standardised effect-size zones over raw differences need an SD. Take it
# from the model when the user did not give one.
fill_zone_sd <- function(zones, model) {
  a <- zones$args
  needs_sd <- zones$type == "es" && is.null(a$sd) &&
    a$thresholds$metric == "d" && a$scale == "identity"
  if (!needs_sd) return(zones)
  if (is.null(model)) {
    cli::cli_abort(c(
      "The zones use standardised ({.val d}) thresholds but the axis shows raw differences, so an SD is needed.",
      "i" = "Pass {.arg model} (e.g. the {.fn aov} fit) to use its residual SD, or set {.arg sd} in the zones layer."
    ), call = rlang::caller_env(2))
  }
  s <- pooled_sd(model)
  cli::cli_inform(c(
    "i" = "Converting d thresholds with the model's pooled (residual) SD = {fmt_num(s)}.",
    " " = "Set {.arg sd} in the zones layer to use a different SD."
  ))
  zones$args$sd <- s
  zones
}
