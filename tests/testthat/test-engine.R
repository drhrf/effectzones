test_that("asymmetric MCID places boundaries at lower and upper", {
  spec <- mcid_zone_spec(mcid_thresholds(lower = -3, upper = 5), null = 0,
                         softness = NULL, beyond = "flat", palette = "diverging")
  expect_identical(zone_breaks(spec), c(-3, 5))
  seg <- zone_segments(spec)
  expect_identical(seg$zone, c("harm", "trivial", "benefit"))
  expect_identical(seg$lo, c(-Inf, -3, 5))
  expect_identical(seg$hi, c(-3, 5, Inf))
})

test_that("direction = 'lower_better' swaps benefit and harm", {
  spec <- mcid_zone_spec(
    mcid_thresholds(lower = -3, upper = 5, direction = "lower_better"),
    null = 0, softness = NULL, beyond = "flat", palette = "diverging"
  )
  seg <- zone_segments(spec)
  expect_identical(seg$zone, c("benefit", "trivial", "harm"))
  expect_identical(seg$lo, c(-Inf, -3, 5))
  pal <- mcid_palettes$diverging
  expect_identical(seg$fill, unname(pal[c("benefit", "trivial", "harm")]))
})

test_that("a range-based MCID fades across the range", {
  spec <- mcid_zone_spec(mcid_thresholds(lower = -2, upper = c(4, 6)), null = 0,
                         softness = NULL, beyond = "flat", palette = "grey")
  seg <- zone_segments(spec, n_slices = 10)
  slices <- seg[!seg$flat, ]
  expect_equal(nrow(slices), 10)
  expect_equal(min(slices$lo), 4)
  expect_equal(max(slices$hi), 6)
  expect_true(all(diff(slices$intensity) > 0))
  # hard edge on the lower side
  expect_true(-2 %in% seg$hi[seg$flat])
})

test_that("beyond = 'multiples' grades zones at 2x and 3x the MCID", {
  spec <- mcid_zone_spec(mcid_thresholds(lower = -2, upper = 4), null = 0,
                         softness = NULL, beyond = "multiples",
                         palette = "diverging")
  expect_identical(zone_breaks(spec), c(-6, -4, -2, 4, 8, 12))
  seg <- zone_segments(spec)
  expect_length(unique(seg$fill), 7)
  # an estimate at 1.2x and one at 4x MCID sit on different backgrounds
  at <- function(x) seg$fill[seg$lo <= x & seg$hi > x]
  expect_false(identical(at(1.2 * 4), at(4 * 4)))
})

test_that("soft transitions do not overlap", {
  thr <- es_thresholds(c(1, 1.05), c("a", "b", "c"), metric = "raw")
  spec <- es_zone_spec(thr, null = 0, softness = 0.5, palette = "grey")
  b <- spec$boundaries
  expect_true(all(b$hi[-nrow(b)] <= b$lo[-1]))
  seg <- zone_segments(spec, 5)
  expect_true(all(seg$hi[-nrow(seg)] == seg$lo[-1]))
})

test_that("softness = 0 gives hard edges and the ES ramp is symmetric", {
  spec <- es_zone_spec(es_benchmarks("cohen_d"), null = 0, softness = 0,
                       palette = "grey")
  seg <- zone_segments(spec)
  expect_true(all(seg$flat))
  expect_identical(seg$zone, c("large", "medium", "small", "negligible",
                               "small", "medium", "large"))
  expect_identical(seg$fill, rev(seg$fill))
  expect_identical(seg$fill[4], "#FFFFFF")
})

test_that("palettes are validated", {
  expect_error(es_palette("nope", 4), "Unknown")
  expect_length(es_palette(c("white", "navy"), 4), 4)
  expect_error(es_palette(c("white", "grey", "navy"), 4), "4 colours")
  expect_error(mcid_palette(c("red", "white")), "three colours")
  expect_named(mcid_palette(c("red", "white", "blue")), c("harm", "trivial", "benefit"))
})
