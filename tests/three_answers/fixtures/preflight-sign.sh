#!/bin/sh
# honest stand-in sign preflight: refuse unless sha256(ZIP) equals DIGEST.  usage: preflight-sign.sh ZIP DIGEST
[ -f "$1" ] || exit 2
[ "$(sha256sum "$1" | cut -d' ' -f1)" = "$2" ] || { echo "preflight: digest mismatch" >&2; exit 1; }
echo "preflight: digest ok"
# SPDX-License-Identifier: GPL-3.0-or-later
