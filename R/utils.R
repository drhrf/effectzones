check_number_positive <- function(x, arg = rlang::caller_arg(x),
                                  call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1 || !is.finite(x) || x <= 0) {
    cli::cli_abort("{.arg {arg}} must be a single positive finite number.",
                   call = call)
  }
  invisible(x)
}

check_choice <- function(x, choices, arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  rlang::arg_match0(x, choices, arg_nm = arg, error_call = call)
}

fmt_num <- function(x) {
  format(x, digits = 3, trim = TRUE, drop0trailing = TRUE)
}

fmt_range <- function(x) {
  if (length(x) == 1) fmt_num(x) else paste0("[", fmt_num(x[1]), ", ", fmt_num(x[2]), "]")
}

# Rename zones. `new` is NULL (keep `default`), an unnamed character vector
# or list with one name per zone in `default` order, or a named vector/list
# mapping some old names to new ones.
resolve_zone_labels <- function(new, default, arg = "zone_labels",
                                call = rlang::caller_env()) {
  if (is.null(new)) return(default)
  if (is.list(new)) {
    if (!all(vapply(new, function(v) is.character(v) && length(v) == 1, logical(1)))) {
      cli::cli_abort("Each element of {.arg {arg}} must be a single string.", call = call)
    }
    new <- unlist(new)
  }
  if (!is.character(new) || anyNA(new) || any(!nzchar(new))) {
    cli::cli_abort("{.arg {arg}} must contain non-empty strings.", call = call)
  }
  nms <- names(new)
  out <- default
  if (is.null(nms) || all(!nzchar(nms))) {
    if (length(new) != length(default)) {
      cli::cli_abort(c(
        "{.arg {arg}} must name all {length(default)} zones, in order: {.val {unname(default)}}.",
        "x" = "It has {length(new)} element{?s}.",
        "i" = "To rename only some zones, use names: {.code c(old = \"new\")}."
      ), call = call)
    }
    out[] <- unname(new)
  } else {
    if (any(!nzchar(nms))) {
      cli::cli_abort("Either name every element of {.arg {arg}} or none.", call = call)
    }
    key <- if (is.null(names(default))) default else names(default)
    unknown <- setdiff(nms, key)
    if (length(unknown)) {
      cli::cli_abort(c(
        paste0("Unknown zone name in {.arg ", arg, "}: {.val {unknown}}."),
        "i" = "Zones are {.val {key}}."
      ), call = call)
    }
    out[match(nms, key)] <- unname(new)
  }
  if (anyDuplicated(out)) {
    cli::cli_abort("Zone labels must be unique.", call = call)
  }
  out
}
