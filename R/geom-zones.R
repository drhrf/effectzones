# Shared layer machinery. Zone boundaries are layer parameters, not position
# aesthetics, so by default they do not train the position scales: the stat
# returns them in columns (.lo, .hi) that ggplot2 does not recognise as
# positions. With expand = TRUE they are returned as xmin/xmax (or
# ymin/ymax) so that every finite boundary trains the scale.

StatZones <- ggplot2::ggproto("StatZones", ggplot2::Stat,
  required_aes = character(),
  dropped_aes = character(),

  compute_panel = function(data, scales, spec, orientation = "x",
                           n_slices = 40, expand = FALSE) {
    sc <- scales[[orientation]]
    if (!is.null(sc) && sc$is_discrete()) {
      cli::cli_abort(c(
        "The effect axis ({.field {orientation}}) must be continuous.",
        "i" = "Set {.arg orientation} to the axis that shows the estimates."
      ))
    }
    seg <- zone_segments(spec, n_slices = n_slices)
    lo <- transform_position_vec(seg$lo, sc)
    hi <- transform_position_vec(seg$hi, sc)
    bad <- is.na(lo) | is.na(hi)
    if (any(bad)) {
      cli::cli_warn(c(
        "Some zone boundaries lie outside the domain of the {.field {orientation}} scale transformation and were dropped.",
        "i" = "For ratios on a log axis use {.code scale = \"log\"} with {.code null = 1}."
      ))
    }
    seg$.lo <- pmin(lo, hi)
    seg$.hi <- pmax(lo, hi)
    seg <- seg[!bad, , drop = FALSE]
    seg$lo <- seg$hi <- NULL
    if (!isTRUE(expand) && !is.null(sc)) {
      # Keep only zones that reach the visible range, so the legend lists
      # just the zones present in the plot.
      rng <- visible_range(sc)
      if (all(is.finite(rng))) {
        seg <- seg[seg$.hi > rng[1] & seg$.lo < rng[2], , drop = FALSE]
      }
    }
    # A factor in legend order keeps the legend order fixed; unused levels
    # are dropped by the scale.
    seg$zone <- factor(seg$zone, levels = names(spec$legend))
    names(seg)[names(seg) == "fill"] <- ".fill"
    seg$PANEL <- data$PANEL[1]
    seg$group <- -1L
    if (isTRUE(expand)) {
      names(seg)[names(seg) == ".lo"] <- paste0(orientation, "min")
      names(seg)[names(seg) == ".hi"] <- paste0(orientation, "max")
    }
    seg
  }
)

# Range of a continuous position scale including its expansion, from the
# data trained so far. Coordinate limits (coord_cartesian(xlim)) are not
# known at this stage; zones are clipped to them at draw time.
visible_range <- function(scale) {
  expand <- scale$expand
  if (inherits(expand, "waiver")) expand <- ggplot2::expansion(mult = 0.05)
  out <- tryCatch(scale$dimension(expand), error = function(e) c(NA, NA))
  sort(out)
}

# Apply a position scale's transformation, keeping infinite ends infinite.
transform_position_vec <- function(x, scale) {
  if (is.null(scale)) return(x)
  out <- suppressWarnings(scale$transform(x))
  inf <- is.infinite(x)
  if (any(inf)) {
    probe <- suppressWarnings(scale$transform(c(1, 10)))
    increasing <- !anyNA(probe) && probe[2] >= probe[1]
    out[inf] <- ifelse(xor(x[inf] > 0, !increasing), Inf, -Inf)
  }
  out[is.nan(out)] <- NA
  out
}

GeomZones <- ggplot2::ggproto("GeomZones", ggplot2::Geom,
  required_aes = character(),
  default_aes = ggplot2::aes(alpha = 0.35),
  zone_aes = "zone_fill",

  draw_panel = function(self, data, panel_params, coord, orientation = "x",
                        labels = FALSE, label_size = 3,
                        label_colour = "grey20") {
    if (nrow(data) == 0) return(grid::nullGrob())
    lo_col <- if (".lo" %in% names(data)) ".lo" else paste0(orientation, "min")
    hi_col <- if (".hi" %in% names(data)) ".hi" else paste0(orientation, "max")
    rng <- coord$backtransform_range(panel_params)[[orientation]]
    rng <- sort(rng)
    lo <- pmax(data[[lo_col]], rng[1])
    hi <- pmin(data[[hi_col]], rng[2])
    keep <- hi > lo
    if (!any(keep)) return(grid::nullGrob())
    data <- data[keep, , drop = FALSE]
    lo <- lo[keep]
    hi <- hi[keep]

    other <- setdiff(c("x", "y"), orientation)
    rects <- data.frame(
      lo = lo, hi = hi, olo = -Inf, ohi = Inf,
      PANEL = data$PANEL, group = -1L,
      fill = data$.fill, colour = NA, alpha = data$alpha,
      linewidth = 0, linetype = 1
    )
    names(rects)[1:4] <- c(paste0(orientation, c("min", "max")),
                           paste0(other, c("min", "max")))
    rect_grob <- ggplot2::GeomRect$draw_panel(rects, panel_params, coord)

    if (!isTRUE(labels)) return(rect_grob)
    label_grob <- zone_label_grob(data[data$flat, , drop = FALSE],
                                  lo[data$flat], hi[data$flat],
                                  panel_params, coord, orientation,
                                  label_size, label_colour)
    grid::grobTree(rect_grob, label_grob)
  },

  draw_key = function(self, data, params, size) {
    fill <- data[[self$zone_aes]] %||% "grey80"
    grid::rectGrob(
      width = grid::unit(1, "npc") - grid::unit(1, "pt"),
      height = grid::unit(1, "npc") - grid::unit(1, "pt"),
      gp = grid::gpar(
        col = "grey60", lwd = 0.5,
        fill = scales::alpha(fill, data$alpha %||% 0.35)
      )
    )
  }
)

GeomEsZones <- ggplot2::ggproto("GeomEsZones", GeomZones,
  default_aes = ggplot2::aes(alpha = 0.35, es_zone = "grey80"),
  zone_aes = "es_zone"
)

GeomMcidZones <- ggplot2::ggproto("GeomMcidZones", GeomZones,
  default_aes = ggplot2::aes(alpha = 0.35, mcid_zone = "grey80"),
  zone_aes = "mcid_zone"
)

# Zone names printed near the top (bands across the x axis) or the right
# edge (bands across the y axis) of the panel, one per visible zone. Whether
# a label fits its zone can only be known at draw time, so the grob drops
# labels wider (or taller) than their zone in makeContent().
zone_label_grob <- function(data, lo, hi, panel_params, coord, orientation,
                            label_size, label_colour) {
  if (nrow(data) == 0) return(grid::nullGrob())
  centre <- data.frame(pos = (lo + hi) / 2, lo = lo, hi = hi)
  names(centre) <- c(orientation, paste0(orientation, c("min", "max")))
  other <- setdiff(c("x", "y"), orientation)
  centre[[other]] <- NA_real_
  tr <- coord$transform(centre, panel_params)
  # After coord$transform the effect axis is "x" if it is drawn horizontally.
  horizontal <- !all(is.na(tr$x))
  axis <- if (horizontal) "x" else "y"
  ok <- !is.na(tr[[axis]])
  if (!any(ok)) return(grid::nullGrob())
  grid::gTree(
    labels = data$zone[ok],
    pos = tr[[axis]][ok],
    extent = abs(tr[[paste0(axis, "max")]] - tr[[paste0(axis, "min")]])[ok],
    horizontal = horizontal,
    gp = grid::gpar(col = label_colour, fontsize = label_size * ggplot2::.pt),
    cl = "effectzones_labels"
  )
}

#' @importFrom grid makeContent
#' @export
makeContent.effectzones_labels <- function(x) {
  # Called after the gTree's gpar is set, so string sizes use its font.
  pad <- grid::unit(1, "mm")
  if (x$horizontal) {
    need <- grid::convertWidth(grid::stringWidth(x$labels) + pad, "npc",
                               valueOnly = TRUE)
  } else {
    need <- grid::convertHeight(grid::stringHeight(x$labels) + pad, "npc",
                                valueOnly = TRUE)
  }
  fits <- need <= x$extent
  if (!any(fits)) return(grid::setChildren(x, grid::gList()))
  txt <- if (x$horizontal) {
    grid::textGrob(x$labels[fits], x = grid::unit(x$pos[fits], "npc"),
                   y = grid::unit(1, "npc") - grid::unit(2, "mm"), vjust = 1)
  } else {
    grid::textGrob(x$labels[fits], y = grid::unit(x$pos[fits], "npc"),
                   x = grid::unit(1, "npc") - grid::unit(2, "mm"), hjust = 1)
  }
  grid::setChildren(x, grid::gList(txt))
}

# Zones objects are built lazily when added to a plot, so that
# plot_contrasts() can fill in a missing sd before the layer is created.
new_zones <- function(type, args) {
  structure(list(type = type, args = args), class = "effectzones_zones")
}

#' @export
print.effectzones_zones <- function(x, ...) {
  cli::cli_text("{.cls effectzones_zones}: {x$type} zones layer. Add it to a ggplot before points and error bars.")
  invisible(x)
}

#' @importFrom ggplot2 ggplot_add
#' @export
ggplot_add.effectzones_zones <- function(object, plot, object_name, ...) {
  parts <- build_zones(object)
  for (p in parts) plot <- ggplot2::ggplot_add(p, plot, object_name)
  plot
}

build_zones <- function(object) {
  a <- object$args
  if (object$type == "es") {
    thr <- to_plot_scale(a$thresholds, sd = a$sd, scale = a$scale)
    spec <- es_zone_spec(thr, null = a$null, softness = a$softness,
                         palette = a$palette, title = a$title)
    geom <- GeomEsZones
    aes_name <- "es_zone"
  } else {
    thr <- to_plot_scale(a$mcid, sd = a$sd)
    spec <- mcid_zone_spec(thr, null = a$null, softness = a$softness,
                           beyond = a$beyond, palette = a$palette,
                           title = a$title, role_labels = a$role_labels)
    geom <- GeomMcidZones
    aes_name <- "mcid_zone"
  }
  zone_quo <- rlang::quo(ggplot2::after_stat(.data$zone))
  mapping <- ggplot2::aes(!!!rlang::set_names(list(zone_quo), aes_name))
  layer <- ggplot2::layer(
    data = data.frame(.zones = 1),
    mapping = mapping,
    stat = StatZones, geom = geom, position = "identity",
    show.legend = a$show.legend, inherit.aes = FALSE,
    params = c(
      list(spec = spec, orientation = a$orientation, n_slices = a$n_slices,
           expand = a$expand, labels = a$labels, label_size = a$label_size,
           label_colour = a$label_colour, alpha = a$alpha),
      a$dots
    )
  )
  scale <- ggplot2::scale_discrete_manual(
    aesthetics = aes_name,
    values = spec$legend,
    drop = TRUE,
    name = spec$title,
    guide = ggplot2::guide_legend(order = 99)
  )
  list(layer, scale)
}

check_common_args <- function(orientation, alpha, expand, labels, label_size,
                              n_slices, call = rlang::caller_env()) {
  if (!is.numeric(alpha) || length(alpha) != 1 || alpha < 0 || alpha > 1) {
    cli::cli_abort("{.arg alpha} must be a single number between 0 and 1.", call = call)
  }
  if (!rlang::is_bool(expand)) cli::cli_abort("{.arg expand} must be {.code TRUE} or {.code FALSE}.", call = call)
  if (!rlang::is_bool(labels)) cli::cli_abort("{.arg labels} must be {.code TRUE} or {.code FALSE}.", call = call)
  check_number_positive(label_size, call = call)
  if (!rlang::is_scalar_integerish(n_slices) || n_slices < 1) {
    cli::cli_abort("{.arg n_slices} must be a positive whole number.", call = call)
  }
  invisible()
}

check_null <- function(null, call = rlang::caller_env()) {
  if (!is.numeric(null) || length(null) != 1 || !is.finite(null)) {
    cli::cli_abort("{.arg null} must be a single finite number.", call = call)
  }
  invisible(null)
}

check_softness <- function(softness, allow_null = FALSE, call = rlang::caller_env()) {
  if (is.null(softness) && allow_null) return(invisible())
  if (!is.numeric(softness) || length(softness) != 1 || !is.finite(softness) ||
      softness < 0 || softness >= 2) {
    cli::cli_abort("{.arg softness} must be a single number in [0, 2).", call = call)
  }
  invisible()
}
