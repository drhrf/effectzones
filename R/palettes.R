es_palettes <- list(
  grey = c("#FFFFFF", "#404040"),
  blue = c("#FFFFFF", "#08519C")
)

mcid_palettes <- list(
  # Blue/orange is distinguishable under the common colour-vision
  # deficiencies; both hues are muted so estimates on top stay legible.
  diverging = c(harm = "#C9792F", trivial = "#F5F5F5", benefit = "#3F7BAE"),
  # Two clearly different grey levels; direction cannot be read from grey
  # alone, so labels = TRUE is recommended with this palette.
  grey = c(harm = "#3A3A3A", trivial = "#FFFFFF", benefit = "#A8A8A8")
)

check_colours <- function(x, arg, call = rlang::caller_env()) {
  ok <- vapply(x, function(col) {
    !inherits(try(scales::col2hcl(col), silent = TRUE), "try-error")
  }, logical(1))
  if (!is.character(x) || anyNA(x) || !all(ok)) {
    cli::cli_abort("{.arg {arg}} must contain valid colour specifications.",
                   call = call)
  }
  invisible(x)
}

# Sequential ramp for effect-size zones: `k` colours, lightest first.
es_palette <- function(palette, k, call = rlang::caller_env()) {
  if (is.character(palette) && length(palette) == 1 && palette %in% names(es_palettes)) {
    ends <- es_palettes[[palette]]
    return(scales::colour_ramp(ends)(seq(0, 1, length.out = k)))
  }
  if (is.character(palette) && length(palette) == 1) {
    cli::cli_abort(c(
      "Unknown {.arg palette} {.val {palette}}.",
      "i" = "Use {.or {.val {names(es_palettes)}}}, {k} colours (lightest first), or 2 colours to interpolate between."
    ), call = call)
  }
  check_colours(palette, "palette", call = call)
  if (length(palette) == k) return(unname(palette))
  if (length(palette) == 2) {
    return(scales::colour_ramp(palette)(seq(0, 1, length.out = k)))
  }
  cli::cli_abort(c(
    "{.arg palette} must have {k} colours (one per zone, lightest first) or 2 colours to interpolate between.",
    "x" = "It has {length(palette)}."
  ), call = call)
}

# Harm / trivial / benefit colours for MCID zones.
mcid_palette <- function(palette, call = rlang::caller_env()) {
  if (is.character(palette) && length(palette) == 1) {
    if (!palette %in% names(mcid_palettes)) {
      cli::cli_abort(c(
        "Unknown {.arg palette} {.val {palette}}.",
        "i" = "Use {.or {.val {names(mcid_palettes)}}} or three colours named {.code harm}, {.code trivial}, {.code benefit}."
      ), call = call)
    }
    return(mcid_palettes[[palette]])
  }
  check_colours(palette, "palette", call = call)
  if (length(palette) != 3) {
    cli::cli_abort("A custom {.arg palette} needs three colours: harm, trivial, benefit.",
                   call = call)
  }
  nms <- names(palette)
  if (is.null(nms)) {
    names(palette) <- c("harm", "trivial", "benefit")
  } else if (!setequal(nms, c("harm", "trivial", "benefit"))) {
    cli::cli_abort("Names of {.arg palette} must be {.code harm}, {.code trivial} and {.code benefit}.",
                   call = call)
  }
  palette[c("harm", "trivial", "benefit")]
}
