# The one static map from %summarytable parameter to this package's
# four-stage split. Two consumers: .check_sas_args() below, and the
# parameter table in vignettes/sas-migration.Rmd.
#
# `arg = NA` means the parameter has no equivalent here; `note` then
# carries the reason. Where a parameter maps but the behavior differs,
# `note` carries the difference -- silently accepting the mapping would
# be worse than erroring, because the number changes without saying so.
#
# Entries store a STAGE, not a function name, because the shape and save
# stages are CORR/JTCVS sibling pairs with different argument sets --
# only hv_man_table_save_jtcvs() has `caption`. Storing one function per
# parameter would send half the callers to the wrong sibling, and for
# TBLTITLE= to an argument that does not exist. `only` marks a parameter
# that exists in one family alone; `note_other` is what the other family
# is told instead. `note_corr`/`note_jtcvs` are for a parameter that is
# valid in BOTH families but whose note text differs because the
# argument shape differs between the siblings (e.g. `footnotes`); when
# only one of a plain `note` or the `note_corr`/`note_jtcvs` pair is
# needed, use whichever fits.
#
# Deliberately not exhaustive over the macro's ~60 parameters. The
# purely typographic ones (f1..f4, pfmt, perfmt, labeln, out, rtfout,
# cwidth1, cwidth2, cwidth3) have no analogue worth a message and would
# bury the ones that matter.

`%||%` <- function(x, y) if (is.null(x)) y else x

.stage_fns <- list(
  compute = c(corr = "hv_tbl_summary",      jtcvs = "hv_tbl_summary"),
  shape   = c(corr = "hv_man_table",        jtcvs = "hv_man_table_jtcvs"),
  save    = c(corr = "hv_man_table_save",   jtcvs = "hv_man_table_save_jtcvs")
)

# hv_tbl_summary() is family-neutral: its output feeds either renderer,
# so it returns NA and the caller decides what to do with that.
.family_of <- function(fn) {
  if (grepl("_jtcvs$", fn)) return("jtcvs")
  if (fn %in% c("hv_man_table", "hv_man_table_save")) return("corr")
  NA_character_
}

.sas_param_map <- list(
  # Stage 1 -- compute
  data     = list(arg = "data",        stage = "compute"),
  class    = list(arg = "by",          stage = "compute"),
  list     = list(arg = "groups",      stage = "compute"),
  con3     = list(arg = "continuous",  stage = "compute"),
  cat1     = list(arg = "binary",      stage = "compute"),
  cat2     = list(arg = "categorical", stage = "compute"),
  pp       = list(arg = "percentiles", stage = "compute"),
  pvalues  = list(arg = "compare",     stage = "compute"),
  asd      = list(arg = "compare",     stage = "compute",
                  note = "use `compare = \"smd\"` or `compare = \"both\"`"),
  totalcol = list(arg = "overall",     stage = "compute"),

  con1 = list(
    arg = "continuous", stage = "compute",
    note = paste0(
      "`CON1=` reported mean +/- SD with one-way ANOVA; every continuous ",
      "variable here is summarized as median (percentiles) and tested ",
      "non-parametrically, which is the `CON3=` behavior"
    )
  ),
  con2 = list(
    arg = "continuous", stage = "compute",
    note = paste0(
      "`CON2=` reported median (min, max); this package reports ",
      "median (percentiles), set by `percentiles =`"
    )
  ),
  ord1 = list(
    arg = "categorical", stage = "compute",
    note = paste0(
      "ordinal variables fold into `categorical` and are tested with ",
      "chi-square, not the Kruskal-Wallis test `ORD1=` used"
    )
  ),

  # Stage 3 -- write
  tbltitle = list(
    arg = "caption", stage = "save", only = "jtcvs",
    note_other = paste0(
      "the CORR saver writes no caption; add the table title in the ",
      "document, or use the JTCVS pair if the journal wants one"
    )
  ),
  addfn    = list(
    arg = "footnotes", stage = "save",
    note_corr = paste0(
      "pass a named list, symbol -> footnote text (see hv_man_table_save())"
    ),
    note_jtcvs = paste0(
      "pass a list of list(row =, col =, text =) entries -- see ",
      "hv_man_table_save_jtcvs() and hv_test_footnotes_jtcvs()"
    )
  ),
  printfn  = list(
    arg = "footnotes", stage = "save",
    note_corr = "pass `hv_man_footnotes()`, or `NULL` for none",
    note_jtcvs = paste0(
      "pass `hv_test_footnotes_jtcvs()`, a list of ",
      "list(row =, col =, text =) entries, or `NULL` for none"
    )
  ),
  rtffile  = list(arg = "file",      stage = "save",
                  note = "output is `.docx`"),
  pdffile  = list(arg = "file",      stage = "save",
                  note = "output is `.docx`"),
  xmlfile  = list(arg = "file",      stage = "save",
                  note = "output is `.docx`"),

  # No equivalent
  weight    = list(arg = NA_character_, stage = NA_character_,
                   note = "weighted summaries are not supported"),
  propenmt  = list(arg = NA_character_, stage = NA_character_,
                   note = "propensity-matched mode is not supported"),
  mwoutcomes = list(arg = NA_character_, stage = NA_character_,
                    note = "matching-weighted outcomes are not supported"),
  subset    = list(arg = NA_character_, stage = NA_character_,
                   note = "subset the data frame before calling"),
  sortby    = list(arg = NA_character_, stage = NA_character_,
                   note = "display order comes from `groups`"),
  colpct    = list(arg = NA_character_, stage = NA_character_,
                   note = "percentages are always column percentages"),
  misscol   = list(arg = NA_character_, stage = NA_character_,
                   note = "a missing-count column is not supported"),
  adhoc     = list(arg = NA_character_, stage = NA_character_,
                   note = "ad-hoc pairwise comparisons are not supported"),
  oddsratios = list(arg = NA_character_, stage = NA_character_,
                    note = "odds-ratio columns are not supported"),
  cutexact  = list(arg = NA_character_, stage = NA_character_,
                   note = paste0(
                     "the chi-square/Fisher switch is not tunable; ",
                     "gtsummary uses Fisher's exact when any expected ",
                     "count is below 5, where `CUTEXACT=50` used a ",
                     "50% threshold"
                   )),
  ncol      = list(arg = NA_character_, stage = NA_character_,
                   note = paste0(
                     "per-group Ns are always shown automatically; ",
                     "`NCOL=3`'s overall N needs `overall = TRUE`"
                   )),
  style     = list(arg = NA_character_, stage = NA_character_,
                   note = "house font and rounding are fixed"),
  page      = list(arg = NA_character_, stage = NA_character_,
                   note = "page setup belongs to the Word document"),
  papersize = list(arg = NA_character_, stage = NA_character_,
                   note = "page setup belongs to the Word document")
)

# Number of formals a function takes before its `...`, used to translate
# a positional extra's index within `dots` into its position in the full
# call (dots[i] is call-argument number `.sas_dots_offset(fn) + i`).
.sas_dots_offset <- function(fn) {
  f <- tryCatch(get(fn, mode = "function"), error = function(e) NULL)
  if (is.null(f)) return(0L)
  form <- names(formals(f))
  idx <- match("...", form)
  if (is.na(idx)) length(form) else idx - 1L
}

# Errors on any name in `dots`. Macro names get a message routing them to
# the right argument and stage; anything else gets the message R itself
# would have given had the function not taken `...`. Taking `...` is what
# makes the macro messages possible, so this restores the default
# strictness that `...` silently removed.
#
# `names(dots)` is NULL, not a length-0 vector, when every extra argument
# is positional -- checking `length(nms) == 0` for "no extras" is wrong
# and silently accepted any number of trailing positional arguments.
.check_sas_args <- function(dots, fn) {
  n <- length(dots)
  if (n == 0L) return(invisible(NULL))

  nms <- names(dots) %||% character(n)
  nms[is.na(nms)] <- ""

  # A recognized macro name can appear anywhere among several unused
  # arguments; find the first one the map actually recognizes so it is
  # not masked by an unrelated typo or positional extra that happens to
  # come first.
  hit <- Find(
    function(i) nzchar(nms[i]) && !is.null(.sas_param_map[[tolower(nms[i])]]),
    seq_len(n)
  )

  if (is.null(hit)) {
    if (!nzchar(nms[1]))
      stop("unused argument (position ", .sas_dots_offset(fn) + 1L, ")",
           call. = FALSE)
    stop("unused argument (", nms[1], ")", call. = FALSE)
  }

  key <- tolower(nms[hit])
  entry <- .sas_param_map[[key]]

  fam <- .family_of(fn)

  # A family-restricted parameter: the family that lacks the argument is
  # told so plainly rather than sent to an argument that does not exist.
  # A family-neutral caller is routed to the family that has it.
  if (!is.null(entry$only)) {
    if (!is.na(fam) && !identical(fam, entry$only))
      stop("`", toupper(key), "=` is a `%summarytable` parameter: ",
           entry$note_other, ".", call. = FALSE)
    fam <- entry$only
  }
  if (is.na(fam)) fam <- "corr"

  # `note` covers a parameter whose note text does not depend on family;
  # `note_corr`/`note_jtcvs` cover one where it does (the two savers'
  # `footnotes` argument shapes differ).
  note <- entry$note %||% entry[[paste0("note_", fam)]] %||% ""

  if (is.na(entry$arg))
    stop("`", toupper(key), "=` is a `%summarytable` parameter: ", note, ".",
         call. = FALSE)

  target <- .stage_fns[[entry$stage]][[fam]]

  fix <- if (identical(target, fn)) {
    paste0("`", key, "` is the `%summarytable` name for `", entry$arg,
           "`. Use `", entry$arg, " =`.")
  } else {
    paste0("`", key, "` is a `%summarytable` parameter this package handles ",
           "at a different stage: pass `", entry$arg, " =` to `", target,
           "()`.")
  }

  stop(fix, if (nzchar(note)) paste0(" Note: ", note, "."), call. = FALSE)
}
