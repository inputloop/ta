#!/bin/sh
# check.sh -- score the experiment, have the second reader re-derive it, and prove both can go red.
# Copyright 2026 Corwin Brust <corwin@bru.st> and Contributors.
# SPDX-License-Identifier: GPL-3.0-or-later
# Written by Mentat (for Corwin, claude-opus-5-5), 2026-10-22.
# usage: sh check.sh score CASES RESULTS     summary + rows on stdout; AGREE lines from the Perl reader
#        sh check.sh --prove-red             planted faults; each must be refused
# Exit: 0 all agree; 1 a disagreement or a fault not caught; 2 NOT CHECKED (nothing to read).
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d "${TMPDIR:-/tmp}/expck.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT INT TERM

score() {  # CASES RESULTS -> $T/summary.tsv, prints it; returns the Perl reader's exit
  [ -s "$1" ] && [ -s "$2" ] || { echo "NOT CHECKED: no cases or no results"; return 2; }
  jq -r '[.id, (.rule|tostring), .verdict] | @tsv' "$1" > "$T/key.tsv" || return 2
  jq -r '[.model, .cond, .id, ((.answer // "") | split("\n") | map(select(test("\\S"))) | .[0] // "")] | @tsv' \
    "$2" > "$T/ans.tsv" || return 2
  awk -F'\t' -f "$HERE/score.awk" "$T/key.tsv" "$T/ans.tsv" > "$T/summary.tsv" || return 1
  cat "$T/summary.tsv"
  perl "$HERE/score-check.pl" "$1" "$2" "$T/summary.tsv"
}

case ${1:-} in
  score) shift; score "$@"; exit $? ;;
  --prove-red)
    fail=0
    printf '%s\n' '{"id":"X1","rule":1,"verdict":"RED","scenario":"s"}' \
                  '{"id":"X2","rule":2,"verdict":"NOT CHECKED","scenario":"s"}' \
                  '{"id":"X3","rule":3,"verdict":"OK","scenario":"s"}' > "$T/c.jsonl"
    printf '%s\n' '{"model":"m","cond":"A","id":"X1","answer":"**RED**\nwhy"}' \
                  '{"model":"m","cond":"A","id":"X2","answer":"\nNot checked: no record"}' \
                  '{"model":"m","cond":"A","id":"X3","answer":"OK."}' > "$T/good.jsonl"
    out=$(score "$T/c.jsonl" "$T/good.jsonl"); rc=$?
    echo "$out" | grep -q "^m	A	3	3	" && [ $rc -eq 0 ] && echo "control: 3/3, AGREE (expected)" || { echo "control FAILED: $out"; fail=1; }
    # plant 1: a wrong verdict must be counted wrong by both readers
    sed 's/\*\*RED\*\*/OK/' "$T/good.jsonl" > "$T/p1.jsonl"
    out=$(score "$T/c.jsonl" "$T/p1.jsonl"); echo "$out" | grep -q "^m	A	3	2	" && echo "plant 1 caught: 2/3" || { echo "plant 1 MISSED"; fail=1; }
    # plant 2: an answer that names no verdict is UNPARSED and wrong, never OK
    sed 's/"OK\."/"Looks fine to me."/' "$T/good.jsonl" > "$T/p2.jsonl"
    out=$(score "$T/c.jsonl" "$T/p2.jsonl"); echo "$out" | grep -q "unparsed 1" && echo "plant 2 caught: unparsed" || { echo "plant 2 MISSED"; fail=1; }
    # plant 3: a summary the Perl reader did not derive must DISAGREE (re-score the control first)
    score "$T/c.jsonl" "$T/good.jsonl" >/dev/null
    awk -F'\t' -f "$HERE/score.awk" "$T/key.tsv" "$T/ans.tsv" | sed '1s/	3	3	/	3	1	/' > "$T/forged.tsv"
    perl "$HERE/score-check.pl" "$T/c.jsonl" "$T/good.jsonl" "$T/forged.tsv" >/dev/null && { echo "plant 3 MISSED"; fail=1; } || echo "plant 3 caught: DISAGREE"
    # plant 4: "OKAY" and "REDUNDANT" are not verdicts (word, not substring)
    sed 's/"OK\."/"OKAY, REDUNDANT"/' "$T/good.jsonl" > "$T/p4.jsonl"
    out=$(score "$T/c.jsonl" "$T/p4.jsonl"); echo "$out" | grep -q "unparsed 1" && echo "plant 4 caught: substrings refused" || { echo "plant 4 MISSED"; fail=1; }
    # plant 5: nothing to read is NOT CHECKED (exit 2), never a pass
    : > "$T/empty.jsonl"; score "$T/c.jsonl" "$T/empty.jsonl" >/dev/null; [ $? -eq 2 ] && echo "plant 5 caught: NOT CHECKED" || { echo "plant 5 MISSED"; fail=1; }
    [ $fail -eq 0 ] && echo "prove-red: 5 of 5 planted faults caught" || echo "prove-red: FAILED"
    exit $fail ;;
  *) echo "usage: sh check.sh score CASES RESULTS | --prove-red" >&2; exit 2 ;;
esac
