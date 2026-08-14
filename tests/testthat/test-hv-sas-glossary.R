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
  # Tightened to a substring unique to the *corrected* mapping (this
  # regressed once already, when CON1's note pointed at itself instead
  # of naming CON3= as the behavior `continuous` actually reproduces).
  # A bare "mean" substring would also match a reintroduced-bug message
  # like "CON1= now maps to mean +/- SD directly".
  expect_error(
    .check_sas_args(list(con1 = "age"), "hv_tbl_summary"),
    "the `CON3=` behavior",
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

test_that("ADDFN= gives a family-appropriate note for each saver", {
  # hv_man_table_save()'s `footnotes` is a named symbol -> text list;
  # hv_man_table_save_jtcvs()'s is a list of list(row=, col=, text=).
  # Following the CORR note in a JTCVS call errors immediately, so the
  # note text must differ by family, not be shared verbatim.
  expect_error(
    .check_sas_args(list(addfn = "note"), "hv_man_table_save"),
    "pass a named list, symbol -> footnote text", fixed = TRUE
  )
  expect_error(
    .check_sas_args(list(addfn = "note"), "hv_man_table_save_jtcvs"),
    "list(row =, col =, text =)", fixed = TRUE
  )
})

test_that("PRINTFN= gives a family-appropriate note for each saver", {
  expect_error(
    .check_sas_args(list(printfn = "note"), "hv_man_table_save"),
    "pass `hv_man_footnotes()`, or `NULL` for none", fixed = TRUE
  )
  expect_error(
    .check_sas_args(list(printfn = "note"), "hv_man_table_save_jtcvs"),
    "hv_test_footnotes_jtcvs()", fixed = TRUE
  )
})

test_that("all-positional extra arguments error instead of being swallowed", {
  # names(dots) is NULL, not character(0), for a fully positional dots
  # list -- the old `length(nms) == 0` guard treated that as "no
  # extras" and returned silently.
  expect_error(
    .check_sas_args(list("JUNK"), "hv_man_table"),
    "unused argument (position 5)", fixed = TRUE
  )
  expect_error(
    hv_man_table(gtsummary::tbl_summary(gtsummary::trial, include = "age"),
                 "Times New Roman", 12, 2, "JUNK"),
    "unused argument (position 5)", fixed = TRUE
  )
})

test_that("a mixed named-and-positional dots list is handled sensibly", {
  # A positional extra followed by an unrecognized named one: reported
  # by position, not the old nonsense "unused argument ()".
  expect_error(
    .check_sas_args(list("JUNK", colour = "red"), "hv_man_table"),
    "unused argument (position 5)", fixed = TRUE
  )
  # A positional extra followed by a *recognized* macro name: the
  # helpful macro-specific message wins over the positional one.
  expect_error(
    .check_sas_args(list("JUNK", class = "trt"), "hv_tbl_summary"),
    "Use `by =`", fixed = TRUE
  )
})

test_that("a recognized macro name is not masked by an earlier typo", {
  # Regression for "only nms[1] is inspected": a generic typo in the
  # first position previously produced a bare "unused argument (colour)"
  # even when a real, more actionable %summarytable name followed it.
  expect_error(
    .check_sas_args(list(colour = "red", class = "trt"), "hv_tbl_summary"),
    "Use `by =`", fixed = TRUE
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
