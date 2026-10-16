# hv_tbl_compare() joins a caller-computed comparison column (for
# example hvtiRpropensity::ps_stddiff()'s %stddiff numbers) onto an
# hv_tbl_summary() table.

cmp_tbl <- function(compare = "none", ...) {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(D = c("age", "grade", "response")),
    continuous = "age", categorical = "grade", binary = "response",
    compare = compare, ...
  )
}

cmp_vals <- c(age = "3.1", grade = "12.0", response = "8.4")

test_that("hv_tbl_compare puts one value on each variable's first row", {
  tb <- hv_tbl_compare(cmp_tbl(), cmp_vals, "Std. Diff. (%)")$table_body
  expect_identical(tb$hv_join_1[tb$row_type == "label"],
                   unname(cmp_vals))
  expect_true(all(is.na(tb$hv_join_1[tb$row_type != "label"])))
})

test_that("hv_tbl_compare leaves a variable it was not given blank", {
  tb <- hv_tbl_compare(cmp_tbl(), cmp_vals["age"], "SD")$table_body
  expect_identical(tb$hv_join_1[tb$row_type == "label"],
                   c("3.1", NA, NA))
})

test_that("hv_tbl_compare's column is visible, labeled and rightmost", {
  tbl <- hv_tbl_compare(cmp_tbl(), cmp_vals, "Std. Diff. (%)")
  st <- tbl$table_styling$header
  expect_false(st$hide[st$column == "hv_join_1"])
  expect_identical(st$label[st$column == "hv_join_1"], "**Std. Diff. (%)**")
  expect_identical(utils::tail(names(tbl$table_body), 1), "hv_join_1")
  expect_identical(attr(tbl, "hv_trailing"),
                   c(hv_join_1 = "Std. Diff. (%)"))
})

test_that("hv_tbl_compare sits beside compare = 'pvalue' in both renderers", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_compare(cmp_tbl("pvalue"), cmp_vals, "Std. Diff. (%)")
  expect_identical(attr(tbl, "hv_trailing"),
                   c(hv_compare_col = "P", hv_join_1 = "Std. Diff. (%)"))
  corr <- hv_man_table(tbl)
  expect_identical(utils::tail(corr$col_keys, 2), c("p.value", "hv_join_1"))
  d <- corr$body$dataset
  expect_identical(d$hv_join_1[d$label == "Age"], "3.1")
  jt <- hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"),
                           trailing = attr(tbl, "hv_trailing"))
  expect_identical(utils::tail(jt$col_keys, 2),
                   c("hv_compare_col", "hv_join_1"))
  jd <- jt$body$dataset
  expect_identical(jd$hv_join_1[jd$label == "Age"], "3.1")
  # The test letters still land on the p-value column.
  notes <- hv_test_footnotes_jtcvs(tbl)
  expect_true(length(notes) > 0L)
  expect_true(all(vapply(notes, `[[`, "", "col") == "hv_compare_col"))
})

test_that("two calls give two columns, in call order", {
  tbl <- hv_tbl_compare(cmp_tbl(), cmp_vals, "A")
  tbl <- hv_tbl_compare(tbl, cmp_vals, "B")
  expect_identical(attr(tbl, "hv_trailing"), c(hv_join_1 = "A",
                                               hv_join_2 = "B"))
})

test_that("a joined table saves to valid .docx through both savers", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_compare(cmp_tbl("pvalue"), cmp_vals, "Std. Diff. (%)")
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(tbl), path)
  expect_identical(nrow(hv_check_docx(path)), 0L)
  jpath <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(
    hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"),
                       trailing = attr(tbl, "hv_trailing")),
    jpath, caption = "T1.", footnotes = hv_test_footnotes_jtcvs(tbl)
  )
  expect_true(file.exists(jpath))
})

test_that("hv_tbl_compare validates its inputs in its own words", {
  tbl <- cmp_tbl()
  expect_error(hv_tbl_compare(tbl, c("3.1", "2"), "SD"),
               "`values` must be a character vector named by variable",
               fixed = TRUE)
  expect_error(hv_tbl_compare(tbl, c(age = 3.1), "SD"),
               "`values` must be a character vector named by variable",
               fixed = TRUE)
  expect_error(hv_tbl_compare(tbl, character(0), "SD"),
               "`values` must be a character vector named by variable",
               fixed = TRUE)
  expect_error(hv_tbl_compare(tbl, c(age = "1", bmi = "2", wt = "3"), "SD"),
               "`values` names variable(s) not in the table: bmi, wt.",
               fixed = TRUE)
  expect_error(hv_tbl_compare(tbl, c(age = "1", age = "2"), "SD"),
               "`values` names a variable more than once: age.",
               fixed = TRUE)
  for (bad in list(NA_character_, "", c("a", "b"), 1)) {
    expect_error(hv_tbl_compare(tbl, cmp_vals, bad),
                 "`label` must be a single non-empty string",
                 fixed = TRUE)
  }
})

test_that("hv_tbl_compare shares the tbl-class contract", {
  m1 <- tryCatch(hv_man_table("nope"), error = conditionMessage)
  m2 <- tryCatch(hv_tbl_compare("nope", cmp_vals, "SD"),
                 error = conditionMessage)
  expect_identical(m1, m2)
})
