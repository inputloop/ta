#!/usr/bin/awk -f
# paper-ids.awk -- list entry ids in a paper per SPEC-paper-ids.md (second implementation, POSIX awk).
# usage: awk -f paper-ids.awk PAPER.md        prints one id per occurrence, in order.
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>.  SPDX-License-Identifier: GPL-3.0-or-later
function isid(t,   p) {
  if (t !~ /-[0-9][0-9][0-9]$/) return 0
  p = substr(t, 1, length(t) - 4)
  if (p ~ /^B[1-9][IU]$/) return 1
  if (p ~ /^P[0-9][0-9]?[AB]$/) return 1
  if (p ~ /^R[0-9]C[0-9][AB]$/) return 1
  if (p ~ /^R[0-9]$/) return 1
  if (p ~ /^R[23][A-Z0-9]+$/) return 1
  if (p ~ /^L[0-9]+[A-Z][A-Z0-9]*$/) return 1
  return 0
}
{
  line = $0
  gsub(/[^A-Za-z0-9-]/, " ", line)
  n = split(line, w, " ")
  for (i = 1; i <= n; i++) {
    t = w[i]
    # a token like X-001-002 is not one id; keep the strict PREFIX-nnn form only
    if (t ~ /^[A-Z][A-Z0-9]*-[0-9][0-9][0-9]$/ && isid(t)) print t
  }
}
