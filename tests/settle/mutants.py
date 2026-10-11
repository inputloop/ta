#!/usr/bin/env python3
"""mutants.py -- prove the provers: plant one fault in a copy of each tool and expect its --prove-red to go red.

usage: python3 mutants.py        (run from anywhere; works on copies under ./.mutants-*/ and removes them)
A mutant that leaves --prove-red at exit 0 SURVIVED: the tool's own proof does not cover that fault.
Exit 0 when every mutant is caught and both control copies pass; 1 otherwise.
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))

SETTLE = [
    ("S1 checkpoint seal skipped", "settle.py",
     'ok, msg = check_seal("checkpoint", sha256_file(ckpt), args["--seal"])', 'ok, msg = True, "mutant: seal skipped"'),
    ("S2 unsettled scored as 0", "settle.py",
     '        if outcome == "unsettled":\n', '        if outcome == "unsettled":\n            total += p ** 2; checked.append(rid)\n'),
    ("S3 receipt-less row scored", "settle.py",
     '        if not receipt:\n', '        if not receipt:\n            total += (p - int(outcome)) ** 2; checked.append(rid)\n'),
    ("S4 receipt never resolved", "settle.py",
     'rok, where = resolve_receipt(receipt, base, roots)', 'rok, where = True, receipt'),
    ("S5 results seal ignored", "settle.py",
     'if args["--results-seal"] is not None:', 'if False:'),
    ("S6 result for an uncalled shot dropped silently", "settle.py",
     '        if rid not in called:\n', '        if rid not in called:\n            continue\n'),
    ("S7 nothing scored reads OK", "settle.py",
     '        return NOT_CHECKED', '        return OK'),
    ("S8 duplicate result: last one wins", "settle.py",
     '        if rid in by_id:\n', '        if False:\n'),
    ("S9 seal prefix floor 8 -> 1 hex", "settle.py",
     '(8 <= len(g) <= 64)', '(1 <= len(g) <= 64)'),
]

DRIFT = [
    ("D1 grader not required", "drift_line.awk", 'if (!has_gr) add("NO-GRADER")', 'if (0) add("NO-GRADER")'),
    ("D2 lower-case none taken as NONE", "drift_line.awk",
     'else if (pb != "NONE" && !concrete(pb)) add("VAGUE-PUSHBACK")', 'else if (tolower(pb) != "none" && !concrete(pb)) add("VAGUE-PUSHBACK")'),
    ("D3 on-bearing rubber stamp allowed", "drift_line.awk",
     'if (obA == "yes" && !concrete(obO)) add("RUBBER-STAMP")', 'if (0) add("RUBBER-STAMP")'),
    ("D4 any word is concrete", "drift_line.awk",
     'if (length(w) >= 3 && w ~ /[a-z]/ && !(w in FILLER)) return 1', 'if (length(w) >= 1) return 1'),
    ("D5 wrapper appends on refusal", "drift_line.sh", 'if [ "$rc" -ne 0 ]; then', 'if false; then'),
    ("D6 wrapper derives still-arguing as yes always", "drift_line.sh",
     'if [ "$3" = NONE ]; then sa=no; else sa=yes; fi', 'sa=yes'),
    ("D7 empty input reads OK", "drift_line.awk", 'exit 77 }', 'exit 0 }'),
    ("D8 ORDER check removed", "drift_line.awk", 'if (last != "" && isstamp(ts) && ts < last) add("ORDER")', ''),
    ("D9 CONTRADICTION check removed", "drift_line.awk",
     'if (saA == "no" && has_pb && pb != "" && pb != "NONE") add("CONTRADICTION")', ''),
    ("D10 ANSWER check removed", "drift_line.awk",
     '(has_sa && saA != "yes" && saA != "no")) add("ANSWER")', '(has_sa && saA != "yes" && saA != "no")) ;'),
    ("D11 unknown field accepted", "drift_line.awk", '|| trim(note) == "" || unknown)', '|| trim(note) == "")'),
]


def copy_tree(dst):
    for f in ("settle.py", "drift_line.awk", "drift_line.sh"):
        shutil.copy(os.path.join(HERE, f), os.path.join(dst, f))
    shutil.copytree(os.path.join(HERE, "fixtures"), os.path.join(dst, "fixtures"))


def run(dst, which):
    cmd = ["python3", "settle.py", "--prove-red"] if which == "settle" else ["sh", "drift_line.sh", "--prove-red"]
    p = subprocess.run(cmd, cwd=dst, capture_output=True, text=True)
    return p.returncode, p.stdout


def main():
    root = tempfile.mkdtemp(prefix=".mutants-", dir=HERE)
    bad = 0
    for which in ("settle", "drift"):
        d = os.path.join(root, f"control-{which}")
        os.mkdir(d)
        copy_tree(d)
        rc, _ = run(d, which)
        print(f"{'ok  ' if rc == 0 else 'FAIL'} control {which}: --prove-red exit {rc} (want 0)")
        bad += rc != 0
    caught = survived = 0
    for which, table in (("settle", SETTLE), ("drift", DRIFT)):
        for i, (name, fname, old, new) in enumerate(table):
            d = os.path.join(root, f"{which}-{i+1}")
            os.mkdir(d)
            copy_tree(d)
            path = os.path.join(d, fname)
            src = open(path).read()
            if src.count(old) != 1:
                print(f"FAIL {name}: mutation site found {src.count(old)} time(s), not applied (harness fault)")
                bad += 1
                continue
            open(path, "w").write(src.replace(old, new))
            rc, out = run(d, which)
            if rc != 0:
                caught += 1
                why = [l for l in out.splitlines() if l.startswith("FAIL")]
                print(f"caught   {name}: --prove-red exit {rc}; first red: {why[0].strip() if why else '(no FAIL line)'}")
            else:
                survived += 1
                print(f"SURVIVED {name}: --prove-red exit 0")
    total = len(SETTLE) + len(DRIFT)
    print(f"mutants: {caught} of {total} caught, {survived} survived")
    shutil.rmtree(root)
    return 0 if (bad == 0 and survived == 0) else 1


if __name__ == "__main__":
    sys.exit(main())
# SPDX-License-Identifier: GPL-3.0-or-later
