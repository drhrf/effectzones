# Visual snapshots depend on the ggplot2 version (legend and theme rendering
# change between releases), so they are stored per ggplot2 major.minor
# version. Snapshots run only when references for the installed version
# exist, or when recording is requested with
# EFFECTZONES_RECORD_SNAPSHOTS=true.
ggplot2_variant <- function() {
  v <- unlist(utils::packageVersion("ggplot2"))
  paste0("ggplot2-", v[1], ".", v[2])
}

expect_zones_snapshot <- function(title, fig) {
  testthat::skip_if_not_installed("vdiffr")
  variant <- ggplot2_variant()
  recording <- identical(Sys.getenv("EFFECTZONES_RECORD_SNAPSHOTS"), "true")
  if (!recording && !dir.exists(testthat::test_path("_snaps", variant))) {
    testthat::skip(paste("No reference snapshots for", variant))
  }
  # As vdiffr::expect_doppelganger(), but with a testthat snapshot variant
  # (vdiffr < 1.0.8 has no `variant` argument).
  file <- paste0(title, ".svg")
  testthat::announce_snapshot_file(name = file)
  path <- tempfile(fileext = ".svg")
  vdiffr::write_svg(fig, path, title)
  testthat::expect_snapshot_file(path, name = file, variant = variant,
                                 compare = testthat::compare_file_text)
}
