# Superscripts and subscripts in study-supplied text (design
# dev/specs/2026-10-21-label-markup-design.md).

# A table whose label, level, `by` levels and section carry markup.
mk_markup_tbl <- function() {
  d <- gtsummary::trial
  attr(d$age, "label") <- "BSA (m^2^)"
  levels(d$grade)[1] <- "HbA~1c~"
  levels(d$grade)[2] <- "~2~"
  d$trt <- factor(d$trt, labels = c("Arm^a^", "Arm^b^"))
  hv_tbl_summary(d, by = "trt", groups = list("Size m^2^" = c("age", "grade")),
                 continuous = "age", categorical = "grade", compare = "p")
}

# Every chunk of a part as "text:alignment".
chunk_aligns <- function(ft, part) {
  unlist(lapply(ft[[part]]$content$data, function(ch) {
    paste0(ch$txt, ":", ifelse(is.na(ch$vertical.align), "baseline",
                               ch$vertical.align))
  }))
}

test_that(".markup_pieces() follows the pair rule", {
  pieces <- function(x) {
    p <- .markup_pieces(x)
    paste0(p$text, ":", p$align)
  }
  expect_identical(pieces("cm^2^/m^2^"),
                   c("cm:baseline", "2:superscript", "/m:baseline",
                     "2:superscript"))
  expect_identical(pieces("HbA~1c~"), c("HbA:baseline", "1c:subscript"))
  expect_identical(pieces("PaO~2~ (mm Hg)"),
                   c("PaO:baseline", "2:subscript", " (mm Hg):baseline"))
  expect_identical(pieces("m^2^~a~"),
                   c("m:baseline", "2:superscript", "a:subscript"))
  # A text that is all markup is one piece, raised or lowered.
  expect_identical(pieces("^2^"), "2:superscript")
  expect_identical(pieces("~2~"), "2:subscript")
  # As typed: no closing marker, whitespace inside, an empty pair.
  expect_identical(pieces("~5 years"), "~5 years:baseline")
  expect_identical(pieces("x ^ y ^ z"), "x ^ y ^ z:baseline")
  expect_identical(pieces("a^^b"), "a^^b:baseline")
  expect_identical(pieces("plain"), "plain:baseline")
  expect_identical(pieces(NA_character_), "NA:baseline")
})

test_that("each table path raises and lowers label, level and header text", {
  tbl <- mk_markup_tbl()
  paths <- list(
    report = hv_man_table(tbl),
    compare = hv_man_table(tbl, style = "manuscript"),
    describe = hv_man_table(tbl, style = "manuscript", layout = "describe")
  )
  for (name in names(paths)) {
    body <- chunk_aligns(paths[[name]], "body")
    header <- chunk_aligns(paths[[name]], "header")
    expect_true("2:superscript" %in% body, info = name)
    expect_true("1c:subscript" %in% body, info = name)
    # A cell that is all markup (the level "~2~") is lowered too.
    expect_true("2:subscript" %in% body, info = name)
    expect_true(all(c("a:superscript", "b:superscript") %in% header),
                info = name)
    expect_false(any(grepl("\\^|~", c(body, header))), info = name)
  }
})

test_that("the deprecated JTCVS table renders markup too", {
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    mk_markup_tbl(), groups = c(stat_1 = "Arm a", stat_2 = "Arm b")
  ))
  expect_true("2:superscript" %in% chunk_aligns(ft, "body"))
})

test_that("a split label keeps its row's bold in Word", {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  hv_man_table_save(hv_man_table(mk_markup_tbl()), out)
  runs <- wx_runs(out, "Size m")
  expect_identical(vapply(runs, `[[`, "", "text"), c("Size m", "2"))
  expect_identical(vapply(runs, `[[`, "", "align"),
                   c("baseline", "superscript"))
  expect_true(all(vapply(runs, `[[`, TRUE, "bold")))
})

test_that("a table without markup is unchanged", {
  ft <- hv_man_table(fx_hv_tbl())
  expect_identical(.apply_markup(ft), ft)
})

test_that("runs without markup are unchanged", {
  runs <- .key_runs(c(SD = "standard deviation"))
  expect_identical(.expand_markup(runs)[names(runs)], runs)
  expect_false(any(.expand_markup(runs)$sub))
})

test_that("the abbreviation key and the caption render markup in Word", {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  hv_man_table_save(
    hv_man_table(mk_markup_tbl(), style = "manuscript"), out,
    abbreviations = c(BSA = "body surface area (m^2^)", "SpO~2~" = "oxygen"),
    caption = "Table 1. Size (m^2^)"
  )
  key <- wx_runs(out, "Key:")
  texts <- vapply(key, `[[`, "", "text")
  aligns <- vapply(key, `[[`, "", "align")
  expect_identical(aligns[texts == "2"], c("superscript", "subscript"))
  expect_true(key[[which(texts == "SpO")]]$italic)
  expect_true(key[[which(texts == "2" & aligns == "subscript")]]$italic)
  cap <- wx_runs(out, "Table 1.")
  expect_identical(vapply(cap, `[[`, "", "align"),
                   c("baseline", "superscript", "baseline"))
  expect_true(all(vapply(cap, `[[`, TRUE, "bold")))
  # The saver's header marks are added after the markup, and both stay
  # raised: the dagger on P, the letters on the group levels.
  header_sup <- unlist(lapply(wx_rows(wx_doc(out))[1:2], function(row) {
    vapply(row, `[[`, "", "sup")
  }))
  expect_true(any(grepl("\u2020", header_sup)))
  expect_true(all(c("a", "b") %in% header_sup))
  expect_identical(nrow(hv_check_docx(out, style = "manuscript")), 0L)
})

test_that("the display's notes and key render markup", {
  ft <- hv_man_table_display(
    hv_man_table(mk_markup_tbl()),
    abbreviations = c(BSA = "body surface area (m^2^)",
                      "SpO~2~" = "saturation of O~2~")
  )
  footer <- chunk_aligns(ft, "footer")
  # One raised 2 (m^2^); two lowered, the italic SpO~2~ and the plain O~2~.
  expect_identical(sum(footer == "2:superscript"), 1L)
  expect_identical(sum(footer == "2:subscript"), 2L)
  expect_false(any(grepl("\\^2\\^|~2~", footer)))
})
