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
