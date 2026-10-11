#!/bin/sh
# drift_line.sh 0.1.0 --- append a drift checkpoint line only if drift_line.awk accepts it.
#
#   drift_line.sh append LOG ON_BEARING ON_BEARING_OBJECT PUSHED_BACK GRADER NOTE
#       ON_BEARING yes|no; ON_BEARING_OBJECT what the bearing was taken against;
#       PUSHED_BACK the concrete thing pushed back on, or NONE (the "no");
#       GRADER self | other:<who>.  still-arguing? is derived: yes when PUSHED_BACK names a thing,
#       no when it is NONE -- so it cannot be typed as a bare yes.  The line is checked BEFORE it
#       is written; on refusal LOG is not touched and the exit is 1.
#   drift_line.sh check [FILE]            one verdict per line (stdin if no FILE); 0 / 1 / 77
#   drift_line.sh audit [--legacy] LOG... read-only verdicts and a tally for each LOG
#   drift_line.sh --prove-red             planted lines must each be refused for their reason;
#                                         good lines accepted; a refused append leaves LOG unchanged
# Exit: 0 accepted / 1 refused / 2 usage / 77 NOT CHECKED (no line read).
set -u
here=$(cd "$(dirname "$0")" && pwd)
AWK=${AWK:-awk}
GATE="$here/drift_line.awk"

now() { printf '%s\n' "${DRIFT_LINE_NOW:-$(date -u +%Y-%m-%dT%H:%MZ)}"; }

compose() {  # on_bearing object pushed_back grader note -> one line on stdout
	if [ "$3" = NONE ]; then sa=no; else sa=yes; fi
	printf '%s · checkpoint · on-bearing? %s — %s · still-arguing? %s · pushed-back: %s · grader: %s · note: %s\n' \
		"$(now)" "$1" "$2" "$sa" "$3" "$4" "$5"
}

append() {
	[ "$#" -eq 6 ] || { printf 'usage: drift_line.sh append LOG ON_BEARING ON_BEARING_OBJECT PUSHED_BACK GRADER NOTE\n' >&2; return 2; }
	log=$1; shift
	[ -f "$log" ] || { printf 'drift_line: no such log: %s (create it first; no silent new logs)\n' "$log" >&2; return 2; }
	line=$(compose "$@")
	last=$("$AWK" -v mode=lastts -f "$GATE" "$log")
	verdict=$(printf '%s\n' "$line" | "$AWK" -v last="$last" -f "$GATE")
	rc=$?
	if [ "$rc" -ne 0 ]; then
		printf 'drift_line: refused, %s untouched: %s\n  line: %s\n' "$log" "${verdict#REFUSE L1 }" "$line"
		return 1
	fi
	printf '%s\n' "$line" >> "$log" || return 2
	printf 'appended to %s:\n%s\n' "$log" "$line"
}

check() {
	if [ "$#" -ge 1 ]; then "$AWK" -f "$GATE" "$1"; else "$AWK" -f "$GATE"; fi
}

audit() {
	legacy=0
	[ "${1:-}" = --legacy ] && { legacy=1; shift; }
	[ "$#" -ge 1 ] || { printf 'usage: drift_line.sh audit [--legacy] LOG...\n' >&2; return 2; }
	worst=0
	for log in "$@"; do
		[ -f "$log" ] || { printf 'drift_line: no such log: %s\n' "$log" >&2; worst=2; continue; }
		"$AWK" -v mode=audit -v legacy="$legacy" -f "$GATE" "$log"
		rc=$?
		[ "$rc" -gt "$worst" ] && worst=$rc
	done
	return "$worst"
}

prove_red() {
	t=$(mktemp -d "${TMPDIR:-/tmp}/prove-red-drift-XXXXXX") || return 2  # not in bin/: the mount may refuse the cleanup
	fails=0; n=0
	T=2026-09-30T23:40Z
	good_ob="on-bearing? yes — the host's published principles"
	# name|want (ACCEPT or the code that must appear)|line
	cat > "$t/cases" <<EOF
good-named|ACCEPT|$T · checkpoint · $good_ob · still-arguing? yes · pushed-back: the widened stop rule in CLAUDE.md · grader: self · note: kept his wording
good-none|ACCEPT|$T · checkpoint · $good_ob · still-arguing? no · pushed-back: NONE · grader: other:P9A · note: nothing contested this stretch
good-onbearing-no|ACCEPT|$T · checkpoint · on-bearing? no — slid to the kit default ordering · still-arguing? yes · pushed-back: the cascade as a rank · grader: self · note: bearing lost, named
bare-yes|RUBBER-STAMP|$T · checkpoint · on-bearing? yes · still-arguing? yes · pushed-back: the unset license · grader: self · note: fine
filler-yes|RUBBER-STAMP|$T · checkpoint · on-bearing? yes — all good · still-arguing? yes · pushed-back: the unset license · grader: self · note: fine
yes-with-none|RUBBER-STAMP|$T · checkpoint · $good_ob · still-arguing? yes · pushed-back: NONE · grader: self · note: yes but nothing named
no-pushback-field|NO-PUSHBACK|$T · checkpoint · $good_ob · still-arguing? yes — the unset license · grader: self · note: old shape
empty-pushback|NO-PUSHBACK|$T · checkpoint · $good_ob · still-arguing? yes · pushed-back:  · grader: self · note: empty noun
vague-pushback|VAGUE-PUSHBACK|$T · checkpoint · $good_ob · still-arguing? yes · pushed-back: some stuff · grader: self · note: filler noun
lowercase-none|VAGUE-PUSHBACK|$T · checkpoint · $good_ob · still-arguing? no · pushed-back: none · grader: self · note: the no must be NONE
no-grader|NO-GRADER|$T · checkpoint · $good_ob · still-arguing? yes · pushed-back: the unset license · note: who graded?
bad-grader|BAD-GRADER|$T · checkpoint · $good_ob · still-arguing? yes · pushed-back: the unset license · grader: other: · note: nobody named
contradiction|CONTRADICTION|$T · checkpoint · $good_ob · still-arguing? no · pushed-back: the unset license · grader: self · note: no but named
question-answer|ANSWER|$T · checkpoint · on-bearing? ? · still-arguing? yes · pushed-back: the unset license · grader: self · note: drift.sh default answer
empty-note|FORMAT|$T · checkpoint · $good_ob · still-arguing? yes · pushed-back: the unset license · grader: self · note:
unknown-field|FORMAT|$T · checkpoint · $good_ob · still-arguing? yes · pushed-back: the unset license · grader: self · mood: fine · note: a field the format does not name
no-stamp|FORMAT|yesterday · checkpoint · $good_ob · still-arguing? yes · pushed-back: the unset license · grader: self · note: bad stamp
EOF
	while IFS='|' read -r name want line; do
		n=$((n + 1))
		got=$(printf '%s\n' "$line" | "$AWK" -f "$GATE")
		case "$want" in
		ACCEPT) case "$got" in ACCEPT*) ok=1 ;; *) ok=0 ;; esac ;;
		*) case "$got" in REFUSE*"$want"*) ok=1 ;; *) ok=0 ;; esac ;;
		esac
		if [ "$ok" = 1 ]; then printf 'ok    %-18s %s\n' "$name" "$got"; else printf 'FAIL  %-18s want %s, got %s\n' "$name" "$want" "$got"; fails=$((fails + 1)); fi
	done < "$t/cases"
	# the wrapper: a refused append must leave the log byte-identical; an accepted one adds one line
	log="$t/DRIFT.log"; printf '# DRIFT.log (prove-red)\n' > "$log"
	before=$(cksum < "$log")
	DRIFT_LINE_NOW=$T append "$log" yes "the host's published principles" "some stuff" self "vague noun" >/dev/null 2>&1; rc=$?
	after=$(cksum < "$log"); n=$((n + 1))
	if [ "$rc" -eq 1 ] && [ "$before" = "$after" ]; then echo "ok    refused-append     log unchanged (cksum), exit 1"; else echo "FAIL  refused-append     exit $rc, log changed? $before -> $after"; fails=$((fails + 1)); fi
	DRIFT_LINE_NOW=$T append "$log" yes "the host's published principles" "the cascade as a rank" other:P9A "named" >/dev/null 2>&1; rc=$?
	lines=$(grep -vc '^#' "$log"); n=$((n + 1))
	if [ "$rc" -eq 0 ] && [ "$lines" -eq 1 ]; then echo "ok    accepted-append    one line added, exit 0"; else echo "FAIL  accepted-append    exit $rc, $lines line(s)"; fails=$((fails + 1)); fi
	DRIFT_LINE_NOW=2026-09-30T23:00Z append "$log" yes "the host's published principles" NONE self "stamped before the last line" >/dev/null 2>&1; rc=$?
	lines=$(grep -vc '^#' "$log"); n=$((n + 1))
	if [ "$rc" -eq 1 ] && [ "$lines" -eq 1 ]; then echo "ok    order-append       earlier stamp refused (ORDER), log unchanged"; else echo "FAIL  order-append       exit $rc, $lines line(s)"; fails=$((fails + 1)); fi
	DRIFT_LINE_NOW=$T append "$log" yes "the host's published principles" NONE self "the no, derived" >/dev/null 2>&1; rc=$?
	n=$((n + 1))
	if [ "$rc" -eq 0 ] && tail -n 1 "$log" | grep -q 'still-arguing? no · pushed-back: NONE'; then echo "ok    none-append        NONE accepted, still-arguing derived as no"; else echo "FAIL  none-append        exit $rc"; fails=$((fails + 1)); fi
	# an empty input is NOT CHECKED, never OK
	printf '# only a comment\n' | "$AWK" -f "$GATE" >/dev/null; rc=$?; n=$((n + 1))
	if [ "$rc" -eq 77 ]; then echo "ok    empty-input        exit 77 NOT CHECKED"; else echo "FAIL  empty-input        exit $rc (want 77)"; fails=$((fails + 1)); fi
	printf 'prove-red: %d of %d held\n' "$((n - fails))" "$n"
	if [ "$fails" -eq 0 ]; then rm -rf "$t"; return 0; fi
	printf 'prove-red: work kept in %s\n' "$t"; return 1
}

cmd=${1:-}; [ "$#" -gt 0 ] && shift
case "$cmd" in
append) append "$@" ;;
check) check "$@" ;;
audit) audit "$@" ;;
--prove-red) prove_red ;;
*) printf 'usage: drift_line.sh append LOG ON_BEARING OBJECT PUSHED_BACK GRADER NOTE | check [FILE] | audit [--legacy] LOG... | --prove-red\n' >&2; exit 2 ;;
esac
# SPDX-License-Identifier: GPL-3.0-or-later
