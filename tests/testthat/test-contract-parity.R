# These tests make sibling divergence a test failure rather than a
# review finding. expect_identical() is deliberately stricter than
# expect_match(): the requirement is that the two messages are the
# same sentence, so the test must fail when they drift by a word.

test_that("font_size contract is identical across both renderers", {
  corr <- fx_plain_tbl()
  jt <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  for (bad in list(10, 13, c(11, 12), "12", NA_real_, numeric(0))) {
    m1 <- tryCatch(hv_man_table(corr, font_size = bad),
                   error = conditionMessage)
    m2 <- tryCatch(hv_man_table_jtcvs(jt, g, font_size = bad),
                   error = conditionMessage)
    expect_identical(m1, m2)
  }
})

test_that("font contract is identical across both renderers", {
  corr <- fx_plain_tbl()
  jt <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  for (bad in list(12, c("a", "b"), "", NA_character_)) {
    m1 <- tryCatch(hv_man_table(corr, font = bad),
                   error = conditionMessage)
    m2 <- tryCatch(hv_man_table_jtcvs(jt, g, font = bad),
                   error = conditionMessage)
    expect_identical(m1, m2)
  }
})

test_that("file contract is identical across both savers", {
  ft_corr <- hv_man_table(fx_plain_tbl())
  ft_jt <- fx_jtcvs_ft()
  for (bad in list(1, NA_character_, "", character(0))) {
    m1 <- tryCatch(hv_man_table_save(ft_corr, bad),
                   error = conditionMessage)
    m2 <- tryCatch(
      hv_man_table_save_jtcvs(ft_jt, bad, caption = "T1."),
      error = conditionMessage
    )
    expect_identical(m1, m2)
  }
})

test_that("tbl-class contract is identical across all consumers", {
  g <- c(stat_1 = "A")
  m1 <- tryCatch(hv_man_table("nope"), error = conditionMessage)
  m2 <- tryCatch(hv_man_table_jtcvs("nope", g),
                 error = conditionMessage)
  m3 <- tryCatch(hv_test_footnotes_jtcvs("nope"),
                 error = conditionMessage)
  expect_identical(m1, m2)
  expect_identical(m1, m3)
})

test_that("ft-class contract is identical across both savers", {
  m1 <- tryCatch(hv_man_table_save("nope", tempfile()),
                 error = conditionMessage)
  m2 <- tryCatch(
    hv_man_table_save_jtcvs("nope", tempfile(), caption = "T1."),
    error = conditionMessage
  )
  expect_identical(m1, m2)
})

test_that("footnote-text contract shares its tail across both savers", {
  # The two savers take genuinely different footnote *shapes* -- CORR:
  # a named list, symbol -> text; JTCVS: list(row =, col =, text =) --
  # so their labels (`footnotes[["*"]]` vs `footnotes[[1]]$text`) and
  # closing fixes (a list has no `row`/`col` to tell a CORR caller
  # about) differ on purpose. What must stay identical is the rule
  # itself: the contract sentence in the middle of both messages.
  ft_corr <- hv_man_table(fx_plain_tbl())
  ft_jt <- fx_jtcvs_ft()
  for (bad in list(NULL, NA, 1, c("a", "b"), "")) {
    m1 <- tryCatch(
      hv_man_table_save(ft_corr, tempfile(fileext = ".docx"),
                        footnotes = list(`*` = bad)),
      error = conditionMessage
    )
    m2 <- tryCatch(
      hv_man_table_save_jtcvs(
        ft_jt, tempfile(fileext = ".docx"), caption = "T1.",
        footnotes = list(list(row = 1, col = "n_stat_1", text = bad))
      ),
      error = conditionMessage
    )
    # Strips the leading "`<label>` " and the trailing " <closing fix>",
    # leaving just "must be a single non-empty string; it is <what
    # arrived>." -- the shared rule.
    tail_of <- function(msg) sub("^`[^`]+` (.*?\\.) .*$", "\\1", msg,
                                 perl = TRUE)
    expect_identical(tail_of(m1), tail_of(m2))
  }
})

test_that("every stop() in the package passes call. = FALSE", {
  ns <- asNamespace("hvtiRtables")
  offenders <- character(0)
  for (nm in ls(ns, all.names = TRUE)) {
    obj <- get(nm, envir = ns)
    if (!is.function(obj) || is.null(body(obj))) next
    for (cl in .fx_stop_calls(body(obj))) {
      args <- as.list(cl)[-1]
      ok <- "call." %in% names(args) &&
        identical(args[["call."]], FALSE)
      if (!ok) offenders <- c(offenders, nm)
    }
  }
  expect_identical(unique(offenders), character(0))
})
