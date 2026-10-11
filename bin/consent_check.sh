#!/bin/sh
# consent_check.sh -- tiny wrapper around consent_check.awk (SPEC-consent.md): does the two things awk
# cannot (sha256, ssh-keygen) and hands their results to the awk as variables.
#   sh consent_check.sh --record REC [--sig SIG --allowed-signers ALLOW] [--source-keys F]
#                       [--now ISO] [--session-end ISO] [--keeper PRINCIPAL] [--seen F]
#   sh consent_check.sh --prove-red [--keep DIR]
# exit 0 PASS / 1 FAIL / 2 PARK / 77 NOT CHECKED / 64 usage
# SPDX-License-Identifier: GPL-3.0-or-later
set -u
here=$(cd "$(dirname "$0")" && pwd)
case "${1:-}" in --prove-red) shift; exec sh "$here/consent_prove_red.sh" "$@" ;; esac
rec="" sig="" allow="" src="" now="" send="" keeper="" seen=""
while [ $# -gt 0 ]; do
	case "$1" in
	--record) rec=$2 ;; --sig) sig=$2 ;; --allowed-signers) allow=$2 ;; --source-keys) src=$2 ;;
	--now) now=$2 ;; --session-end) send=$2 ;; --keeper) keeper=$2 ;; --seen) seen=$2 ;;
	*) echo "usage: consent_check.sh --record REC [--sig SIG --allowed-signers ALLOW] [--source-keys F] [--now ISO] [--session-end ISO] [--keeper P] [--seen F] | --prove-red" >&2; exit 64 ;;
	esac
	[ $# -ge 2 ] || { echo "consent_check.sh: $1 needs a value" >&2; exit 64; }
	shift 2
done
[ -r "$rec" ] || { echo "consent_check.sh: cannot read record: $rec" >&2; exit 77; }
[ -n "$now" ] || now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
t=$(mktemp -d) || exit 64; trap 'rm -rf "$t"' EXIT
principal=$(CC_MODE=extract CC_OUT=$t awk -f "$here/consent_check.awk" "$rec") || principal=""
sha=NA; sigst=NA; sigwhy="" sigfp=""
if [ -f "$t/hashin" ]; then
	if command -v sha256sum >/dev/null 2>&1; then sha=$(sha256sum < "$t/hashin" | cut -c1-64)
	elif command -v shasum >/dev/null 2>&1; then sha=$(shasum -a 256 < "$t/hashin" | cut -c1-64)
	elif command -v openssl >/dev/null 2>&1; then sha=$(openssl dgst -sha256 < "$t/hashin" | sed 's/.*= *//'); fi
fi
if [ -z "$sig" ] || [ -z "$allow" ]; then sigwhy="no --sig/--allowed-signers"
elif ! command -v ssh-keygen >/dev/null 2>&1; then sigwhy="no ssh-keygen"
elif [ ! -f "$t/sigin" ] || [ -z "$principal" ]; then sigwhy="no payload or no principal"
else
	if ssh-keygen -Y verify -f "$allow" -I "$principal" -n consent-record -s "$sig" < "$t/sigin" > "$t/v" 2>&1
	then sigst=GOOD; else sigst=BAD; sigwhy=$(tr '\n' ' ' < "$t/v" | cut -c1-120); fi
	CC_P=$principal awk 'BEGIN { p = ENVIRON["CC_P"] } $1 == p { for (i = 2; i <= NF; i++) if ($i ~ /^(ssh-|ecdsa-|sk-)/) { print $i, $(i+1); exit } }' "$allow" > "$t/pub"
	[ -s "$t/pub" ] && sigfp=$(ssh-keygen -lf "$t/pub" 2>/dev/null | awk '{print $2}')
fi
CC_MODE=check CC_SHA=$sha CC_SIG=$sigst CC_SIGWHY=$sigwhy CC_SIGFP=$sigfp CC_NOW=$now CC_SESSEND=$send \
	CC_KEEPER=$keeper CC_SRCKEYS=$src CC_SEEN=$seen awk -f "$here/consent_check.awk" "$rec"
