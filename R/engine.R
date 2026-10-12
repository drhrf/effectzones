# Internal rendering engine shared by geom_es_zones() and geom_mcid_zones().
#
# A "zone spec" describes zones along the effect axis in u-space, where the
# null is at u = 0. For additive zones x = null + u; for multiplicative
# zones (ratios on a log axis) x = null * exp(u).
#
#   zones:      data frame, one row per zone in axis order (label, side,
#               intensity, colour)
#   boundaries: data frame, one row per boundary between consecutive zones
#               (at, lo, hi): the transition runs from lo to hi; lo == hi is
#               a hard edge
#   transform:  "additive" or "multiplicative"
#   null:       position of the null on the data scale
#   legend:     named colour vector in legend order, and a title

new_zone_spec <- function(zones, boundaries, transform, null, legend, title) {
  stopifnot(nrow(zones) == nrow(boundaries) + 1)
  boundaries <- resolve_overlaps(boundaries)
  structure(
    list(zones = zones, boundaries = boundaries, transform = transform,
         null = null, legend = legend, title = title),
    class = "zone_spec"
  )
}

# Soft transitions of neighbouring boundaries must not overlap (and must not
# cross the null between the two central boundaries). Where they would, both
# are shrunk to the midpoint between the two boundaries.
resolve_overlaps <- function(b) {
  n <- nrow(b)
  if (n < 2) return(b)
  for (i in seq_len(n - 1)) {
    if (b$hi[i] > b$lo[i + 1]) {
      mid <- (b$at[i] + b$at[i + 1]) / 2
      b$hi[i] <- min(b$hi[i], mid)
      b$lo[i + 1] <- max(b$lo[i + 1], mid)
    }
  }
  b
}

soft_bounds <- function(at, softness) {
  half <- softness * abs(at) / 2
  data.frame(at = at, lo = at - half, hi = at + half)
}

# Effect-size zones: symmetric, sequential ramp from the null outwards.
es_zone_spec <- function(thr, null, softness, palette, title = NULL) {
  multiplicative <- identical(thr$scale, "log")
  u <- if (multiplicative) log(thr$cuts) else thr$cuts
  u_lower <- thr$cuts_lower %||% thr$cuts
  if (multiplicative) u_lower <- log(u_lower)
  m <- length(u)
  cols <- es_palette(palette, m + 1)
  idx <- c(m:1, 0, 1:m) # zone index in axis order
  zones <- data.frame(
    label = thr$labels[idx + 1],
    side = c(rep("lower", m), "centre", rep("upper", m)),
    intensity = idx / m,
    colour = cols[idx + 1],
    stringsAsFactors = FALSE
  )
  boundaries <- soft_bounds(c(-rev(u_lower), u), softness)
  legend <- stats::setNames(cols, thr$labels)
  new_zone_spec(
    zones, boundaries,
    transform = if (multiplicative) "multiplicative" else "additive",
    null = null, legend = legend,
    title = title %||% es_title(thr)
  )
}

es_title <- function(thr) {
  thr$title %||% "Effect-size zones"
}

mcid_multiple_cap <- 3L

# MCID zones: harm / trivial / benefit, optionally graded in multiples.
mcid_zone_spec <- function(thr, null, softness, beyond, palette, title = NULL,
                           role_labels = NULL) {
  role_labels <- role_labels %||%
    c(harm = "harm", trivial = "trivial", benefit = "benefit")
  pal <- mcid_palette(palette)
  benefit_upper <- thr$direction == "higher_better"
  side_name <- if (benefit_upper) c(lower = "harm", upper = "benefit") else
    c(lower = "benefit", upper = "harm")
  cap <- if (beyond == "multiples") mcid_multiple_cap else 1L

  one_side <- function(thresh, side) {
    role <- side_name[[side]]
    at <- mean(thresh)
    first <- if (length(thresh) == 2) {
      data.frame(at = at, lo = min(thresh), hi = max(thresh))
    } else {
      soft_bounds(at, softness %||% 0)
    }
    more <- if (cap > 1) soft_bounds(at * seq(2, cap), softness %||% 0) else NULL
    b <- rbind(first, more)
    levels <- seq_len(cap)
    ramp <- scales::colour_ramp(c(pal[["trivial"]], pal[[role]],
                                  scales::colour_ramp(c(pal[[role]], "#000000"))(0.5)))
    t <- if (cap > 1) 0.5 + 0.5 * (levels - 1) / (cap - 1) else 0.5
    labels <- if (cap > 1) {
      shown <- role_labels[[role]]
      c(paste0(shown, " (1\u{2013}2\u{00d7} MCID)"),
        if (cap > 2) paste0(shown, " (", seq(2, cap - 1), "\u{2013}", seq(3, cap), "\u{00d7} MCID)"),
        paste0(shown, " (\u{2265}", cap, "\u{00d7} MCID)"))
    } else {
      role_labels[[role]]
    }
    zones <- data.frame(label = labels, side = side, intensity = t,
                        colour = ramp(t), stringsAsFactors = FALSE)
    list(b = b, zones = zones)
  }
  lo <- one_side(thr$lower, "lower")
  hi <- one_side(thr$upper, "upper")
  # lower side: boundaries and zones run outwards, so reverse for axis order
  lo$b <- lo$b[rev(seq_len(nrow(lo$b))), , drop = FALSE]
  lo$zones <- lo$zones[rev(seq_len(nrow(lo$zones))), , drop = FALSE]
  centre <- data.frame(label = role_labels[["trivial"]], side = "centre", intensity = 0,
                       colour = pal[["trivial"]], stringsAsFactors = FALSE)
  zones <- rbind(lo$zones, centre, hi$zones)
  boundaries <- rbind(lo$b, hi$b)
  rownames(zones) <- rownames(boundaries) <- NULL

  harm_z <- zones[zones$side == names(side_name)[side_name == "harm"], ]
  ben_z <- zones[zones$side == names(side_name)[side_name == "benefit"], ]
  # Legend order: strongest harm ... trivial ... strongest benefit
  harm_z <- harm_z[order(-harm_z$intensity), ]
  ben_z <- ben_z[order(ben_z$intensity), ]
  legend <- c(stats::setNames(harm_z$colour, harm_z$label),
              stats::setNames(pal[["trivial"]], role_labels[["trivial"]]),
              stats::setNames(ben_z$colour, ben_z$label))
  new_zone_spec(zones, boundaries, transform = "additive", null = null,
                legend = legend, title = title %||% mcid_title(thr))
}

mcid_title <- function(thr) {
  if (isTRUE(thr$provisional)) return("MCID (provisional, distribution-based)")
  src <- thr$source
  if (is.null(src)) return("MCID")
  if (nchar(src) <= 40) paste0("MCID: ", src) else "MCID"
}

# Turn a zone spec into rectangles along the effect axis, on the data scale.
# Returns lo, hi, zone, side, intensity, fill and flat (FALSE for transition
# slices).
zone_segments <- function(spec, n_slices = 40) {
  z <- spec$zones
  b <- spec$boundaries
  n <- nrow(b)
  out <- vector("list", 2 * n + 1)
  edges_lo <- c(-Inf, b$hi)
  edges_hi <- c(b$lo, Inf)
  for (i in seq_len(n + 1)) {
    out[[2 * i - 1]] <- data.frame(
      lo = edges_lo[i], hi = edges_hi[i], zone = z$label[i], side = z$side[i],
      intensity = z$intensity[i], fill = z$colour[i], flat = TRUE,
      stringsAsFactors = FALSE
    )
    if (i <= n && b$hi[i] > b$lo[i]) {
      cuts <- seq(b$lo[i], b$hi[i], length.out = n_slices + 1)
      mid <- (cuts[-1] + cuts[-length(cuts)]) / 2
      frac <- (mid - b$lo[i]) / (b$hi[i] - b$lo[i])
      ramp <- scales::colour_ramp(c(z$colour[i], z$colour[i + 1]))
      nearer <- ifelse(mid < b$at[i], i, i + 1)
      out[[2 * i]] <- data.frame(
        lo = cuts[-length(cuts)], hi = cuts[-1], zone = z$label[nearer],
        side = z$side[nearer],
        intensity = z$intensity[i] + frac * (z$intensity[i + 1] - z$intensity[i]),
        fill = ramp(frac), flat = FALSE, stringsAsFactors = FALSE
      )
    }
  }
  seg <- do.call(rbind, out)
  seg <- seg[seg$hi > seg$lo, , drop = FALSE]
  if (spec$transform == "multiplicative") {
    seg$lo <- spec$null * exp(seg$lo)
    seg$hi <- spec$null * exp(seg$hi)
  } else {
    seg$lo <- spec$null + seg$lo
    seg$hi <- spec$null + seg$hi
  }
  rownames(seg) <- NULL
  seg
}

# Finite boundary positions on the data scale (used for scale training when
# expand = TRUE, and by tests).
zone_breaks <- function(spec) {
  u <- sort(unique(c(spec$boundaries$lo, spec$boundaries$at, spec$boundaries$hi)))
  if (spec$transform == "multiplicative") spec$null * exp(u) else spec$null + u
}
