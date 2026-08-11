# Shared argument validators (.check_*) and precondition assertions
# (.assert_*). Layer 1 validates one argument's own shape; layer 2
# validates relationships between arguments, or between an argument and
# the data it references.
#
# All error via stop(call. = FALSE) and return their input invisibly.
# None has a predicate (is_valid_*) form: every use in this package is
# fail-fast at function entry, and offering both forms would be the
# first place the two could drift apart.
#
# There is deliberately no .check_font(): its contract is identical to
# .check_string(), so `font` is validated by .check_string(font, "font").
# A wrapper would add a name without adding a rule.

# The "Received:" clause. Reports class and length rather than the
# value, which keeps the message short for a data frame or a connection,
# and is the most diagnostic thing for the commonest real mistake -- an
# argument-order slip, where the class mismatch is the tell. Both
# branches report the class for exactly that reason: a bare "a vector
# of length 8" for a 200-row data frame (8 columns) threw away the one
# thing this clause exists to say.
.describe <- function(x) {
  if (is.null(x)) return("NULL")
  if (length(x) != 1L)
    return(sprintf("%s of length %d", class(x)[1], length(x)))
  if (is.atomic(x) && is.na(x)) return("NA")
  sprintf("%s of length 1", class(x)[1])
}

.check_gtsummary <- function(x, arg = "tbl") {
  if (!inherits(x, "gtsummary"))
    stop("`", arg, "` must be a gtsummary table object. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_flextable <- function(x, arg = "ft") {
  if (!inherits(x, "flextable"))
    stop("`", arg, "` must be a flextable object. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_string <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x))
    stop("`", arg, "` must be a single non-empty string. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_font_size <- function(x, arg = "font_size") {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
        !(x %in% c(11, 12)))
    stop("`", arg, "` must be 11 or 12 (house rule: 12pt, 11pt ",
         "permitted for wide tables). Received: ", .describe(x), ".",
         call. = FALSE)
  invisible(x)
}

# Folds the string check and the directory check together because both
# savers already perform exactly those two steps in sequence; splitting
# them would leave two things to remember instead of one.
.check_file <- function(x, arg = "file") {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x))
    stop("`", arg, "` must be a single non-empty file path. Received: ",
         .describe(x), ".", call. = FALSE)
  out_dir <- dirname(x)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)
  invisible(x)
}

# Both savers render a footnote as a superscript marker plus the text
# as a document paragraph, so anything that is not one non-empty string
# writes a malformed document rather than failing: NULL and "" give a
# dangling "* " with nothing after it, NA gives "* NA", a number gives
# "* 1", and a length-2 vector gives "* a* b". But the two savers take
# genuinely different footnote *shapes* -- CORR: a named list, symbol
# -> text; JTCVS: list(row =, col =, text =) -- so only the contract
# sentence is shared (see test-contract-parity.R). `label` is each
# caller's own accessor path to the bad value (naming the symbol for
# CORR, `[[k]]$text` for JTCVS, rather than a position that forces
# counting list entries), and `closing` is each caller's own fix,
# since a JTCVS caller has `row`/`col` to be told about and a CORR
# caller does not.
.check_footnote_text <- function(x, label, closing) {
  if (is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x))
    return(invisible(x))
  got <- if (is.null(x)) "missing" else .describe(x)
  stop("`", label, "` must be a single non-empty string; it is ", got,
       ". ", closing, call. = FALSE)
}

# The type check precedes the empty-value shortcut deliberately. Taking
# them the other way round skipped the type check for anything empty, so
# `list()` was accepted while `list(N = "x")` errored -- the same type
# treated two ways on length alone. NULL and character(0) stay no-ops.
.check_abbreviations <- function(x, arg = "abbreviations") {
  if (is.null(x)) return(invisible(x))
  if (!is.character(x))
    stop("`", arg, "` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)). Received: ", .describe(x),
         ".", call. = FALSE)
  if (length(x) == 0L) return(invisible(x))
  nms <- names(x)
  if (is.null(nms) || anyNA(nms) || any(!nzchar(nms)))
    stop("`", arg, "` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)); every element must have a ",
         "non-empty name.", call. = FALSE)
  invisible(x)
}

# ---- Layer 2: precondition assertions ----------------------------

.assert_type_buckets <- function(continuous, binary, categorical) {
  buckets <- list(continuous = continuous, binary = binary,
                  categorical = categorical)
  for (nm in names(buckets)) {
    b <- buckets[[nm]]
    if (!is.character(b) || anyNA(b))
      stop("`", nm, "` must be a character vector of variable names. ",
           "Received: ", .describe(b), ".", call. = FALSE)
  }
  all_vars <- unlist(buckets, use.names = FALSE)
  dup <- unique(all_vars[duplicated(all_vars)])
  if (length(dup) == 0L) return(invisible(NULL))
  hits_for <- function(v) {
    names(buckets)[vapply(buckets, function(b) v %in% b, logical(1))]
  }
  # A name duplicated *within* one bucket looks identical to a name
  # that spans two buckets once unlist() flattens them -- both show
  # up as `dup`. Split on bucket-set membership (length(hits) > 1)
  # so the two get their own, non-contradictory messages below.
  cross <- dup[vapply(dup, function(v) length(hits_for(v)) > 1L,
                      logical(1))]
  if (length(cross) > 0L) {
    where <- vapply(cross, function(v) {
      sprintf("%s (%s)", v, paste(hits_for(v), collapse = ", "))
    }, character(1))
    stop("`", cross[1], "` appears in more than one of `continuous`, ",
         "`binary`, and `categorical`. Every variable must be ",
         "classified exactly once. Overlapping: ",
         paste(where, collapse = "; "), ".", call. = FALSE)
  }
  # Remaining `dup` entries are duplicated inside a single bucket
  # only (e.g. c("age", "age") passed as `continuous`); a variable
  # spanning buckets is already handled above.
  intra <- setdiff(dup, cross)[1]
  nm <- hits_for(intra)
  stop("`", nm, "` lists `", intra, "` more than once. Each variable ",
       "name may appear at most once per bucket. Remove the ",
       "duplicate from `", nm, "`.", call. = FALSE)
}

# Compact, bounded account of what a column actually holds. Bounded
# because a continuous column has hundreds of distinct values and the
# message has to stay one readable sentence.
.describe_column <- function(x) {
  vals <- sort(unique(stats::na.omit(x)))
  n <- length(vals)
  if (n == 0L) return("no non-missing values")
  shown <- as.character(vals[seq_len(min(3L, n))])
  sprintf("%d distinct non-missing value%s (%s%s)", n,
          if (n == 1L) "" else "s", paste(shown, collapse = ", "),
          if (n > 3L) ", ..." else "")
}

# The encodings this package is willing to read an "event" out of, for
# a `binary` (SAS CAT1=) variable: logical, numeric 0/1, or yes/no
# character/factor. `.event_value()` below names the event for each, and
# hv_tbl_summary() passes it to gtsummary as `value =`, so this is the
# package's own definition rather than a mirror of gtsummary's internal
# guesser -- gtsummary is told the answer and never guesses.
#
# It has to stay a rule of ours regardless: a two-valued column in some
# other encoding has no event we could name, and left to itself
# gtsummary dies with "Summary type is \"dichotomous\" but no summary
# value has been assigned.", which is banned vocabulary. So `binary`
# needs this alongside the at-most-2-values rule.
.is_dichotomizable <- function(x) {
  if (is.logical(x)) return(TRUE)
  vals <- unique(stats::na.omit(x))
  if (is.numeric(x)) return(setequal(vals, c(0, 1)))
  if (is.factor(x))
    return(nlevels(x) == 2L &&
             setequal(toupper(levels(x)), c("NO", "YES")))
  if (is.character(x))
    return(length(vals) == 2L &&
             setequal(toupper(vals), c("NO", "YES")))
  FALSE
}

# The event level of a dichotomizable column -- the "1" side, the one
# whose count gtsummary reports. Returns the value as it appears in the
# data (so a lowercase "yes" stays lowercase), because gtsummary matches
# it against the column, not against a normalized form.
#
# Only ever called on a column .is_dichotomizable() has accepted, so the
# branches are exhaustive by construction; the final NULL is unreachable
# and exists so a future encoding added to one function but not the
# other fails at gtsummary rather than returning a silently wrong event.
.event_value <- function(x) {
  if (is.logical(x)) return(TRUE)
  if (is.numeric(x)) return(1)
  levs <- if (is.factor(x)) levels(x) else unique(stats::na.omit(x))
  hit <- levs[toupper(levs) == "YES"]
  if (length(hit) == 1L) return(hit)
  NULL
}

# Which bucket the data actually suits, for the "Move `x` to ..." fix.
.suggest_bucket <- function(x) {
  if (.is_dichotomizable(x)) return("binary")
  if (is.numeric(x)) return("continuous")
  "categorical"
}

# .assert_type_buckets() checks that the buckets do not overlap; this
# checks that a variable's DATA suits the bucket it was put in. Without
# it, `continuous` on a factor produced "{N} ||| NA (NA, NA)" cells --
# which satisfy .assert_stat_convention(), because the convention
# genuinely is applied and only the statistic is NA -- so the table
# rendered and saved as a complete, correctly styled, all-NA
# manuscript table. `categorical` (SAS CAT2=) gets no type rule:
# factors, characters, and small-integer codes are all legitimate.
.assert_bucket_data <- function(data, continuous, binary, categorical) {
  buckets <- list(continuous = continuous, binary = binary,
                  categorical = categorical)
  # Checked first, and for every bucket: an all-missing column gives
  # the same all-NA table the type rules below exist to prevent, and
  # would otherwise be reported as a type error instead.
  for (nm in names(buckets)) {
    for (v in buckets[[nm]]) {
      if (length(stats::na.omit(data[[v]])) > 0L) next
      stop("`", nm, "` lists `", v, "`, but `", v, "` has no ",
           "non-missing values, so every statistic for it would be ",
           "NA. Drop `", v, "` from `groups` and `", nm,
           "`, or check the data.", call. = FALSE)
    }
  }
  for (v in continuous) {
    x <- data[[v]]
    if (is.numeric(x)) next
    stop("`continuous` lists `", v, "`, but `", v, "` is ",
         class(x)[1], " data with ", .describe_column(x),
         ". `continuous` summarizes numeric columns as a median and ",
         "percentiles, so non-numeric data gives a table of NA ",
         "statistics. Move `", v, "` to `", .suggest_bucket(x), "`.",
         call. = FALSE)
  }
  for (v in binary) {
    x <- data[[v]]
    if (length(unique(stats::na.omit(x))) > 2L)
      stop("`binary` lists `", v, "`, but `", v, "` has ",
           .describe_column(x), ". `binary` summarizes a two-valued ",
           "variable as a single \"n (%)\" row, so it accepts at ",
           "most 2 distinct values. Move `", v, "` to `",
           .suggest_bucket(x), "`.", call. = FALSE)
    if (!.is_dichotomizable(x)) {
      # The "Recode to 0/1" fix below is impossible advice for two
      # real cases, so those get their own closing sentence: a
      # constant column already IS 0/1 (there is no event to
      # recode), and a factor whose only problem is an unused level
      # is fixed by droplevels(), not a recode. The contract sentence
      # itself never changes -- only the fix at the end does.
      contract <- paste0(
        "`binary` lists `", v, "`, but `", v, "` has ",
        .describe_column(x), ". `binary` renders one \"n (%)\" ",
        "row and so needs an unambiguous event value: it accepts ",
        "logical, 0/1, or Yes/No data."
      )
      vals <- unique(stats::na.omit(x))
      if (length(vals) == 1L)
        stop(contract, " A column with no variation has no event ",
             "to count; move `", v, "` to `categorical`, which ",
             "shows every level.", call. = FALSE)
      if (is.factor(x)) {
        dropped <- droplevels(x)
        if (nlevels(dropped) < nlevels(x) && .is_dichotomizable(dropped))
          stop(contract,
               sprintf(" `%s` is a factor with %d levels but only %d ",
                       v, nlevels(x), nlevels(dropped)),
               "appear in the data; droplevels() may be what ",
               "you want.", call. = FALSE)
      }
      stop(contract, " Recode `", v, "` to 0/1, or move it to ",
           "`categorical`, which shows every level.", call. = FALSE)
    }
  }
  invisible(NULL)
}

.assert_jtcvs_groups <- function(tbl, groups, arg = "groups") {
  if (!is.character(groups) || length(groups) == 0L || anyNA(groups))
    stop("`", arg, "` must be a named character vector, stat_<k> ",
         "column name -> spanning header label, e.g. ",
         "c(stat_1 = \"Drug A (n=98)\"). Received: ",
         .describe(groups), ".", call. = FALSE)
  nms <- names(groups)
  if (is.null(nms) || anyNA(nms) || any(!nzchar(nms)))
    stop("`", arg, "` must be a named character vector; every element ",
         "must have a non-empty name, e.g. ",
         "c(stat_1 = \"Drug A (n=98)\").", call. = FALSE)
  available <- names(tbl$table_body)
  not_found <- setdiff(nms, available)
  if (length(not_found) > 0L) {
    # Show the stat_ columns, which is what a group name always is.
    # Fall back to every column when a hand-built object has none, so
    # the message never ends with an empty "Available:".
    shown <- grep("^stat_", available, value = TRUE)
    if (length(shown) == 0L) shown <- available
    stop("`", arg, "` names must be columns in `tbl$table_body`. ",
         "Not found: ", paste(not_found, collapse = ", "),
         ". Available: ", paste(shown, collapse = ", "), ".",
         call. = FALSE)
  }
  # A repeated name builds the same n_/disp_ column pair twice, and
  # flextable rejects that with "duplicated col_keys: n_stat_1,
  # disp_stat_1" -- internal column names the caller never wrote and
  # cannot find in any help page.
  dup <- unique(nms[duplicated(nms)])
  if (length(dup) > 0L)
    stop("`", arg, "` must name each column at most once. Duplicated: ",
         paste(dup, collapse = ", "), ". Each stat_<k> column gets one ",
         "spanning label, e.g. c(stat_1 = \"A\", stat_2 = \"B\").",
         call. = FALSE)
  invisible(groups)
}

# The non-NA qualifier is load-bearing and was established empirically:
# a valid hv_tbl_summary() table carries NA stat cells on the parent
# label row of a multi-level categorical variable. A rule requiring
# every cell to split would reject correct tables.
.assert_stat_convention <- function(tb, groups, arg = "tbl") {
  for (col in names(groups)) {
    # tb[[col]] is NULL for a missing column, and !any(logical(0)) is
    # TRUE, so without this guard the loop would `next` past an
    # unknown column instead of erroring -- a silent pass inside the
    # function whose job is catching a silent failure.
    # .assert_jtcvs_groups() is the user-facing name check (with its
    # "Available:" listing) and normally runs first; this is only a
    # defensive backstop for callers that don't run it first.
    if (!col %in% names(tb))
      stop("`", arg, "` has no column `", col, "`.", call. = FALSE)
    vals <- tb[[col]]
    keep <- !is.na(vals)
    if (!any(keep)) next
    parts <- strsplit(vals[keep], " \\|\\|\\| ")
    bad <- which(lengths(parts) != 2L)
    if (length(bad) == 0L) next
    stop("`", arg, "` was not built with the \"{N_obs} ||| {stat}\" ",
         "convention hv_man_table_jtcvs() requires, so column `", col,
         "` cannot be split into its N and statistic parts. Build it ",
         "with hv_tbl_summary(), or pass statistic = ",
         "list(all_continuous() ~ \"{N_obs} ||| {mean} \u00B1 {sd}\")",
         ". First unparseable value: \"", vals[keep][bad[1]], "\".",
         call. = FALSE)
  }
  invisible(NULL)
}

.assert_footnote_entries <- function(footnotes, ft,
                                     arg = "footnotes") {
  if (is.null(footnotes)) return(invisible(NULL))
  # Checked before the loop rather than inside it: seq_along() is empty
  # for any zero-length value, so a wrong-typed empty one (character(0))
  # would otherwise pass by never entering the loop at all.
  if (!is.list(footnotes))
    stop("`", arg, "` must be a list of the form ",
         "list(list(row =, col =, text =), ...). Received: ",
         .describe(footnotes), ".", call. = FALSE)
  n_body <- flextable::nrow_part(ft, "body")
  for (k in seq_along(footnotes)) {
    fn <- footnotes[[k]]
    # Guards every fn$ access below. Dropping the outer nesting is the
    # likeliest mistake against a documented list(list(row =, col =,
    # text =)) shape, and it used to die on the first fn$ with
    # "$ operator is invalid for atomic vectors" -- as did
    # footnotes = "a note" and footnotes = list("a note").
    if (!is.list(fn))
      stop("`", arg, "[[", k, "]]` must be a list of the form ",
           "list(row =, col =, text =). Received: ", .describe(fn),
           ". `", arg, "` is a list *of* footnotes, so one footnote ",
           "is list(list(row = 1, col = \"n_stat_1\", ",
           "text = \"...\")).", call. = FALSE)
    # Fractional rows are checked explicitly: flextable accepts them
    # silently rather than erroring, so without this they would mark
    # whatever cell they truncate to, which is the silent-wrong-cell
    # failure this validation exists to prevent.
    if (!is.numeric(fn$row) || length(fn$row) == 0L ||
          anyNA(fn$row) || any(!is.finite(fn$row)) ||
          any(fn$row %% 1 != 0) || any(fn$row < 1) ||
          any(fn$row > n_body))
      stop("`", arg, "[[", k, "]]$row` must be whole numbers between ",
           "1 and ", n_body, ", indexing `ft`'s body rows. Row ",
           "indices count the section-header rows ",
           "hv_man_table_jtcvs() interleaves; ",
           "hv_test_footnotes_jtcvs() computes them for you.",
           call. = FALSE)
    if (!is.character(fn$col) || length(fn$col) != 1L ||
          !fn$col %in% ft$col_keys) {
      # A missing `col` used to leave this message ending at a bare
      # colon with nothing after it. Report the name when there is
      # one, and .describe() the shape when there isn't.
      got <- if (is.null(fn$col)) {
        "missing"
      } else if (is.character(fn$col) && length(fn$col) == 1L) {
        sprintf("\"%s\"", fn$col)
      } else {
        .describe(fn$col)
      }
      stop("`", arg, "[[", k, "]]$col` is not a column in `ft`; it is ",
           got, ". Available: ", paste(ft$col_keys, collapse = ", "),
           ". Each footnote needs list(row =, col =, text =).",
           call. = FALSE)
    }
    .check_footnote_text(
      fn$text, sprintf("%s[[%d]]$text", arg, k),
      "Each footnote needs list(row =, col =, text =)."
    )
  }
  invisible(NULL)
}
