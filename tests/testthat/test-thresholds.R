test_that("es_benchmarks() returns the published cut-points with a source", {
  expected <- list(
    cohen_d = c(0.2, 0.5, 0.8),
    sawilowsky_d = c(0.01, 0.2, 0.5, 0.8, 1.2, 2.0),
    cohen_r = c(0.1, 0.3, 0.5),
    funder_ozer_r = c(0.05, 0.10, 0.20, 0.30, 0.40),
    gignac_szodorai_r = c(0.10, 0.20, 0.30),
    cohen_eta2 = c(0.01, 0.06, 0.14),
    cohen_f = c(0.10, 0.25, 0.40),
    chen_or = c(1.68, 3.47, 6.71)
  )
  expect_setequal(names(benchmark_sets), names(expected))
  for (set in names(expected)) {
    b <- es_benchmarks(set)
    expect_s3_class(b, "es_thresholds")
    expect_identical(b$cuts, expected[[set]], label = set)
    expect_length(b$labels, length(expected[[set]]) + 1)
    expect_true(is.character(b$source) && nzchar(b$source), label = set)
  }
  expect_match(es_benchmarks("chen_or")$source, "1%")
  expect_identical(es_benchmarks("chen_or")$metric, "or")
})

test_that("es_benchmarks() without a set lists the options", {
  expect_snapshot(sets <- es_benchmarks())
  expect_identical(sets, names(benchmark_sets))
  expect_error(es_benchmarks("nope"), "must be one of")
})

test_that("es_thresholds() validates its input", {
  expect_error(es_thresholds(c(0.2, 0.5), c("a", "b")), "one more element")
  expect_error(es_thresholds(c(0.5, 0.2), c("a", "b", "c")), "increasing")
  expect_error(es_thresholds(c(-0.2, 0.5), c("a", "b", "c")), "positive")
  expect_error(es_thresholds(c(0.5, 2), c("a", "b", "c"), metric = "or"), "greater than 1")
  expect_error(es_thresholds(0.2, c("a", "a")), "unique")
  x <- es_thresholds(c(0.1, 0.3), c("a", "b", "c"), source = "Me")
  expect_identical(x$labels, c("a", "b", "c"))
  expect_snapshot(print(x))
})

test_that("mcid_distribution() computes provisional thresholds", {
  h <- mcid_distribution(sd = 10, "half_sd")
  expect_s3_class(h, "mcid_thresholds")
  expect_identical(h$lower, -5)
  expect_identical(h$upper, 5)
  expect_true(h$provisional)
  expect_match(h$source, "Norman")
  expect_match(h$source, "McGlothlin")

  s <- mcid_distribution(sd = 10, "sem", reliability = 0.84)
  expect_equal(s$upper, 4)
  expect_equal(s$lower, -4)
  expect_true(s$provisional)
  expect_match(s$source, "SEM")

  expect_error(mcid_distribution(sd = 10, "sem"), "requires `reliability`")
  expect_error(mcid_distribution(sd = 10, "sem", reliability = 1.2), "between 0 and 1")
  expect_equal(mcid_distribution(sd = 10, "one_fifth_sd")$upper, 2)
})

test_that("mcid_thresholds() handles shorthand, ranges and validation", {
  m <- mcid_thresholds(mcid = 3)
  expect_identical(c(m$lower, m$upper), c(-3, 3))
  expect_false(m$provisional)
  r <- mcid_thresholds(mcid = c(4, 2))
  expect_identical(r$lower, c(-4, -2))
  expect_identical(r$upper, c(2, 4))
  a <- mcid_thresholds(lower = -2, upper = c(5, 3))
  expect_identical(a$upper, c(3, 5))
  expect_error(mcid_thresholds(lower = 2, upper = 3), "negative")
  expect_error(mcid_thresholds(lower = -2), "required")
  expect_error(mcid_thresholds(lower = -2, upper = 2, mcid = 2), "not both")
  expect_error(mcid_thresholds(lower = -2, upper = c(1, 2, 3)), "length-2")
})
