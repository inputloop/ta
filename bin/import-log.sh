#!/bin/sh
# import-log.sh --- bring material home with its provenance, keep the log compact, read it back in words.
#
#   sh bin/import-log.sh add   [--group G] [--tags a,b] [--note TEXT] [--exclude GLOB]... ALIAS PATH...
#   sh bin/import-log.sh add   [--group G] [--tags a,b] --list FILE      (lines: ALIAS:PATH or ALIAS<TAB>PATH)
#   sh bin/import-log.sh note  [--group G] [--tags a,b] TEXT...
#   sh bin/import-log.sh say   [--last N | --all | --id ID | --group G | --kind K]   the log, in plain words
#   sh bin/import-log.sh ls    [--last N | --all]                                   one short line per record
#   sh bin/import-log.sh stats                           size, threshold, days, what would be archived now
#   sh bin/import-log.sh verify [--sources]              re-hash every imported copy (and, with --sources, its origin)
#   sh bin/import-log.sh archive                         archive now if the threshold says so (see below)
#   sh bin/import-log.sh slices                          list the archived slices
#   sh bin/import-log.sh slice-say SLICE.tar.gz          read an archived slice back in plain words
#   sh bin/import-log.sh selftest [--prove-red]          prove the archiving rules, and that the proof can fail
#
# Options that may appear anywhere:
#   --root DIR            the TA root (default: the folder above bin/)
#   --log FILE            the log (default: ROOT/IMPORT-LOG.tsv)
#   --roots FILE          alias -> directory map, TSV (default: ROOT/.import/roots.tsv); never written to the log
#   --max-lines N         archiving threshold given on the command line
#   --force-archiving     archive now whatever the configured/default threshold says (a --max-lines given on the
#                         command line still applies); a failed archive always STOPs (--continue-after-stop ignored)
#   --continue-after-stop if archiving is required and cannot be completed, warn and do the work anyway
#   --dry-run             say what would happen; write nothing
#
# THE ARCHIVING RULES (DESIGN-2026-09-30-import-log.md, S1-S12; each default names its kept loser and its flip).
#   Threshold: the log's physical line count (header included) is compared with a threshold -- from --max-lines,
#     else $IMPORT_LOG_MAX_LINES, else `max_lines=` in ROOT/.import/config, else 4000.  More lines than the
#     threshold means archiving is REQUIRED, and it is done FIRST, before the command's own work.
#   A run is a calendar date (the system's local date; several runs on one date are one run).
#   A record may be archived only when two whole runs have passed since it was added: at least two distinct
#     earlier-than-today dates in the log fall strictly after the record's date.  Today is the run in progress
#     and never counts as passed.  (Kept loser: count today.  Flip: his word that "passed" includes the current run.)
#   Archiving writes the eligible records as a JSON log (plus their verbatim TSV lines and a sha256 manifest) into
#     ROOT/archive/import-log/IMPORT-LOG-SLICE-<today>-<first>-<last>.tar.gz, verifies the slice by reading it
#     back, builds the truncated log (header + kept records in order + one ARCHIVE record whose note names the
#     unique ids, days, groups, tags, kinds and sources represented in the slice), proves kept + archived == old,
#     and only then rotates the truncated file into place.
#   If archiving is required and cannot be completed (nothing old enough, or any step fails): STOP, exit 3 --
#     unless --continue-after-stop, which warns and carries on.  (Kept loser: nothing-eligible is a no-op success.
#     Flip: his word that an over-threshold log with nothing old enough should not stop work.)
#   --force-archiving: archives regardless of the configured or default threshold, but a --max-lines given on the
#     command line still gates it; and a forced archive that fails STOPs even with --continue-after-stop.
#
# Exit: 0 ok · 1 a check went red / an operation failed · 2 usage · 3 STOP (archiving required, not completed)
#       · 77 NOT CHECKED (nothing could be checked -- never reported as OK).
# Test-only: IMPORT_LOG_TODAY=YYYY-MM-DD overrides the system date; an ARCHIVE record says when it was used.
#            IMPORT_LOG_FAULT=corrupt-slice|drop-kept plants a fault inside archiving, so the read-back and the
#            rebuild proof can be seen to fire (a guard nobody has watched go red is not yet a guard).
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>.  SPDX-License-Identifier: GPL-3.0-or-later
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.  It is distributed WITHOUT ANY WARRANTY; see <https://www.gnu.org/licenses/>.
set -u
VERSION=0.1.0
TAB=$(printf '\t')
HEADER="#id${TAB}stamp${TAB}day${TAB}kind${TAB}group${TAB}source${TAB}dest${TAB}sha256${TAB}bytes${TAB}tags${TAB}status${TAB}note"
me=$0
here=$(cd "$(dirname "$0")" && pwd)

die()  { printf 'import-log: %s\n' "$*" >&2; exit 2; }
fail() { printf 'import-log: FAIL %s\n' "$*" >&2; exit 1; }
say2() { printf '%s\n' "$*" >&2; }

# ---------- options (anywhere on the line) ----------
ROOT= ; LOG= ; ROOTS= ; CLI_MAX= ; FORCE=0 ; CONT=0 ; DRY=0
GROUP= ; TAGS= ; NOTE= ; LIST= ; EXCLUDES= ; LAST= ; ALL=0 ; WANT_ID= ; WANT_KIND= ; SOURCES=0 ; PROVE=0
CMD= ; set_ops=
while [ "$#" -gt 0 ]; do
	case $1 in
	--root) [ "$#" -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
	--log) [ "$#" -ge 2 ] || die "--log needs a value"; LOG=$2; shift 2 ;;
	--roots) [ "$#" -ge 2 ] || die "--roots needs a value"; ROOTS=$2; shift 2 ;;
	--max-lines) [ "$#" -ge 2 ] || die "--max-lines needs a value"; CLI_MAX=$2; shift 2 ;;
	--force-archiving) FORCE=1; shift ;;
	--continue-after-stop) CONT=1; shift ;;
	--dry-run) DRY=1; shift ;;
	--group) [ "$#" -ge 2 ] || die "--group needs a value"; GROUP=$2; shift 2 ;;
	--tags) [ "$#" -ge 2 ] || die "--tags needs a value"; TAGS=$2; shift 2 ;;
	--note) [ "$#" -ge 2 ] || die "--note needs a value"; NOTE=$2; shift 2 ;;
	--list) [ "$#" -ge 2 ] || die "--list needs a value"; LIST=$2; shift 2 ;;
	--exclude) [ "$#" -ge 2 ] || die "--exclude needs a value"; EXCLUDES="$EXCLUDES
$2"; shift 2 ;;
	--last) [ "$#" -ge 2 ] || die "--last needs a value"; LAST=$2; shift 2 ;;
	--all) ALL=1; shift ;;
	--id) [ "$#" -ge 2 ] || die "--id needs a value"; WANT_ID=$2; shift 2 ;;
	--kind) [ "$#" -ge 2 ] || die "--kind needs a value"; WANT_KIND=$2; shift 2 ;;
	--sources) SOURCES=1; shift ;;
	--prove-red) PROVE=1; shift ;;
	-h|--help|help) CMD=help; shift ;;
	--) shift; while [ "$#" -gt 0 ]; do set_ops="$set_ops
$1"; shift; done ;;
	-*) die "unknown option: $1 (try: help)" ;;
	*) if [ -z "$CMD" ]; then CMD=$1; else set_ops="$set_ops
$1"; fi; shift ;;
	esac
done
[ -n "$CMD" ] || CMD=help
case $CLI_MAX in ''|*[!0-9]*) [ -z "$CLI_MAX" ] || die "--max-lines must be a whole number" ;; esac
case $LAST in ''|*[!0-9]*) [ -z "$LAST" ] || die "--last must be a whole number" ;; esac

[ -n "$ROOT" ] || ROOT=$(cd "$here/.." && pwd)
[ -n "$LOG" ] || LOG=$ROOT/IMPORT-LOG.tsv
[ -n "$ROOTS" ] || ROOTS=$ROOT/.import/roots.tsv
ARCH=$ROOT/archive/import-log
CONF=$ROOT/.import/config

# The run key is the keeper's calendar date: `tz=` in the config names his zone, so a shell that runs on UTC
# (a VM, a container) does not start tomorrow's run five hours early.  Without it, the system's local date.
CONF_TZ=
[ -f "$CONF" ] && CONF_TZ=$(awk -F= '$1=="tz"{gsub(/[ \t\r]/,"",$2); print $2}' "$CONF" | tail -n 1)
if [ -n "${IMPORT_LOG_TODAY:-}" ]; then
	case $IMPORT_LOG_TODAY in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) die "IMPORT_LOG_TODAY must be YYYY-MM-DD" ;; esac
	TODAY=$IMPORT_LOG_TODAY; TODAY_SRC=override
elif [ -n "$CONF_TZ" ]; then
	TODAY=$(TZ=$CONF_TZ date +%Y-%m-%d); TODAY_SRC="system, tz $CONF_TZ"
else
	TODAY=$(date +%Y-%m-%d); TODAY_SRC=system
fi
stamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }
clean() { printf '%s' "$1" | tr '\t\r\n' '   '; }        # a field never carries a tab or a line break

# ---------- the threshold, and where it came from ----------
threshold() {       # prints: VALUE SOURCE
	if [ -n "$CLI_MAX" ]; then printf '%s cli\n' "$CLI_MAX"; return; fi
	if [ -n "${IMPORT_LOG_MAX_LINES:-}" ]; then
		case $IMPORT_LOG_MAX_LINES in *[!0-9]*) die "IMPORT_LOG_MAX_LINES must be a whole number" ;; esac
		printf '%s env\n' "$IMPORT_LOG_MAX_LINES"; return
	fi
	if [ -f "$CONF" ]; then
		v=$(awk -F= '$1=="max_lines"{gsub(/[ \t\r]/,"",$2); print $2}' "$CONF" | tail -n 1)
		if [ -n "$v" ]; then
			case $v in *[!0-9]*) die "max_lines in $CONF must be a whole number" ;; esac
			printf '%s config\n' "$v"; return
		fi
	fi
	printf '4000 default\n'
}
nlines() { if [ -f "$LOG" ]; then wc -l < "$LOG" | tr -d ' '; else echo 0; fi; }

ensure_log() {
	[ -f "$LOG" ] && return 0
	[ "$DRY" = 1 ] && return 0
	mkdir -p "$(dirname "$LOG")" || fail "cannot create $(dirname "$LOG")"
	printf '%s\n' "$HEADER" > "$LOG" || fail "cannot create $LOG"
}
next_id() {
	awk -F'\t' 'BEGIN{m=0} !/^#/ && $1 ~ /^L[0-9]+$/ { n=substr($1,2)+0; if(n>m) m=n } END{ printf "L%06d\n", m+1 }' "$LOG" 2>/dev/null || echo L000001
}
append() {          # kind group source dest sha bytes tags status note
	[ "$DRY" = 1 ] && { printf 'dry-run: would log %s %s %s\n' "$1" "$3" "$8"; return 0; }
	id=$(next_id)
	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$(stamp)" "$TODAY" "$1" "$(clean "$2")" \
		"$(clean "$3")" "$(clean "$4")" "$5" "$6" "$(clean "$7")" "$8" "$(clean "$9")" >> "$LOG" || fail "cannot append to $LOG"
	LAST_ID=$id
}

# ---------- eligibility: which records have had two whole runs pass since they were added ----------
eligible_ids() {    # prints eligible ids, one per line; warnings on stderr
	[ -f "$LOG" ] || return 0
	awk -F'\t' -v today="$TODAY" '
	!/^#/ && NF>=3 {
		d=$3
		if (d !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) { printf "import-log: WARN %s has no usable date (%s); never archived\n", $1, d > "/dev/stderr"; next }
		if (d > today) { printf "import-log: WARN %s is dated %s, after today (%s); never archived\n", $1, d, today > "/dev/stderr"; next }
		n++; id[n]=$1; day[n]=d
		if (d < today) seen[d]=1                                            # MUT:today-excluded
	}
	END {
		for (i=1; i<=n; i++) {
			passed=0
			for (x in seen) if (x > day[i]) passed++                        # MUT:distinct-days
			if (passed >= 2) print id[i]                                    # MUT:two-runs
		}
	}' "$LOG"
}

# ---------- JSON ----------
json_records() {    # TSV data lines on stdin -> JSON array elements (one per line, comma-separated)
	awk -F'\t' '
	function esc(s) { gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\t/,"\\t",s); gsub(/\r/,"\\r",s); return s }
	BEGIN { split("id stamp day kind group source dest sha256 bytes tags status note", k, " ") }
	{
		line="    {"
		for (i=1; i<=12; i++) {
			v=(i<=NF)?$i:""
			if (i==9 && v ~ /^[0-9]+$/) val=v; else val="\"" esc(v) "\""
			line=line (i>1?", ":"") "\"" k[i] "\": " val
		}
		line=line "}"
		out[++n]=line
	}
	END { for (i=1; i<=n; i++) print out[i] (i<n?",":"") }'
}
ranges() {          # ids on stdin (L000001 ...) -> "L000001-L000004,L000009"
	sed 's/^L//' | sort -n | awk '
	function flush() { if (s=="") return; out=out (out==""?"":",") sprintf("L%06d", s) (e>s?sprintf("-L%06d", e):""); }
	{ n=$1+0; if (s=="" ) { s=n; e=n; next } if (n==e+1) { e=n; next } flush(); s=n; e=n }
	END { flush(); print out }'
}
distinct_col() {    # COL on stdin TSV -> comma list of distinct non-empty values (tags split on commas)
	awk -F'\t' -v c="$1" '{ v=$c; if (c==10) { m=split(v,a,/,/); for(i=1;i<=m;i++){ t=a[i]; gsub(/^ +| +$/,"",t); if(t!="" && !(t in s)){ s[t]=1; o[++n]=t } } }
		else if (c==6) { sub(/:.*/,"",v); if (v!="" && v!="-" && !(v in s)) { s[v]=1; o[++n]=v } }
		else if (v!="" && v!="-" && !(v in s)) { s[v]=1; o[++n]=v } }
		END { for (i=1;i<=n;i++) printf "%s%s", (i>1?",":""), o[i]; print "" }'
}
kind_counts() { awk -F'\t' '{ c[$4]++ } END { for (k in c) printf "%s=%d\n", k, c[k] }' | sort | paste -sd, -; }

# ---------- archive ----------
LOCK=
unlock() { [ -n "$LOCK" ] && { rmdir "$LOCK" 2>/dev/null || say2 "import-log: WARN could not remove lock $LOCK -- remove it by hand"; }; LOCK=; }
archive_now() {     # returns 0 archived+rotated, 4 nothing eligible, 1 a step failed
	[ -f "$LOG" ] || { say2 "import-log: archive: no log at $LOG"; return 4; }
	ids=$(eligible_ids)
	if [ -z "$ids" ]; then
		say2 "import-log: archive: nothing is old enough -- no record has had two whole runs (dates before $TODAY) pass since it was added"
		return 4
	fi
	cnt=$(printf '%s\n' "$ids" | wc -l | tr -d ' ')
	if [ "$DRY" = 1 ]; then
		printf 'dry-run: would archive %s record(s): %s\n' "$cnt" "$(printf '%s\n' "$ids" | ranges)"
		return 0
	fi
	LOCK=$LOG.lock
	mkdir "$LOCK" 2>/dev/null || { LOCK=; say2 "import-log: archive: $LOG.lock exists -- another run is archiving, or one died; remove it by hand if none is"; return 1; }
	w=$(mktemp -d 2>/dev/null) || { unlock; say2 "import-log: archive: no temp dir"; return 1; }
	old_sha=$(sha256sum "$LOG" | cut -d' ' -f1)
	printf '%s\n' "$ids" > "$w/ids"
	awk -F'\t' 'NR==FNR { want[$1]=1; next } !/^#/ && ($1 in want)' "$w/ids" "$LOG" > "$w/out.tsv"
	awk -F'\t' 'NR==FNR { want[$1]=1; next } /^#/ || !($1 in want)' "$w/ids" "$LOG" > "$w/keep.tsv"
	n_out=$(wc -l < "$w/out.tsv" | tr -d ' ')
	[ "$n_out" = "$cnt" ] || { rm -rf "$w"; unlock; say2 "import-log: archive: selected $n_out lines for $cnt ids"; return 1; }
	first=$(sort "$w/ids" | head -n 1); last=$(sort "$w/ids" | tail -n 1)
	base=IMPORT-LOG-SLICE-$TODAY-$first-$last
	mkdir -p "$w/$base" "$ARCH" || { rm -rf "$w"; unlock; say2 "import-log: archive: cannot create $ARCH"; return 1; }
	days=$(cut -f3 "$w/out.tsv" | sort -u | paste -sd, -)
	{
		printf '{\n  "format": "ta-import-log-slice/1",\n'
		printf '  "tool": "import-log.sh %s",\n' "$VERSION"
		printf '  "created": "%s",\n  "archived_on": "%s",\n  "date_source": "%s",\n' "$(stamp)" "$TODAY" "$TODAY_SRC"
		printf '  "log": "%s",\n' "$(basename "$LOG")"
		printf '  "threshold": %s,\n  "threshold_source": "%s",\n  "forced": %s,\n' "$TH" "$TH_SRC" "$( [ "$FORCE" = 1 ] && echo true || echo false)"
		printf '  "rule": "a record is archived once two whole runs (distinct calendar dates before archived_on) have passed since it was added",\n'
		printf '  "columns": ["id","stamp","day","kind","group","source","dest","sha256","bytes","tags","status","note"],\n'
		printf '  "count": %s,\n' "$cnt"
		printf '  "days": ["%s"],\n' "$(printf '%s' "$days" | sed 's/,/","/g')"
		printf '  "records": [\n'
		json_records < "$w/out.tsv"
		printf '  ]\n}\n'
	} > "$w/$base/$base.json"
	{ printf '%s\n' "$HEADER"; cat "$w/out.tsv"; } > "$w/$base/$base.tsv"
	( cd "$w/$base" && sha256sum "$base.json" "$base.tsv" > MANIFEST.sha256 )
	tarf=$ARCH/$base.tar.gz
	[ -e "$tarf" ] && tarf=$ARCH/$base-$(date -u +%H%M%S).tar.gz
	( cd "$w" && tar -czf "$tarf.part" "$base" ) || { rm -rf "$w"; rm -f "$tarf.part" 2>/dev/null; unlock; say2 "import-log: archive: tar failed"; return 1; }
	[ "${IMPORT_LOG_FAULT:-}" = corrupt-slice ] && printf 'garbage' >> "$tarf.part"     # test-only fault (DESIGN S16)
	abandon() { rm -rf "$w"; rm -f "$tarf.part" 2>/dev/null; unlock; say2 "import-log: archive: $1 -- nothing rotated, no slice kept"; }
	# read the slice back before trusting it
	mkdir "$w/check" && ( cd "$w/check" && tar -xzf "$tarf.part" ) 2>/dev/null || { abandon "the slice does not read back"; return 1; }
	( cd "$w/check/$base" && sha256sum -c MANIFEST.sha256 >/dev/null 2>&1 ) || { abandon "slice manifest does not verify"; return 1; }
	cmp -s "$w/check/$base/$base.tsv" "$w/$base/$base.tsv" || { abandon "slice TSV differs after read-back"; return 1; }
	jn=$(grep -c '^    {"id": ' "$w/check/$base/$base.json")
	[ "$jn" = "$cnt" ] || { abandon "slice JSON holds $jn records, expected $cnt"; return 1; }
	tsha=$(sha256sum "$tarf.part" | cut -d' ' -f1)
	# the ARCHIVE record: its note names what the slice represents
	u_ids=$(ranges < "$w/ids")
	u_groups=$(distinct_col 5 < "$w/out.tsv")
	u_tags=$(distinct_col 10 < "$w/out.tsv")
	u_src=$(distinct_col 6 < "$w/out.tsv")
	u_kinds=$(kind_counts < "$w/out.tsv")
	rel=${tarf#"$ROOT"/}
	note="archived $cnt record(s) into $rel; ids: $u_ids; days: $days; groups: ${u_groups:--}; tags: ${u_tags:--}; kinds: $u_kinds; sources: ${u_src:--}; threshold $TH ($TH_SRC)$( [ "$FORCE" = 1 ] && printf ', forced')$( [ "$TODAY_SRC" = override ] && printf ', date overridden by IMPORT_LOG_TODAY')"
	aid=$(next_id)
	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$aid" "$(stamp)" "$TODAY" ARCHIVE "archive-$TODAY" "-" "$rel" "$tsha" \
		"$(wc -c < "$tarf.part" | tr -d ' ')" "archive" "OK" "$(clean "$note")" >> "$w/keep.tsv"
	[ "${IMPORT_LOG_FAULT:-}" = drop-kept ] && { grep -v '^#' "$w/keep.tsv" | head -n 1 > "$w/drop"; grep -vxF -f "$w/drop" "$w/keep.tsv" > "$w/k2"; mv "$w/k2" "$w/keep.tsv"; }   # test-only fault (DESIGN S16)
	# prove: kept + archived (less the one new ARCHIVE line) rebuild the old data lines exactly
	a=$( { grep -v '^#' "$LOG"; } | sort | sha256sum | cut -d' ' -f1)
	b=$( { grep -v '^#' "$w/keep.tsv" | grep -v "^$aid$TAB"; cat "$w/out.tsv"; } | sort | sha256sum | cut -d' ' -f1)
	[ "$a" = "$b" ] || { abandon "kept + archived does not rebuild the old log"; return 1; }
	# currency pull: the log must not have moved under us
	[ "$(sha256sum "$LOG" | cut -d' ' -f1)" = "$old_sha" ] || { abandon "the log changed while archiving"; return 1; }
	mv "$tarf.part" "$tarf" || { abandon "cannot name the slice"; return 1; }
	cp "$w/keep.tsv" "$LOG.new" && mv -f "$LOG.new" "$LOG" || { rm -rf "$w"; unlock; say2 "import-log: archive: rotate failed; the slice stands at $rel and the old log is untouched"; return 1; }
	rm -rf "$w"; unlock
	printf 'archived %s record(s) -> %s (sha256 %s); log now %s lines; ARCHIVE record %s\n' "$cnt" "$rel" "$(printf '%s' "$tsha" | cut -c1-16)" "$(nlines)" "$aid"
	return 0
}

# the check that runs before any work: archive first if the threshold says so
precheck() {
	lines=$(nlines)
	required=0
	if [ "$FORCE" = 1 ] && [ "$TH_SRC" != cli ]; then required=1; why="--force-archiving (the $TH_SRC threshold of $TH is bypassed)"  # MUT:force-cli
	elif [ "$lines" -gt "$TH" ]; then required=1; why="the log has $lines lines, over the $TH_SRC threshold of $TH"   # MUT:threshold-gt
	fi
	[ "$required" = 1 ] || return 0
	say2 "import-log: archiving required first: $why"
	archive_now; rc=$?
	[ "$rc" = 0 ] && return 0
	if [ "$FORCE" = 1 ]; then                                                                   # MUT:force-suppresses
		[ "$CONT" = 1 ] && say2 "import-log: --continue-after-stop is suppressed by --force-archiving"
		say2 "import-log: STOP -- archiving was forced and could not be completed; nothing else was done"
		exit 3
	fi
	if [ "$CONT" = 1 ]; then
		say2 "import-log: WARN archiving was required and could not be completed; continuing because --continue-after-stop was given"
		return 0
	fi
	say2 "import-log: STOP -- archiving was required and could not be completed; nothing else was done (use --continue-after-stop to work anyway)"
	exit 3
}

# ---------- roots ----------
root_of() {
	[ -f "$ROOTS" ] || { say2 "import-log: no roots map at $ROOTS (lines: ALIAS<TAB>DIRECTORY)"; return 1; }
	r=$(awk -F'\t' -v a="$1" '!/^#/ && $1==a { print $2; exit }' "$ROOTS")
	[ -n "$r" ] || { say2 "import-log: alias '$1' is not in $ROOTS"; return 1; }
	[ -d "$r" ] || { say2 "import-log: root for '$1' is not a directory here: $r"; return 1; }
	printf '%s\n' "$r"
}
excluded() {        # relpath -> 0 if excluded
	case "/$1/" in */.git/*) return 0 ;; esac
	[ -n "$EXCLUDES" ] || return 1
	printf '%s\n' "$EXCLUDES" | while IFS= read -r g; do
		[ -n "$g" ] || continue
		# shellcheck disable=SC2254
		case $1 in $g) echo hit; break ;; esac
	done | grep -q hit
}

N_NEW=0; N_SAME=0; N_CHG=0; N_BAD=0; DRY_BYTES=0
import_one() {      # alias root relpath
	a=$1; r=$2; p=$3
	case $p in *"$TAB"*|*'
'*) say2 "import-log: refuse (tab or newline in path): $a:$p"; N_BAD=$((N_BAD+1)); return ;; esac
	src=$r/$p
	[ -f "$src" ] || { say2 "import-log: MISSING source $a:$p"; N_BAD=$((N_BAD+1)); return; }
	dest=imports/$a/$p; D=$ROOT/$dest
	ssha=$(sha256sum "$src" | cut -d' ' -f1); sbytes=$(wc -c < "$src" | tr -d ' ')
	status=NEW; extra=
	if [ -f "$D" ]; then
		dsha=$(sha256sum "$D" | cut -d' ' -f1)
		if [ "$dsha" = "$ssha" ]; then
			N_SAME=$((N_SAME+1)); [ "$DRY" = 1 ] && printf 'dry-run: same %s:%s\n' "$a" "$p"; return
		fi
		status=CHANGED; extra="was $(printf '%s' "$dsha" | cut -c1-16); prior copy kept at imports/.superseded/$TODAY/$a/$p.$(printf '%s' "$dsha" | cut -c1-16)"
	fi
	if [ "$DRY" = 1 ]; then
		printf 'dry-run: %s %s:%s (%s bytes)\n' "$status" "$a" "$p" "$sbytes"
		[ "$status" = NEW ] && N_NEW=$((N_NEW+1)) || N_CHG=$((N_CHG+1)); DRY_BYTES=$((DRY_BYTES+sbytes)); return
	fi
	if [ "$status" = CHANGED ]; then
		sup=$ROOT/imports/.superseded/$TODAY/$a/$p.$(printf '%s' "$dsha" | cut -c1-16)
		mkdir -p "$(dirname "$sup")" && mv "$D" "$sup" || { say2 "import-log: cannot keep the prior copy of $dest"; N_BAD=$((N_BAD+1)); return; }
	fi
	mkdir -p "$(dirname "$D")" && cp -p "$src" "$D" 2>/dev/null || cp "$src" "$D" || { say2 "import-log: copy failed: $a:$p"; N_BAD=$((N_BAD+1)); return; }
	csha=$(sha256sum "$D" | cut -d' ' -f1)
	[ "$csha" = "$ssha" ] || { say2 "import-log: copy of $a:$p does not hash like its source; not logged"; N_BAD=$((N_BAD+1)); return; }
	n=$NOTE; [ -n "$extra" ] && n="${n:+$n; }$extra"
	append IMPORT "${GROUP:-import-$TODAY}" "$a:$p" "$dest" "$ssha" "$sbytes" "$TAGS" "$status" "${n:--}"
	[ "$status" = NEW ] && N_NEW=$((N_NEW+1)) || N_CHG=$((N_CHG+1))
}
import_path() {     # alias relpath (file or directory)
	r=$(root_of "$1") || { N_BAD=$((N_BAD+1)); return; }
	p=${2#./}; p=${p%/}
	if [ -d "$r/$p" ]; then
		( cd "$r" && find "./$p" -type f 2>/dev/null ) | sed 's|^\./||' | sort > "${TMPD}/walk"
		while IFS= read -r f; do excluded "$f" && continue; import_one "$1" "$r" "$f"; done < "${TMPD}/walk"
	else
		excluded "$p" && { say2 "import-log: excluded $1:$p"; return; }
		import_one "$1" "$r" "$p"
	fi
}

cmd_add() {
	TMPD=$(mktemp -d) || fail "no temp dir"
	if [ -n "$LIST" ]; then
		[ -f "$LIST" ] || die "no list file: $LIST"
		tr -d '\r' < "$LIST" | while IFS= read -r line; do
			case $line in ''|'#'*) continue ;; esac
			case $line in *"$TAB"*) a=${line%%"$TAB"*}; p=${line#*"$TAB"} ;; *:*) a=${line%%:*}; p=${line#*:} ;; *) say2 "import-log: list line has no alias: $line"; continue ;; esac
			printf '%s\t%s\n' "$a" "$p"
		done > "$TMPD/list"
		while IFS="$TAB" read -r a p; do import_path "$a" "$p"; done < "$TMPD/list"
	else
		oifs=$IFS; IFS='
'; set -f; set -- $set_ops; set +f; IFS=$oifs
		[ "$#" -ge 2 ] || die "usage: add [--group G] [--tags T] [--note N] ALIAS PATH... | add --list FILE"
		a=$1; shift
		for p in "$@"; do import_path "$a" "$p"; done
	fi
	rm -rf "$TMPD"
	[ "$DRY" = 1 ] && printf 'dry-run: would bring in %s bytes; ' "$DRY_BYTES"
	printf 'import: %s new, %s changed (prior copies kept), %s already identical, %s refused/missing; log %s lines\n' \
		"$N_NEW" "$N_CHG" "$N_SAME" "$N_BAD" "$(nlines)"
	[ "$N_BAD" = 0 ]
}

cmd_note() {
	txt=$(printf '%s' "$set_ops" | sed '1{/^$/d}' | paste -sd' ' -)
	[ -n "$txt" ] || die "usage: note TEXT..."
	append NOTE "${GROUP:-note-$TODAY}" "-" "-" "-" "-" "$TAGS" "-" "$txt"
	[ "$DRY" = 1 ] || printf 'noted %s\n' "$LAST_ID"
}

# ---------- reading it back ----------
select_rows() {
	awk -F'\t' -v all="$ALL" -v last="${LAST:-}" -v id="$WANT_ID" -v grp="$GROUP" -v kind="$WANT_KIND" '
	!/^#/ && NF>=12 { if (id!="" && $1!=id) next; if (grp!="" && $5!=grp) next; if (kind!="" && $4!=kind) next; r[++n]=$0 }
	END { s=1; if (all!=1 && id=="") { k=(last==""?20:last+0); if (n>k) s=n-k+1 } for (i=s;i<=n;i++) print r[i] }' "$1"
}
words() {           # TSV rows on stdin -> sentences
	awk -F'\t' '
	function fp(h) { return (length(h)>=16) ? substr(h,1,6) "…" substr(h,length(h)-3) : h }
	function num(n,  s, o) { s=n ""; o=""; while (length(s) > 3) { o="," substr(s, length(s)-2) o; s=substr(s, 1, length(s)-3) } return s o }
	{
		when=$3 " (" substr($2,12,5) " UTC)"
		if ($4=="IMPORT") {
			st=($11=="NEW")?"a new copy":($11=="CHANGED")?"a CHANGED copy -- the origin had moved on since the last import":"status " $11
			printf "%s -- on %s, brought in %s as %s: %s bytes, fingerprint %s; %s.", $1, when, $6, $7, num($9), fp($8), st
		} else if ($4=="ARCHIVE") {
			printf "%s -- on %s, archived older records: %s", $1, when, $12
		} else if ($4=="NOTE") {
			printf "%s -- on %s, a note: %s", $1, when, $12
		} else {
			printf "%s -- on %s, a %s record about %s.", $1, when, $4, $6
		}
		if ($5!="" && $5!="-") printf " Group %s.", $5
		if ($10!="" && $10!="-" && $4!="ARCHIVE") printf " Tags: %s.", $10
		if ($4=="IMPORT" && $12!="" && $12!="-") printf " Note: %s.", $12
		print ""
	}'
}
cmd_say() {
	[ -f "$LOG" ] || { echo "There is no import log yet at $LOG."; return 0; }
	th=$TH; ths=$TH_SRC
	awk -F'\t' -v th="$th" -v ths="$ths" -v lines="$(nlines)" -v today="$TODAY" '
	!/^#/ && NF>=12 { n++; c[$4]++; if(!($3 in d)){ d[$3]=1; nd++ } if ($3>last) last=$3; if (first=="" || $3<first) first=$3 }
	END {
		if (n==0) { print "The import log is empty."; exit }
		printf "The import log holds %d record(s): %d import(s), %d archive record(s), %d note(s), over %d day(s) from %s to %s. ", n, c["IMPORT"], c["ARCHIVE"], c["NOTE"], nd, first, last
		printf "It is %d lines long; archiving starts past %d lines (%s threshold). Today is %s.\n", lines, th, ths, today
	}' "$LOG"
	e=$(eligible_ids 2>/dev/null | wc -l | tr -d ' ')
	[ "$e" -gt 0 ] && printf '%s record(s) are old enough to archive (two whole runs have passed since they were added).\n' "$e"
	echo
	select_rows "$LOG" | words
}
cmd_ls() {
	[ -f "$LOG" ] || { echo "no log"; return 0; }
	select_rows "$LOG" | awk -F'\t' '{ printf "%-8s %s %-7s %-8s %s\n", $1, $3, $4, $11, ($4=="IMPORT")?$6:substr($12,1,90) }'
}
cmd_stats() {
	th=$TH; ths=$TH_SRC
	lines=$(nlines)
	printf 'log        %s\nlines      %s (threshold %s, from %s; %s)\ntoday      %s (%s date)\n' "$LOG" "$lines" "$th" "$ths" \
		"$( [ "$lines" -gt "$th" ] && echo 'OVER: archiving is required before work' || echo 'under')" "$TODAY" "$TODAY_SRC"
	[ -f "$LOG" ] || return 0
	echo "records by day (a day is a run):"
	awk -F'\t' '!/^#/ && NF>=12 { c[$3]++ } END { for (d in c) printf "  %s  %d\n", d, c[d] }' "$LOG" | sort
	echo "records by kind:"
	awk -F'\t' '!/^#/ && NF>=12 { c[$4]++ } END { for (k in c) printf "  %-8s %d\n", k, c[k] }' "$LOG" | sort
	echo "records by group:"
	awk -F'\t' '!/^#/ && NF>=12 { c[$5]++ } END { for (k in c) printf "  %-32s %d\n", k, c[k] }' "$LOG" | sort
	e=$(eligible_ids | ranges)
	printf 'eligible   %s\n' "${e:-none (no record has had two whole runs pass)}"
}
cmd_verify() {
	[ -f "$LOG" ] || { echo "NOT CHECKED: no log"; exit 77; }
	ok=0; bad=0; miss=0; cur=0; moved=0; gone=0; noroot=0
	awk -F'\t' '!/^#/ && $4=="IMPORT" { last[$7]=$0 } END { for (k in last) print last[k] }' "$LOG" | sort > "${TMPDIR:-/tmp}/il-verify.$$"
	while IFS="$TAB" read -r id st dy kd gp src dst sha by tg stt nt; do
		if [ ! -f "$ROOT/$dst" ]; then printf 'MISSING  %s (%s)\n' "$dst" "$id"; miss=$((miss+1)); continue; fi
		h=$(sha256sum "$ROOT/$dst" | cut -d' ' -f1)
		if [ "$h" = "$sha" ]; then ok=$((ok+1)); else printf 'CHANGED  %s (%s): logged %s, now %s\n' "$dst" "$id" "$(printf '%s' "$sha" | cut -c1-16)" "$(printf '%s' "$h" | cut -c1-16)"; bad=$((bad+1)); fi   # MUT:verify-hash
		if [ "$SOURCES" = 1 ]; then
			a=${src%%:*}; p=${src#*:}
			r=$(root_of "$a" 2>/dev/null) || { noroot=$((noroot+1)); continue; }
			if [ ! -f "$r/$p" ]; then printf 'GONE     %s (origin no longer there)\n' "$src"; gone=$((gone+1))
			elif [ "$(sha256sum "$r/$p" | cut -d' ' -f1)" = "$sha" ]; then cur=$((cur+1))
			else printf 'MOVED-ON %s (origin changed since import; re-add to bring it current)\n' "$src"; moved=$((moved+1)); fi
		fi
	done < "${TMPDIR:-/tmp}/il-verify.$$"
	rm -f "${TMPDIR:-/tmp}/il-verify.$$"
	sl=0; slbad=0
	for t in "$ARCH"/*.tar.gz; do
		[ -e "$t" ] || continue; sl=$((sl+1))
		tar -tzf "$t" >/dev/null 2>&1 || { printf 'SLICE-BAD %s (does not read)\n' "${t#"$ROOT"/}"; slbad=$((slbad+1)); }
	done
	awk -F'\t' '!/^#/ && $4=="ARCHIVE" { print $7 "\t" $8 }' "$LOG" > "${TMPDIR:-/tmp}/il-slices.$$"
	while IFS="$TAB" read -r rel sha; do
		if [ ! -f "$ROOT/$rel" ]; then printf 'SLICE-MISSING %s\n' "$rel"; slbad=$((slbad+1))
		elif [ "$(sha256sum "$ROOT/$rel" | cut -d' ' -f1)" != "$sha" ]; then printf 'SLICE-CHANGED %s\n' "$rel"; slbad=$((slbad+1)); fi
	done < "${TMPDIR:-/tmp}/il-slices.$$"
	rm -f "${TMPDIR:-/tmp}/il-slices.$$"
	printf 'copies: %s match, %s changed, %s missing' "$ok" "$bad" "$miss"
	[ "$SOURCES" = 1 ] && printf '; origins: %s current, %s moved on, %s gone, %s not reachable (no root)' "$cur" "$moved" "$gone" "$noroot"
	printf '; slices: %s read, %s bad\n' "$sl" "$slbad"
	[ $((ok+bad+miss)) -gt 0 ] || { echo "NOT CHECKED: the log has no imports"; exit 77; }
	[ "$bad" = 0 ] && [ "$miss" = 0 ] && [ "$slbad" = 0 ]
}
cmd_slices() {
	found=0
	for t in "$ARCH"/*.tar.gz; do
		[ -e "$t" ] || continue; found=1
		n=$(tar -xzOf "$t" --wildcards '*.json' 2>/dev/null | grep -c '^    {"id": ')
		printf '%s  %s records  sha256 %s\n' "${t#"$ROOT"/}" "$n" "$(sha256sum "$t" | cut -c1-16)"
	done
	[ "$found" = 1 ] || echo "no slices yet in ${ARCH#"$ROOT"/}"
}
cmd_slice_say() {
	oifs=$IFS; IFS='
'; set -f; set -- $set_ops; set +f; IFS=$oifs; [ "$#" -ge 1 ] || die "usage: slice-say SLICE.tar.gz"
	t=$1; [ -f "$t" ] || t=$ROOT/$1; [ -f "$t" ] || die "no slice: $1"
	printf 'Slice %s:\n' "$(basename "$t")"
	tar -xzOf "$t" --wildcards '*.tsv' | grep -v '^#' | words
}

# ---------- selftest: the rules, run in a scratch tree; --prove-red runs them against mutants ----------
cmd_selftest() {
	if [ "$PROVE" = 1 ]; then
		t=$(mktemp -d) || fail "no temp dir"; rc=0
		for name in today-excluded two-runs distinct-days threshold-gt force-cli force-suppresses verify-hash; do
			case $name in
			today-excluded)   expr='/# MUT:today-excluded/s/if (d < today) //' ;;
			two-runs)         expr='/# MUT:two-runs/s/passed >= 2/passed >= 1/' ;;
			distinct-days)    expr='/# MUT:distinct-days/s/for (x in seen) if (x > day\[i\]) passed++/for (j=1;j<=n;j++) if (day[j] > day[i]) passed++/' ;;
			threshold-gt)     expr='/# MUT:threshold-gt/s/-gt "\$TH"/-ge "$TH"/' ;;
			force-cli)        expr='/# MUT:force-cli/s/ \&\& \[ "\$TH_SRC" != cli \]//' ;;
			force-suppresses) expr='/# MUT:force-suppresses/s/if \[ "\$FORCE" = 1 \]; then/if false; then/' ;;
			verify-hash)      expr='/# MUT:verify-hash/s/if \[ "\$h" = "\$sha" \]/if true/' ;;
			esac
			sed "$expr" "$me" > "$t/mut.sh"
			if cmp -s "$me" "$t/mut.sh"; then printf 'prove-red: mutant %-16s DID NOT APPLY (the rule it targets has moved)\n' "$name"; rc=1; continue; fi
			if sh "$t/mut.sh" selftest >/dev/null 2>&1; then printf 'prove-red: mutant %-16s SURVIVED -- the selftest cannot see this fault\n' "$name"; rc=1
			else printf 'prove-red: mutant %-16s caught\n' "$name"; fi
		done
		if sh "$me" selftest >/dev/null 2>&1; then echo "prove-red: the unmutated tool passes"; else echo "prove-red: the unmutated tool FAILS its own selftest"; rc=1; fi
		rm -rf "$t"
		[ "$rc" = 0 ] && echo "PROVE-RED OK" || echo "PROVE-RED FAILED"
		return "$rc"
	fi
	t=$(mktemp -d) || fail "no temp dir"
	pass=0; bad=0
	ck() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else bad=$((bad+1)); printf 'selftest FAIL %s: expected %s, got %s\n' "$3" "$2" "$1"; fi; }
	mkdir -p "$t/src/d" "$t/ta/bin" "$t/ta/.import"
	cp "$me" "$t/ta/bin/import-log.sh"
	printf 'src\t%s\n' "$t/src" > "$t/ta/.import/roots.tsv"
	T="sh $t/ta/bin/import-log.sh"
	for i in 1 2 3; do printf 'one %s\n' "$i" > "$t/src/d/a$i.txt"; done
	IMPORT_LOG_TODAY=2026-01-01 $T add --group g1 --tags x src d/a1.txt >/dev/null 2>&1; ck $? 0 "add day1"
	IMPORT_LOG_TODAY=2026-01-01 $T add --group g1 --tags x src d/a1.txt >/dev/null 2>&1; ck "$(grep -vc '^#' "$t/ta/IMPORT-LOG.tsv")" 1 "same bytes not re-logged"
	IMPORT_LOG_TODAY=2026-01-02 $T add --group g2 --tags y src d/a2.txt >/dev/null 2>&1
	IMPORT_LOG_TODAY=2026-01-02 $T note --group g2 second run same day >/dev/null 2>&1
	# on 2026-01-03, before anything is written that day: two records on 01-02 are ONE run -> nothing eligible
	ck "$(IMPORT_LOG_TODAY=2026-01-03 $T stats 2>/dev/null | awk '/^eligible/{print $2}')" none "several records on one date are one run"
	# a log exactly AT the threshold is not over it
	IMPORT_LOG_TODAY=2026-01-03 $T --max-lines "$(wc -l < "$t/ta/IMPORT-LOG.tsv")" add --group g3 --tags z src d/a3.txt >/dev/null 2>&1; ck $? 0 "at the threshold is not over it"
	# on 2026-01-03, now with a record today: today is not a passed run -> still nothing eligible
	ck "$(IMPORT_LOG_TODAY=2026-01-03 $T stats 2>/dev/null | awk '/^eligible/{print $2}')" none "today is not a passed run"
	# forced on 01-03: nothing eligible -> STOP (3), even with --continue-after-stop
	IMPORT_LOG_TODAY=2026-01-03 $T --force-archiving --continue-after-stop note x >/dev/null 2>&1; ck $? 3 "forced archive with nothing eligible STOPs; continue suppressed"
	# over a tiny CLI threshold with nothing eligible: STOP; continue-after-stop proceeds
	IMPORT_LOG_TODAY=2026-01-03 $T --max-lines 2 note y >/dev/null 2>&1; ck $? 3 "over threshold, nothing eligible: STOP"
	IMPORT_LOG_TODAY=2026-01-03 $T --max-lines 2 --continue-after-stop note y >/dev/null 2>&1; ck $? 0 "continue-after-stop proceeds"
	# on 2026-01-04: day1 has 01-02 and 01-03 after it -> eligible; day2 has only 01-03 -> not
	ck "$(IMPORT_LOG_TODAY=2026-01-04 $T stats 2>/dev/null | awk '/^eligible/{print $2}')" L000001 "two whole runs passed"
	# forced with a CLI threshold the log is under: no archiving, work proceeds
	IMPORT_LOG_TODAY=2026-01-04 $T --force-archiving --max-lines 100 note z >/dev/null 2>&1; ck $? 0 "force honours a CLI threshold"
	ck "$(grep -c "${TAB}ARCHIVE${TAB}" "$t/ta/IMPORT-LOG.tsv")" 0 "no archive under a CLI threshold"
	# config threshold bypassed by force: archives L000001
	printf 'max_lines=100\n' > "$t/ta/.import/config"
	IMPORT_LOG_TODAY=2026-01-04 $T --force-archiving note w >/dev/null 2>&1; ck $? 0 "force bypasses config threshold and archives"
	ck "$(grep -c "${TAB}ARCHIVE${TAB}" "$t/ta/IMPORT-LOG.tsv")" 1 "one ARCHIVE record"
	ck "$(grep -c '^L000001	' "$t/ta/IMPORT-LOG.tsv")" 0 "archived record left the log"
	nt=$(awk -F'\t' '$4=="ARCHIVE"{print $12}' "$t/ta/IMPORT-LOG.tsv")
	case $nt in *"ids: L000001"*"groups: g1"*"tags: x"*) ck 1 1 "note names ids, groups, tags" ;; *) ck "$nt" "ids/groups/tags" "note names ids, groups, tags" ;; esac
	s=$(ls "$t/ta/archive/import-log/"*.tar.gz 2>/dev/null | head -n 1)
	ck "$(tar -xzOf "$s" --wildcards '*.json' | grep -c '"id": "L000001"')" 1 "slice JSON carries the record"
	$T verify >/dev/null 2>&1; ck $? 0 "verify after archive"
	# a changed byte in an imported copy must turn verify red (P1A-002 found this guard unwatched by the selftest)
	printf 'tamper' >> "$t/ta/imports/src/d/a2.txt"
	$T verify >/dev/null 2>&1; ck $? 1 "verify sees a changed copy"
	rm -rf "$t"
	printf 'selftest: %s passed, %s failed\n' "$pass" "$bad"
	[ "$bad" = 0 ]
}

usage() { sed -n '2,/^# Copyright/p' "$me" | sed 's/^# \{0,1\}//; /^Copyright/d'; }

# ---------- dispatch ----------
case $CMD in
help) usage; exit 0 ;;
selftest) cmd_selftest; exit $? ;;
slices) cmd_slices; exit 0 ;;
slice-say) cmd_slice_say; exit 0 ;;
add|note|say|ls|stats|verify|archive) ;;
*) die "unknown command: $CMD (try: help)" ;;
esac

# the check that runs before any work touching the log (stats alone only reports; see DESIGN S9)
thr=$(threshold) || exit 2
TH=${thr% *}; TH_SRC=${thr#* }
case $CMD in
stats) : ;;
archive)
	precheck
	lines=$(nlines)
	if [ "$FORCE" = 0 ] && [ "$lines" -le "$TH" ]; then echo "no archiving required: $lines lines, $TH_SRC threshold $TH (use --force-archiving to archive what is old enough anyway)"; fi
	exit 0 ;;
*) precheck ;;
esac

case $CMD in
add)    ensure_log; cmd_add ;;
note)   ensure_log; cmd_note ;;
say)    cmd_say ;;
ls)     cmd_ls ;;
stats)  cmd_stats ;;
verify) cmd_verify ;;
esac
