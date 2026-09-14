mk_corr_data <- function() {
  set.seed(3)
  n <- 80
  a1c <- rnorm(n, 6.5, 1)
  data.frame(
    a1c = a1c,
    glu = 20 * a1c + rnorm(n, 0, 20),
    alb = 4 - 0.1 * a1c + rnorm(n, 0, 0.4),
    grp = factor(rep(c("low", "high"), each = n / 2))
  )
}

test_that("Pearson CI matches cor.test at the default 68% level", {
  d <- mk_corr_data()
  out <- hv_correlation_table(d, vars = c("glu", "alb"), with = "a1c",
                              method = "pearson")
  ref <- stats::cor.test(d$glu, d$a1c, conf.level = 0.68)
  row <- out[out$variable == "glu", ]
  expect_equal(row$estimate, unname(ref$estimate))
  expect_equal(c(row$conf.low, row$conf.high), as.numeric(ref$conf.int))
  expect_equal(attr(out, "conf_level"), 0.68)
})

test_that("Spearman estimate and Fisher p-value are computed by hand", {
  d <- mk_corr_data()
  out <- hv_correlation_table(d, vars = "alb", with = "a1c",
                              method = "spearman")
  r <- stats::cor(d$alb, d$a1c, method = "spearman")
  expect_equal(out$estimate, r)
  expect_equal(out$p.value, 2 * stats::pnorm(-abs(atanh(r)) * sqrt(80 - 3)))
})

test_that("both methods by default, spearman first", {
  out <- hv_correlation_table(mk_corr_data(), vars = "glu", with = "a1c")
  expect_equal(out$method, c("spearman", "pearson"))
})

test_that("with = NULL gives every unordered pair of vars", {
  out <- hv_correlation_table(mk_corr_data(), vars = c("a1c", "glu", "alb"),
                              method = "pearson")
  expect_equal(nrow(out), 3L)
  expect_equal(paste(out$variable, out$with),
               c("a1c glu", "a1c alb", "glu alb"))
})

test_that("missing values are deleted pairwise", {
  d <- mk_corr_data()
  d$glu[1:5] <- NA
  d$alb[6:8] <- NA
  out <- hv_correlation_table(d, vars = c("glu", "alb"), with = "a1c",
                              method = "pearson")
  expect_equal(out$n, c(75L, 77L))
})

test_that("display is 'r (lcl, ucl)' at `digits` places", {
  out <- hv_correlation_table(mk_corr_data(), vars = "glu", with = "a1c",
                              method = "pearson")
  expect_match(
    out$display,
    "^-?[0-9]\\.[0-9]{2} \\(-?[0-9]\\.[0-9]{2}, -?[0-9]\\.[0-9]{2}\\)$"
  )
})

test_that("labels come from a haven-style label attribute, else the name", {
  d <- mk_corr_data()
  attr(d$glu, "label") <- "Preop: Glucose"
  out <- hv_correlation_table(d, vars = c("glu", "alb"), with = "a1c",
                              method = "pearson")
  expect_equal(out$label, c("Preop: Glucose", "alb"))
})

test_that("n <= 3 gives an NA interval, not an error", {
  d <- mk_corr_data()[1:3, ]
  out <- hv_correlation_table(d, vars = "glu", with = "a1c", method = "pearson")
  expect_true(is.na(out$conf.low))
  expect_true(is.na(out$display))
})

test_that("by stratifies: one block per level, carried first", {
  d <- mk_corr_data()
  out <- hv_correlation_table(d, vars = "glu", with = "a1c", by = "grp",
                              method = "pearson")
  expect_equal(names(out)[1], "grp")
  expect_equal(nrow(out), 2L)
  hi <- d[d$grp == "high", ]
  expect_equal(out$estimate[out$grp == "high"], stats::cor(hi$glu, hi$a1c))
  expect_equal(out$n, c(40L, 40L))
})

test_that("errors name the problem", {
  d <- mk_corr_data()
  expect_error(hv_correlation_table(list(), vars = "a"), "data frame")
  expect_error(hv_correlation_table(d, vars = "nope", with = "a1c"),
               "not found")
  expect_error(hv_correlation_table(d, vars = "grp", with = "a1c"), "numeric")
  expect_error(hv_correlation_table(d, vars = "glu"), "at least two")
  expect_error(hv_correlation_table(d, vars = "glu", with = "a1c",
                                    conf_level = 95), "between 0 and 1")
})

test_that("vars/with overlap keeps pairs against a different with-column", {
  out <- hv_correlation_table(mk_corr_data(), vars = c("glu", "alb"),
                              with = c("a1c", "glu"), method = "pearson")
  expect_equal(paste(out$variable, out$with),
               c("glu a1c", "alb a1c", "alb glu"))
})

test_that("every vars column also in with errors with the exact message", {
  d <- mk_corr_data()
  expect_error(
    hv_correlation_table(d, vars = "a1c", with = "a1c", method = "pearson"),
    "No pairs to correlate: every column in `vars` is also in `with`.",
    fixed = TRUE
  )
})

test_that("with = character(0) errors clearly", {
  d <- mk_corr_data()
  expect_error(
    hv_correlation_table(d, vars = c("glu", "alb"), with = character(0),
                         method = "pearson"),
    "with"
  )
})

test_that("by preserves a factor column's class and levels", {
  d <- mk_corr_data()
  out <- hv_correlation_table(d, vars = "glu", with = "a1c", by = "grp",
                              method = "pearson")
  expect_s3_class(out$grp, "factor")
  expect_equal(levels(out$grp), levels(d$grp))
})

test_that("by preserves a numeric column's type and sorts numerically", {
  d <- mk_corr_data()
  d$k <- rep(c(9, 10), each = 40)
  out <- hv_correlation_table(d, vars = "glu", with = "a1c", by = "k",
                              method = "pearson")
  expect_true(is.numeric(out$k))
  expect_equal(out$k, c(9, 10))
})

test_that("by with NAs deletes pairwise per stratum, second stratum too", {
  d <- mk_corr_data()
  d$glu[d$grp == "low"][1:3] <- NA
  d$glu[d$grp == "high"][1:5] <- NA
  out <- hv_correlation_table(d, vars = "glu", with = "a1c", by = "grp",
                              method = "pearson")
  low <- d[d$grp == "low", ]
  ok <- stats::complete.cases(low$glu, low$a1c)
  expect_equal(out$estimate[out$grp == "low"],
               stats::cor(low$glu[ok], low$a1c[ok]))
  high <- d[d$grp == "high", ]
  ok2 <- stats::complete.cases(high$glu, high$a1c)
  expect_equal(out$estimate[out$grp == "high"],
               stats::cor(high$glu[ok2], high$a1c[ok2]))
  expect_equal(out$n, c(35L, 37L))
})

test_that("duplicate vars/with are de-duplicated", {
  out <- hv_correlation_table(mk_corr_data(), vars = c("glu", "glu"),
                              with = "a1c", method = "pearson")
  expect_equal(nrow(out), 1L)
})

test_that("digits must be a single non-negative whole number", {
  d <- mk_corr_data()
  expect_error(hv_correlation_table(d, vars = "glu", with = "a1c",
                                    digits = -1), "digits")
  expect_error(hv_correlation_table(d, vars = "glu", with = "a1c",
                                    digits = 1.5), "digits")
  expect_error(hv_correlation_table(d, vars = "glu", with = "a1c",
                                    digits = c(1, 2)), "digits")
})

test_that("by naming a column also in vars or with errors", {
  d <- mk_corr_data()
  expect_error(hv_correlation_table(d, vars = "glu", with = "a1c", by = "glu"),
               "glu")
  expect_error(hv_correlation_table(d, vars = "glu", with = "a1c", by = "a1c"),
               "a1c")
})
