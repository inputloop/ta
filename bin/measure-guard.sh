#!/bin/sh
# measure-guard.sh --- prove a declared measure is not volumetric.
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>
# SPDX-License-Identifier: GPL-3.0-or-later
# Developed and tested with the help of Bryant Frankford and B.K. Graphics
# (bkgraphics.com).
#
# Two probes per measure, both must pass:
#   Probe A  VOLUME-UP, VALUE-FLAT   -- the measure must NOT move  (negative control)
#   Probe B  VOLUME-FLAT, VALUE-UP   -- the measure MUST move      (positive probe)
# Plus a closure check: a `derived' measure whose transitive inputs are all
# volumetric IS volumetric, whatever its name.
#
# POSIX sh + awk only.  No cwd assumption: pass absolute paths.
# Usage: measure-guard.sh MEASURES_TSV PROBES_TSV
# Exit:  0 all admissible; 1 one or more FAIL; 2 usage/input error.

set -eu

usage () {
    printf '%s\n' "usage: $0 MEASURES_TSV PROBES_TSV" >&2
    exit 2
}

[ $# -eq 2 ] || usage
measures=$1
probes=$2
[ -r "$measures" ] || { printf 'cannot read %s\n' "$measures" >&2; exit 2; }
[ -r "$probes"   ] || { printf 'cannot read %s\n' "$probes"   >&2; exit 2; }

awk -F'\t' -v OFS='\t' '
function abspct(a, b,   d) {          # percent change from a to b, absolute
    if (a == 0) return (b == 0) ? 0 : 100
    d = (b - a) / a * 100
    return (d < 0) ? -d : d
}
function signed(a, b) { if (a == 0) return (b == 0) ? 0 : 100; return (b - a) / a * 100 }

# --- closure: is this measure volumetric once its inputs are followed? ---
function isvol(m, seen,   n, i, parts, any, allvol) {
    if (m in seen) return 0                     # cycle: contributes nothing
    seen[m] = 1
    if (!(m in VOL)) return 0                   # unknown leaf: not evidence
    if (VOL[m] == "volumetric") return 1
    if (VOL[m] != "derived") return 0
    if (INPUTS[m] == "" || INPUTS[m] == "-") return 0
    n = split(INPUTS[m], parts, ",")
    any = 0; allvol = 1
    for (i = 1; i <= n; i++) {
        if (!(parts[i] in VOL)) { allvol = 0; continue }
        any = 1
        if (!isvol(parts[i], seen)) allvol = 0
    }
    return (any && allvol)
}

NR == FNR {                                     # pass 1: measures.tsv
    if (FNR == 1) next
    if ($1 == "" || $1 ~ /^#/) next
    M[$1] = 1; UNIT[$1] = $2; DIR[$1] = $4; VOL[$1] = $5
    INPUTS[$1] = $7; TOL[$1] = ($8 == "" ? 5 : $8 + 0); NOTE[$1] = $10
    order[++nm] = $1
    next
}
{                                               # pass 2: probes.tsv
    if (FNR == 1) next
    if ($1 == "" || $1 ~ /^#/) next
    # measure  probe  before  after
    if ($2 == "A") { A_BEFORE[$1] = $3 + 0; A_AFTER[$1] = $4 + 0; HAVE_A[$1] = 1 }
    if ($2 == "B") { B_BEFORE[$1] = $3 + 0; B_AFTER[$1] = $4 + 0; HAVE_B[$1] = 1 }
}
END {
    fails = 0
    printf "%-16s %-16s %-22s %-22s %s\n", "MEASURE", "CLOSURE", "PROBE A (vol-up)", "PROBE B (value-up)", "VERDICT"
    for (i = 1; i <= nm; i++) {
        m = order[i]
        delete seen
        vol = isvol(m, seen)
        closure = vol ? "VOLUMETRIC" : "non-volumetric"

        # A fenced volumetric is admissible AS COST, and is not probed for quality.
        if (VOL[m] == "volumetric") {
            printf "%-16s %-16s %-22s %-22s %s\n", m, closure, "-", "-", "FENCED (cost only)"
            continue
        }

        if (vol) {                              # claims non-volumetric, closure says otherwise
            printf "%-16s %-16s %-22s %-22s %s\n", m, closure, "-", "-", "FAIL closure"
            fails++
            continue
        }

        if (!HAVE_A[m] || !HAVE_B[m]) {
            printf "%-16s %-16s %-22s %-22s %s\n", m, closure, \
                (HAVE_A[m] ? "ok" : "MISSING"), (HAVE_B[m] ? "ok" : "MISSING"), "FAIL no-probe"
            fails++
            continue
        }

        da = abspct(A_BEFORE[m], A_AFTER[m])
        db = signed(B_BEFORE[m], B_AFTER[m])
        # Probe B must move in the declared good direction.
        if (DIR[m] == "down-good") db = -db

        aok = (da <= TOL[m])
        bok = (db > TOL[m])
        verdict = (aok && bok) ? "PASS" : "FAIL"
        if (verdict == "FAIL") fails++

        printf "%-16s %-16s %-22s %-22s %s\n", m, closure, \
            sprintf("%+.1f%% (tol %d) %s", da, TOL[m], aok ? "ok" : "MOVED"), \
            sprintf("%+.1f%% %s", db, bok ? "ok" : "INERT"), verdict
    }
    printf "\n%d measure(s) failed.\n", fails
    exit (fails > 0 ? 1 : 0)
}
' "$measures" "$probes"
