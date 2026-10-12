test_that("ES mode: Cohen d on the raw scale via pooled SD", {
  fit <- aov(weight ~ group, data = PlantGrowth)
  p <- forest(tukey_df(), geom_es_zones(es_benchmarks("cohen_d"),
                                        sd = pooled_sd(fit), labels = TRUE)) +
    ggplot2::theme_minimal()
  expect_zones_snapshot("es-cohen-d-raw", p)
})

test_that("ES mode on a log-OR axis", {
  p <- forest(or_df(), geom_es_zones(es_benchmarks("chen_or"), scale = "log",
                                     null = 1)) +
    ggplot2::geom_vline(xintercept = 1, linetype = 2) +
    ggplot2::scale_x_log10() +
    ggplot2::theme_minimal()
  expect_zones_snapshot("es-chen-or-log", p)
})

test_that("MCID mode: symmetric, hard edges", {
  p <- forest(tukey_df(), geom_mcid_zones(0.4)) + ggplot2::theme_minimal()
  expect_zones_snapshot("mcid-symmetric-hard", p)
})

test_that("MCID mode: asymmetric range-based soft edges, multiples", {
  thr <- mcid_thresholds(lower = -0.25, upper = c(0.3, 0.5),
                         source = "Two anchor studies")
  p <- forest(tukey_df(), geom_mcid_zones(thr, beyond = "multiples")) +
    ggplot2::theme_minimal()
  expect_zones_snapshot("mcid-asymmetric-range-multiples", p)
})

test_that("MCID mode: provisional distribution-based legend", {
  p <- forest(tukey_df(), geom_mcid_zones(mcid_distribution(sd = 0.7),
                                          palette = "grey", labels = TRUE)) +
    ggplot2::theme_minimal()
  expect_zones_snapshot("mcid-provisional-grey", p)
})
