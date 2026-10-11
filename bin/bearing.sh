#!/bin/sh
# bearing.sh --- the bearing ratio SP/UF: claim over grounding.
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>
# SPDX-License-Identifier: GPL-3.0-or-later
# Developed and tested with the help of Bryant Frankford and B.K. Graphics
# (bkgraphics.com).
#
# Formula is Corwin's (2026-08-28):
#   SP / UF   S=SHOW  P=PLAN-CONFIDENCE  U=UNDERSTANDING  F=FEEL
#   UF is the product of measured feeling and understanding -- the mass weight of
#   total bearing instrumentation, one end's view multiplied out to approximate a
#   volume.  Rung 0 of UF is an ordinal product (H x M): a confession, not a fallacy.
#
# Reads:  > 1 over-claim (showing more than you understand)
#         ~ 1 calibrated
#         < 1 under-claim / buried lead -- a failure here, not modesty
#
# The rung is REQUIRED and is printed with every ratio: a rung-0 ratio and a rung-3
# ratio are different statements wearing the same numeral.
#
# POSIX sh + awk only.  Absolute paths.
# Usage: bearing.sh BEARING_TSV [BAND_PCT]      (BAND_PCT default 20 = "~1" window)
# Exit:  0 all rows calibrated; 1 one or more rows outside the band or malformed; 2 usage.

set -eu

usage () {
    printf '%s\n' "usage: $0 BEARING_TSV [BAND_PCT]" >&2
    exit 2
}

[ $# -ge 1 ] && [ $# -le 2 ] || usage
tsv=$1
band=${2-20}
[ -r "$tsv" ] || { printf 'cannot read %s\n' "$tsv" >&2; exit 2; }
case $band in ''|*[!0-9]*) printf 'BAND_PCT must be a whole number\n' >&2; exit 2 ;; esac

awk -F'\t' -v BAND="$band" '
# Rung 0 accepts ordinal words; every other rung demands numbers.
function ordval(w) {
    if (w == "L" || w == "LOW")      return 1
    if (w == "M" || w == "MEDIUM")   return 2
    if (w == "H" || w == "HIGH")     return 3
    if (w == "VH" || w == "EXTREME") return 4
    return -1
}
function num(x) { return (x ~ /^[0-9]+(\.[0-9]+)?$/) }

FNR == 1 { next }
$1 == "" || $1 ~ /^#/ { next }
{
    # id  claim  rung  S  P  U  F  face_kind  basis
    n++
    ID[n]=$1; CLAIM[n]=$2; RUNG[n]=$3+0; S[n]=$4; P[n]=$5; U[n]=$6; F[n]=$7
    FACE[n]=$8; BASIS[n]=$9

    why=""
    if ($3 !~ /^[0-3]$/) why = why "rung must be 0-3 and declared; "

    if (RUNG[n] == 0) {
        for (i = 4; i <= 7; i++) if (ordval($i) < 0 && !num($i)) why = why "rung 0 wants an ordinal or a number in col " i "; "
        sv=ordval($4); if (sv<0) sv=$4+0
        pv=ordval($5); if (pv<0) pv=$5+0
        uv=ordval($6); if (uv<0) uv=$6+0
        fv=ordval($7); if (fv<0) fv=$7+0
    } else {
        for (i = 4; i <= 7; i++) if (!num($i)) why = why "rung " RUNG[n] " requires measured numbers, col " i " is not; "
        sv=$4+0; pv=$5+0; uv=$6+0; fv=$7+0
    }

    # The padding exposure: at rungs 0-1 the denominator is a volume approximation and
    # can be inflated by adding instrumentation.  Demand the face be declared as a READ
    # (comprehension) rather than a COUNT (inventory), or say the exposure is live.
    if (RUNG[n] <= 1) {
        if (FACE[n] != "read" && FACE[n] != "count")
            why = why "declare face_kind as read|count (Probe-A exposure turns on it); "
    }
    if (BASIS[n] == "" || BASIS[n] == "-") why = why "no basis; "

    if (uv * fv == 0 && why == "") why = why "UF is zero -- ungrounded claim, ratio undefined; "

    WHY[n]=why
    if (why == "") { SP[n]=sv*pv; UF[n]=uv*fv; R[n]=SP[n]/UF[n] }
}
END {
    lo = 1 - BAND/100; hi = 1 + BAND/100
    bad = 0
    printf "BEARING RATIO  SP/UF   calibrated band %.2f..%.2f\n\n", lo, hi
    printf "%-12s %-30s %4s %8s %8s %8s  %-9s %s\n", "ID", "CLAIM", "RUNG", "SP", "UF", "RATIO", "FACE", "READ"
    for (i = 1; i <= n; i++) {
        if (WHY[i] != "") { continue }
        if (R[i] > hi)      { verdict = "OVER-CLAIM";  bad++ }
        else if (R[i] < lo) { verdict = "UNDER-CLAIM (buried lead)"; bad++ }
        else                  verdict = "calibrated"
        pad = (RUNG[i] <= 1 && FACE[i] == "count") ? "  [padding exposure LIVE]" : ""
        printf "%-12s %-30s %4d %8.2f %8.2f %8.2f  %-9s %s%s\n", \
            ID[i], substr(CLAIM[i],1,30), RUNG[i], SP[i], UF[i], R[i], FACE[i], verdict, pad
    }
    printf "\nMALFORMED -- no ratio computed\n"
    m=0
    for (i = 1; i <= n; i++) if (WHY[i] != "") { printf "%-12s %s\n", ID[i], WHY[i]; m++; bad++ }
    if (m == 0) printf "  (none)\n"

    printf "\nRungs are not comparable across rows: 0=ordinal product (a confession),\n"
    printf "1=one-end view x extent, 2=measured feeling x understanding, 3=summed per component.\n"
    printf "\n%d row(s) not calibrated or malformed.\n", bad
    exit (bad > 0 ? 1 : 0)
}
' "$tsv"
