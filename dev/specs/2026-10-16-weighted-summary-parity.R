# Parity measurement for 2026-10-16-weighted-summary-design.md.
#
# Compares SAS's weighted summaries, as %summarytable computes them (proc
# freq + WEIGHT for counts; proc univariate WEIGHT VARDEF=WDF for mean, SD
# and percentiles), against survey and gtsummary::tbl_svysummary(). No SAS
# is available here, so the "SAS" column is the documented SAS definition
# implemented in R (sas_* below), and the script checks that implementation
# against R's own type = 2 quantiles under equal weights first.
#
# Synthetic data only. Run from the package root:
#   Rscript dev/specs/2026-10-16-weighted-summary-parity.R

suppressPackageStartupMessages({
  library(survey)
  library(gtsummary)
})
cat("gtsummary", format(packageVersion("gtsummary")),
    "| survey", format(packageVersion("survey")),
    "| cardx", format(packageVersion("cardx")),
    "| hvtiRpropensity", format(packageVersion("hvtiRpropensity")), "\n\n")

# ---- SAS definitions, as documented --------------------------------------

# Weighted mean.
sas_mean <- function(x, w) sum(w * x) / sum(w)
# VARDEF=WDF: divisor is sum(w) - 1.
sas_sd_wdf <- function(x, w) sqrt(sum(w * (x - sas_mean(x, w))^2) / (sum(w) - 1))
# proc univariate with a WEIGHT statement ignores PCTLDEF= and uses the
# weighted empirical distribution with averaging (the analogue of
# PCTLDEF=5): with W = sum(w) and cumulative weights c_i over sorted x,
#   x_(1)                        if w_1 > pW
#   (x_(i) + x_(i+1)) / 2        if c_i == pW
#   x_(i+1)                      if c_i < pW < c_(i+1)
sas_wpctl <- function(x, w, p) {
  o <- order(x); x <- x[o]; w <- w[o]
  cw <- cumsum(w); pw <- p * sum(w)
  if (w[1] > pw) return(x[1])
  i <- max(which(cw <= pw))
  if (cw[i] == pw && i < length(x)) (x[i] + x[i + 1]) / 2 else x[min(i + 1, length(x))]
}

# ---- self-check: equal weights reduce to PCTLDEF=5 (R type = 2) ----------

set.seed(20261016)
chk <- vapply(1:500, function(k) {
  x <- round(rnorm(sample(5:60, 1)), 1)          # ties on purpose
  p <- sample(c(.15, .16, .25, .5, .75, .84, .85), 1)
  sas_wpctl(x, rep(1, length(x)), p) ==
    unname(quantile(x, p, type = 2))
}, logical(1))
cat("Self-check, unit weights vs quantile(type = 2):",
    sum(chk), "of", length(chk), "agree\n\n")

# ---- synthetic cohort with matching weights -------------------------------

set.seed(20261016)
n <- 400
d <- data.frame(
  age    = round(rnorm(n, 65, 11)),                 # integer-valued: ties
  bili   = round(rlnorm(n, 0, 0.6), 1),             # skewed, 1 dp: ties
  ef     = rnorm(n, 55, 9),                         # continuous, no ties
  female = rbinom(n, 1, 0.4),
  nyha   = factor(sample(c("I", "II", "III", "IV"), n, TRUE,
                         prob = c(.2, .4, .3, .1)))
)
e <- plogis(-0.4 + 0.04 * (d$age - 65) + 0.5 * d$female + 0.3 * log(d$bili))
d$grp <- rbinom(n, 1, e)
d$mw  <- pmin(e, 1 - e) / ifelse(d$grp == 1, e, 1 - e)   # matching weight
d$bili[sample(n, 12)] <- NA                               # some missing
cat("Groups:", paste(names(table(d$grp)), table(d$grp), sep = "=", collapse = "  "),
    "| sum(mw) by group:",
    paste(round(tapply(d$mw, d$grp, sum), 2), collapse = ", "), "\n\n")

# ---- one comparison per weight regime ------------------------------------

pp <- c(16, 84)   # %summarytable's PP= default
compare_cont <- function(d, wcol, label) {
  des <- svydesign(ids = ~1, weights = reformulate(wcol), data = d)
  rows <- list()
  for (g in 0:1) {
    sub_d <- d[d$grp == g, ]
    sub <- subset(des, grp == g)
    for (v in c("age", "bili", "ef")) {
      ok <- !is.na(sub_d[[v]]); x <- sub_d[[v]][ok]; w <- sub_d[[wcol]][ok]
      sv_q <- function(rule, p)
        unname(coef(svyquantile(reformulate(v), sub, p, qrule = rule,
                                ci = FALSE, na.rm = TRUE)))[1]
      rows[[length(rows) + 1]] <- data.frame(
        weights = label, grp = g, var = v,
        stat = c("N (sum w)", "mean", "SD", "p16", "median", "p84"),
        SAS = c(sum(w), sas_mean(x, w), sas_sd_wdf(x, w),
                sas_wpctl(x, w, .16), sas_wpctl(x, w, .5), sas_wpctl(x, w, .84)),
        survey_math = c(sum(w), coef(svymean(reformulate(v), sub, na.rm = TRUE)),
                        sqrt(coef(svyvar(reformulate(v), sub, na.rm = TRUE))),
                        sv_q("math", .16), sv_q("math", .5), sv_q("math", .84)),
        survey_school = c(NA, NA, NA,
                          sv_q("school", .16), sv_q("school", .5), sv_q("school", .84))
      )
    }
  }
  out <- do.call(rbind, rows)

  # gtsummary's own numbers, read from the unrounded cards.
  tb <- tbl_svysummary(
    des, by = grp, include = c(age, bili, ef),
    statistic = all_continuous() ~
      "{N_nonmiss} {mean} {sd} {p16} {median} {p84}",
    missing = "no"
  )
  card <- tb$cards$tbl_svysummary
  card <- card[card$variable %in% c("age", "bili", "ef") &
                 card$stat_name %in% c("N_nonmiss", "mean", "sd", "p16",
                                       "median", "p84") &
                 !is.na(card$group1), ]
  key <- c(N_nonmiss = "N (sum w)", mean = "mean", sd = "SD",
           p16 = "p16", median = "median", p84 = "p84")
  gts <- data.frame(
    grp = as.integer(as.character(unlist(card$group1_level))),
    var = card$variable, stat = key[card$stat_name],
    gtsummary = as.numeric(unlist(card$stat))
  )
  merge(out, gts, by = c("grp", "var", "stat"), sort = FALSE)
}

res_mw   <- compare_cont(d, "mw", "matching")
d$unit   <- 1
res_unit <- compare_cont(d, "unit", "unit (=1)")
d$half   <- d$mw / 2
res_half <- compare_cont(d, "half", "matching / 2")

show <- function(r) {
  r$d_gts <- signif(r$gtsummary - r$SAS, 3)
  r$d_school <- signif(r$survey_school - r$SAS, 3)
  r$rel_gts <- ifelse(r$SAS == 0, NA, signif((r$gtsummary - r$SAS) / abs(r$SAS), 3))
  r[c("SAS", "survey_math", "survey_school", "gtsummary")] <-
    lapply(r[c("SAS", "survey_math", "survey_school", "gtsummary")], signif, 6)
  print(r[order(r$weights, r$var, r$grp, match(r$stat, c("N (sum w)", "mean",
        "SD", "p16", "median", "p84"))), ], row.names = FALSE)
}
for (r in list(res_mw, res_unit, res_half)) { show(r); cat("\n") }

# gtsummary == survey "math" everywhere? (it should: cardx calls
# svyquantile() without qrule, and sqrt(svyvar()).)
all_res <- rbind(res_mw, res_unit, res_half)
cat("max |gtsummary - survey_math|:",
    max(abs(all_res$gtsummary - all_res$survey_math)), "\n")
cat("max |survey_school - SAS| over percentiles:",
    max(abs(all_res$survey_school - all_res$SAS), na.rm = TRUE), "\n")
sd_rows <- all_res[all_res$stat == "SD", ]
cat("SD ratio gtsummary / SAS-WDF, by regime:\n")
print(aggregate(cbind(ratio = sd_rows$gtsummary / sd_rows$SAS) ~ weights,
                sd_rows, function(z) round(range(z), 5)))
cat("\n")

# ---- what the SD difference does to a displayed cell ---------------------

# hv_tbl_summary() prints mean +/- SD with EHB/Blackstone paired rounding,
# so a small SD change can move the printed precision. Count how often.
bp <- hvtiRtables:::.format_blackstone_pair
disp <- do.call(rbind, lapply(split(all_res, list(all_res$weights,
                                                  all_res$grp, all_res$var)),
  function(r) {
    m <- r$SAS[r$stat == "mean"]
    data.frame(weights = r$weights[1], grp = r$grp[1], var = r$var[1],
               SAS = bp(m, r$SAS[r$stat == "SD"]),
               gtsummary = bp(m, r$gtsummary[r$stat == "SD"]))
  }))
disp$differs <- disp$SAS != disp$gtsummary
cat("Displayed mean\u00B1SD cells that differ:", sum(disp$differs), "of",
    nrow(disp), "\n")
print(disp[disp$differs, ], row.names = FALSE)
cat("\n")

# ---- where "math" and SAS part: an exact cumulative-weight hit -----------

# The draws above never land a cumulative weight exactly on p * W, so all
# three rules agree. A group whose weights are all 1 (a matching weight is
# exactly 1 for a treated patient with e <= 0.5, and for a control with
# e >= 0.5) lands on it whenever n * p is a whole number.
tie_case <- function(x, w, p) {
  dd <- data.frame(x = x, w = w)
  des <- svydesign(ids = ~1, weights = ~w, data = dd)
  q <- function(rule) unname(coef(svyquantile(~x, des, p, qrule = rule,
                                              ci = FALSE)))[1]
  c(SAS = sas_wpctl(x, w, p), math = q("math"), school = q("school"))
}
cat("x = 1:10, w = 1, median:      ",
    tie_case(1:10, rep(1, 10), .5), "\n")
cat("x = 1:50, w = 1, p16 (n*p=8): ",
    tie_case(1:50, rep(1, 50), .16), "\n")
cat("x = 1:4,  w = .5,1,1,.5, median:",
    tie_case(1:4, c(.5, 1, 1, .5), .5), "\n")
set.seed(3)
hits <- replicate(2000, {
  m <- sample(20:120, 1); x <- round(rnorm(m, 60, 10), 1)
  w <- rep(1, m)
  any(abs(sapply(c(.16, .5, .84), function(p) sas_wpctl(x, w, p) -
        unname(quantile(x, p, type = 1)))) > 0)
})
cat("Share of unit-weight groups (n 20-120, 1 dp data) where some of",
    "p16/median/p84 differ between SAS and 'math':", mean(hits), "\n\n")

# ---- categorical: weighted n and % ----------------------------------------

des <- svydesign(ids = ~1, weights = ~mw, data = d)
tb <- tbl_svysummary(des, by = grp, include = c(female, nyha),
                     statistic = all_categorical() ~ "{n} {N} {p} {n_unweighted}",
                     missing = "no")
card <- tb$cards$tbl_svysummary
card <- card[card$stat_name %in% c("n", "p") & !is.na(card$group1), ]
gts_cat <- data.frame(
  grp = as.integer(as.character(unlist(card$group1_level))),
  var = card$variable, level = as.character(unlist(card$variable_level)),
  stat = card$stat_name, gtsummary = as.numeric(unlist(card$stat))
)
sas_cat <- do.call(rbind, lapply(0:1, function(g) {
  s <- d[d$grp == g, ]
  rbind(
    data.frame(grp = g, var = "female", level = c("0", "1"),
               n = tapply(s$mw, factor(s$female, 0:1), sum)),
    data.frame(grp = g, var = "nyha", level = levels(d$nyha),
               n = tapply(s$mw, s$nyha, sum))
  ) |> transform(p = n / sum(s$mw))
}))
sas_long <- rbind(
  data.frame(sas_cat[1:3], stat = "n", SAS = sas_cat$n),
  data.frame(sas_cat[1:3], stat = "p", SAS = sas_cat$p)
)
cat_cmp <- merge(sas_long, gts_cat, by = c("grp", "var", "level", "stat"))
cat("Categorical: max |gtsummary - proc freq WEIGHT| for n:",
    signif(max(abs(cat_cmp$gtsummary - cat_cmp$SAS)[cat_cmp$stat == "n"]), 3),
    " for p:",
    signif(max(abs(cat_cmp$gtsummary - cat_cmp$SAS)[cat_cmp$stat == "p"]), 3),
    "\n\n")

# ---- __WCountf. as an R formatter ----------------------------------------

# picture __WCountf (round)
#   0 = "0"; (0, 0.001) = "<0.001"; [0.001, 0.1] = 3 dp; (0.1, 1) = 2 dp;
#   [1, high] = 1 dp; missing = " "
wcount <- function(x) {
  out <- ifelse(is.na(x), "",
         ifelse(x == 0, "0",
         ifelse(x < 0.001, "<0.001",
         ifelse(x <= 0.1, formatC(x, format = "f", digits = 3),
         ifelse(x < 1,    formatC(x, format = "f", digits = 2),
                          formatC(x, format = "f", digits = 1, big.mark = ""))))))
  out
}
cat("wcount():", paste(wcount(c(0, 0.0004, 0.05, 0.35, 1, 12.25, 12.35, 1234.56, NA)),
                       collapse = " | "), "\n\n")

# ---- unweighted and weighted SMD: gtsummary vs ps_stddiff ------------------

d$grpf <- factor(d$grp)
smd_gts <- tbl_summary(d, by = grpf, include = c(age, bili, ef, female, nyha),
                       type = list(female ~ "dichotomous"), value = list(female ~ 1),
                       missing = "no") |>
  add_difference(everything() ~ "smd")
smd_g <- smd_gts$table_body[smd_gts$table_body$row_type == "label",
                            c("variable", "estimate")]
psd_u <- hvtiRpropensity::ps_stddiff(d, "grp", gaussian = c("age", "ef"),
                                     nong_ord = "bili", binary = "female",
                                     categorical = "nyha", treated_level = 1)
psd_w <- hvtiRpropensity::ps_stddiff(d, "grp", gaussian = c("age", "ef"),
                                     nong_ord = "bili", binary = "female",
                                     categorical = "nyha", weight_col = "mw",
                                     treated_level = 1)
smd_cmp <- merge(
  merge(smd_g, psd_u$tables$stddiff[c("variable", "type", "stddiff")],
        by = "variable"),
  setNames(psd_w$tables$stddiff[c("variable", "stddiff")],
           c("variable", "stddiff_weighted")),
  by = "variable"
)
names(smd_cmp)[2] <- "gtsummary_smd"
smd_cmp$ratio <- round(abs(smd_cmp$gtsummary_smd) / abs(smd_cmp$stddiff), 3)
cat("Standardized differences (ps_stddiff returns a proportion, not %):\n")
print(smd_cmp, row.names = FALSE)

# ---- weighted p-values: ps_mw_var seeded vs unseeded ----------------------

mw1 <- hvtiRpropensity::ps_mw_var(d, "grp", outcomes = c("age", "bili", "ef"),
                                  weight_col = "mw", n_rep = 1000L, seed = 1L,
                                  treated_level = 1)
mw2 <- hvtiRpropensity::ps_mw_var(d, "grp", outcomes = c("age", "bili", "ef"),
                                  weight_col = "mw", n_rep = 1000L, seed = 2L,
                                  treated_level = 1)
cat("\nps_mw_var() columns:", paste(names(mw1$tables[[1]]), collapse = ", "), "\n")
cat("\nps_mw_var(), seed 1:\n"); print(mw1$tables[[1]], row.names = FALSE)
cat("\nps_mw_var(), seed 2:\n"); print(mw2$tables[[1]], row.names = FALSE)
