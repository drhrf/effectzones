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

test_that("an aov fit gives the same contrasts and supplies its SD", {
  fit <- aov(weight ~ group, data = PlantGrowth)
  p0 <- plot_contrasts(fit)
  expect_equal(sort(ggplot2::layer_data(p0, 2)$xmin),
               sort(unname(TukeyHSD(fit)$group[, "lwr"])))
  expect_message(
    p <- plot_contrasts(fit, zones = geom_es_zones(es_benchmarks("cohen_d"))),
    "pooled within-group"
  )
  ld <- ggplot2::layer_data(p, 1)
  b <- sort(unique(ld$.lo[ld$flat & is.finite(ld$.lo)]))
  s <- sigma(fit)
  expect_true(any(abs(b - 0.2 * s * 1.05) < 1e-9))
})

test_that("a TukeyHSD object's model is recovered from its call and verified", {
  fit <- aov(weight ~ group, data = PlantGrowth)
  tk <- TukeyHSD(fit)
  expect_message(
    expect_message(
      p <- plot_contrasts(tk, zones = geom_es_zones(es_benchmarks("cohen_d"))),
      "reproduces these Tukey contrasts"
    ),
    "pooled within-group"
  )
  expect_equal(ggplot2::layer_data(p, 1)$PANEL[1], factor(1))

  # If the data behind the call have changed, the refit is rejected
  pg <- PlantGrowth
  tk2 <- TukeyHSD(aov(weight ~ group, data = pg))
  pg$weight <- pg$weight * 2
  expect_error(
    plot_contrasts(tk2, zones = geom_es_zones(es_benchmarks("cohen_d"))),
    "does not reproduce"
  )
  # Explicit sd always works and needs no model
  expect_no_message(
    plot_contrasts(tk2, zones = geom_es_zones(es_benchmarks("cohen_d"), sd = 1))
  )
})

test_that("the SD is not chosen automatically beyond one-way models", {
  fit2 <- aov(breaks ~ wool + tension, data = warpbreaks)
  expect_error(
    plot_contrasts(fit2, zones = geom_es_zones(es_benchmarks("cohen_d"))),
    "2 terms"
  )
  expect_error(
    plot_contrasts(fit2, zones = geom_es_zones(es_benchmarks("cohen_d"))),
    "pooled_sd\\(model\\)"
  )
  # The user can accept the residual SD explicitly
  p <- plot_contrasts(fit2, zones = geom_es_zones(es_benchmarks("cohen_d"),
                                                  sd = pooled_sd(fit2)))
  expect_s3_class(p, "ggplot")
  # MCID zones never need an SD
  expect_s3_class(plot_contrasts(fit2, zones = geom_mcid_zones(5)), "ggplot")
})

test_that("plot_contrasts() handles several TukeyHSD terms and data frames", {
  fit <- aov(breaks ~ wool + tension, data = warpbreaks)
  p <- plot_contrasts(TukeyHSD(fit), zones = geom_mcid_zones(5))
  expect_s3_class(p$facet, "FacetGrid")
  p1 <- plot_contrasts(TukeyHSD(fit), which = "tension")
  expect_identical(nrow(p1$data), 3L)
  expect_identical(nrow(plot_contrasts(fit, which = "tension")$data), 3L)
  expect_error(plot_contrasts(TukeyHSD(fit), which = "nope"), "Unknown")
  expect_error(plot_contrasts(data.frame(term = "a")), "missing")
  expect_s3_class(plot_contrasts(tukey_df()), "ggplot")
  expect_error(
    plot_contrasts(tukey_df(), zones = geom_es_zones(es_benchmarks("cohen_d"))),
    "SD is needed"
  )
  expect_error(plot_contrasts(1), "Can't plot")
})

test_that("plot_contrasts() works with emmeans means and contrasts", {
  skip_if_not_installed("emmeans")
  fit <- aov(weight ~ group, data = PlantGrowth)
  em <- emmeans::emmeans(fit, ~group)
  ct <- pairs(em)
  ci <- as.data.frame(confint(ct))
  p <- plot_contrasts(ct)
  ld <- ggplot2::layer_data(p, 2)
  expect_equal(sort(ld$xmin), sort(ci$lower.CL))
  expect_equal(sort(ld$xmax), sort(ci$upper.CL))

  # A grid of means: pairwise contrasts are computed, and its SD is used
  expect_message(
    pm <- plot_contrasts(em, zones = geom_es_zones(es_benchmarks("cohen_d"))),
    "pooled within-group"
  )
  expect_equal(sort(ggplot2::layer_data(pm, 3)$xmin), sort(ci$lower.CL))

  # A contrast grid has no SD: the means grid or the fit must be given
  expect_error(plot_contrasts(ct, zones = geom_es_zones(es_benchmarks("cohen_d"))),
               "SD is needed")
  expect_message(
    plot_contrasts(ct, zones = geom_es_zones(es_benchmarks("cohen_d")), model = em),
    "pooled within-group"
  )
  expect_message(
    plot_contrasts(ct, zones = geom_es_zones(es_benchmarks("cohen_d")), model = fit),
    "pooled within-group"
  )
})
