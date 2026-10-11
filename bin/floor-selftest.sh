#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# floor-selftest.sh -- run every installed floor tool's own self-test; one plain line per tool, then a summary.
#
#   sh floor-selftest.sh [--keep DIR]   run them all; keep each tool's full output in DIR
#   sh floor-selftest.sh --prove-red    plant faults in throwaway copies; every one must answer as it must
#
# Answers (the three-answer convention it reports on):
#   0   every tool's self-test answered 0 AND printed its own pass line
#   1   RED: at least one self-test answered anything other than 0 or 77, answered 0 without its pass
#       line, or a tool file is missing from this bin/ (a broken install is RED, not "not checked")
#   77  NOT CHECKED: no tool went RED, but at least one could not run here -- a program it needs
#       (python3, awk, perl, ssh-keygen, sha256sum) is not on PATH, or its own self-test said 77.
#       The tool and the missing program are named.
#   RED outranks NOT CHECKED: one red among unrunnable tools still answers 1.
#
# It reads nothing but this bin/ and ../tests/.  It points TMPDIR at its own temp dir for every tool and
# removes that dir when all pass (paper-citations.py --prove-red leaves its temp tree behind otherwise).
# No installed tool needs perl today; a tool added later that does should list it in needs().
# POSIX sh plus mktemp, cp, ln, grep, tail, cut; it calls no awk itself, so it can report awk missing.
set -u
BIN=$(cd "$(dirname "$0")" && pwd)
TESTS=$(cd "$BIN/.." && pwd)/tests
TOOLS="three_answers.py owner_check.py settle.py drift_line.sh cases-check.sh paper-citations.py consent_check.sh"

needs() {  # the programs a tool's self-test cannot run without (besides sh and the base utilities)
	case $1 in
	three_answers.py)   echo "python3" ;;
	owner_check.py)     echo "python3 sha256sum" ;;
	settle.py)          echo "python3 awk" ;;
	drift_line.sh)      echo "awk" ;;
	cases-check.sh)     echo "awk" ;;
	paper-citations.py) echo "python3" ;;
	consent_check.sh)   echo "awk ssh-keygen sha256sum" ;;
	esac
}

passline() {  # words the tool prints only when its own proof held (read from each tool's source)
	case $1 in
	three_answers.py)   echo "prove-red PASS:" ;;
	owner_check.py)     echo "(PASS: all plants red and all controls clean" ;;
	settle.py)          echo "held (good fixture scores;" ;;
	drift_line.sh)      echo "held" ;;
	cases-check.sh)     echo "prove-red: OK -- every mutant went red" ;;
	paper-citations.py) echo "PROVE-RED OK" ;;
	consent_check.sh)   echo "plants exited as expected" ;;
	esac
}

run_one() {  # tool workdir -- the tool's own documented self-test, invoked with its interpreter
	case $1 in
	three_answers.py)   python3 "$BIN/three_answers.py" --prove-red --workdir "$2/three_answers" ;;
	owner_check.py)     python3 "$BIN/owner_check.py" --prove-red ;;
	settle.py)          python3 "$BIN/settle.py" --prove-red ;;
	drift_line.sh)      sh "$BIN/drift_line.sh" --prove-red ;;
	cases-check.sh)     sh "$BIN/cases-check.sh" --prove-red "$TESTS/cases-check/cases.tsv" ;;
	paper-citations.py) python3 "$BIN/paper-citations.py" --prove-red ;;
	consent_check.sh)   sh "$BIN/consent_check.sh" --prove-red ;;
	esac
}

lastline() {  # the last non-blank line of a file, cut to 110 characters
	grep -v '^[[:space:]]*$' "$1" 2>/dev/null | tail -n 1 | cut -c1-110
}

floor() {  # [keep-dir]
	keep=${1:-}
	t=$(mktemp -d) || { echo "floor-selftest: NOT CHECKED -- could not make a temp dir"; return 77; }
	logs=${keep:-$t/logs}; mkdir -p "$logs" "$t/work" "$t/tmp"
	npass=0 nred=0 nnc=0 red="" nc=""
	for tool in $TOOLS; do
		log=$logs/$tool.log
		if [ ! -f "$BIN/$tool" ]; then
			printf 'RED          %-19s is not installed in %s\n' "$tool" "$BIN"
			nred=$((nred + 1)); red="$red $tool"; continue
		fi
		missing=""
		for prog in $(needs "$tool"); do command -v "$prog" >/dev/null 2>&1 || missing="$missing $prog"; done
		if [ -n "$missing" ]; then
			printf 'NOT CHECKED  %-19s could not run here: it needs%s, which is not on PATH\n' "$tool" "$missing"
			nnc=$((nnc + 1)); nc="$nc $tool (needs$missing)"; continue
		fi
		( TMPDIR=$t/tmp; export TMPDIR; cd "$t/work" && run_one "$tool" "$t/work" ) > "$log" 2>&1
		rc=$?
		said=$(lastline "$log")
		case $rc in
		0)	if grep -qF -- "$(passline "$tool")" "$log"; then
				printf 'PASSED       %-19s its own proof held: %s\n' "$tool" "$said"; npass=$((npass + 1))
			else
				printf 'RED          %-19s answered 0 but did not print its pass line (%s); last said: %s\n' "$tool" "$(passline "$tool")" "${said:-nothing}"
				nred=$((nred + 1)); red="$red $tool"
			fi ;;
		77)	printf 'NOT CHECKED  %-19s its own self-test said it could not check: %s\n' "$tool" "${said:-nothing}"
			nnc=$((nnc + 1)); nc="$nc $tool (said 77)" ;;
		*)	printf 'RED          %-19s its self-test answered %s: %s\n' "$tool" "$rc" "${said:-nothing}"
			nred=$((nred + 1)); red="$red $tool" ;;
		esac
	done
	n=$((npass + nred + nnc))
	printf 'floor-selftest: %d tool(s): %d passed, %d red, %d not checked here\n' "$n" "$npass" "$nred" "$nnc"
	if [ "$n" -eq 0 ]; then ans=77; echo "answer: 77 NOT CHECKED -- no tool was listed"
	elif [ "$nred" -gt 0 ]; then ans=1; echo "answer: 1 RED -- did not hold:$red"
	elif [ "$nnc" -gt 0 ]; then ans=77; echo "answer: 77 NOT CHECKED -- could not run here:$nc"
	else ans=0; echo "answer: 0 OK -- every tool's own proof held"; fi
	if [ -n "$keep" ] || [ "$ans" -eq 0 ]; then rm -rf "$t"
	else printf 'full output of each self-test kept in %s\n' "$logs"; rm -rf "$t/work" "$t/tmp"; fi
	return "$ans"
}

# ---------------------------------------------------------------- --prove-red
prove_red() {
	P=$(mktemp -d) || { echo "floor-selftest --prove-red: NOT CHECKED -- no temp dir"; return 77; }
	TMPDIR=$P/tmp; export TMPDIR; mkdir -p "$TMPDIR"
	SH=$(command -v sh)
	n=0 fails=0
	copy() {  # case -> a fresh install copy at $P/$1 (bin/ + tests/)
		mkdir -p "$P/$1"; cp -R "$BIN" "$P/$1/bin"
		[ -d "$TESTS" ] && cp -R "$TESTS" "$P/$1/tests"
		echo "$P/$1"
	}
	hidepath() {  # case pattern... -> a dir of links to every command on PATH except the named ones
		hp=$P/$1/path; shift; mkdir -p "$hp"
		oifs=$IFS; IFS=:
		for dir in $PATH; do
			IFS=$oifs
			[ -d "$dir" ] || continue
			for f in "$dir"/*; do
				b=${f##*/}; skip=0
				for pat in "$@"; do case $b in $pat) skip=1 ;; esac; done
				[ "$skip" = 1 ] || [ -e "$hp/$b" ] || ln -s "$f" "$hp/$b" 2>/dev/null
			done
		done
		IFS=$oifs
		echo "$hp"
	}
	stub() {  # copy tool kind -- replace one installed tool with a planted stand-in
		case $3 in
		red-sh)    printf '#!/bin/sh\necho "stub: planted failure"\nexit 1\n' > "$1/bin/$2" ;;
		usage-sh)  printf '#!/bin/sh\necho "stub: usage"\nexit 2\n' > "$1/bin/$2" ;;
		blind-py)  printf 'import sys\nsys.exit(0)\n' > "$1/bin/$2" ;;
		nc-py)     printf 'import sys\nprint("NOT CHECKED: stub could not see its input")\nsys.exit(77)\n' > "$1/bin/$2" ;;
		gone)      rm -f "$1/bin/$2" ;;
		esac
	}
	expect() {  # label copy want-exit must-say [PATH-dir]
		n=$((n + 1))
		if [ -n "${5:-}" ]; then PATH=$5 "$SH" "$2/bin/floor-selftest.sh" > "$2/floor.out" 2>&1
		else "$SH" "$2/bin/floor-selftest.sh" > "$2/floor.out" 2>&1; fi
		got=$?
		w=$(printf '%s' "$4" | tr -s ' ')   # compare with runs of spaces squeezed: the column padding is not the claim
		if tr -s ' ' < "$2/floor.out" | grep -qF -- "$w"; then said=yes; else said=NO; fi
		if [ "$got" -eq "$3" ] && [ "$said" = yes ]; then
			printf 'ok    %-44s answered %s (want %s), says "%s"\n' "$1" "$got" "$3" "$w"
		else
			printf 'FAIL  %-44s answered %s (want %s); says "%s"? %s\n' "$1" "$got" "$3" "$w" "$said"
			sed 's/^/        | /' "$2/floor.out"
			fails=$((fails + 1))
		fi
	}
	echo "floor-selftest --prove-red (each case runs a throwaway copy of bin/ and tests/)"
	c=$(copy c1);                            expect "c1 control: the install as it is"            "$c" 0  "answer: 0 OK"
	c=$(copy c2); stub "$c" drift_line.sh red-sh;   expect "c2 drift_line.sh replaced by a stub exiting 1" "$c" 1  "RED          drift_line.sh"
	c=$(copy c3); stub "$c" cases-check.sh usage-sh; expect "c3 cases-check.sh stub exits 2 (not 0/77)"   "$c" 1  "RED          cases-check.sh"
	c=$(copy c4); stub "$c" paper-citations.py blind-py; expect "c4 a blind stub: exit 0, prints nothing"  "$c" 1  "did not print its pass line"
	c=$(copy c5); stub "$c" settle.py nc-py;          expect "c5 a stub whose own self-test says 77"      "$c" 77 "settle.py (said 77)"
	c=$(copy c6); expect "c6 python3 hidden from PATH" "$c" 77 "needs python3" "$(hidepath c6 'python3' 'python3.*')"
	c=$(copy c7); expect "c7 awk hidden from PATH"     "$c" 77 "needs awk"     "$(hidepath c7 awk mawk gawk nawk)"
	c=$(copy c8); stub "$c" drift_line.sh red-sh
	              expect "c8 python3 hidden AND a red stub: RED wins" "$c" 1 "did not hold: drift_line.sh" "$(hidepath c8 'python3' 'python3.*')"
	c=$(copy c9); stub "$c" owner_check.py gone;      expect "c9 a tool file missing from bin/"           "$c" 1  "owner_check.py      is not installed"
	if [ "$fails" -eq 0 ]; then
		rm -rf "$P"
		echo "floor-selftest --prove-red: $n of $n cases answered as they must (0, 1 and 77 each shown)"
		return 0
	fi
	echo "floor-selftest --prove-red: $fails of $n cases did NOT answer as they must; work kept in $P"
	return 1
}

case ${1:-} in
--prove-red) prove_red ;;
--keep)      [ -n "${2:-}" ] || { echo "usage: floor-selftest.sh [--keep DIR] | --prove-red" >&2; exit 2; }; mkdir -p "$2" && floor "$2" ;;
"")          floor ;;
*)           echo "usage: floor-selftest.sh [--keep DIR] | --prove-red" >&2; exit 2 ;;
esac
