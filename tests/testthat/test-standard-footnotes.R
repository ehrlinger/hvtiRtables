test_that("standard_footnotes returns the two house-standard footnotes", {
  sf <- standard_footnotes()
  expect_identical(sf, list(
    `*` = "Number of non-missing values.",
    `†` = "Median (15th, 85th percentile)."
  ))
})

test_that("standard_footnotes can be overridden with modifyList", {
  sf <- modifyList(standard_footnotes(), list(`†` = "custom text"))
  expect_identical(sf[["*"]], "Number of non-missing values.")
  expect_identical(sf[["†"]], "custom text")
})

test_that("standard_footnotes can be extended with an extra symbol", {
  sf <- c(standard_footnotes(), list(`‡` = "extra note"))
  expect_length(sf, 3)
  expect_identical(sf[["‡"]], "extra note")
})
