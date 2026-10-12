test_that("geom_es_zones() requires thresholds and lists the benchmark sets", {
  expect_error(geom_es_zones(), "no default benchmark set")
  expect_error(geom_es_zones(), "cohen_d")
  expect_error(geom_es_zones(), "fallback")
  expect_snapshot(geom_es_zones(), error = TRUE)
  expect_error(geom_es_zones(mcid_thresholds(mcid = 1)), "geom_mcid_zones")
})

test_that("geom_mcid_zones() requires an MCID and accepts a bare number", {
  expect_error(geom_mcid_zones(), "no automatic MCID")
  z <- geom_mcid_zones(2)
  expect_s3_class(z, "effectzones_zones")
  expect_identical(z$args$mcid$upper, 2)
})

test_that("argument checks fail early", {
  b <- es_benchmarks("cohen_d")
  expect_error(geom_es_zones(b, scale = "log", null = 0), "positive")
  expect_error(geom_es_zones(es_benchmarks("chen_or"), null = 1), "log-ratio")
  expect_error(geom_es_zones(b, orientation = "z"), "must be one of")
  expect_error(geom_es_zones(b, alpha = 2), "alpha")
  expect_error(geom_es_zones(es_benchmarks("cohen_r"), sd = 2), "own scale")
  expect_error(geom_mcid_zones(1, softness = -1), "softness")
})

test_that("zones do not change the axis range unless expand = TRUE", {
  df <- tukey_df()
  thr <- es_benchmarks("cohen_d")
  base <- ggplot2::ggplot(df, ggplot2::aes(estimate, term)) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = lower, xmax = upper), orientation = "y")
  with_zones <- forest(df, geom_es_zones(thr, sd = 0.6))
  expect_equal(x_range(with_zones), x_range(base))

  # Wide zones (sd = 2: cuts at 0.4, 1.0, 1.6) extend the range when expanded
  expanded <- forest(df, geom_es_zones(thr, sd = 2, expand = TRUE))
  r <- x_range(expanded)
  expect_false(isTRUE(all.equal(r, x_range(base))))
  expect_lte(r[1], -1.6 * 1.05)
  expect_gte(r[2], 1.6 * 1.05)

  m <- forest(df, geom_mcid_zones(mcid_thresholds(lower = -3, upper = 4)))
  expect_equal(x_range(m), x_range(base))
  m2 <- forest(df, geom_mcid_zones(mcid_thresholds(lower = -3, upper = 4), expand = TRUE))
  expect_equal(x_range(m2), c(-3, 4))
})

test_that("zones are clipped to the panel and reach its edges", {
  p <- forest(tukey_df(), geom_es_zones(es_benchmarks("cohen_d"), sd = 0.6))
  g <- ggplot2::layer_grob(p, 1)[[1]]
  left <- as.numeric(g$x)
  right <- left + as.numeric(g$width)
  expect_equal(min(left), 0)
  expect_equal(max(right), 1)
  expect_true(all(left >= 0 & right <= 1 + 1e-12))
})

test_that("zones work with coord_flip()", {
  p <- forest(tukey_df(), geom_mcid_zones(0.4)) + ggplot2::coord_flip()
  g <- ggplot2::layer_grob(p, 1)[[1]]
  # bands now run horizontally: full width, partial heights
  expect_true(all(abs(as.numeric(g$width) - 1) < 1e-9))
  expect_gt(length(unique(as.numeric(g$height))), 1)
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("zones work with orientation = 'y'", {
  df <- tukey_df()
  p <- ggplot2::ggplot(df, ggplot2::aes(term, estimate)) +
    geom_es_zones(es_benchmarks("cohen_d"), sd = 0.6, orientation = "y",
                  labels = TRUE) +
    ggplot2::geom_point()
  g <- ggplot2::layer_grob(p, 1)[[1]]
  rects <- g$children[[1]]
  expect_true(all(abs(as.numeric(rects$width) - 1) < 1e-9))
  expect_equal(ggplot2::layer_scales(p)$y$range$range, range(df$estimate))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("zones work with facet_wrap()", {
  df <- rbind(cbind(tukey_df(), panel = "a"), cbind(tukey_df(), panel = "b"))
  p <- forest(df, geom_es_zones(es_benchmarks("cohen_d"), sd = 0.6)) +
    ggplot2::facet_wrap(~panel)
  ld <- ggplot2::layer_data(p, 1)
  expect_setequal(as.character(unique(ld$PANEL)), c("1", "2"))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("zones work on a log10 axis (odds ratios)", {
  p <- forest(or_df(), geom_es_zones(es_benchmarks("chen_or"), scale = "log",
                                     null = 1, softness = 0)) +
    ggplot2::scale_x_log10()
  ld <- ggplot2::layer_data(p, 1)
  bounds <- sort(unique(c(ld$.lo, ld$.hi)))
  bounds <- bounds[is.finite(bounds)]
  all_bounds <- log10(c(1 / c(1.74, 4.28, 11.40), 1.68, 3.47, 6.71))
  # zones wholly outside the visible range are dropped
  expect_true(all(sapply(bounds, function(b) any(abs(b - all_bounds) < 1e-12))))
  expect_true(all(log10(c(1.68, 3.47, 6.71)) %in% bounds))
  expect_equal(x_range(p), log10(range(c(or_df()$lower, or_df()$upper))))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("additive zones on a log axis warn about dropped boundaries", {
  p <- forest(or_df(), geom_es_zones(es_benchmarks("cohen_d"))) +
    ggplot2::scale_x_log10()
  expect_warning(ggplot2::ggplot_build(p), "outside the domain")
})

test_that("zones respect coord_cartesian() limits and scale transforms", {
  p <- forest(tukey_df(), geom_es_zones(es_benchmarks("cohen_d"), sd = 0.6)) +
    ggplot2::coord_cartesian(xlim = c(-0.2, 0.2))
  g <- ggplot2::layer_grob(p, 1)[[1]]
  expect_equal(min(as.numeric(g$x)), 0)
  expect_equal(max(as.numeric(g$x) + as.numeric(g$width)), 1)

  p2 <- forest(tukey_df(), geom_mcid_zones(0.4)) +
    ggplot2::scale_x_continuous(trans = "reverse")
  ld <- ggplot2::layer_data(p2, 1)
  expect_setequal(ld$.lo[is.finite(ld$.lo)], c(-0.4, 0.4))
  expect_no_error(ggplot2::ggplotGrob(p2))
})

test_that("legend title reflects the source and provisional status", {
  p <- forest(tukey_df(), geom_mcid_zones(mcid_distribution(sd = 1)))
  b <- ggplot2::ggplot_build(p)
  sc <- b$plot$scales$get_scales("mcid_zone")
  expect_identical(sc$name, "MCID (provisional, distribution-based)")
  p2 <- forest(tukey_df(), geom_es_zones(es_benchmarks("cohen_d"), sd = 0.6))
  sc2 <- ggplot2::ggplot_build(p2)$plot$scales$get_scales("es_zone")
  expect_identical(sc2$name, "Cohen (1988), d")
  expect_identical(sc2$get_limits(), c("negligible", "small", "medium", "large"))
})

test_that("zones do not interfere with a fill scale used by other layers", {
  df <- tukey_df()
  p <- ggplot2::ggplot(df, ggplot2::aes(estimate, term)) +
    geom_es_zones(es_benchmarks("cohen_d"), sd = 0.6) +
    ggplot2::geom_point(ggplot2::aes(fill = term), shape = 21)
  b <- ggplot2::ggplot_build(p)
  expect_setequal(b$plot$scales$get_scales("fill")$get_limits(), df$term)
})

test_that("zone_labels renames zones, fully or partly", {
  thr <- es_benchmarks("cohen_d")
  z <- geom_es_zones(thr, sd = 0.6,
                     zone_labels = c("below small", "small", "medium", "large"))
  expect_identical(z$args$thresholds$labels[1], "below small")
  z2 <- geom_es_zones(thr, sd = 0.6, zone_labels = list(negligible = "below small"))
  expect_identical(z2$args$thresholds$labels, c("below small", "small", "medium", "large"))
  expect_error(geom_es_zones(thr, zone_labels = c("a", "b")), "all 4 zones")
  expect_error(geom_es_zones(thr, zone_labels = c(tiny = "a")), "Unknown zone name")
  expect_error(geom_es_zones(thr, zone_labels = c("a", "a", "b", "c")), "unique")

  p <- forest(tukey_df(), geom_es_zones(thr, sd = 0.6,
                                        zone_labels = c(negligible = "below small")))
  sc <- ggplot2::ggplot_build(p)$plot$scales$get_scales("es_zone")
  expect_true("below small" %in% sc$get_limits())

  m <- geom_mcid_zones(0.4, zone_labels = c("worse", "no important change", "better"),
                       beyond = "multiples")
  p2 <- forest(tukey_df(), m)
  lim <- ggplot2::ggplot_build(p2)$plot$scales$get_scales("mcid_zone")$get_limits()
  expect_true("no important change" %in% lim)
  expect_true(any(grepl("^better \\(", lim)))
  expect_false(any(grepl("benefit|harm|trivial", lim)))
})

test_that("the legend lists only zones present in the panel", {
  # estimates span about -1.1 to 1.6; with sd = 2 the cuts are at 0.4, 1, 1.6
  p <- forest(tukey_df(), geom_es_zones(es_benchmarks("cohen_d"), sd = 2,
                                        softness = 0))
  lim <- ggplot2::ggplot_build(p)$plot$scales$get_scales("es_zone")$get_limits()
  expect_identical(lim, c("negligible", "small", "medium", "large"))

  p2 <- forest(tukey_df(), geom_es_zones(es_benchmarks("cohen_d"), sd = 10,
                                         softness = 0))
  lim2 <- ggplot2::ggplot_build(p2)$plot$scales$get_scales("es_zone")$get_limits()
  expect_identical(lim2, "negligible")

  m <- forest(tukey_df(), geom_mcid_zones(mcid_thresholds(lower = -5, upper = 0.5)))
  lim3 <- ggplot2::ggplot_build(m)$plot$scales$get_scales("mcid_zone")$get_limits()
  expect_identical(lim3, c("trivial", "benefit"))

  # expand = TRUE shows every zone
  e <- forest(tukey_df(), geom_mcid_zones(mcid_thresholds(lower = -5, upper = 0.5),
                                          expand = TRUE))
  lim4 <- ggplot2::ggplot_build(e)$plot$scales$get_scales("mcid_zone")$get_limits()
  expect_identical(lim4, c("harm", "trivial", "benefit"))
})
