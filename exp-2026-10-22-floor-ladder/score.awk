# score.awk -- score answers against the planted verdicts.
# Copyright 2026 Corwin Brust <corwin@bru.st> and Contributors.
# SPDX-License-Identifier: GPL-3.0-or-later
# Written by Mentat (for Corwin, claude-opus-5-5), 2026-10-22.
# input, two files, both TSV:  KEY: id <TAB> rule <TAB> verdict     ANSWERS: model <TAB> cond <TAB> id <TAB> first-line
# usage: awk -F'\t' -f score.awk key.tsv answers.tsv
# output: one row per model+cond: model cond total right OK_right/OK_n RED_right/RED_n NC_right/NC_n unparsed
#         then one row per answer: ROW model cond id want got (right|WRONG)
# The answer's first NON-BLANK line (check.sh feeds it so) is read by its words: NOT CHECKED wins, then RED, then OK; anything else is UNPARSED, and wrong.
function verdict(s,   u) {
  u = toupper(s); gsub(/[^A-Z ]/, " ", u); gsub(/  +/, " ", u); u = " " u " "
  if (u ~ / NOT CHECKED /) return "NOT CHECKED"
  if (u ~ / RED /) return "RED"
  if (u ~ / OK /) return "OK"
  return "UNPARSED"
}
FNR == NR { want[$1] = $3; next }
{
  m = $1; c = $2; id = $3; got = verdict($4)
  if (!(id in want)) { print "score.awk: answer for unknown case " id > "/dev/stderr"; bad = 1; next }
  k = m "\t" c; seen[k] = 1; tot[k]++; w = want[id]; n[k, w]++
  ok = (got == w); if (ok) { right[k]++; r[k, w]++ }
  if (got == "UNPARSED") unp[k]++
  rows[++nr] = "ROW\t" m "\t" c "\t" id "\t" w "\t" got "\t" (ok ? "right" : "WRONG")
}
END {
  for (k in seen)
    printf "%s\t%d\t%d\tOK %d/%d\tRED %d/%d\tNC %d/%d\tunparsed %d\n", k, tot[k], right[k] + 0,
      r[k, "OK"] + 0, n[k, "OK"] + 0, r[k, "RED"] + 0, n[k, "RED"] + 0,
      r[k, "NOT CHECKED"] + 0, n[k, "NOT CHECKED"] + 0, unp[k] + 0 | "sort"
  close("sort")
  for (i = 1; i <= nr; i++) print rows[i]
  exit bad
}
