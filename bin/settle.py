#!/usr/bin/env python3
"""settle.py 0.1.0 -- settle a sealed CHECKPOINT of called shots against a RESULTS file.

usage:
  settle.py CHECKPOINT.md RESULTS.tsv --seal HEX [--results-seal HEX] [--base DIR] [--roots ROOTS.tsv]
  settle.py --prove-red

CHECKPOINT.md  the markdown table the house uses for called shots: columns  # | shot | p | check.
RESULTS.tsv    tab-separated  id <TAB> outcome <TAB> receipt   (outcome: 1, 0 or unsettled;
               receipt: PATH:LINE[-LINE] relative to --base (default: the results file's folder),
               or ALIAS:PATH#L<n>[-<m>] resolved through --roots). Lines starting with # are comments;
               a first row whose id is "id" is a header.
--seal HEX     the checkpoint's sha256 as recorded BEFORE the evidence existed (full 64 hex, or a
               prefix of at least 8 hex; a trailing "..." or the ellipsis character is dropped).
--results-seal HEX  the results file's sha256 as recorded when it was settled; any later edit goes RED.

Three answers, always (exit code):
  0   scored: at least one shot settled and nothing is RED
  1   RED: unsealed or mismatched checkpoint, a receipt that does not resolve, a results file edited
      after its seal, a result for a shot never called, a duplicate or malformed row
  77  NOT CHECKED: nothing could be scored (every shot unsettled or without a receipt)
Unsettled or receipt-less shots are NOT CHECKED: never scored as 0, never counted in the total.
The Brier term per shot is (p - o)^2; the total is their sum over settled shots, and the mean is
the Brier score over the same shots.
"""
import hashlib
import os
import re
import subprocess
import sys
import tempfile

RED, OK, NOT_CHECKED = 1, 0, 77
HEX = re.compile(r"^[0-9a-f]+$")
ALIAS_RE = re.compile(r"^([A-Za-z0-9_-]+):(.+)#L(\d+)(?:-L?(\d+))?$")
PATHLINE_RE = re.compile(r"^(.+):(\d+)(?:-(\d+))?$")


def sha256_file(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()


def clean_seal(given):
    g = given.strip().lower()
    for tail in ("…", "..."):
        if g.endswith(tail):
            g = g[: -len(tail)]
    return g


def check_seal(label, actual, given):
    """-> (ok, message)."""
    if given is None:
        return False, f"RED  {label} UNSEALED: no seal given; its sha256 is {actual} -- record that before the evidence exists"
    g = clean_seal(given)
    if not HEX.match(g) or not (8 <= len(g) <= 64):
        return False, f"RED  {label} seal is not 8..64 hex: {given!r}"
    if not actual.startswith(g):
        return False, f"RED  {label} SEAL MISMATCH: sealed {g} but the file hashes to {actual} -- edited after sealing, or the wrong file"
    kind = "full" if len(g) == 64 else f"prefix {len(g)}/64"
    return True, f"ok   {label} sealed ({kind}): {actual}"


def split_row(line):
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|") and not s.endswith("\\|"):
        s = s[:-1]
    cells, cur, i = [], "", 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s) and s[i + 1] == "|":
            cur += "|"
            i += 2
            continue
        if s[i] == "|":
            cells.append(cur.strip())
            cur = ""
        else:
            cur += s[i]
        i += 1
    cells.append(cur.strip())
    return cells


def is_header(cells):
    if len(cells) < 4:
        return False
    c = [x.lower() for x in cells]
    return c[0] == "#" and c[1].startswith("shot") and c[2] == "p" and "check" in c[3]


def parse_checkpoint(path):
    """-> (rows, faults). rows: list of (id, p, lineno)."""
    lines = open(path, encoding="utf-8").read().splitlines()
    tables, faults = [], []
    i = 0
    while i < len(lines):
        if lines[i].lstrip().startswith("|") and is_header(split_row(lines[i])):
            rows = []
            j = i + 1
            if j < len(lines) and re.match(r"^\s*\|?\s*:?-{3,}", lines[j]):
                j += 1
            while j < len(lines) and lines[j].lstrip().startswith("|"):
                cells = split_row(lines[j])
                rid = cells[0] if cells else ""
                if len(cells) < 4 or not rid:
                    faults.append(f"RED  checkpoint L{j+1}: malformed row (need #, shot, p, check)")
                else:
                    try:
                        p = float(cells[2])
                    except ValueError:
                        p = None
                    if p is None or not (0.0 <= p <= 1.0):
                        faults.append(f"RED  checkpoint L{j+1}: {rid} has p={cells[2]!r}, not a probability in [0,1]")
                    else:
                        rows.append((rid, p, j + 1))
                j += 1
            tables.append(rows)
            i = j
        else:
            i += 1
    if not tables:
        faults.append("RED  checkpoint: no table with columns  # | shot | p | check")
        return [], faults
    if len(tables) > 1:
        faults.append(f"RED  checkpoint: {len(tables)} called-shot tables; one checkpoint, one table")
    rows = tables[0]
    seen = set()
    for rid, _, ln in rows:
        if rid in seen:
            faults.append(f"RED  checkpoint L{ln}: shot {rid} called twice")
        seen.add(rid)
    if not rows and not faults:
        faults.append("RED  checkpoint: the table has no shots")
    return rows, faults


def load_roots(path):
    roots = {}
    if not path:
        return roots
    here = os.path.dirname(os.path.abspath(path))
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) >= 2:
            root = parts[1]
            roots[parts[0]] = root if os.path.isabs(root) else os.path.normpath(os.path.join(here, root))
    return roots


def resolve_receipt(receipt, base, roots):
    """-> (ok, where_or_reason)."""
    m = ALIAS_RE.match(receipt)
    if m:
        alias, rel, lo, hi = m.group(1), m.group(2), int(m.group(3)), m.group(4)
        if alias not in roots:
            return False, f"unknown alias {alias!r} (pass --roots with it)"
        path = os.path.join(roots[alias], rel)
    else:
        m = PATHLINE_RE.match(receipt)
        if not m:
            return False, "not PATH:LINE or ALIAS:PATH#L<n>"
        rel, lo, hi = m.group(1), int(m.group(2)), m.group(3)
        path = rel if os.path.isabs(rel) else os.path.join(base, rel)
    hi = int(hi) if hi else lo
    if not os.path.isfile(path):
        return False, f"no such file: {path}"
    text = open(path, encoding="utf-8", errors="replace").read().splitlines()
    if lo < 1 or hi < lo or hi > len(text):
        return False, f"line {lo}-{hi} outside {path} ({len(text)} lines)"
    if not any(t.strip() for t in text[lo - 1:hi]):
        return False, f"line {lo}-{hi} of {path} is blank"
    return True, f"{path}:{lo}" + (f"-{hi}" if hi != lo else "")


def parse_results(path):
    """-> (rows, faults). rows: list of (id, outcome, receipt, lineno)."""
    rows, faults = [], []
    for n, line in enumerate(open(path, encoding="utf-8").read().splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.split("\t")
        if n == 1 and parts[0].strip().lower() == "id":
            continue
        while len(parts) < 3:
            parts.append("")
        rid, outcome, receipt = parts[0].strip(), parts[1].strip().lower(), parts[2].strip()
        if not rid or outcome not in ("1", "0", "unsettled"):
            faults.append(f"RED  results L{n}: malformed row (id, outcome 1/0/unsettled, receipt): {line!r}")
            continue
        rows.append((rid, outcome, receipt, n))
    return rows, faults


def settle(argv):
    args = {"--seal": None, "--results-seal": None, "--base": None, "--roots": None}
    pos = []
    it = iter(argv)
    for a in it:
        if a in args:
            try:
                args[a] = next(it)
            except StopIteration:
                print(f"settle: {a} needs a value", file=sys.stderr)
                return 2
        elif a.startswith("--"):
            print(f"settle: unknown option {a}", file=sys.stderr)
            return 2
        else:
            pos.append(a)
    if len(pos) != 2:
        print(__doc__.split("\n\n")[1], file=sys.stderr)
        return 2
    ckpt, results = pos
    for f in (ckpt, results):
        if not os.path.isfile(f):
            print(f"settle: no such file: {f}", file=sys.stderr)
            return 2

    # 1. the seal comes first: an unsealed or edited checkpoint is refused before anything is scored
    ok, msg = check_seal("checkpoint", sha256_file(ckpt), args["--seal"])
    print(msg)
    if not ok:
        print("settle: RED -- refused; nothing scored")
        return RED
    rsha = sha256_file(results)
    if args["--results-seal"] is not None:
        rok, rmsg = check_seal("results", rsha, args["--results-seal"])
        print(rmsg)
        if not rok:
            print("settle: RED -- refused; nothing scored")
            return RED
    else:
        print(f"note results unsealed; freeze them with --results-seal {rsha}")

    shots, faults = parse_checkpoint(ckpt)
    res, rfaults = parse_results(results)
    faults += rfaults
    called = {rid: p for rid, p, _ in shots}
    base = args["--base"] or os.path.dirname(os.path.abspath(results))
    roots = load_roots(args["--roots"])

    by_id = {}
    for rid, outcome, receipt, n in res:
        if rid not in called:
            faults.append(f"RED  results L{n}: {rid} was never called in the checkpoint -- a shot named after the fact")
            continue
        if rid in by_id:
            faults.append(f"RED  results L{n}: second result for {rid}; supersede with a new sealed file, not a second row")
            continue
        by_id[rid] = (outcome, receipt, n)

    lines, total, checked, not_checked = [], 0.0, [], []
    for rid, p, _ in shots:
        if rid not in by_id:
            not_checked.append((rid, "no result row"))
            lines.append(f"{rid:<6} p={p:.2f}  NOT CHECKED  (no result row)")
            continue
        outcome, receipt, n = by_id[rid]
        if outcome == "unsettled":
            not_checked.append((rid, "unsettled"))
            lines.append(f"{rid:<6} p={p:.2f}  NOT CHECKED  (unsettled)")
            continue
        if not receipt:
            not_checked.append((rid, "no receipt"))
            lines.append(f"{rid:<6} p={p:.2f}  NOT CHECKED  (outcome {outcome} given without a receipt)")
            continue
        rok, where = resolve_receipt(receipt, base, roots)
        if not rok:
            faults.append(f"RED  results L{n}: {rid} receipt {receipt!r} does not resolve: {where}")
            lines.append(f"{rid:<6} p={p:.2f}  RED          (receipt does not resolve)")
            continue
        o = int(outcome)
        term = (p - o) ** 2
        total += term
        checked.append(rid)
        lines.append(f"{rid:<6} p={p:.2f}  outcome={o}  brier={term:.4f}  receipt={where}")

    print(f"checkpoint {len(shots)} shot(s); results {len(res)} row(s)")
    for ln in lines:
        print("  " + ln)
    for f in faults:
        print(f)
    k = len(checked)
    nc = ", ".join(f"{r} {why}" for r, why in not_checked) or "none"
    if k:
        print(f"total: Brier sum {total:.4f} over {k} settled shot(s); mean {total / k:.4f}")
    else:
        print("total: no shot settled -- no Brier total")
    print(f"NOT CHECKED {len(not_checked)}: {nc}")
    if faults:
        print(f"settle: RED -- {len(faults)} fault(s)")
        return RED
    if k == 0:
        print("settle: NOT CHECKED -- nothing could be scored")
        return NOT_CHECKED
    print(f"settle: scored {k} of {len(shots)} shot(s)")
    return OK


# ---------------------------------------------------------------- prove-red
def _run(argv):
    import io
    import contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = settle(argv)
    return rc, buf.getvalue()


def _awk_oracle(ckpt, results):
    """The Brier sum recomputed by awk straight from the fixture files -- a second language for the arithmetic."""
    prog = r'''
    FNR==NR { if ($0 ~ /^\| *F[0-9]+ *\|/) { n=split($0,c,"|"); id=c[2]; gsub(/ /,"",id); p=c[4]; gsub(/ /,"",p); P[id]=p } next }
    FNR==1 && $1=="id" { next }
    ($2=="1" || $2=="0") && $3!="" { s += (P[$1]-$2)^2 }
    END { printf "%.4f\n", s }'''
    out = subprocess.run(["awk", "-F", "\t", prog, ckpt, results], capture_output=True, text=True)
    return out.stdout.strip()


def prove_red():
    here = os.path.dirname(os.path.abspath(__file__))
    fx = next((d for d in (os.path.join(here, "fixtures"), os.path.normpath(os.path.join(here, os.pardir, "tests", "settle", "fixtures"))) if os.path.isfile(os.path.join(d, "checkpoint-good.md"))), os.path.join(here, "fixtures"))  # install: ../tests/settle/fixtures
    need = ["checkpoint-good.md", "results-good.tsv", "evidence.txt"]
    for f in need:
        if not os.path.isfile(os.path.join(fx, f)):
            print(f"prove-red: fixture missing: {os.path.join(fx, f)}")
            return 2
    t = tempfile.mkdtemp(prefix="prove-red-settle-")  # not in bin/: the mount may refuse the cleanup
    for f in need:
        with open(os.path.join(fx, f), "rb") as a, open(os.path.join(t, f), "wb") as b:
            b.write(a.read())
    with open(os.path.join(t, "roots.tsv"), "w") as fh:
        fh.write(f"fx\t{t}\n")
    ck, rs, roots = os.path.join(t, "checkpoint-good.md"), os.path.join(t, "results-good.tsv"), os.path.join(t, "roots.tsv")
    seal = sha256_file(ck)
    rseal = sha256_file(rs)
    good_results = open(rs, encoding="utf-8").read()
    good_ckpt = open(ck, encoding="utf-8").read()

    def with_results(text, name):
        p = os.path.join(t, name)
        open(p, "w", encoding="utf-8").write(text)
        return p

    def with_ckpt(text, name):
        p = os.path.join(t, name)
        open(p, "w", encoding="utf-8").write(text)
        return p

    fails = 0
    # the good fixture must score, and its sum must equal the awk oracle
    rc, out = _run([ck, rs, "--seal", seal, "--results-seal", rseal, "--roots", roots])
    m = re.search(r"Brier sum ([0-9.]+) over (\d+)", out)
    oracle = _awk_oracle(ck, rs)
    nc = re.search(r"NOT CHECKED (\d+):", out)
    good = rc == OK and m and m.group(1) == oracle and m.group(2) == "2" and nc and nc.group(1) == "3"
    print(f"{'ok  ' if good else 'FAIL'} good fixture: exit {rc}, sum {m.group(1) if m else '?'} vs awk oracle {oracle}, "
          f"settled {m.group(2) if m else '?'} (want 2), NOT CHECKED {nc.group(1) if nc else '?'} (want 3)")
    fails += 0 if good else 1

    cases = [
        ("unsealed checkpoint (no --seal)", [ck, rs, "--roots", roots], RED, "checkpoint UNSEALED"),
        ("wrong seal", [ck, rs, "--seal", "0" * 64, "--roots", roots], RED, "checkpoint SEAL MISMATCH"),
        ("seal shorter than 8 hex (a true prefix)", [ck, rs, "--seal", seal[:4], "--roots", roots], RED, "seal is not 8..64 hex"),
        ("checkpoint p edited after sealing",
         [with_ckpt(good_ckpt.replace("| 0.70 |", "| 0.95 |"), "ck-edited.md"), rs, "--seal", seal, "--roots", roots], RED,
         "checkpoint SEAL MISMATCH"),
        ("receipt names a missing file",
         [ck, with_results(good_results.replace("evidence.txt:2", "evidence-gone.txt:2"), "r-missing.tsv"), "--seal", seal, "--roots", roots],
         RED, "does not resolve: no such file"),
        ("receipt line beyond end of file",
         [ck, with_results(good_results.replace("evidence.txt:2", "evidence.txt:99"), "r-eof.tsv"), "--seal", seal, "--roots", roots],
         RED, "does not resolve: line 99-99 outside"),
        ("receipt alias not in roots",
         [ck, with_results(good_results.replace("fx:evidence.txt", "zz:evidence.txt"), "r-alias.tsv"), "--seal", seal, "--roots", roots],
         RED, "unknown alias 'zz'"),
        ("result edited after sealing (F2 0 -> 1)",
         [ck, with_results(good_results.replace("F2\t0\t", "F2\t1\t"), "r-edited.tsv"), "--seal", seal, "--results-seal", rseal,
          "--roots", roots], RED, "results SEAL MISMATCH"),
        ("result for a shot never called",
         [ck, with_results(good_results + "F9\t1\tevidence.txt:2\n", "r-uncalled.tsv"), "--seal", seal, "--roots", roots],
         RED, "F9 was never called"),
        ("two results for one shot",
         [ck, with_results(good_results + "F1\t0\tevidence.txt:3\n", "r-dup.tsv"), "--seal", seal, "--roots", roots],
         RED, "second result for F1"),
        ("every shot unsettled",
         [ck, with_results("id\toutcome\treceipt\nF1\tunsettled\t\nF2\tunsettled\t\n", "r-none.tsv"), "--seal", seal, "--roots", roots],
         NOT_CHECKED, "nothing could be scored"),
    ]
    for name, argv, want, why in cases:
        rc, out = _run(argv)
        hit = rc == want and why in out
        print(f"{'ok  ' if hit else 'FAIL'} {name}: exit {rc} (want {want}), {'names' if why in out else 'MISSING'} {why!r}")
        fails += 0 if hit else 1
    print(f"prove-red: {len(cases) + 1 - fails} of {len(cases) + 1} held (good fixture scores; {len(cases)} planted faults each answer as they must)")
    if fails == 0:
        import shutil
        shutil.rmtree(t, ignore_errors=True)  # a host that fences deletes (a mounted folder) must not turn a held proof RED
    else:
        print(f"prove-red: work kept for inspection in {t}")
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    if sys.argv[1:] == ["--prove-red"]:
        sys.exit(prove_red())
    sys.exit(settle(sys.argv[1:]))
# SPDX-License-Identifier: GPL-3.0-or-later
