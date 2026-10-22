#!/usr/bin/env python3
# recipe_check.py -- the second reader of RECIPE.org: what each :tangle block makes, read by its own
#   code (not a port of recipe.sh's awk), against the project.  One line per target, then its seal:
#     SAME|DRIFT|MISSING <TAB> PATH        and, for ":seal yes",   SEALED|STALE <TAB> PATH.sha256
#   recipe.sh check compares these lines with its own and says AGREE or DISAGREE.
# Copyright 2026 Corwin Brust <corwin@bru.st> and Contributors.
# SPDX-License-Identifier: GPL-3.0-or-later
# Written by Mentat (for Corwin, claude-opus-5-5), 2026-10-22.  Tangled from RECIPE.org.
# usage: python3 -I bin/recipe_check.py RECIPE PROJECT
import hashlib, os, re, sys

BEGIN = re.compile(r'^[ \t]*#\+begin_src(?:[ \t]|$)', re.I)
END = re.compile(r'^[ \t]*#\+end_src[ \t]*$', re.I)
# org-unescape-code-in-string (org-src.el): drop one comma from a line that is commas then "*" or "#+"
UNESC = re.compile(r'^([ \t]*),(,*(?:\*|#\+))')

def header(line, name):
    m = re.search(r'(?:^|[ \t]):' + name + r'[ \t]+(\S+)', line)
    return m.group(1) if m else None

def made(recipe):
    out, cur, body = [], None, None
    with open(recipe, 'rb') as f:
        lines = f.read().decode('utf-8').split('\n')
    if lines and lines[-1] == '':
        lines.pop()
    for ln in lines:
        if body is None and BEGIN.match(ln):
            t = header(ln, 'tangle')
            cur = None if t in (None, 'no') else (t, header(ln, 'seal') == 'yes')
            body = []
            continue
        if body is not None and END.match(ln):
            if cur:
                text = ''.join(UNESC.sub(r'\1\2', b) + '\n' for b in body)
                out.append((cur[0], cur[1], text.encode('utf-8')))
            cur, body = None, None
            continue
        if body is not None:
            body.append(ln)
    return out

def main(argv):
    if len(argv) != 2:
        print('usage: recipe_check.py RECIPE PROJECT', file=sys.stderr); return 2
    recipe, proj = argv
    rows = made(recipe)
    if not rows:
        print('NOT CHECKED\tno :tangle blocks'); return 2
    bad = 0
    for path, seal, want in rows:
        p = os.path.join(proj, path)
        if not os.path.isfile(p):
            print('MISSING\t' + path); bad = 1
        else:
            with open(p, 'rb') as f:
                got = f.read()
            if got == want: print('SAME\t' + path)
            else: print('DRIFT\t' + path); bad = 1
        if seal:
            sc = p + '.sha256'
            ok = False
            if os.path.isfile(sc) and os.path.isfile(p):
                parts = open(sc, encoding='utf-8').read().split()
                with open(p, 'rb') as f:
                    ok = len(parts) >= 2 and parts[0] == hashlib.sha256(f.read()).hexdigest() \
                         and parts[1].lstrip('*') == os.path.basename(path)
            print(('SEALED\t' if ok else 'STALE\t') + path + '.sha256'); bad |= (not ok)
    return 1 if bad else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
