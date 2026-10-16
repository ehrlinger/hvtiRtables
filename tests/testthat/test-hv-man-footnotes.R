test_that("hv_man_footnotes returns the two house-standard footnotes", {
  sf <- hv_man_footnotes()
  expect_identical(sf, list(
    `*` = "Number of non-missing values.",
    `†` = "No. (%) or Median (15th, 85th percentile)."
  ))
})

test_that("hv_man_footnotes follows the continuous statistic", {
  expect_identical(
    hv_man_footnotes(continuous_stat = "mean")[["†"]],
    "No. (%) or Mean±SD."
  )
  expect_identical(
    # Under "both" the dagger describes the statistic columns; the
    # medians sit in their own, self-headed column.
    hv_man_footnotes(continuous_stat = "both")[["†"]],
    "No. (%) or Mean±SD."
  )
  expect_identical(
    hv_man_footnotes(percentiles = c(16, 84))[["†"]],
    "No. (%) or Median (16th, 84th percentile)."
  )
})

test_that("hv_man_footnotes formats custom percentiles as ordinals", {
  cases <- list(
    `1st and 2nd` = list(p = c(1, 2), want = "(1st, 2nd percentile)."),
    `11th and 13th` = list(p = c(11, 13), want = "(11th, 13th percentile)."),
    `12th and 13th` = list(p = c(12, 13), want = "(12th, 13th percentile)."),
    `21st and 22nd` = list(p = c(21, 22), want = "(21st, 22nd percentile).")
  )
  for (case in cases) {
    expect_identical(
      hv_man_footnotes(percentiles = case$p)[["†"]],
      paste("No. (%) or Median", case$want)
    )
  }
})

test_that("hv_man_footnotes rejects malformed percentiles", {
  expect_error(
    hv_man_footnotes(percentiles = c(10, 50, 90)),
    "`percentiles` must be a numeric vector of length 2", fixed = TRUE
  )
  for (p in list(c(10.5, 85), c(-5, 85), c(15, 150), c(NA_real_, 85))) {
    expect_error(
      hv_man_footnotes(percentiles = p),
      "`percentiles` must be whole numbers between 0 and 100", fixed = TRUE
    )
  }
  expect_error(
    hv_man_footnotes(percentiles = c(85, 15)),
    "`percentiles` must be increasing", fixed = TRUE
  )
})

test_that("non-finite percentiles fail without a coercion warning", {
  warnings <- character(0)
  expect_error(
    withCallingHandlers(
      hv_man_footnotes(percentiles = c(Inf, 85)),
      warning = function(cnd) {
        warnings <<- c(warnings, conditionMessage(cnd))
        invokeRestart("muffleWarning")
      }
    ),
    "`percentiles` must be whole numbers between 0 and 100", fixed = TRUE
  )
  expect_length(warnings, 0L)
})

test_that("hv_man_footnotes can be overridden with modifyList", {
  sf <- modifyList(hv_man_footnotes(), list(`†` = "custom text"))
  expect_identical(sf[["*"]], "Number of non-missing values.")
  expect_identical(sf[["†"]], "custom text")
})

test_that("hv_man_footnotes can be extended with an extra symbol", {
  sf <- c(hv_man_footnotes(), list(`‡` = "extra note"))
  expect_length(sf, 3)
  expect_identical(sf[["‡"]], "extra note")
})
