test_that("d thresholds convert to raw differences by multiplying by sd", {
  x <- to_plot_scale(es_benchmarks("cohen_d"), sd = 2)
  expect_equal(x$cuts, c(0.4, 1.0, 1.6))
  expect_identical(x$metric, "raw")
  expect_identical(to_plot_scale(es_benchmarks("cohen_d"))$cuts, c(0.2, 0.5, 0.8))
})

test_that("OR zones are symmetric on the log scale (c and 1/c)", {
  cuts <- c(1.5, 2.5, 4.3)
  thr <- es_thresholds(cuts, c("a", "b", "c", "d"), metric = "or")
  spec <- es_zone_spec(to_plot_scale(thr, scale = "log"),
                       null = 1, softness = 0, palette = "grey")
  br <- sort(zone_breaks(spec))
  expect_equal(br, sort(c(1 / cuts, cuts)))
  expect_equal(log(br), -rev(log(br)))
})

test_that("d converts to odds ratios with the Chinn approximation", {
  x <- to_plot_scale(es_benchmarks("cohen_d"), scale = "log")
  expect_equal(x$cuts, exp(c(0.2, 0.5, 0.8) * pi / sqrt(3)))
  expect_identical(x$scale, "log")
  expect_match(x$note, "Chinn")
})

test_that("ratio thresholds on an identity axis become log ratios", {
  x <- to_plot_scale(es_benchmarks("chen_or"), scale = "identity")
  expect_equal(x$cuts, log(c(1.68, 3.47, 6.71)))
  expect_equal(x$cuts_lower, log(c(1.74, 4.28, 11.40)))
})

test_that("asymmetric cuts give asymmetric boundaries", {
  spec <- es_zone_spec(to_plot_scale(es_benchmarks("chen_or"), scale = "log"),
                       null = 1, softness = 0, palette = "grey")
  expect_equal(zone_breaks(spec),
               c(1 / c(11.40, 4.28, 1.74), 1.68, 3.47, 6.71))
  thr <- es_thresholds(c(0.2, 0.5), c("a", "b", "c"), cuts_lower = c(0.3, 0.6))
  expect_equal(to_plot_scale(thr, sd = 2)$cuts_lower, c(0.6, 1.2))
  expect_error(es_thresholds(0.2, c("a", "b"), cuts_lower = c(0.1, 0.3)), "same length")
})

test_that("r, eta2 and f are drawn on their own scale only", {
  expect_error(to_plot_scale(es_benchmarks("cohen_r"), sd = 2), "own scale")
  expect_error(to_plot_scale(es_benchmarks("cohen_f"), scale = "log"), "own scale")
  expect_identical(to_plot_scale(es_benchmarks("cohen_eta2"))$cuts, c(0.01, 0.06, 0.14))
})

test_that("MCID thresholds can be standardised", {
  x <- to_plot_scale(mcid_thresholds(lower = -4, upper = 6), sd = 2)
  expect_identical(c(x$lower, x$upper), c(-2, 3))
  expect_error(to_plot_scale(mcid_thresholds(mcid = 1), scale = "log"), "identity")
})

test_that("pooled_sd() returns sigma for aov/lm", {
  fit <- aov(weight ~ group, data = PlantGrowth)
  expect_identical(pooled_sd(fit), sigma(fit))
  expect_identical(pooled_sd(lm(weight ~ group, data = PlantGrowth)), sigma(fit))
  expect_error(pooled_sd(1:3), "Can't extract")
  g <- glm(cbind(ncases, ncontrols) ~ agegp, data = esoph, family = binomial)
  expect_error(pooled_sd(g), "no residual SD")
})

test_that("pooled_sd() works for emmGrid objects", {
  skip_if_not_installed("emmeans")
  fit <- aov(weight ~ group, data = PlantGrowth)
  em <- emmeans::emmeans(fit, ~group)
  expect_equal(pooled_sd(em), sigma(fit))
  expect_error(pooled_sd(pairs(em)), "does not carry")
})
