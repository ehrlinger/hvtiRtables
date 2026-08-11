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
# argument-order slip, where the class mismatch is the tell.
.describe <- function(x) {
  if (is.null(x)) return("NULL")
  if (length(x) != 1L)
    return(sprintf("a vector of length %d", length(x)))
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

.check_abbreviations <- function(x, arg = "abbreviations") {
  if (is.null(x) || length(x) == 0L) return(invisible(x))
  if (!is.character(x))
    stop("`", arg, "` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)). Received: ", .describe(x),
         ".", call. = FALSE)
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
         "list(all_continuous() ~ \"{N_obs} ||| {mean} ± {sd}\")",
         ". First unparseable value: \"", vals[keep][bad[1]], "\".",
         call. = FALSE)
  }
  invisible(NULL)
}

.assert_footnote_entries <- function(footnotes, ft,
                                     arg = "footnotes") {
  if (is.null(footnotes)) return(invisible(NULL))
  n_body <- flextable::nrow_part(ft, "body")
  for (k in seq_along(footnotes)) {
    fn <- footnotes[[k]]
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
          !fn$col %in% ft$col_keys)
      stop("`", arg, "[[", k, "]]$col` is not a column in `ft`: ",
           paste(fn$col, collapse = ", "), call. = FALSE)
    if (!is.character(fn$text) || length(fn$text) != 1L ||
          is.na(fn$text) || !nzchar(fn$text)) {
      got <- if (is.null(fn$text)) "missing" else .describe(fn$text)
      stop("`", arg, "[[", k, "]]$text` must be a single non-empty ",
           "string; it is ", got, ". Each footnote needs ",
           "list(row =, col =, text =).", call. = FALSE)
    }
  }
  invisible(NULL)
}
