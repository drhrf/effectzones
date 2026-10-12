#' Minimal clinically important difference (MCID) thresholds
#'
#' Define the boundaries of a "trivial" zone around the null, flanked by a
#' "benefit" zone and a "harm" zone, for use with [geom_mcid_zones()].
#'
#' `lower` and `upper` are positions on the difference scale, relative to
#' the null: `lower` must be negative and `upper` positive. Which of them is
#' the improvement threshold depends on `direction`:
#'
#' * `"higher_better"`: differences above `upper` are benefit, below
#'   `lower` are harm (deterioration).
#' * `"lower_better"`: differences below `lower` are benefit, above
#'   `upper` are harm.
#'
#' The two thresholds need not be equal in size (asymmetric MCIDs are
#' common, for example when deterioration is felt at a smaller change than
#' improvement). Each may be a single value or a length-2 range, which
#' expresses uncertainty about where the threshold lies (for example, two
#' anchor-based studies that disagree). [geom_mcid_zones()] draws a range
#' as a gradual transition rather than a line.
#'
#' A single positive value `mcid = x` is shorthand for `lower = -x,
#' upper = x`. A length-2 positive `mcid` gives a symmetric range.
#'
#' @param lower,upper Thresholds on the difference scale: `lower < 0 <
#'   upper`. Each is a number or a length-2 range.
#' @param direction Whether higher (`"higher_better"`) or lower
#'   (`"lower_better"`) values of the outcome are desirable.
#' @param source Optional citation for the thresholds, shown in the legend
#'   title.
#' @param provisional `TRUE` when the thresholds are not patient-derived
#'   (e.g. distribution-based, see [mcid_distribution()]). The legend title
#'   then says so.
#' @param mcid Symmetric shorthand: a positive number (or length-2 positive
#'   range) used for both sides. Cannot be combined with `lower`/`upper`.
#'
#' @return An object of class `mcid_thresholds`.
#' @references
#' Jaeschke R, Singer J, Guyatt GH (1989). Measurement of health status:
#' ascertaining the minimal clinically important difference. *Controlled
#' Clinical Trials* 10(4):407-415. \doi{10.1016/0197-2456(89)90005-6}
#'
#' McGlothlin AE, Lewis RJ (2014). Minimal clinically important difference:
#' defining what really matters to patients. *JAMA* 312(13):1342-1343. \doi{10.1001/jama.2014.13128}
#' @seealso [mcid_distribution()], [geom_mcid_zones()]
#' @export
#' @examples
#' # Symmetric: +/- 10 points
#' mcid_thresholds(mcid = 10)
#'
#' # Asymmetric, with an uncertain improvement threshold
#' mcid_thresholds(lower = -5, upper = c(8, 12),
#'                 source = "Anchor-based (two studies)")
#'
#' # Pain score: lower is better
#' mcid_thresholds(lower = -1.5, upper = 1, direction = "lower_better")
mcid_thresholds <- function(lower = NULL, upper = NULL,
                            direction = c("higher_better", "lower_better"),
                            source = NULL, provisional = FALSE, mcid = NULL) {
  direction <- rlang::arg_match(direction)
  if (!is.null(mcid)) {
    if (!is.null(lower) || !is.null(upper)) {
      cli::cli_abort("Supply either {.arg mcid} or {.arg lower}/{.arg upper}, not both.")
    }
    check_threshold(mcid, "mcid", sign = 1)
    lower <- -rev(mcid)
    upper <- mcid
  }
  if (is.null(lower) || is.null(upper)) {
    cli::cli_abort(c(
      "Both {.arg lower} and {.arg upper} are required.",
      "i" = "Use {.code mcid = x} for symmetric thresholds at {.code -x} and {.code +x}."
    ))
  }
  lower <- sort(check_threshold(lower, "lower", sign = -1))
  upper <- sort(check_threshold(upper, "upper", sign = 1))
  if (!is.null(source) && (!is.character(source) || length(source) != 1)) {
    cli::cli_abort("{.arg source} must be a single string or {.code NULL}.")
  }
  if (!rlang::is_bool(provisional)) {
    cli::cli_abort("{.arg provisional} must be {.code TRUE} or {.code FALSE}.")
  }
  structure(
    list(lower = lower, upper = upper, direction = direction, source = source,
         provisional = provisional, sd = NULL),
    class = "mcid_thresholds"
  )
}

check_threshold <- function(x, arg, sign, call = rlang::caller_env()) {
  if (!is.numeric(x) || !length(x) %in% 1:2 || anyNA(x) || any(!is.finite(x))) {
    cli::cli_abort("{.arg {arg}} must be a finite number or a length-2 range.",
                   call = call)
  }
  if (any(sign * x <= 0)) {
    what <- if (sign > 0) "positive" else "negative"
    cli::cli_abort(c(
      "{.arg {arg}} must be {what}.",
      "i" = "Thresholds are differences from the null: {.code lower < 0 < upper}."
    ), call = call)
  }
  if (length(x) == 2 && x[1] == x[2]) {
    cli::cli_abort("A range in {.arg {arg}} must have two different values.",
                   call = call)
  }
  as.numeric(x)
}

#' @export
print.mcid_thresholds <- function(x, ...) {
  benefit_upper <- x$direction == "higher_better"
  cli::cli_text("{.cls mcid_thresholds} ({x$direction})")
  cli::cli_text("{.strong {if (benefit_upper) 'harm' else 'benefit'}}: difference < {fmt_range(x$lower)}")
  cli::cli_text("{.strong trivial}: between {fmt_range(x$lower)} and {fmt_range(x$upper)}")
  cli::cli_text("{.strong {if (benefit_upper) 'benefit' else 'harm'}}: difference > {fmt_range(x$upper)}")
  if (x$provisional) {
    cli::cli_text("{.emph Provisional: not derived from patients' judgements.}")
  }
  if (!is.null(x$source)) cli::cli_text("Source: {x$source}")
  invisible(x)
}

#' Distribution-based (provisional) MCID
#'
#' Compute a distribution-based MCID and return it as symmetric
#' [mcid_thresholds()] marked `provisional = TRUE`. This is never done
#' automatically: you must call it explicitly.
#'
#' * `"half_sd"`: `0.5 * sd` (Norman, Sloan & Wyrwich 2003).
#' * `"one_fifth_sd"`: `0.2 * sd`, a convention equal to Cohen's "small" d.
#' * `"sem"`: one standard error of measurement, `sd * sqrt(1 - reliability)`
#'   (Wyrwich, Tierney & Wolinsky 1999); requires `reliability`.
#'
#' @section Why "provisional":
#' Distribution-based values describe the spread or the measurement error of
#' a score, not what patients regard as a worthwhile change. McGlothlin &
#' Lewis (2014) object that such values are not patient-derived and should
#' not be treated as an MCID in their own right; anchor-based estimates are
#' preferred. The legend of [geom_mcid_zones()] is therefore titled
#' "MCID (provisional, distribution-based)".
#'
#' Note also that half an SD is exactly Cohen's "medium" standardised
#' difference (d = 0.5) and one fifth of an SD is his "small" (d = 0.2). A
#' distribution-based MCID therefore adds no clinical information beyond
#' [geom_es_zones()] with [es_benchmarks("cohen_d")][es_benchmarks()]; it
#' only relabels effect-size zones in clinical language.
#'
#' @param sd Standard deviation of the outcome (in the population the MCID
#'   should describe, usually baseline SD).
#' @param method `"half_sd"`, `"sem"` or `"one_fifth_sd"`.
#' @param reliability Reliability coefficient of the instrument (e.g.
#'   test-retest ICC), required for `method = "sem"`.
#' @param direction Passed to [mcid_thresholds()].
#' @return An [mcid_thresholds()] object with `provisional = TRUE`.
#' @references
#' Norman GR, Sloan JA, Wyrwich KW (2003). Interpretation of changes in
#' health-related quality of life: the remarkable universality of half a
#' standard deviation. *Medical Care* 41(5):582-592. \doi{10.1097/01.mlr.0000062554.74615.4c}
#'
#' Wyrwich KW, Tierney WM, Wolinsky FD (1999). Further evidence supporting an
#' SEM-based criterion for identifying meaningful intra-individual changes in
#' health-related quality of life. *Journal of Clinical Epidemiology*
#' 52(9):861-873. \doi{10.1016/s0895-4356(99)00071-2}
#'
#' McGlothlin AE, Lewis RJ (2014). Minimal clinically important difference:
#' defining what really matters to patients. *JAMA* 312(13):1342-1343. \doi{10.1001/jama.2014.13128}
#' @export
#' @examples
#' mcid_distribution(sd = 10)
#' mcid_distribution(sd = 10, method = "sem", reliability = 0.84)
mcid_distribution <- function(sd, method = c("half_sd", "sem", "one_fifth_sd"),
                              reliability = NULL,
                              direction = c("higher_better", "lower_better")) {
  check_number_positive(sd)
  method <- rlang::arg_match(method)
  caveat <- paste(
    "Distribution-based values are not patient-derived (McGlothlin AE, Lewis",
    "RJ (2014). JAMA 312(13):1342-1343, doi:10.1001/jama.2014.13128) and are",
    "provisional until an",
    "anchor-based MCID is available."
  )
  if (method == "sem") {
    if (is.null(reliability)) {
      cli::cli_abort(c(
        "{.code method = \"sem\"} requires {.arg reliability}.",
        "i" = "The SEM is {.code sd * sqrt(1 - reliability)}."
      ))
    }
    if (!is.numeric(reliability) || length(reliability) != 1 ||
        !is.finite(reliability) || reliability <= 0 || reliability >= 1) {
      cli::cli_abort("{.arg reliability} must be a single number strictly between 0 and 1.")
    }
    value <- sd * sqrt(1 - reliability)
    source <- paste0(
      "One SEM = SD x sqrt(1 - reliability) = ", fmt_num(sd), " x sqrt(1 - ",
      fmt_num(reliability), ") = ", fmt_num(value), ". SEM-based criterion: ",
      "Wyrwich KW, Tierney WM, Wolinsky FD (1999). J Clin Epidemiol ",
      "52(9):861-873. doi:10.1016/s0895-4356(99)00071-2. ", caveat
    )
  } else {
    if (!is.null(reliability)) {
      cli::cli_warn("{.arg reliability} is ignored unless {.code method = \"sem\"}.")
    }
    k <- if (method == "half_sd") 0.5 else 0.2
    value <- k * sd
    source <- if (method == "half_sd") {
      paste0(
        "Half SD = 0.5 x ", fmt_num(sd), " = ", fmt_num(value), ". Norman GR, ",
        "Sloan JA, Wyrwich KW (2003). Med Care 41(5):582-592.",
        " doi:10.1097/01.mlr.0000062554.74615.4c. Equal to ",
        "Cohen's 'medium' d = 0.5. ", caveat
      )
    } else {
      paste0(
        "One fifth SD = 0.2 x ", fmt_num(sd), " = ", fmt_num(value),
        ". Equal to Cohen's 'small' d = 0.2. ", caveat
      )
    }
  }
  out <- mcid_thresholds(mcid = value, direction = direction, source = source,
                         provisional = TRUE)
  out$method <- method
  out
}
