test_that(".describe reports class and length, never the value", {
  expect_identical(.describe(NULL), "NULL")
  expect_identical(.describe(c(11, 12)), "numeric of length 2")
  expect_identical(.describe(character(0)), "character of length 0")
  expect_identical(.describe(NA), "NA")
  expect_identical(.describe(10), "numeric of length 1")
  expect_identical(.describe("x"), "character of length 1")
})

test_that(".describe keeps the class in the length-not-1 branch", {
  # The clause exists for the argument-order slip, where the class
  # mismatch is the tell -- so the length-not-1 branch must report the
  # class too. "a vector of length 8" for a 200-row data frame (8
  # columns) was actively misleading.
  expect_identical(.describe(gtsummary::trial),
                   "tbl_df of length 8")
  expect_identical(.describe(fx_plain_tbl()),
                   "tbl_summary of length 5")
  expect_identical(
    tryCatch(hv_man_table(gtsummary::trial), error = conditionMessage),
    paste0("`tbl` must be a gtsummary table object. Received: ",
           "tbl_df of length 8.")
  )
  expect_identical(
    tryCatch(
      hv_man_table_save(fx_plain_tbl(), tempfile(fileext = ".docx")),
      error = conditionMessage
    ),
    paste0("`ft` must be a flextable object. Received: ",
           "tbl_summary of length 5.")
  )
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
           "permitted for wide tables). Received: numeric of ",
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

test_that(".assert_type_buckets rejects a variable in two buckets", {
  expect_silent(
    .assert_type_buckets(c("age"), character(0), c("sex"))
  )
  expect_identical(
    tryCatch(
      .assert_type_buckets(c("mpg"), c("mpg"), character(0)),
      error = conditionMessage
    ),
    paste0("`mpg` appears in more than one of `continuous`, `binary`, ",
           "and `categorical`. Every variable must be classified ",
           "exactly once. Overlapping: mpg (continuous, binary).")
  )
})

test_that(".assert_type_buckets requires character vectors", {
  expect_error(.assert_type_buckets(1, character(0), character(0)),
               "`continuous` must be a character vector")
})

test_that(".assert_type_buckets flags duplication within one bucket", {
  expect_identical(
    tryCatch(
      .assert_type_buckets(c("age", "age"), character(0),
                           character(0)),
      error = conditionMessage
    ),
    paste0("`continuous` lists `age` more than once. Each variable ",
           "name may appear at most once per bucket. Remove the ",
           "duplicate from `continuous`.")
  )
})

test_that(".assert_type_buckets: cross-bucket beats intra-bucket", {
  # "age" is both duplicated inside `continuous` AND present in
  # `binary`. The cross-bucket reading wins: it is the classification
  # conflict that matters (which bucket does "age" belong to?), and
  # its message already reports every bucket the name appears in, so
  # it is never contradicted by the intra-bucket duplicate.
  expect_identical(
    tryCatch(
      .assert_type_buckets(c("age", "age"), c("age"), character(0)),
      error = conditionMessage
    ),
    paste0("`age` appears in more than one of `continuous`, `binary`, ",
           "and `categorical`. Every variable must be classified ",
           "exactly once. Overlapping: age (continuous, binary).")
  )
})

test_that(".assert_jtcvs_groups checks names exist in table_body", {
  tbl <- fx_jtcvs_tbl()
  expect_silent(
    .assert_jtcvs_groups(tbl, c(stat_1 = "A", stat_2 = "B"))
  )
  expect_identical(
    tryCatch(
      .assert_jtcvs_groups(tbl, c(stat_3 = "C")),
      error = conditionMessage
    ),
    paste0("`groups` names must be columns in `tbl$table_body`. ",
           "Not found: stat_3. Available: stat_1, stat_2.")
  )
  expect_error(.assert_jtcvs_groups(tbl, c("A", "B")),
               "must have a non-empty name")
  expect_error(.assert_jtcvs_groups(tbl, character(0)),
               "must be a named character vector")
})

test_that(".assert_stat_convention accepts NA cells", {
  # A valid hv_tbl_summary() table carries NA stat cells on the parent
  # label row of a multi-level categorical. Requiring every cell to
  # split would reject correct tables.
  tbl <- fx_hv_tbl()
  expect_true(anyNA(tbl$table_body$stat_1))
  expect_silent(
    .assert_stat_convention(tbl$table_body,
                            c(stat_1 = "A", stat_2 = "B"))
  )
})

test_that(".assert_stat_convention errors on a column absent from tb", {
  # Unreachable via the wired call path (.assert_jtcvs_groups() runs
  # first and rejects an unknown name), but nothing enforces that
  # ordering, so this function must not silently pass a `groups`
  # column that isn't in `tb`.
  tbl <- fx_jtcvs_tbl()
  expect_error(
    .assert_stat_convention(tbl$table_body, c(stat_9 = "Z")),
    "`tbl` has no column `stat_9`", fixed = TRUE
  )
})

test_that(".assert_stat_convention rejects a table without |||", {
  tbl <- fx_plain_tbl()
  msg <- tryCatch(
    .assert_stat_convention(tbl$table_body, c(stat_1 = "A")),
    error = conditionMessage
  )
  expect_match(msg, "was not built with the", fixed = TRUE)
  expect_match(msg, "hv_tbl_summary()", fixed = TRUE)
  expect_match(msg, "First unparseable value:", fixed = TRUE)
})

test_that(".assert_footnote_entries requires a non-empty text", {
  ft <- fx_jtcvs_ft()
  ok <- list(list(row = 1, col = "n_stat_1", text = "Note."))
  expect_silent(.assert_footnote_entries(ok, ft))
  expect_identical(
    tryCatch(
      .assert_footnote_entries(
        list(list(row = 1, col = "n_stat_1")), ft
      ),
      error = conditionMessage
    ),
    paste0("`footnotes[[1]]$text` must be a single non-empty ",
           "string; it is missing. Each footnote needs ",
           "list(row =, col =, text =).")
  )
  expect_error(
    .assert_footnote_entries(
      list(list(row = 1, col = "n_stat_1", text = "")), ft
    ),
    "must be a single non-empty string"
  )
})

test_that(".assert_footnote_entries keeps the row and col checks", {
  ft <- fx_jtcvs_ft()
  expect_error(
    .assert_footnote_entries(
      list(list(row = 1.5, col = "n_stat_1", text = "x")), ft
    ),
    "must be whole numbers"
  )
  expect_error(
    .assert_footnote_entries(
      list(list(row = 1, col = "nope", text = "x")), ft
    ),
    "is not a column in `ft`"
  )
})

test_that(".assert_jtcvs_groups rejects a duplicated column name", {
  tbl <- fx_jtcvs_tbl()
  expect_identical(
    tryCatch(
      .assert_jtcvs_groups(tbl, c(stat_1 = "A", stat_1 = "B")),
      error = conditionMessage
    ),
    paste0("`groups` must name each column at most once. Duplicated: ",
           "stat_1. Each stat_<k> column gets one spanning label, ",
           "e.g. c(stat_1 = \"A\", stat_2 = \"B\").")
  )
})

test_that(".assert_footnote_entries rejects a non-list entry", {
  # Forgetting the outer nesting is the likeliest mistake against a
  # documented list(list(row =, col =, text =)) shape, and it leaked
  # "$ operator is invalid for atomic vectors" from the first fn$ access.
  ft <- fx_jtcvs_ft()
  for (bad in list(list(row = 1, col = "label", text = "x"),
                   "a note", list("a note"))) {
    msg <- tryCatch(.assert_footnote_entries(bad, ft),
                    error = conditionMessage)
    expect_false(grepl("$ operator", msg, fixed = TRUE))
    expect_match(msg, "must be a list of the form", fixed = TRUE)
  }
  expect_identical(
    tryCatch(
      .assert_footnote_entries(
        list(row = 1, col = "label", text = "x"), ft
      ),
      error = conditionMessage
    ),
    paste0("`footnotes[[1]]` must be a list of the form ",
           "list(row =, col =, text =). Received: numeric of ",
           "length 1. `footnotes` is a list *of* footnotes, so one ",
           "footnote is list(list(row = 1, col = \"n_stat_1\", ",
           "text = \"...\")).")
  )
})

test_that(".assert_footnote_entries says what arrived for col", {
  # The message used to end at a trailing colon with nothing after it
  # whenever fn$col was NULL: no "Received:", no runnable fix.
  ft <- fx_jtcvs_ft()
  expect_identical(
    tryCatch(
      .assert_footnote_entries(list(list(row = 1, text = "x")), ft),
      error = conditionMessage
    ),
    paste0("`footnotes[[1]]$col` is not a column in `ft`; it is ",
           "missing. Available: ", paste(ft$col_keys, collapse = ", "),
           ". Each footnote needs list(row =, col =, text =).")
  )
  expect_match(
    tryCatch(
      .assert_footnote_entries(
        list(list(row = 1, col = "nope", text = "x")), ft
      ),
      error = conditionMessage
    ),
    "it is \"nope\"", fixed = TRUE
  )
})

test_that(".check_abbreviations checks type before allowing empty", {
  # An empty value skipped the type check entirely, so `list()` was
  # accepted while `list(N = "x")` errored -- the same type treated two
  # ways on length alone.
  expect_silent(.check_abbreviations(NULL))
  expect_silent(.check_abbreviations(character(0)))
  expect_error(.check_abbreviations(list()), "named character vector")
  expect_error(.check_abbreviations(numeric(0)), "named character vector")
})

test_that(".assert_footnote_entries rejects a non-list of entries", {
  ft <- fx_jtcvs_ft()
  # list() is a well-formed empty entry list; character(0) is not a
  # list at all and was accepted only because seq_along() was empty.
  expect_silent(.assert_footnote_entries(NULL, ft))
  expect_silent(.assert_footnote_entries(list(), ft))
  expect_error(.assert_footnote_entries(character(0), ft),
               "must be a list of the form")
})
