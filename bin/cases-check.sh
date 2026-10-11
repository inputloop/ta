#!/bin/sh
# cases-check.sh --- read a precedence cases register back in words, and count only what may count.
#
#   cases-check.sh check <cases.tsv>      exit 0 well-formed, 1 FLAG (malformed), 77 NOT CHECKED
#   cases-check.sh --prove-red <cases.tsv> build mutants from the register; every one must go red;
#                                          exit 0 only if all did (and the unmutated copy is clean)
#
# What it counts: ONLY rows with kind=recorded and agree=no (an org's rule met a person's
# instruction and they disagreed). Constructed rows are read back and never counted, so a
# fixture can never flip a default that waits on "the first recorded case".
#   ORG-WINS n (blessed by <owner>)   decided_by=org-rule, blessed_by names an owner
#   ORG-FIRST n (unblessed)           decided_by=org-rule, blessed_by "-": printed, does NOT flip
#   EQUALS n confessed                decided_by=asked:<who>
#   PERSON-WINS n                     decided_by=person
#   none of the above                 NO CASE -- the Org rung is derived
set -u
TAB=$(printf '\t')
HEADER="id${TAB}kind${TAB}date${TAB}where${TAB}org${TAB}org_rule_source${TAB}org_rule${TAB}org_strength${TAB}addressed_to${TAB}person_instruction${TAB}newer${TAB}agree${TAB}decided_by${TAB}outcome${TAB}blessed_by${TAB}called${TAB}receipt"

check() {
	f=${1:-}
	if [ -z "$f" ] || [ ! -r "$f" ] || [ ! -f "$f" ]; then
		printf 'NOT CHECKED: %s (missing or unreadable)\n' "${f:-<no file named>}"; return 77
	fi
	awk -F"$TAB" -v H="$HEADER" '
	function flag(m){ print "FLAG  line " NR ": " m; bad++ }
	NR==1 { if ($0 != H) flag("header is not the register header (17 named columns)"); next }
	/^[ \t]*$/ { next }
	{
		if (NF != 17) { flag("has " NF " columns, wants 17"); next }
		id=$1; kind=$2; agree=$12; dec=$13; bl=$15; rc=$17
		if (id in seen) flag("duplicate id " id); seen[id]=1
		if (kind != "constructed" && kind != "recorded") flag("kind must be constructed|recorded (got " kind ")")
		if (agree != "yes" && agree != "no") flag("agree must be yes|no (got " agree ")")
		if ($9 != "assistant" && $9 != "person" && $9 != "both") flag("addressed_to must be assistant|person|both (got " $9 ")")
		if ($11 != "org" && $11 != "person" && $11 != "same") flag("newer must be org|person|same (got " $11 ")")
		if (dec !~ /^(org-rule|person|default|pending|asked:.+)$/) flag("decided_by must be org-rule|person|default|pending|asked:<who> (got " dec ")")
		if (kind == "constructed" && dec != "pending") flag("a constructed row claims a decision (" dec "); only a record can decide")
		if (kind == "recorded" && (rc == "-" || rc == "")) flag("a recorded row has no receipt")
		if ($7 == "" || $7 == "-") flag("org_rule is empty; quote the org verbatim")
		# read it back in words
		verb = (agree == "yes") ? "agree" : "disagree"
		printf "%s  (%s, %s)  %s, in %s, says: \"%s\" (its own word: %s; addressed to the %s).\n", id, kind, $3, $5, $4, $7, $8, $9
		printf "      The person asked: \"%s\"; they %s; the %s side is newer. Decided by: %s. Outcome: %s. Blessed by: %s.\n", $10, verb, $11, dec, $14, bl
		printf "      Called in advance: %s. Receipt: %s.\n", $16, rc
		if (kind == "recorded" && agree == "no") {
			if (dec == "org-rule" && bl != "-" && bl != "") { ow++; owner = owner " " bl }
			else if (dec == "org-rule") of++
			else if (dec ~ /^asked:/) eq++
			else if (dec == "person") pw++
		}
		if (kind == "constructed") nc++
	}
	END {
		if (NR < 1) { flag("empty file"); }
		n = ow + of + eq + pw
		if (n == 0) printf "NO CASE -- the Org rung is derived (%d constructed row(s) read, none counted)\n", nc
		else {
			if (ow) printf "ORG-WINS: %d case(s), blessed by%s\n", ow, owner
			if (of) printf "ORG-FIRST: %d case(s), unblessed -- does not flip the default\n", of
			if (eq) printf "EQUALS: %d confessed\n", eq
			if (pw) printf "PERSON-WINS: %d case(s)\n", pw
		}
		exit (bad > 0) ? 1 : 0
	}' "$f"
}

prove_red() {
	src=${1:-}
	[ -r "$src" ] || { printf 'NOT CHECKED: %s (missing or unreadable)\n' "${src:-<no file named>}"; return 77; }
	t=$(mktemp -d) || return 77; rc=0
	expect() {  # name want_exit file [must_grep] [must_not_grep]
		out=$(check "$3" 2>&1); got=$?
		ok=1; [ "$got" -eq "$2" ] || ok=0
		if [ -n "${4:-}" ]; then printf '%s\n' "$out" | grep -q -- "$4" || ok=0; fi
		if [ -n "${5:-}" ]; then printf '%s\n' "$out" | grep -q -- "$5" && ok=0; fi
		if [ "$ok" -eq 1 ]; then printf 'prove-red: %-34s went as expected (exit %s)\n' "$1" "$got"
		else printf 'prove-red: %-34s DID NOT (exit %s, wanted %s)\n' "$1" "$got" "$2"; rc=1; fi
	}
	cp "$src" "$t/clean.tsv"
	expect 'control: the register as given' 0 "$t/clean.tsv" 'NO CASE'
	awk -F"$TAB" -v OFS="$TAB" 'NR==2{NF=16} {print}' "$src" > "$t/m1.tsv"
	expect 'm1 a row loses a column' 1 "$t/m1.tsv"
	awk -F"$TAB" -v OFS="$TAB" 'NR==2{$2="maybe"} {print}' "$src" > "$t/m2.tsv"
	expect 'm2 kind is neither word' 1 "$t/m2.tsv"
	awk -F"$TAB" -v OFS="$TAB" 'NR==2{$13="org-rule"} {print}' "$src" > "$t/m3.tsv"
	expect 'm3 a fixture claims a decision' 1 "$t/m3.tsv"
	awk -F"$TAB" -v OFS="$TAB" 'NR==2{$2="recorded";$13="org-rule";$17="-"} {print}' "$src" > "$t/m4.tsv"
	expect 'm4 a record with no receipt' 1 "$t/m4.tsv"
	awk -F"$TAB" -v OFS="$TAB" 'NR==1{$13="winner"} {print}' "$src" > "$t/m5.tsv"
	expect 'm5 header renamed' 1 "$t/m5.tsv"
	awk -F"$TAB" -v OFS="$TAB" 'NR==3{$1="P5B-C1"} {print}' "$src" > "$t/m6.tsv"
	expect 'm6 duplicate id' 1 "$t/m6.tsv"
	expect 'm7 register missing' 77 "$t/absent.tsv"
	awk -F"$TAB" -v OFS="$TAB" 'NR==2{$2="recorded";$13="org-rule";$15="-";$17="some/receipt#L1"} {print}' "$src" > "$t/m8.tsv"
	expect 'm8 unblessed org-first must not flip' 0 "$t/m8.tsv" 'ORG-FIRST: 1' 'ORG-WINS'
	rm -rf "$t"
	[ "$rc" -eq 0 ] && echo 'prove-red: OK -- every mutant went red and the control stayed clean'
	return $rc
}

cmd=${1:-}; [ "$#" -gt 0 ] && shift
case "$cmd" in
check) check "$@" ;;
--prove-red|prove-red) prove_red "$@" ;;
*) printf 'usage: cases-check.sh check <cases.tsv> | --prove-red <cases.tsv>\n' >&2; exit 2 ;;
esac
# SPDX-License-Identifier: GPL-3.0-or-later
