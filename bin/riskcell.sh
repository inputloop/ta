#!/bin/sh
# riskcell.sh --- price a CONCERN into a RISK, or refuse to.
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>
# SPDX-License-Identifier: GPL-3.0-or-later
# Developed and tested with the help of Bryant Frankford and B.K. Graphics
# (bkgraphics.com).
#
# Canon (RISK-CANON.md): nothing is called RISK without BOTH
#   OCCR_FCTR  likelihood to occur, percentile, with a defensible basis
#   COST_BLST  material+ cost, whole dollars (or dollars/unit), >=1 named expense
# and a receipt a stranger can follow.  Anything short of that stays a CONCERN.
# UNMEASURED is a legal value and is never treated as zero.
#
# POSIX sh + awk only.  Absolute paths; no cwd or writability assumption.
# Usage: riskcell.sh RISKS_TSV [TIME_RATE_USD_PER_HOUR]
# Exit:  0 report produced; 1 one or more rows refused the word RISK; 2 usage.

set -eu

usage () {
    printf '%s\n' "usage: $0 RISKS_TSV [TIME_RATE_USD_PER_HOUR]" >&2
    exit 2
}

[ $# -ge 1 ] && [ $# -le 2 ] || usage
risks=$1
rate=${2-0}
[ -r "$risks" ] || { printf 'cannot read %s\n' "$risks" >&2; exit 2; }

case $rate in
    ''|*[!0-9.]*) printf 'TIME_RATE must be numeric, got: %s\n' "$rate" >&2; exit 2 ;;
esac

awk -F'\t' -v RATE="$rate" '
function money(x) { return sprintf("$%d", (x < 0 ? x - 0.5 : x + 0.5)) }

FNR == 1 { next }
$1 == "" || $1 ~ /^#/ { next }
{
    id = $1; name = $2; occr = $3; occr_basis = $4
    cost = $5; unit = $6; cost_basis = $7; time_hr = $8; receipt = $9

    n++; ID[n] = id; NAME[n] = name; OCCR[n] = occr; OB[n] = occr_basis
    COST[n] = cost; UNIT[n] = unit; CB[n] = cost_basis; TH[n] = time_hr; RC[n] = receipt

    why = ""
    if (occr == "UNMEASURED" || occr == "" ) why = why "no OCCR_FCTR; "
    else if (occr ~ /[^0-9]/)               why = why "OCCR_FCTR not a percentile (ordinal words do not multiply); "
    else if (occr + 0 < 0 || occr + 0 > 100) why = why "OCCR_FCTR out of 0-100; "
    if (ob_missing(occr_basis))             why = why "no defensible basis for OCCR_FCTR; "
    if (cost == "UNMEASURED" || cost == "") why = why "no COST_BLST; "
    else if (cost ~ /[^0-9.]/)              why = why "COST_BLST not a number (name the expense in whole dollars); "
    if (ob_missing(cost_basis))             why = why "no materially noticeable expense named; "
    if (ob_missing(receipt))                why = why "no receipt; "

    WHY[n] = why
    if (why == "") {
        c = cost + 0
        if (RATE > 0 && TH[n] != "" && TH[n] != "-") c = c + (TH[n] + 0) * RATE
        FULLCOST[n] = c
        EXP[n]  = (occr + 0) / 100 * c
        P10[n]  = (occr + 0) * 0.5 / 100 * c      # band: half the estimate
        P90[n]  = (occr + 0) * 1.5 / 100 * c      # band: half again above
        if (P90[n] > c) P90[n] = c                # cannot exceed the cost itself
        priced++
        rollup += EXP[n]
    } else refused++
}
function ob_missing(s) { return (s == "" || s == "-" || s == "TBD" || s == "?") }
END {
    printf "RISK REGISTER   time counted at $%s/hr%s\n\n", RATE, (RATE+0 == 0 ? "  (TIME_RATE unset: hours reported, not priced)" : "")

    printf "PRICED  -- these may be called RISK\n"
    printf "%-10s %-34s %5s %10s %10s %s\n", "ID", "NAME", "OCCR", "COST", "EXPECTED", "BAND P10..P90"
    for (i = 1; i <= n; i++) if (WHY[i] == "")
        printf "%-10s %-34s %4s%% %10s %10s %s..%s\n", ID[i], substr(NAME[i],1,34), OCCR[i], \
            money(FULLCOST[i]), money(EXP[i]), money(P10[i]), money(P90[i])
    if (priced == 0) printf "  (none)\n"

    printf "\nREFUSED -- these stay CONCERN; the word RISK is not available\n"
    for (i = 1; i <= n; i++) if (WHY[i] != "")
        printf "%-10s %-34s  %s\n", ID[i], substr(NAME[i],1,34), WHY[i]
    if (refused == 0) printf "  (none)\n"

    printf "\nROLL-UP expected cost of priced rows: %s\n", money(rollup)
    printf "  (honest only if the rows are independent -- say so in the plan when they are not)\n"

    printf "\nRECEIPTS\n"
    for (i = 1; i <= n; i++) if (WHY[i] == "")
        printf "  %-10s occr: %s\n             cost: %s\n             check: %s\n", ID[i], OB[i], CB[i], RC[i]

    printf "\n%d priced, %d refused.\n", priced, refused
    exit (refused > 0 ? 1 : 0)
}
' "$risks"
