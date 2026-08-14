test_that("a same-stage macro name names the R argument to use", {
  expect_error(
    .check_sas_args(list(class = "trt"), "hv_tbl_summary"),
    "`class` is the `%summarytable` name for `by`",
    fixed = TRUE
  )
})

test_that("a different-stage macro name names the function to pass it to", {
  expect_error(
    .check_sas_args(list(addfn = "note"), "hv_tbl_summary"),
    "pass `footnotes =` to `hv_man_table_save()`",
    fixed = TRUE
  )
})

test_that("the message names the sibling matching the caller's family", {
  # Same parameter, two families, two different destination functions.
  expect_error(
    .check_sas_args(list(addfn = "note"), "hv_man_table_save_jtcvs"),
    "Use `footnotes =`", fixed = TRUE
  )
  expect_error(
    .check_sas_args(list(rtffile = "t.rtf"), "hv_man_table_jtcvs"),
    "pass `file =` to `hv_man_table_save_jtcvs()`", fixed = TRUE
  )
  expect_error(
    .check_sas_args(list(rtffile = "t.rtf"), "hv_man_table"),
    "pass `file =` to `hv_man_table_save()`", fixed = TRUE
  )
})

test_that("TBLTITLE= is honest that the CORR saver has no caption", {
  # hv_man_table_save() genuinely has no `caption` argument; naming one
  # would send the reader to an argument that does not exist.
  expect_error(
    .check_sas_args(list(tbltitle = "Table 1"), "hv_man_table_save"),
    "the CORR saver writes no caption",
    fixed = TRUE
  )
  expect_error(
    .check_sas_args(list(tbltitle = "Table 1"), "hv_man_table_save_jtcvs"),
    "Use `caption =`", fixed = TRUE
  )
  # A family-neutral caller is routed to the family that has the argument.
  expect_error(
    .check_sas_args(list(tbltitle = "Table 1"), "hv_tbl_summary"),
    "pass `caption =` to `hv_man_table_save_jtcvs()`", fixed = TRUE
  )
})

test_that("an unsupported macro parameter says so and names no argument", {
  expect_error(
    .check_sas_args(list(weight = "wt"), "hv_tbl_summary"),
    "weighted summaries are not supported",
    fixed = TRUE
  )
})

test_that("CON1 explains the statistic change rather than mapping silently", {
  expect_error(
    .check_sas_args(list(con1 = "age"), "hv_tbl_summary"),
    "mean",
    fixed = TRUE
  )
})

test_that("macro names are matched case-insensitively", {
  expect_error(
    .check_sas_args(list(CLASS = "trt"), "hv_tbl_summary"),
    "`by`",
    fixed = TRUE
  )
})

test_that("a non-macro unused argument still errors, generically", {
  expect_error(
    .check_sas_args(list(colour = "red"), "hv_tbl_summary"),
    "unused argument",
    fixed = TRUE
  )
})

test_that("no dots is silent", {
  expect_null(.check_sas_args(list(), "hv_tbl_summary"))
})

test_that("every map entry is well formed", {
  for (nm in names(.sas_param_map)) {
    entry <- .sas_param_map[[nm]]
    expect_true(is.list(entry), info = nm)
    expect_true(all(c("arg", "stage") %in% names(entry)), info = nm)
    # An entry either routes somewhere or explains why it does not.
    if (is.na(entry$arg)) {
      expect_true(is.na(entry$stage), info = nm)
      expect_true(nzchar(entry$note %||% ""), info = nm)
    } else {
      expect_true(entry$stage %in% names(.stage_fns), info = nm)
    }
    # A family-restricted entry must say what the other family gets.
    if (!is.null(entry$only)) {
      expect_true(entry$only %in% c("corr", "jtcvs"), info = nm)
      expect_true(nzchar(entry$note_other %||% ""), info = nm)
    }
  }
})

test_that("map names are already lowercase", {
  expect_identical(names(.sas_param_map), tolower(names(.sas_param_map)))
})

test_that("each public function routes SAS names through the glossary", {
  tbl <- gtsummary::tbl_summary(gtsummary::trial, by = "trt",
                                include = "age")
  ft <- hv_man_table(tbl)

  expect_error(
    hv_tbl_summary(gtsummary::trial, groups = list(D = "age"),
                   continuous = "age", class = "trt"),
    "Use `by =`", fixed = TRUE
  )
  expect_error(hv_man_table(tbl, style = "journal"),
               "house font and rounding are fixed", fixed = TRUE)
  expect_error(
    hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"),
                       style = "journal"),
    "house font and rounding are fixed", fixed = TRUE
  )
  expect_error(
    hv_man_table_save(ft, tempfile(fileext = ".docx"), tbltitle = "T1"),
    "the CORR saver writes no caption", fixed = TRUE
  )
  expect_error(
    hv_man_table_save_jtcvs(ft, tempfile(fileext = ".docx"),
                            caption = "T1", addfn = "note"),
    "`footnotes =`", fixed = TRUE
  )
})

test_that("a typo that reaches ... is still caught", {
  # `percentyles` matches no formal, so it lands in `...`. Note that
  # `percentile` would NOT reach here -- R partial-matches it to
  # `percentiles` and the call is correct. Only names that match nothing
  # are at risk of being silently swallowed by `...`, and those are
  # exactly what this guards.
  expect_error(
    hv_tbl_summary(gtsummary::trial, groups = list(D = "age"),
                   continuous = "age", percentyles = c(16, 84)),
    "unused argument", fixed = TRUE
  )
})
