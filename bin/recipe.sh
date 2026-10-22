#!/bin/sh
# recipe.sh -- the circle: project -> RECIPE.org -> project.  Every file the recipe makes is a source
#   block in RECIPE.org with ":tangle PATH"; this tool writes those files from the recipe (tangle),
#   folds edited files back into the recipe (untangle), and proves the two agree (check).
# Copyright 2026 Corwin Brust <corwin@bru.st> and Contributors.
# SPDX-License-Identifier: GPL-3.0-or-later
# Written by Mentat (for Corwin, claude-opus-5-5), 2026-10-22.  Tangled from RECIPE.org; edit there,
# or edit this file and run "untangle" so the recipe takes the change back.
#
# usage: sh bin/recipe.sh tangle   [RECIPE]   write every :tangle target; ":seal yes" also writes PATH.sha256
#        sh bin/recipe.sh untangle [RECIPE]   take each target's bytes on disk back into its block
#                                             (the recipe as it was is kept first under .arc/)
#        sh bin/recipe.sh check    [RECIPE]   each target SAME, DRIFT or MISSING; each seal SEALED or STALE;
#                                             the circle closed (untangle then tangle gives the same bytes);
#                                             the second reader (bin/recipe_check.py) must AGREE
#        sh bin/recipe.sh list     [RECIPE]   each target and its block's line
#        sh bin/recipe.sh --prove-red         planted faults; each must be caught
# RECIPE defaults to RECIPE.org at the top of the project (the folder above bin/).
# The rules are org-babel's, so Emacs tangles the same bytes (RECIPE.org says how to check that):
#   a body line that starts (after spaces) with "*" or "#+", or with commas then one of those, is
#   written in the recipe with one more comma; tangling removes that one comma.  A target ends with
#   exactly the body and one newline, so a file must end in a newline to be folded back.
# Refused, each said in words: a target that is absolute or climbs out with "..", two blocks naming one
#   target, a target with no final newline (untangle), a recipe with no :tangle blocks (NOT CHECKED).
# Exit: 0 all agree; 1 a DRIFT, MISSING, STALE, DISAGREE or refusal; 2 NOT CHECKED or usage.
set -u
me=recipe.sh
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOP=$(dirname -- "$HERE")
AWK=${AWK:-awk}   # a command and its words: AWK="busybox awk" works

# blocks RECIPE: one line per tangled block: LINE<TAB>TARGET<TAB>SEAL   (refusals on stderr, exit 1)
blocks() {
  $AWK -v me="$me" '
    function arg(line, name,   r) {
      r = " " line " "
      if (!match(r, "[ \t]:" name "[ \t]+[^ \t]+")) return ""
      r = substr(r, RSTART, RLENGTH); sub("^[ \t]:" name "[ \t]+", "", r); return r }
    BEGIN { bad = 0 }
    !inb && tolower($0) ~ /^[ \t]*#\+begin_src([ \t]|$)/ {
      inb = 1; t = arg($0, "tangle"); if (t == "" || t == "no") next
      s = arg($0, "seal"); if (s != "yes") s = "no"
      if (t ~ /^\// || t ~ /^[A-Za-z]:/ || t ~ /(^|\/)\.\.(\/|$)/) {
        printf "%s: REFUSED: line %d: target %s is not inside the project\n", me, NR, t > "/dev/stderr"; bad = 1; next }
      if (t in seen) {
        printf "%s: REFUSED: line %d: %s is also the target of line %d; one block per file\n", me, NR, t, seen[t] > "/dev/stderr"; bad = 1; next }
      seen[t] = NR; printf "%d\t%s\t%s\n", NR, t, s; next }
    inb && tolower($0) ~ /^[ \t]*#\+end_src[ \t]*$/ { inb = 0 }
    END { exit bad }' "$1"
}

# tangle_to RECIPE OUTDIR: write every target under OUTDIR (seals too)
tangle_to() {
  blocks "$1" > "${TMP}/blocks" || return 1
  [ -s "${TMP}/blocks" ] || { echo "$me: NOT CHECKED: $1 has no :tangle blocks"; return 2; }
  while IFS='	' read -r ln t s; do mkdir -p "$2/$(dirname -- "$t")"; : > "$2/$t"; done < "${TMP}/blocks"
  $AWK -v out="$2" -v list="${TMP}/blocks" '
    BEGIN { while ((getline l < list) > 0) { split(l, f, "\t"); T[f[1]] = f[2] } }
    !inb && (NR in T) { inb = 1; tgt = out "/" T[NR]; next }
    !inb && tolower($0) ~ /^[ \t]*#\+begin_src([ \t]|$)/ { skip = 1; inb = 1; next }
    inb && tolower($0) ~ /^[ \t]*#\+end_src[ \t]*$/ { if (!skip) close(tgt); inb = 0; skip = 0; next }
    inb && !skip {
      line = $0
      if (line ~ /^[ \t]*,+(\*|#\+)/) { match(line, /^[ \t]*/); line = substr(line, 1, RLENGTH) substr(line, RLENGTH + 2) }
      print line > tgt }' "$1"
  while IFS='	' read -r ln t s; do
    [ "$s" = yes ] && ( cd "$2/$(dirname -- "$t")" && sha256sum "$(basename -- "$t")" > "$(basename -- "$t").sha256" )
  done < "${TMP}/blocks"
  return 0
}

# untangle_to RECIPE ROOT OUT: the recipe with each block's body replaced by ROOT/target's bytes, to OUT
untangle_to() {
  blocks "$1" > "${TMP}/ublocks" || return 1
  bad=0
  while IFS='	' read -r ln t s; do
    f="$2/$t"
    [ -f "$f" ] || { echo "$me: REFUSED: $t is missing; nothing to fold back" >&2; bad=1; continue; }
    if [ -s "$f" ] && [ "$(tail -c 1 "$f" | od -An -c | tr -d ' ')" != '\n' ]; then
      echo "$me: REFUSED: $t does not end in a newline, so the recipe cannot give it back byte for byte" >&2; bad=1; fi
  done < "${TMP}/ublocks"
  [ $bad -eq 0 ] || return 1
  $AWK -v root="$2" -v list="${TMP}/ublocks" '
    BEGIN { while ((getline l < list) > 0) { split(l, f, "\t"); T[f[1]] = f[2] } }
    (NR in T) { print; inb = 1
      src = root "/" T[NR]
      while ((getline b < src) > 0) {
        if (b ~ /^[ \t]*,*(\*|#\+)/) { match(b, /^[ \t]*/); b = substr(b, 1, RLENGTH) "," substr(b, RLENGTH + 1) }
        print b }
      close(src); next }
    inb && tolower($0) ~ /^[ \t]*#\+end_src[ \t]*$/ { print; inb = 0; next }
    inb { next }
    { print }' "$1" > "$3"
}

# compare_tree LIST A B: for each target, SAME / DRIFT / MISSING (A is what the recipe makes, B the project)
compare_tree() {
  rc=0
  while IFS='	' read -r ln t s; do
    if [ ! -f "$3/$t" ]; then echo "MISSING	$t	(the recipe makes it at line $ln; it is not in the project)"; rc=1
    elif cmp -s "$2/$t" "$3/$t"; then echo "SAME	$t"
    else echo "DRIFT	$t	(differs from its block at line $ln: untangle to keep the file, tangle to keep the recipe)"; rc=1; fi
    if [ "$s" = yes ]; then
      if [ ! -f "$3/$t.sha256" ]; then echo "STALE	$t.sha256	(missing)"; rc=1
      elif ( cd "$3/$(dirname -- "$t")" && sha256sum -c "$(basename -- "$t").sha256" >/dev/null 2>&1 ); then echo "SEALED	$t.sha256"
      else echo "STALE	$t.sha256	(does not match $t)"; rc=1; fi
    fi
  done < "$1"
  return $rc
}

check() {
  R=$1; P=$2
  [ -f "$R" ] || { echo "$me: NOT CHECKED: no recipe at $R"; return 2; }
  blocks "$R" > "${TMP}/cblocks" || return 1
  [ -s "${TMP}/cblocks" ] || { echo "$me: NOT CHECKED: $R has no :tangle blocks"; return 2; }
  mkdir -p "${TMP}/made"; tangle_to "$R" "${TMP}/made" || return $?
  compare_tree "${TMP}/cblocks" "${TMP}/made" "$P" > "${TMP}/verdicts"; rc=$?
  cat "${TMP}/verdicts"
  # the circle: fold what the recipe makes back into a copy of the recipe; it must be the recipe itself
  if untangle_to "$R" "${TMP}/made" "${TMP}/again.org" 2>"${TMP}/uerr"; then
    if cmp -s "$R" "${TMP}/again.org"; then echo "CLOSED	the circle: recipe -> files -> recipe gives the same bytes"
    else echo "OPEN	the circle: recipe -> files -> recipe changed the recipe"; rc=1; fi
  else cat "${TMP}/uerr"; echo "OPEN	the circle could not be folded back"; rc=1; fi
  # the second reader, in another language, must reach the same verdicts
  if command -v python3 >/dev/null 2>&1 && [ -f "$HERE/recipe_check.py" ]; then
    python3 -I "$HERE/recipe_check.py" "$R" "$P" > "${TMP}/second" 2>&1
    if cut -f1,2 "${TMP}/verdicts" | cmp -s - "${TMP}/second"; then echo "AGREE	the second reader (recipe_check.py)"
    else echo "DISAGREE	the second reader (recipe_check.py) reached other verdicts:"; sed 's/^/	/' "${TMP}/second"; rc=1; fi
  else echo "NOT CHECKED	the second reader (python3 or bin/recipe_check.py is not here)"; fi
  return $rc
}

prove_red() {
  F=${TMP}/fx; mkdir -p "$F/bin"; fail=0; n=0
  cp "$0" "$F/bin/recipe.sh"; [ -f "$HERE/recipe_check.py" ] && cp "$HERE/recipe_check.py" "$F/bin/"
  q='#'; printf '%s\n' "${q}+TITLE: fixture" "* A" "${q}+begin_src markdown -i :tangle a.md :seal yes" \
    "plain" "${q}+end_src" "* B" "${q}+begin_src sh :tangle no" "echo not a target" "${q}+end_src" > "$F/RECIPE.org"
  ( cd "$F" && sh bin/recipe.sh tangle >/dev/null )
  r() { ( cd "$F" && sh bin/recipe.sh "$@" ) 2>&1; }
  ok() { n=$((n+1)); echo "caught: $1"; }; miss() { n=$((n+1)); fail=$((fail+1)); echo "MISSED: $1"; }
  n=$((n+1)); o=$(r check); [ $? -eq 0 ] && echo "$o" | grep -q '^CLOSED' && echo "control: SAME, SEALED, CLOSED (expected)" || { echo "control FAILED:"; echo "$o"; fail=$((fail+1)); }
  echo edited >> "$F/a.md"; o=$(r check); echo "$o" | grep -q '^DRIFT	a.md' && echo "$o" | grep -q '^STALE' && ok "P1 an edited file is DRIFT and its seal STALE" || miss P1
  r untangle >/dev/null; r tangle >/dev/null; o=$(r check); [ $? -eq 0 ] && grep -q '^edited$' "$F/RECIPE.org" && ok "P2 untangle takes the edit into the recipe; tangle reseals; check is clean" || miss "P2"
  rm "$F/a.md"; o=$(r check); echo "$o" | grep -q '^MISSING	a.md' && ok "P3 a deleted file is MISSING" || miss P3
  printf '%s\n' '* heading inside' '#+end_src' ',#+already one comma' '  *indented star' '**bold**' 'x' > "$F/a.md"
  r untangle >/dev/null; r tangle >/dev/null; o=$(r check)
  if [ $? -eq 0 ] && grep -q '^,\* heading inside$' "$F/RECIPE.org" && grep -q '^,,#+already' "$F/RECIPE.org" && printf '%s\n' '* heading inside' '#+end_src' ',#+already one comma' '  *indented star' '**bold**' 'x' | cmp -s - "$F/a.md"
  then ok "P4 org lines in a body are comma-escaped in the recipe and come back byte for byte"; else miss "P4"; fi
  printf 'no newline' > "$F/a.md"; o=$(r untangle); [ $? -ne 0 ] && echo "$o" | grep -q 'does not end in a newline' && ok "P5 a file with no final newline is refused, not silently changed" || miss P5
  printf 'x\n' > "$F/a.md"; r untangle >/dev/null; r tangle >/dev/null
  cp "$F/RECIPE.org" "$F/keep.org"
  printf '%s\n' "${q}+begin_src sh :tangle ../out.sh" "x" "${q}+end_src" >> "$F/RECIPE.org"; o=$(r check); [ $? -eq 1 ] && echo "$o" | grep -q 'not inside the project' && ok "P6 a target outside the project is refused" || miss P6
  cp "$F/keep.org" "$F/RECIPE.org"; printf '%s\n' "${q}+begin_src sh :tangle a.md" "y" "${q}+end_src" >> "$F/RECIPE.org"; o=$(r check); [ $? -eq 1 ] && echo "$o" | grep -q 'one block per file' && ok "P7 two blocks naming one file are refused" || miss P7
  cp "$F/keep.org" "$F/RECIPE.org"; echo 'x  a.md' > "$F/a.md.sha256"; o=$(r check); echo "$o" | grep -q '^STALE' && ok "P8 a seal that does not match is STALE" || miss P8
  r tangle >/dev/null; printf '* nothing to make\n' > "$F/RECIPE.org"; o=$(r check); [ $? -eq 2 ] && echo "$o" | grep -q 'NOT CHECKED' && ok "P9 a recipe that makes nothing is NOT CHECKED, never a pass" || miss P9
  cp "$F/keep.org" "$F/RECIPE.org"
  if [ -f "$F/bin/recipe_check.py" ] && command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "import sys" "print('SAME\ta.md')" > "$F/bin/recipe_check.py"; echo changed >> "$F/a.md"; o=$(r check)
    echo "$o" | grep -q '^DISAGREE' && ok "P10 a second reader that says SAME to a drifted file is caught DISAGREEING" || miss P10
  else n=$((n+1)); echo "NOT CHECKED: P10 (python3 or recipe_check.py is not here)"; fi
  echo "$me prove-red: $((n-fail)) of $n (the control and ten planted faults) as expected"
  [ $fail -eq 0 ]
}

TMP=$(mktemp -d "${TMPDIR:-/tmp}/recipe.XXXXXX") || exit 2
trap 'rm -rf "$TMP"' EXIT INT TERM
cmd=${1:-}; [ $# -gt 0 ] && shift
R=${1:-$TOP/RECIPE.org}; P=$(dirname -- "$R")
case $cmd in
  tangle)   tangle_to "$R" "$P"; rc=$?; [ $rc -eq 0 ] && cut -f2 "${TMP}/blocks" | sed 's/^/tangled	/'; exit $rc ;;
  untangle) untangle_to "$R" "$P" "${TMP}/new.org" || exit 1
            if cmp -s "$R" "${TMP}/new.org"; then echo "untangle: the recipe already holds every file"; exit 0; fi
            mkdir -p "$P/.arc"; cp "$R" "$P/.arc/$(basename -- "$R").$(date -u +%Y%m%dT%H%M%SZ)"
            cp "${TMP}/new.org" "$R"; echo "untangle: the recipe took the files back; the old recipe is in .arc/"; exit 0 ;;
  check)    check "$R" "$P"; exit $? ;;
  list)     blocks "$R"; exit $? ;;
  --prove-red) prove_red; exit $? ;;
  *) sed -n '9,16p' "$0"; exit 2 ;;
esac
