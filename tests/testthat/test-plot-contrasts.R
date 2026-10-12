test_that("plot_contrasts() draws TukeyHSD intervals exactly", {
  fit <- aov(weight ~ group, data = PlantGrowth)
  tk <- TukeyHSD(fit)
  p <- plot_contrasts(tk)
  expect_s3_class(p, "ggplot")
  ld <- ggplot2::layer_data(p, 2) # error bars
  ref <- tk$group
  expect_equal(sort(ld$xmin), sort(unname(ref[, "lwr"])))
  expect_equal(sort(ld$xmax), sort(unname(ref[, "upr"])))
  pts <- ggplot2::layer_data(p, 3)
  expect_equal(sort(pts$x), sort(unname(ref[, "diff"])))
  expect_no_error(ggplot2::ggplotGrob(p))
})

test_that("plot_contrasts() fills sd from the model and says so", {
  fit <- aov(weight ~ group, data = PlantGrowth)
  expect_message(
    p <- plot_contrasts(TukeyHSD(fit), zones = geom_es_zones(es_benchmarks("cohen_d")),
                        model = fit),
    "pooled"
  )
  ld <- ggplot2::layer_data(p, 1)
  b <- sort(unique(ld$.lo[ld$flat & is.finite(ld$.lo)]))
  s <- sigma(fit)
  expect_equal(b, sort(c(-0.8, -0.5, -0.2, 0.2, 0.5, 0.8) * s * c(0.95, 0.95, 0.95, 1.05, 1.05, 1.05)))
  expect_error(
    plot_contrasts(TukeyHSD(fit), zones = geom_es_zones(es_benchmarks("cohen_d"))),
    "SD is needed"
  )
})

test_that("plot_contrasts() handles several TukeyHSD terms and data frames", {
  fit <- aov(breaks ~ wool + tension, data = warpbreaks)
  p <- plot_contrasts(TukeyHSD(fit), zones = geom_mcid_zones(5))
  expect_s3_class(p$facet, "FacetGrid")
  p1 <- plot_contrasts(TukeyHSD(fit), which = "tension")
  expect_identical(nrow(p1$data), 3L)
  expect_error(plot_contrasts(TukeyHSD(fit), which = "nope"), "Unknown")
  expect_error(plot_contrasts(data.frame(term = "a")), "missing")
  expect_s3_class(plot_contrasts(tukey_df()), "ggplot")
  expect_error(plot_contrasts(1), "Can't plot")
})

test_that("plot_contrasts() works with emmeans contrasts", {
  skip_if_not_installed("emmeans")
  fit <- aov(weight ~ group, data = PlantGrowth)
  em <- emmeans::emmeans(fit, ~group)
  ct <- pairs(em)
  ci <- as.data.frame(confint(ct))
  p <- plot_contrasts(ct)
  ld <- ggplot2::layer_data(p, 2)
  expect_equal(sort(ld$xmin), sort(ci$lower.CL))
  expect_equal(sort(ld$xmax), sort(ci$upper.CL))
  expect_message(
    plot_contrasts(ct, zones = geom_es_zones(es_benchmarks("cohen_d")), model = em),
    "pooled"
  )
  expect_error(plot_contrasts(em), "contrasts")
})
