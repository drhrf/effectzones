tukey_df <- function() {
  fit <- stats::aov(weight ~ group, data = datasets::PlantGrowth)
  tk <- stats::TukeyHSD(fit)$group
  data.frame(term = rownames(tk), estimate = tk[, "diff"],
             lower = tk[, "lwr"], upper = tk[, "upr"])
}

or_df <- function() {
  data.frame(term = c("A", "B", "C", "D"),
             estimate = c(0.7, 1.4, 2.6, 5.0),
             lower = c(0.45, 0.9, 1.5, 2.4),
             upper = c(1.1, 2.2, 4.5, 10.4))
}

forest <- function(df, zones, ...) {
  ggplot2::ggplot(df, ggplot2::aes(estimate, term)) +
    zones +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = lower, xmax = upper),
                           width = 0.2, orientation = "y") +
    ggplot2::geom_point()
}

x_range <- function(p) ggplot2::layer_scales(p)$x$range$range
