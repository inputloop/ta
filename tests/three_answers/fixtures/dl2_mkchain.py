#!/usr/bin/env python3
"""Build an N-generation chain for dl2-verify from its SPEC TEXT (polygram:bin/dl2-verify.sh L18-22):
C1 gen == position, C2 name integer == gen, C3 name hex16 == first 16 of sha256(whole file),
C4 prev empty for gen 1 else sha256:<sha256 of previous file's bytes>.  v3 names: g<gen>-<hex16>.md.
usage: dl2_mkchain.py DIR [N] [--tamper]   (--tamper appends a byte to gen 1 after naming it)"""
import hashlib, os, sys
d = sys.argv[1]; n = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 2
os.makedirs(d, exist_ok=True); prev = ""; first = None
for i in range(1, n + 1):
    body = "---\nseam: p1b\ngen: %d\nprev: %s\n---\ngeneration %d of a synthetic seam\n" % (i, prev, i)
    b = body.encode(); h = hashlib.sha256(b).hexdigest()
    p = os.path.join(d, "g%04d-%s.md" % (i, h[:16])); open(p, "wb").write(b)
    first = first or p; prev = "sha256:" + h
if "--tamper" in sys.argv:
    open(first, "ab").write(b"x")
# SPDX-License-Identifier: GPL-3.0-or-later
