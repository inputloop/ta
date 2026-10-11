#!/usr/bin/env python3
"""paper-citations.py -- forward-check every entry id a paper cites, and generate the back-links.

    python3 bin/paper-citations.py PAPER.md --root TURN_DIR [--journal JOURNAL.md] [--out CITATIONS.md]
    python3 bin/paper-citations.py --prove-red

An id is `<PREFIX>-<nnn>` where PREFIX maps to one file:
    B<1-9><I|U>  -> act1/r1/B<n>-<informed|uninformed>/WAVE-*.md
    P<n><A|B>    -> act1/r2/P<n><A|B>/WAVE-*.md
    R<n>         -> act1/r3/R<n>/WAVE-*.md
    L<n><LETTER>...  -> any file under act2/ that holds `### <id>:` (Act II rows). A line reference such as
                    L151-153 is NOT an id: an L-id needs a letter after its digits (fixed 2026-09-30 after a false RED).
Named sources (SCORE P<n>, S-doubt, S-reward, journal) resolve to their files by name.

Forward: every cited id must exist as a `### <id>:` header in its file -- else `MISSING <id>` and exit 1.
Back: for each source file, the paper sections (## / ### headings) that cite it.
Exit 0 all resolve · 1 a cited id does not resolve · 2 usage · 77 the paper cites nothing.
Copyright (C) 2026 Corwin Brust <corwin@bru.st>.  SPDX-License-Identifier: GPL-3.0-or-later
"""
import glob, hashlib, os, re, sys, tempfile

ID_RE = re.compile(r'\b((?:B[1-9][IU])|(?:P\d{1,2}[AB])|(?:R\dC\d[AB])|(?:R\d)|(?:R[23][A-Z0-9]+)|(?:L\d+[A-Z][A-Z0-9]*))-(\d{3})\b')
NAMED = [
    (re.compile(r'\bSCORE P\d+\b|\bSCORE R1'), 'act1/r2/SCORE-2026-09-30-round-2-cross-arm.md'),
    (re.compile(r'\bdoubt\b'), 'act1/r4/S-doubt/WAVE-20260930T2330Z-act1r4-swot-doubt.md'),
    (re.compile(r'\breward\b'), 'act1/r4/S-reward/WAVE-20260930T2330Z-act1r4-swot-reward.md'),
    (re.compile(r'\bjournal\b', re.I), 'JOURNAL-2026-09-30-bring-home.md'),
]


def file_for(prefix, root):
    if re.fullmatch(r'B[1-9][IU]', prefix):
        arm = 'informed' if prefix[-1] == 'I' else 'uninformed'
        pat = f'{root}/act1/r1/{prefix[:2]}-{arm}/WAVE-*.md'
    elif re.fullmatch(r'P\d{1,2}[AB]', prefix):
        pat = f'{root}/act1/r2/{prefix}/WAVE-*.md'
    elif re.fullmatch(r'R\d', prefix):
        pat = f'{root}/act1/r3/{prefix}/WAVE-*.md'
    elif re.fullmatch(r'R\dC\d[AB]', prefix):
        pat = f'{root}/act2/r1/{prefix}/WAVE-*.md'
    else:
        pat = f'{root}/act2/**/*.md'
    hits = sorted(glob.glob(pat, recursive=True))
    return hits


def sha(p):
    with open(p, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def run(paper, root, journal=None, out=None):
    text = open(paper).read().splitlines()
    section = '(head)'
    cites = []            # (id, prefix, section, paper line)
    named = []            # (file, section)
    for n, line in enumerate(text, 1):
        m = re.match(r'^(#{2,3}) (.+)', line)
        if m:
            section = m.group(2).strip()
        for mm in ID_RE.finditer(line):
            cites.append((mm.group(0), mm.group(1), section, n))
        for rx, f in NAMED:
            if rx.search(line):
                named.append((f, section))
    if not cites:
        print('NOT CHECKED: the paper cites no entry ids')
        return 77
    missing = []
    resolved = {}          # id -> (file, line)
    for cid, pfx, sec, n in cites:
        if cid in resolved:
            continue
        found = None
        for f in file_for(pfx, root):
            for k, l in enumerate(open(f, errors='replace').read().splitlines(), 1):
                if l.startswith(f'### {cid}:'):
                    found = (f, k)
                    break
            if found:
                break
        if found:
            resolved[cid] = found
        else:
            missing.append((cid, n))
    back = {}
    for cid, pfx, sec, n in cites:
        if cid in resolved:
            back.setdefault(resolved[cid][0], set()).add(sec)
    for f, sec in named:
        fp = os.path.join(root, f)
        if os.path.exists(fp):
            back.setdefault(fp, set()).add(sec)
    lines = []
    lines.append('produced-by: bin/paper-citations.py · subject: %s · sha256: %s' % (os.path.basename(paper), sha(paper)))
    lines.append('')
    lines.append('# CITATIONS · 2026-09-30 · %s -- forward and back' % os.path.basename(paper))
    lines.append('')
    lines.append('WHAT THIS IS: every entry id the paper cites, resolved to the file and line of the entry that')
    lines.append('carries it (forward); then, for every source file, its sha256 and the paper sections that cite it')
    lines.append('(back). Generated; do not hand-edit. Each entry carries its own `came-from` lines into the snapshot,')
    lines.append('which the citation gate (`xref-check.sh check`) resolved with 0 FLAGs.')
    lines.append('')
    lines.append('## 7.1 Back-links: source file -> sections of the paper that cite it')
    lines.append('')
    lines.append('| source file | sha256 (16) | entries | cited by |')
    lines.append('|---|---|---|---|')
    for f in sorted(back):
        rel = os.path.relpath(f, root)
        nent = sum(1 for l in open(f, errors='replace') if re.match(r'^### [A-Z0-9-]+: ', l))
        lines.append('| `%s` | `%s` | %d | %s |' % (rel, sha(f)[:16], nent, ' · '.join(sorted(back[f]))))
    lines.append('')
    lines.append('## 7.2 Forward: id -> entry (%d distinct ids, %d citations)' % (len(resolved) + len(missing), len(cites)))
    lines.append('')
    for cid in sorted(resolved, key=lambda x: (ID_RE.match(x).group(1), x)):
        f, k = resolved[cid]
        lines.append('- `%s` -> `%s#L%d`' % (cid, os.path.relpath(f, root), k))
    for cid, n in missing:
        lines.append('- `%s` -> **MISSING** (cited at paper L%d)' % (cid, n))
    if journal and os.path.exists(journal):
        lines.append('')
        lines.append('## 8. The covering journal (printed whole; sha256 %s)' % sha(journal)[:16])
        lines.append('')
        lines.extend(open(journal).read().splitlines())
    body = '\n'.join(lines) + '\n'
    if out:
        open(out, 'w').write(body)
    for cid, n in missing:
        print('MISSING %s (paper L%d)' % (cid, n))
    print('paper-citations: %d citations, %d distinct ids, %d resolved, %d MISSING; %d source files back-linked'
          % (len(cites), len(resolved) + len(missing), len(resolved), len(missing), len(back)))
    return 1 if missing else 0


def prove_red():
    t = tempfile.mkdtemp()
    os.makedirs(f'{t}/act1/r1/B1-informed')
    open(f'{t}/act1/r1/B1-informed/WAVE-x.md', 'w').write('### B1I-001: real\nbody\n')
    os.makedirs(f'{t}/act2/r1/R1C4A')
    open(f'{t}/act2/r1/R1C4A/WAVE-y.md', 'w').write('### R1C4A-002: real\nbody\n')
    good = f'{t}/good.md'; bad = f'{t}/bad.md'; empty = f'{t}/empty.md'
    open(good, 'w').write('## S\ncites B1I-001 and R1C4A-002; a line ref L151-153 is not an id\n')
    open(bad, 'w').write('## S\ncites B1I-001 and R1C4A-009\n')
    open(empty, 'w').write('## S\nno ids here\n')
    import contextlib, io
    with contextlib.redirect_stdout(io.StringIO()):
        a = run(good, t); b = run(bad, t); c = run(empty, t)
    ok = (a == 0 and b == 1 and c == 77)
    print('prove-red: good->%d bad->%d empty->%d : %s' % (a, b, c, 'PROVE-RED OK' if ok else 'PROVE-RED FAILED'))
    return 0 if ok else 1


if __name__ == '__main__':
    a = sys.argv[1:]
    if '--prove-red' in a:
        sys.exit(prove_red())
    if not a or a[0].startswith('-'):
        print(__doc__); sys.exit(2)
    paper = a[0]
    root = a[a.index('--root') + 1] if '--root' in a else os.path.dirname(os.path.abspath(paper))
    journal = a[a.index('--journal') + 1] if '--journal' in a else None
    out = a[a.index('--out') + 1] if '--out' in a else None
    sys.exit(run(paper, root, journal, out))
