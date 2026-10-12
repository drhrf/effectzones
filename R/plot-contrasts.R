#' Forest-style plot of contrasts over interpretive zones
#'
#' Draws contrasts (rows) against their estimated difference (x axis) as
#' points with confidence-interval bars and a reference line at the null.
#' A zones layer from [geom_es_zones()] or [geom_mcid_zones()], if given, is
#' drawn first, behind everything else.
#'
#' @section Which SD converts d to the raw scale:
#' Standardised (`"d"`) thresholds must be multiplied by an SD before they
#' can be drawn over raw differences. `plot_contrasts()` takes that SD from
#' the fitted model only when the choice is not an extra assumption:
#'
#' * **One-way, fixed-effects, unweighted linear model** (e.g.
#'   `aov(y ~ group)`): the residual SD is the pooled within-group SD, the
#'   usual denominator of Cohen's d. It is the same quantity the ANOVA and
#'   the Tukey intervals already rely on (equal variances). It is used
#'   automatically and a message reports its value.
#' * **Anything else** (several factors, covariates, interactions,
#'   weights, GLMs): the residual SD has the variance of every other term
#'   removed. That is right for manipulated (randomised) factors and too
#'   small for measured factors and covariates, and the model does not
#'   record which is which. The function stops and explains the rigorous
#'   procedure: (1) decide what SD the benchmark refers to, before seeing
#'   results; (2) preferably use an external, pre-specified SD; (3)
#'   otherwise refit with only the manipulated factors and use that
#'   residual SD (Olejnik & Algina 2003), e.g.
#'   `sd = pooled_sd(update(model, . ~ treatment))`; if every term was
#'   manipulated, `sd = pooled_sd(model)`; (4) report the SD's own
#'   uncertainty.
#' @references
#' Olejnik S, Algina J (2003). Generalized eta and omega squared statistics:
#' measures of effect size for some common research designs. *Psychological
#' Methods* 8(4):434-447. \doi{10.1037/1082-989X.8.4.434}
#'
#' @section Where the model comes from:
#' * `aov` fits: pass the fit itself; Tukey contrasts are computed from it.
#' * `TukeyHSD` objects store the call that fitted the model but not the
#'   model. When an SD is needed and `model` is not given, the call is
#'   re-evaluated in the calling environment, and the refitted model is used
#'   only if its Tukey contrasts reproduce `x` exactly; otherwise an error
#'   asks for `model`. A message says when this happens.
#' * `emmGrid` of estimated means (from `emmeans()`): pairwise contrasts are
#'   computed (`emmeans::contrast(method = "pairwise")`, Tukey-adjusted), and
#'   the grid's own residual SD is used.
#' * `emmGrid` of contrasts (from `contrast()` or `pairs()`): emmeans does not
#'   keep the residual SD in contrast grids, so pass the means grid or the
#'   fit as `model`, or set `sd`.
#'
#' @param x An `aov` fit, a `TukeyHSD` object, an `emmGrid` (of means or of
#'   contrasts), or a data frame with columns `term`, `estimate`, `lower`,
#'   `upper`.
#' @param zones A zones layer from [geom_es_zones()] or [geom_mcid_zones()],
#'   or `NULL`.
#' @param ... Passed to methods. For `emmGrid`, passed to `confint()` (e.g.
#'   `level`, `adjust`).
#' @param which For `aov` and `TukeyHSD`: the term(s) to plot. Default all;
#'   several terms are shown in separate panels.
#' @param conf.level For `aov`: family-wise confidence level of the Tukey
#'   intervals.
#' @param model A fitted model (or, for emmeans contrasts, the emmeans grid
#'   of means) used to fill a missing `sd` in `zones`.
#' @param null Position of the null (reference line). Defaults to 0, or 1 for
#'   ratios from emmeans.
#' @param xlab Axis title for the difference axis.
#' @return A ggplot object.
#' @seealso [geom_es_zones()], [geom_mcid_zones()], [pooled_sd()]
#' @export
#' @examples
#' fit <- aov(weight ~ group, data = PlantGrowth)
#' plot_contrasts(fit)
#'
#' # The residual SD of the one-way model converts d to raw differences
#' plot_contrasts(fit, zones = geom_es_zones(es_benchmarks("cohen_d")))
#'
#' # A TukeyHSD object works too: its model is refitted and checked
#' tk <- TukeyHSD(fit)
#' plot_contrasts(tk, zones = geom_es_zones(es_benchmarks("cohen_d")))
#'
#' plot_contrasts(fit,
#'                zones = geom_mcid_zones(mcid_thresholds(lower = -0.3,
#'                                                        upper = c(0.4, 0.6))))
plot_contrasts <- function(x, zones = NULL, ...) {
  UseMethod("plot_contrasts")
}

#' @export
plot_contrasts.default <- function(x, zones = NULL, ...) {
  cli::cli_abort(c(
    "Can't plot contrasts from {.obj_type_friendly {x}}.",
    "i" = "Use an {.cls aov} fit, a {.cls TukeyHSD} object, an {.cls emmGrid}, or a data frame with columns {.field term}, {.field estimate}, {.field lower}, {.field upper}."
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
plot_contrasts.aov <- function(x, zones = NULL, ..., which = NULL,
                               conf.level = 0.95, xlab = NULL) {
  if (inherits(x, "aovlist")) {
    cli::cli_abort("Models with an {.code Error()} term are not supported; supply {.arg sd} and a data frame of contrasts.")
  }
  tk <- if (is.null(which)) {
    stats::TukeyHSD(x, conf.level = conf.level)
  } else {
    stats::TukeyHSD(x, which = which, conf.level = conf.level)
  }
  plot_contrasts.TukeyHSD(tk, zones = zones, model = x, xlab = xlab)
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
  # The model is recovered only if the zones actually need an SD.
  if (is.null(model)) {
    env <- parent.frame()
    model <- function() recover_tukey_model(x, env)
  }
  build_contrast_plot(df, zones = zones, model = model, null = 0, xlab = xlab,
                      log = FALSE, facet = length(which) > 1, focus = which)
}

#' @rdname plot_contrasts
#' @export
plot_contrasts.emmGrid <- function(x, zones = NULL, ..., model = NULL,
                                   xlab = NULL) {
  rlang::check_installed("emmeans", "to plot emmeans contrasts.")
  grid_df <- as.data.frame(x)
  is_contrast <- any(c("contrast", "estimate", "ratio", "odds.ratio") %in% names(grid_df))
  if (!is_contrast) {
    cli::cli_inform(c("i" = "Plotting pairwise contrasts of these means (Tukey-adjusted)."))
    model <- model %||% x
    x <- emmeans::contrast(x, method = "pairwise")
  }
  ci <- as.data.frame(stats::confint(x, ...))
  est_col <- intersect(c("estimate", "ratio", "odds.ratio"), names(ci))[1]
  lo_col <- intersect(c("lower.CL", "asymp.LCL"), names(ci))[1]
  hi_col <- intersect(c("upper.CL", "asymp.UCL"), names(ci))[1]
  term_col <- intersect(c("contrast", "term"), names(ci))[1]
  if (is.na(est_col) || is.na(lo_col) || is.na(hi_col) || is.na(term_col)) {
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
  build_contrast_plot(df, zones = zones, model = model,
                      null = if (ratio) 1 else 0, xlab = xlab, log = ratio)
}

build_contrast_plot <- function(df, zones, model, null, xlab, log, facet = FALSE,
                                focus = NULL) {
  if (!is.null(zones) && !inherits(zones, "effectzones_zones")) {
    cli::cli_abort("{.arg zones} must come from {.fn geom_es_zones} or {.fn geom_mcid_zones}.")
  }
  if (!is.null(zones)) zones <- fill_zone_sd(zones, model, focus = focus)
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
# from the model only when that is not an extra assumption (see the
# "Which SD" section of ?plot_contrasts).
fill_zone_sd <- function(zones, model, focus = NULL,
                         call = quote(plot_contrasts())) {
  a <- zones$args
  needs_sd <- zones$type == "es" && is.null(a$sd) &&
    a$thresholds$metric == "d" && a$scale == "identity"
  if (!needs_sd) return(zones)
  if (is.function(model)) model <- model()
  if (is.null(model)) {
    cli::cli_abort(c(
      "The zones use standardised ({.val d}) thresholds but the axis shows raw differences, so an SD is needed.",
      "i" = "Pass the fitted model as {.arg model}, or set {.arg sd} in the zones layer."
    ), call = call)
  }
  s <- model_sd_for_d(model, focus = focus, call = call)
  cli::cli_inform(c(
    "i" = "Converting d thresholds with the residual (pooled within-group) SD of the one-way model: {fmt_num(s)}.",
    " " = "Set {.arg sd} in the zones layer to use a different SD."
  ))
  zones$args$sd <- s
  zones
}

# Residual SD of a model, only when it equals the conventional pooled
# within-group SD: a one-way, fixed-effects, unweighted linear model.
model_sd_for_d <- function(model, focus = NULL, call = rlang::caller_env()) {
  if (inherits(model, "emmGrid")) {
    terms <- model@model.info$terms
    s <- model@misc$sigma
    if (is.null(s)) {
      cli::cli_abort(c(
        "This {.cls emmGrid} does not carry the model's residual SD (contrast grids drop it).",
        "i" = "Pass the {.code emmeans()} grid of means or the fitted model as {.arg model}, or set {.arg sd}."
      ), call = call)
    }
    why <- one_way_problem(terms, weighted = FALSE, glm = FALSE)
  } else if (inherits(model, "lm")) {
    why <- one_way_problem(stats::terms(model),
                           weighted = !is.null(stats::weights(model)),
                           glm = inherits(model, c("glm", "mlm")))
    s <- if (is.null(why)) pooled_sd(model) else NA
  } else {
    cli::cli_abort("Can't take an SD from {.obj_type_friendly {model}}; set {.arg sd} in the zones layer.",
                   call = call)
  }
  if (!is.null(why)) abort_choose_sd(why, model, focus = focus, call = call)
  s
}

one_way_problem <- function(terms, weighted, glm) {
  if (glm) return("the model is not a linear model with normal errors")
  if (weighted) return("the model is weighted")
  if (is.null(terms)) return("the model's terms are unknown")
  labels <- attr(terms, "term.labels")
  if (length(labels) != 1) {
    return(paste0("the model has ", length(labels), " terms (",
                  paste(labels, collapse = ", "), "), not one"))
  }
  NULL
}

# Re-fit the model behind a TukeyHSD object from its stored call, and accept
# it only if it reproduces the contrasts exactly.
recover_tukey_model <- function(x, env) {
  cl <- attr(x, "orig.call")
  fail <- function(reason) {
    cli::cli_abort(c(
      "Can't recover the model behind this {.cls TukeyHSD} object: {reason}.",
      "i" = "Pass the {.fn aov} fit itself ({.code plot_contrasts(fit)}) or as {.arg model}, or set {.arg sd} in the zones layer."
    ), call = NULL)
  }
  if (is.null(cl)) fail("it does not store its call")
  refit <- tryCatch(eval(cl, env), error = function(e) NULL)
  if (!inherits(refit, "aov")) fail("re-evaluating its call failed")
  level <- attr(x, "conf.level") %||% 0.95
  tk <- tryCatch(
    stats::TukeyHSD(refit, which = names(x), conf.level = level,
                    ordered = isTRUE(attr(x, "ordered"))),
    error = function(e) NULL
  )
  same <- !is.null(tk) && all(vapply(names(x), function(w) {
    identical(dimnames(tk[[w]]), dimnames(x[[w]])) &&
      isTRUE(all.equal(unclass(tk[[w]]), unclass(x[[w]]), tolerance = 1e-10))
  }, logical(1)))
  if (!same) {
    fail("refitting its call does not reproduce these contrasts (the data may have changed)")
  }
  cli::cli_inform(c(
    "i" = "Refitted {.code {deparse1(cl)}} to get the model's SD; it reproduces these Tukey contrasts exactly."
  ))
  refit
}

# The model is not one-way, so its residual SD is not automatically the right
# standardizer. Stop, and teach how to choose one (see the "Which SD" section
# of ?plot_contrasts and vignette("effectzones")).
abort_choose_sd <- function(why, model, focus = NULL, call = rlang::caller_env()) {
  labels <- if (inherits(model, "emmGrid")) {
    attr(model@model.info$terms, "term.labels")
  } else if (inherits(model, "lm")) {
    attr(stats::terms(model), "term.labels")
  }
  focus <- intersect(focus %||% character(), labels)
  if (!length(focus)) focus <- labels[1] %||% "group"
  refit <- paste0("sd = pooled_sd(update(model, . ~ ",
                  paste(focus, collapse = " * "), "))")
  cli::cli_abort(c(
    "Not choosing an SD for you: {why}.",
    "i" = paste(
      "The model's residual SD has the variance of every other term removed.",
      "That is right for factors you manipulated (randomised), but too small",
      "for factors you only measured (sex, age, site, baseline covariates):",
      "it inflates d and narrows the zones."
    ),
    " " = "",
    " " = "{.strong The rigorous procedure, in order of preference:}",
    " " = paste(
      "{.strong 1. Decide what the benchmark's SD refers to}, and fix it before",
      "seeing the results. Usually that is the SD of the outcome in the target",
      "population, at baseline."
    ),
    " " = paste(
      "{.strong 2. Best option: an external, pre-specified SD}, for example the",
      "baseline SD from the protocol or from a large prior study. It doesn't",
      "depend on the model, isn't inflated by covariate adjustment, and can't",
      "be tuned after looking at the contrasts. Give it as",
      "{.code geom_es_zones(..., sd = <value>)}."
    ),
    " " = paste(
      "{.strong 3. If the SD must come from the data}: refit the model with only",
      "the manipulated factors (the factor of interest, other randomised",
      "factors, and their interactions), and use that model's residual SD.",
      "Measured factors and covariates go back into the error term. That gives",
      "the SD of people within treatment cells, the generalized standardizer",
      "behind Olejnik & Algina (2003). For a randomised ANCOVA this amounts to",
      "the unadjusted within-group SD instead of the covariate-adjusted one.",
      "For example, if only {.field {focus}} was randomised:",
      "{.code {refit}}, where {.code model} is your fitted model.",
      "If every term in the model was manipulated (a fully randomised",
      "factorial), the model's own residual SD is the answer:",
      "{.code sd = pooled_sd(model)}."
    ),
    " " = paste(
      "{.strong 4. State the remaining sampling uncertainty.} The SD is still an",
      "estimate with finite degrees of freedom, so it has its own confidence",
      "interval, and that uncertainty carries into where each boundary sits",
      "(d \u00d7 SD). effectzones does not draw it yet: report the SD, where",
      "it came from, and its confidence interval with the plot."
    ),
    " " = "",
    "!" = paste(
      "This can't be fully automatic. Whether a factor is manipulated or",
      "measured depends on the study design, and the model object doesn't",
      "record it. So effectzones can't infer it; you have to say."
    ),
    "i" = "Worked examples: {.code vignette(\"effectzones\")}, section \"Converting thresholds to the plot scale, and which SD to use\"."
  ), call = call)
}
