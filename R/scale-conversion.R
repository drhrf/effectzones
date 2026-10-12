#' Convert thresholds to the scale of the plot axis
#'
#' Thresholds are defined on the scale of an effect-size metric; estimates
#' are often plotted on another scale (raw mean differences, odds ratios).
#' `to_plot_scale()` converts thresholds to the axis on which the estimates
#' are drawn. [geom_es_zones()] and [geom_mcid_zones()] call it for you; use
#' it directly to inspect the boundaries that will be drawn.
#'
#' @section Effect-size thresholds:
#' * `d` with `sd`: cuts are multiplied by `sd` to give raw differences.
#'   Which SD to use is a substantive choice; for contrasts from a linear
#'   model the residual SD ([pooled_sd()]) is the usual one, but a baseline
#'   or reference-population SD may be more appropriate.
#' * `d` with `scale = "log"`: cuts are converted to odds ratios with
#'   `log(OR) = d * pi / sqrt(3)` (Chinn 2000). This is an approximation
#'   that assumes an underlying logistic distribution; it is not the same
#'   mapping as [es_benchmarks("chen_or")][es_benchmarks()].
#' * `or`/`rr` with `scale = "log"`: zones are multiplicative around the
#'   null: a cut `c` gives boundaries `null / c` and `null * c` (symmetric
#'   on the log scale unless `cuts_lower` differs from `cuts`).
#'   Use with `null = 1` and a log axis (e.g. [ggplot2::scale_x_log10()]).
#' * `or`/`rr` with `scale = "identity"`: for an axis showing log ratios on
#'   a linear scale; cuts become `-log(c)` and `log(c)` around `null = 0`.
#' * `r`, `eta2`, `f`: drawn on their own scale only. There is no
#'   conversion to raw differences.
#'
#' @section MCID thresholds:
#' MCIDs are already on the raw scale. If `sd` is given they are divided by
#' it, for an axis showing standardised differences.
#'
#' @param thresholds An [es_thresholds()] or [mcid_thresholds()] object.
#' @param sd Standard deviation used for conversion between standardised
#'   and raw units, or `NULL`.
#' @param scale `"identity"` (additive zones, `null +/- cut`) or `"log"`
#'   (multiplicative zones, `null * cut` and `null / cut`).
#' @return An object of the same class with converted thresholds. The
#'   `scale` element records whether zones are additive or multiplicative
#'   and `note` describes the conversion.
#' @references
#' Chinn S (2000). A simple method for converting an odds ratio to effect
#' size for use in meta-analysis. *Statistics in Medicine*
#' 19(22):3127-3131. \doi{10.1002/1097-0258(20001130)19:22<3127::AID-SIM784>3.0.CO;2-M}
#' @export
#' @examples
#' to_plot_scale(es_benchmarks("cohen_d"), sd = 2)
#' to_plot_scale(es_benchmarks("cohen_d"), scale = "log")
#' to_plot_scale(es_benchmarks("chen_or"), scale = "log")
to_plot_scale <- function(thresholds, sd = NULL, scale = c("identity", "log")) {
  UseMethod("to_plot_scale")
}

#' @export
to_plot_scale.default <- function(thresholds, sd = NULL, scale = c("identity", "log")) {
  cli::cli_abort(
    "{.arg thresholds} must be an {.cls es_thresholds} or {.cls mcid_thresholds} object, not {.obj_type_friendly {thresholds}}."
  )
}

#' @export
to_plot_scale.es_thresholds <- function(thresholds, sd = NULL, scale = c("identity", "log")) {
  scale <- rlang::arg_match(scale)
  if (!is.null(sd)) check_number_positive(sd)
  x <- thresholds
  metric <- x$metric
  if (!identical(x$scale, "identity") || metric %in% c("log_or", "log_rr")) {
    # Already converted: only a no-op request is allowed.
    if (!is.null(sd) || scale != x$scale) {
      cli::cli_abort("These thresholds have already been converted ({x$note}).")
    }
    return(x)
  }
  if (metric %in% c("r", "eta2", "f")) {
    if (!is.null(sd) || scale != "identity") {
      cli::cli_abort(c(
        "Thresholds on the {.val {metric}} scale are drawn on their own scale only.",
        "i" = "There is no conversion from {.val {metric}} to raw differences or ratios; use {.code sd = NULL, scale = \"identity\"}."
      ))
    }
    return(x)
  }
  if (metric == "raw") {
    if (!is.null(sd) || scale != "identity") {
      cli::cli_abort("Thresholds with {.code metric = \"raw\"} are already on the raw scale; use {.code sd = NULL, scale = \"identity\"}.")
    }
    return(x)
  }
  if (metric == "d") {
    if (scale == "identity") {
      if (is.null(sd)) return(x)
      x$cuts <- x$cuts * sd
      x$cuts_lower <- x$cuts_lower * sd
      x$metric <- "raw"
      x$note <- paste0("d cut-points multiplied by SD = ", fmt_num(sd), ".")
      return(x)
    }
    if (!is.null(sd)) {
      cli::cli_abort("{.arg sd} is not used when converting d to odds ratios; set {.code sd = NULL}.")
    }
    x$cuts <- exp(x$cuts * pi / sqrt(3))
    x$cuts_lower <- exp(x$cuts_lower * pi / sqrt(3))
    x$metric <- "or"
    x$scale <- "log"
    x$note <- paste(
      "Approximation: log(OR) = d * pi / sqrt(3) (Chinn 2000), which assumes",
      "a logistic latent variable."
    )
    return(x)
  }
  # Ratio metrics
  if (!is.null(sd)) {
    cli::cli_abort("{.arg sd} is not used for ratio metrics ({.val {metric}}).")
  }
  if (scale == "log") {
    x$scale <- "log"
    x$note <- "Multiplicative zones: boundaries at null / c and null * c."
  } else {
    x$cuts <- log(x$cuts)
    x$cuts_lower <- log(x$cuts_lower)
    x$metric <- paste0("log_", metric)
    x$note <- "Cut-points on the log-ratio scale: boundaries at -log(c) and log(c)."
  }
  x
}

#' @export
to_plot_scale.mcid_thresholds <- function(thresholds, sd = NULL, scale = c("identity", "log")) {
  scale <- rlang::arg_match(scale)
  if (scale != "identity") {
    cli::cli_abort("MCID thresholds are differences on the raw scale; only {.code scale = \"identity\"} is supported.")
  }
  x <- thresholds
  if (is.null(sd)) return(x)
  check_number_positive(sd)
  if (!is.null(x$sd)) {
    cli::cli_abort("These MCID thresholds have already been standardised.")
  }
  x$lower <- x$lower / sd
  x$upper <- x$upper / sd
  x$sd <- sd
  x
}

#' Pooled (residual) standard deviation of a model
#'
#' Returns the residual standard deviation (the square root of the mean
#' squared error) used to convert standardised thresholds to the raw scale
#' of model contrasts.
#'
#' * `lm`/`aov`: [stats::sigma()].
#' * `emmGrid` (from \pkg{emmeans}): the `sigma` stored with the reference
#'   grid, which emmeans takes from the model. Grids of contrasts (from
#'   `contrast()` or `pairs()`) do not keep it; use the `emmeans()` grid or
#'   the model.
#'
#' `pooled_sd()` always returns the residual SD when asked. In a one-way
#' model it equals the pooled within-group SD, the usual denominator of
#' Cohen's d. With several factors or covariates it is the SD left after
#' removing them, so d computed from it is a partial standardised
#' difference; [plot_contrasts()] therefore uses it automatically only for
#' one-way models.
#'
#' The residual SD is one defensible choice, not the only one. When the
#' thresholds were defined relative to another SD (e.g. the baseline SD of
#' the outcome in the target population), supply that value as `sd`
#' instead.
#'
#' @param model A fitted model.
#' @param ... Unused.
#' @return A single positive number.
#' @export
#' @examples
#' fit <- aov(weight ~ group, data = PlantGrowth)
#' pooled_sd(fit)
pooled_sd <- function(model, ...) {
  UseMethod("pooled_sd")
}

#' @export
pooled_sd.default <- function(model, ...) {
  cli::cli_abort(c(
    "Can't extract a pooled SD from {.obj_type_friendly {model}}.",
    "i" = "Methods exist for {.cls lm}, {.cls aov} and {.cls emmGrid}.",
    "i" = "Otherwise supply {.arg sd} explicitly."
  ))
}

#' @export
pooled_sd.lm <- function(model, ...) {
  if (inherits(model, "glm")) {
    cli::cli_abort(c(
      "A {.cls glm} has no residual SD on the outcome scale.",
      "i" = "Supply {.arg sd} explicitly."
    ))
  }
  s <- stats::sigma(model)
  if (!is.finite(s) || s <= 0) {
    cli::cli_abort("The model's residual SD is not a positive finite number.")
  }
  s
}

#' @export
pooled_sd.emmGrid <- function(model, ...) {
  s <- model@misc$sigma
  if (is.null(s) || !is.numeric(s) || length(s) != 1 || !is.finite(s) || s <= 0) {
    cli::cli_abort(c(
      "This {.cls emmGrid} does not carry a single residual SD.",
      "i" = "Grids from {.code contrast()} or {.code pairs()} do not keep it; use the {.code emmeans()} grid or the fitted model instead.",
      "i" = "Or supply {.arg sd} explicitly, e.g. {.code sd = sigma(model)}."
    ))
  }
  s
}
