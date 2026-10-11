#!/bin/sh
# selftest.sh --- prove the checkers can fail.
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>
# SPDX-License-Identifier: GPL-3.0-or-later
# Developed and tested with the help of Bryant Frankford and B.K. Graphics
# (bkgraphics.com).
#
# A claim needs a tool that fails it.  Every case below plants a fault and
# asserts the tool REFUSES; a tool that passes a planted fault is broken, and
# this script says so rather than reporting green.
#
# Usage: selftest.sh [PROJECT_DIR]     (default: the directory above this script)
# Exit:  0 all cases as expected; 1 a checker did not behave; 2 usage/input.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
proj=${1-$(CDPATH= cd -- "$here/.." && pwd)}
[ -d "$proj" ] || { printf 'no such directory: %s\n' "$proj" >&2; exit 2; }

tmp=${TMPDIR-/tmp}/tatp-selftest.$$
mkdir -p "$tmp" || exit 2
trap 'rm -rf "$tmp"' EXIT INT TERM

pass=0; fail=0
ck () {                       # ck NAME EXPECTED_EXIT ACTUAL_EXIT
    if [ "$2" -eq "$3" ]; then
        printf 'ok    %-46s (exit %s)\n' "$1" "$3"; pass=$((pass+1))
    else
        printf 'BROKE %-46s (want %s, got %s)\n' "$1" "$2" "$3"; fail=$((fail+1))
    fi
}
run () { "$@" >/dev/null 2>&1; }

# ---------------------------------------------------------------- measure-guard
printf '\n== measure-guard: planted failures must be caught ==\n'

# The shipped declaration deliberately contains three planted failures
# (bytes_written, constant_seven, effort_score), so the real files must exit 1.
if run sh "$here/measure-guard.sh" "$proj/measures.tsv" "$proj/probes.tsv"
then ck "shipped measures flag their planted failures" 1 0
else ck "shipped measures flag their planted failures" 1 1
fi

# A clean subset must pass, or the guard refuses everything and proves nothing.
head -1 "$proj/measures.tsv"                       >"$tmp/clean.tsv"
grep '^guess_delta	'  "$proj/measures.tsv"        >>"$tmp/clean.tsv"
grep '^guess_calib	'  "$proj/measures.tsv"        >>"$tmp/clean.tsv"
head -1 "$proj/probes.tsv"                         >"$tmp/cleanp.tsv"
grep '^guess_delta	'  "$proj/probes.tsv"          >>"$tmp/cleanp.tsv"
grep '^guess_calib	'  "$proj/probes.tsv"          >>"$tmp/cleanp.tsv"
if run sh "$here/measure-guard.sh" "$tmp/clean.tsv" "$tmp/cleanp.tsv"
then ck "clean measures pass (guard is not a no-sayer)" 0 0
else ck "clean measures pass (guard is not a no-sayer)" 0 1
fi

# A measure with no probes at all must be refused, not silently admitted.
printf 'measure\tunit\tdenom\tdir\tvol\tbasis\tinputs\ttol_pct\tfresh\tnote\n' >"$tmp/noprobe.tsv"
printf 'orphan\tratio\t-\tup-good\tnon-volumetric\tcounted\t-\t5\t2026-08-28\tno probes\n' >>"$tmp/noprobe.tsv"
printf 'measure\tprobe\tbefore\tafter\tnote\n' >"$tmp/emptyp.tsv"
if run sh "$here/measure-guard.sh" "$tmp/noprobe.tsv" "$tmp/emptyp.tsv"
then ck "unprobed measure is refused" 1 0
else ck "unprobed measure is refused" 1 1
fi

# ---------------------------------------------------------------- riskcell
printf '\n== riskcell: the word RISK must be refusable ==\n'

hdr='id	name	occr_pct	occr_basis	cost_usd	cost_unit	cost_basis	time_hr	receipt'

printf '%s\n' "$hdr" >"$tmp/unmeasured.tsv"
printf 'X1\tsomething bad\tUNMEASURED\t-\t100\t-\ta named fee\t0\tsomewhere\n' >>"$tmp/unmeasured.tsv"
if run sh "$here/riskcell.sh" "$tmp/unmeasured.tsv" 75
then ck "UNMEASURED occurrence is refused" 1 0
else ck "UNMEASURED occurrence is refused" 1 1
fi

printf '%s\n' "$hdr" >"$tmp/ordinal.tsv"
printf 'X2\tsomething bad\tHIGH\tgut feel\tMEDIUM\t-\tsome money\t0\tsomewhere\n' >>"$tmp/ordinal.tsv"
if run sh "$here/riskcell.sh" "$tmp/ordinal.tsv" 75
then ck "ordinal HIGH x MEDIUM is refused" 1 0
else ck "ordinal HIGH x MEDIUM is refused" 1 1
fi

printf '%s\n' "$hdr" >"$tmp/noreceipt.tsv"
printf 'X3\tsomething bad\t40\ttwo of five prior runs\t200\t-\treplacement part\t0\t-\n' >>"$tmp/noreceipt.tsv"
if run sh "$here/riskcell.sh" "$tmp/noreceipt.tsv" 75
then ck "priced but unreceipted row is refused" 1 0
else ck "priced but unreceipted row is refused" 1 1
fi

printf '%s\n' "$hdr" >"$tmp/good.tsv"
printf 'X4\tsomething bad\t40\ttwo of five prior runs, logged\t200\t-\treplacement part, whole dollars\t1\tDRIFT.log 2026-08-28\n' >>"$tmp/good.tsv"
if run sh "$here/riskcell.sh" "$tmp/good.tsv" 75
then ck "fully measured row is accepted" 0 0
else ck "fully measured row is accepted" 0 1
fi

# A zero rate must not silently price hours at zero and call it complete.
if sh "$here/riskcell.sh" "$tmp/good.tsv" 2>/dev/null | grep -q 'TIME_RATE unset'
then ck "unset TIME_RATE is announced, not assumed" 0 0
else ck "unset TIME_RATE is announced, not assumed" 0 1
fi

# ---------------------------------------------------------------- bearing
printf '\n== bearing: the rung must be declared and honoured ==\n'

bhdr='id	claim	rung	S	P	U	F	face_kind	basis'

printf '%s\n' "$bhdr" >"$tmp/b_ok.tsv"
printf 'OK1\tcalibrated claim\t1\t3\t4\t3\t4\tread\tlogged prior runs\n' >>"$tmp/b_ok.tsv"
if run sh "$here/bearing.sh" "$tmp/b_ok.tsv" 20
then ck "calibrated row passes" 0 0
else ck "calibrated row passes" 0 1
fi

# Rung 0 is a CONFESSION and must compute -- the correction of 2026-08-28.
printf '%s\n' "$bhdr" >"$tmp/b_rung0.tsv"
printf 'OK2\tordinal, honestly declared\t0\tM\tM\tM\tM\tread\tjudgement only, and it says so\n' >>"$tmp/b_rung0.tsv"
if run sh "$here/bearing.sh" "$tmp/b_rung0.tsv" 20
then ck "rung 0 ordinal product COMPUTES (not refused)" 0 0
else ck "rung 0 ordinal product COMPUTES (not refused)" 0 1
fi

# ...but an ordinal smuggled into a rung that claims measurement must be refused.
printf '%s\n' "$bhdr" >"$tmp/b_smuggle.tsv"
printf 'X5\tordinal at rung 2\t2\tH\tM\tH\tM\tread\tclaims measurement it does not have\n' >>"$tmp/b_smuggle.tsv"
if run sh "$here/bearing.sh" "$tmp/b_smuggle.tsv" 20
then ck "ordinal smuggled into rung 2 is refused" 1 0
else ck "ordinal smuggled into rung 2 is refused" 1 1
fi

printf '%s\n' "$bhdr" >"$tmp/b_norung.tsv"
printf 'X6\tno rung declared\t\t3\t4\t3\t4\tread\tsomething\n' >>"$tmp/b_norung.tsv"
if run sh "$here/bearing.sh" "$tmp/b_norung.tsv" 20
then ck "undeclared rung is refused" 1 0
else ck "undeclared rung is refused" 1 1
fi

printf '%s\n' "$bhdr" >"$tmp/b_zero.tsv"
printf 'X7\tungrounded claim\t1\t4\t4\t0\t3\tread\tno grounding at all\n' >>"$tmp/b_zero.tsv"
if run sh "$here/bearing.sh" "$tmp/b_zero.tsv" 20
then ck "zero UF is refused, not divided by" 1 0
else ck "zero UF is refused, not divided by" 1 1
fi

# Under-claim must fail too: a buried lead is a failure here, not modesty.
printf '%s\n' "$bhdr" >"$tmp/b_under.tsv"
printf 'X8\tburied lead\t2\t1\t1\t5\t5\tread\tunderstood far more than shown\n' >>"$tmp/b_under.tsv"
if run sh "$here/bearing.sh" "$tmp/b_under.tsv" 20
then ck "under-claim fails as loudly as over-claim" 1 0
else ck "under-claim fails as loudly as over-claim" 1 1
fi

# The padding exposure must be announced whenever the face is an inventory.
printf '%s\n' "$bhdr" >"$tmp/b_count.tsv"
printf 'X9\tcounted face\t1\t3\t3\t3\t3\tcount\tinventory, not comprehension\n' >>"$tmp/b_count.tsv"
if sh "$here/bearing.sh" "$tmp/b_count.tsv" 20 2>/dev/null | grep -q 'padding exposure LIVE'
then ck "count-face announces the Probe-A exposure" 0 0
else ck "count-face announces the Probe-A exposure" 0 1
fi

printf '\n%d ok, %d broke.\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
