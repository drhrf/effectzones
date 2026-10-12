# Draws man/figures/logo.png (the hex logo). Run from the package root.
library(grid)
out <- "man/figures/logo.png"
png(out, width = 518, height = 600, res = 144, bg = "transparent", type = "cairo")
grid.newpage()
# pointy-top hexagon in npc
ang <- seq(90, 450, by = 60)[1:6] * pi / 180
hx <- 0.5 + 0.49 * cos(ang) * (600 / 518) * 0.866 / 0.866 * 0.845
hy <- 0.5 + 0.49 * sin(ang)
hex <- polygonGrob(hx, hy, gp = gpar(fill = "#2C3E50", col = NA))
grid.draw(hex)
pushViewport(viewport(clip = polygonGrob(hx, hy)))
# zones: harm (orange) -> trivial -> benefit (blue), with soft fades
cols <- c("#C9792F", "#F5F5F5", "#3F7BAE")
ramp <- colorRamp(cols, space = "Lab")
xs <- seq(0.0, 1.0, length.out = 301)
band_y <- 0.20; band_h <- 0.42
for (i in seq_len(length(xs) - 1)) {
  m <- (xs[i] + xs[i + 1]) / 2
  f <- (m - 0.08) / 0.84
  # piecewise: harm 0-0.3, fade, trivial 0.38-0.58, fade, benefit 0.66-1
  u <- if (f < 0.30) 0 else if (f < 0.38) (f - 0.30) / 0.08 * 0.5 else if (f < 0.58) 0.5 else if (f < 0.66) 0.5 + (f - 0.58) / 0.08 * 0.5 else 1
  rgbv <- ramp(u)
  grid.rect(x = xs[i], y = band_y, width = xs[i + 1] - xs[i] + 0.004, height = band_h,
            just = c("left", "bottom"),
            gp = gpar(fill = rgb(rgbv[1], rgbv[2], rgbv[3], maxColorValue = 255), col = NA))
}
# null line
grid.lines(x = c(0.48, 0.48), y = c(band_y, band_y + band_h), gp = gpar(col = "#2C3E50", lty = 2, lwd = 1.6))
# three estimates with CIs
est <- list(c(0.30, 0.55, 0.42), c(0.55, 0.88, 0.71), c(0.40, 0.66, 0.53))
yy <- band_y + band_h * c(0.78, 0.5, 0.22)
for (k in 1:3) {
  e <- est[[k]]
  grid.lines(x = e[1:2], y = c(yy[k], yy[k]), gp = gpar(col = "#1B2631", lwd = 2.6))
  grid.lines(x = c(e[1], e[1]), y = yy[k] + c(-0.022, 0.022), gp = gpar(col = "#1B2631", lwd = 2.6))
  grid.lines(x = c(e[2], e[2]), y = yy[k] + c(-0.022, 0.022), gp = gpar(col = "#1B2631", lwd = 2.6))
  grid.points(x = e[3], y = yy[k], pch = 21, size = unit(7, "pt"),
              gp = gpar(fill = "#1B2631", col = "#FFFFFF", lwd = 1))
}
popViewport()
grid.text("effectzones", x = 0.5, y = 0.76, gp = gpar(col = "#FFFFFF", fontsize = 21, fontface = "bold"))
grid.polygon(hx, hy, gp = gpar(fill = NA, col = "#18BC9C", lwd = 7))
dev.off()
