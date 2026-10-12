test_that("chen_or_thresholds() reproduces the published odds ratios", {
  one <- chen_or_thresholds(0.01)
  expect_lt(max(abs(one$cuts - c(1.68, 3.47, 6.71))), 0.006)
  five <- chen_or_thresholds(0.05)
  expect_lt(max(abs(five$cuts - c(1.52, 2.74, 4.72))), 0.006)
  expect_identical(one$metric, "or")
  expect_match(one$title, "1%")
})

test_that("protective boundaries come from negative d, not 1/OR", {
  x <- chen_or_thresholds(0.01)
  expect_equal(1 / x$cuts_lower, or_from_d(-c(0.2, 0.5, 0.8), 0.01))
  expect_gt(x$cuts_lower[3], x$cuts[3])
  # the two sides coincide only at a 50% baseline risk
  half <- chen_or_thresholds(0.5)
  expect_equal(half$cuts_lower, half$cuts)
  # published rounding of the lower side in es_benchmarks("chen_or")
  expect_equal(round(x$cuts_lower, 2), es_benchmarks("chen_or")$cuts_lower)
})

test_that("chen_or_thresholds() validates input", {
  expect_error(chen_or_thresholds(0), "between 0 and 1")
  expect_error(chen_or_thresholds(1.2), "between 0 and 1")
  expect_error(chen_or_thresholds(0.1, d = c(0.5, 0.2)), "increasing")
  expect_s3_class(geom_es_zones(chen_or_thresholds(0.1), scale = "log", null = 1),
                  "effectzones_zones")
})
