#!/bin/sh
# CHECK-baseline.sh -- the TA baseline keeps .sha256 sidecars beside eight files and, until
# 2026-09-17, nothing ran them.  This runs them, and it can be made to fail on command.
#
# usage: sh CHECK-baseline.sh              verify every <file>.sha256 pair here
#        sh CHECK-baseline.sh --prove-red  plant a fault and require it to fire
#
# WHY A SIDECAR IS THE WEAK FORM.  A .sha256 beside a file is a CLAIM that travels separately from
# the thing it claims.  Lose the sidecar and nothing notices; carry the pair to another machine and
# nobody has watched the check go red, so green means nothing yet.  The strong form carries the
# payload and the hash in ONE file that computes the hash itself -- c4/bin/on1fl emits it:
#     sh ../c4/bin/on1fl RISK-CANON.md "TA risk canon" "the baseline, carried and self-proving"
# Keep the sidecars; they are cheap and they verify.  Use the one-file form when it leaves.
#
# GPL-3.0-or-later.
set -u
d=$(cd "$(dirname "$0")" && pwd)
ok=0 ; bad=0 ; orphan=0
verify() {                       # verify DIR
	for s in "$1"/*.sha256 ; do
		[ -e "$s" ] || { echo "no sidecars in $1" >&2 ; return 2 ; }
		f=${s%.sha256}
		if [ ! -f "$f" ] ; then printf 'ORPHAN  %s (no %s)\n' "$(basename "$s")" "$(basename "$f")" ; orphan=$((orphan+1)) ; continue ; fi
		want=$(awk '{print $1}' "$s") ; got=$(sha256sum "$f" | cut -d' ' -f1)
		if [ "$want" = "$got" ] ; then printf 'OK      %s\n' "$(basename "$f")" ; ok=$((ok+1))
		else printf 'DRIFT   %s\n        claim %s\n        real  %s\n' "$(basename "$f")" "$want" "$got" ; bad=$((bad+1)) ; fi
	done
}

if [ "${1:-}" = "--prove-red" ] ; then
	t=$(mktemp -d) || exit 2 ; trap 'rm -rf "$t"' EXIT HUP INT TERM
	printf 'baseline\n' > "$t/good.md" ; sha256sum "$t/good.md" | awk '{print $1}' > "$t/good.md.sha256"
	printf 'baseline\n' > "$t/moved.md" ; sha256sum "$t/moved.md" | awk '{print $1}' > "$t/moved.md.sha256"
	printf 'moved\n'    > "$t/moved.md"                       # fault 1: the file changed under its claim
	printf 'deadbeef\n' > "$t/gone.md.sha256"                  # fault 2: a claim with nothing behind it
	verify "$t"
	printf '\nprove-red: ok=%s drift=%s orphan=%s ' "$ok" "$bad" "$orphan"
	if [ "$ok" = 1 ] && [ "$bad" = 1 ] && [ "$orphan" = 1 ] ; then echo "-- both planted faults fired." ; exit 0
	else echo "-- WRONG: this check cannot see its own faults." ; exit 1 ; fi
fi

verify "$d"
printf '\nTA baseline: %s verified, %s drifted, %s orphaned.\n' "$ok" "$bad" "$orphan"
[ "$bad" = 0 ] && [ "$orphan" = 0 ]
