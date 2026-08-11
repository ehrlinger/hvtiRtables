test_that(".describe reports class and length, never the value", {
  expect_identical(.describe(NULL), "NULL")
  expect_identical(.describe(c(11, 12)), "a vector of length 2")
  expect_identical(.describe(character(0)), "a vector of length 0")
  expect_identical(.describe(NA), "NA")
  expect_identical(.describe(10), "numeric of length 1")
  expect_identical(.describe("x"), "character of length 1")
})

test_that(".check_font_size accepts only 11 and 12", {
  expect_identical(.check_font_size(11), 11)
  expect_identical(.check_font_size(12), 12)
  for (bad in list(10, 13, c(11, 12), "12", NA_real_, numeric(0),
                   NULL)) {
    expect_error(.check_font_size(bad), "must be 11 or 12")
  }
})

test_that(".check_font_size message names the house rule", {
  expect_identical(
    tryCatch(.check_font_size(c(11, 12)), error = conditionMessage),
    paste0("`font_size` must be 11 or 12 (house rule: 12pt, 11pt ",
           "permitted for wide tables). Received: a vector of ",
           "length 2.")
  )
})

test_that(".check_string rejects every non-single-string shape", {
  expect_identical(.check_string("ok", "caption"), "ok")
  for (bad in list("", NA_character_, character(0), c("a", "b"), 1,
                   NULL, list("a"))) {
    expect_error(.check_string(bad, "caption"), "caption")
  }
})

test_that(".check_gtsummary and .check_flextable check class", {
  expect_error(.check_gtsummary("nope"), "gtsummary")
  expect_error(.check_flextable("nope"), "flextable")
  expect_error(.check_gtsummary("nope", "x"), "`x`")
})

test_that(".check_file rejects bad paths and missing directories", {
  f <- tempfile(fileext = ".docx")
  expect_identical(.check_file(f), f)
  for (bad in list(1, NA_character_, "", character(0), c("a", "b"),
                   NULL)) {
    expect_error(.check_file(bad), "must be a single non-empty file")
  }
  expect_error(
    .check_file(file.path(tempdir(), "no-such-dir", "x.docx")),
    "Output directory does not exist"
  )
})

test_that(".check_abbreviations enforces the documented type", {
  expect_silent(.check_abbreviations(NULL))
  expect_silent(.check_abbreviations(character(0)))
  expect_silent(.check_abbreviations(c(N = "sample size")))
  expect_error(.check_abbreviations(c("no name")), "non-empty name")
  expect_error(.check_abbreviations(list(N = "x")),
               "named character vector")
})
