#!/usr/bin/env python3
"""three_answers.py -- a conformance harness for the three-answer exit convention.

The convention (t0:intermediary/OFFERING-2026-09-30.md L16-20): a check answers
0 OK / 1 RED / 77 NOT CHECKED, and a check that cannot see says so in its own
exit -- never RED, never OK.  This harness asks every listed tool the question
twice (three times when a known-bad input is listed): once over an EMPTY input,
once over a KNOWN-GOOD input the row constructs, and optionally over a KNOWN-BAD
input.  It then says which of the four answers each run gave.

  OK                exit 0 on a real input
  RED               any other non-zero exit (a crash is RED, and flagged)
  NOT-CHECKED       exit 77; or, over EMPTY input only, a non-zero exit whose
                    output says it had nothing to check
  GREEN-WHEN-BLIND  exit 0 over EMPTY input (the exit channel says green; an
                    output that ALSO says "nothing checked" is flagged, but the
                    exit decides -- a caller reads the exit, not the prose)
  "Says it had nothing to check" means a whole-run phrase (NOT CHECKED, nothing
  to check, no sidecars, ... is empty).  Item words (SKIP, UNMEASURED,
  NOTVISIBLE, no-response, no-key) are recorded as a flag and never move a class.

Row verdict (census.tsv, column `verdict`):
  the EMPTY run's class, when the KNOWN-GOOD run was OK (the row is anchored);
  BROKEN      when both EMPTY and KNOWN-GOOD went RED (the tool cannot run);
  UNANCHORED  when the KNOWN-GOOD run was not OK for any other reason;
  SETUP-FAIL  when the row's own input construction failed (a harness fault).
  +CANNOT-GO-RED is appended when a KNOWN-BAD run exited 0.

Usage:
  three_answers.py census TOOLS.tsv [--out census.tsv] [--workdir DIR] [--only NAME] [--keep]
  three_answers.py --prove-red [--workdir DIR]

TOOLS.tsv (tab-separated, header row, '#' lines skipped):
  set    P (primary census row) | S (supplementary probe, reported apart)
  name   row id, e.g. t0:t0-kit/verify.sh
  tree   ALIAS:PATH[!EXCL,EXCL] copied fresh into $T for every run, or '-'
  cmd    sh snippet run in $W; sees $W $T $IN $FX $SNAP $R_<alias>
  empty  sh snippet (set -e) that builds the EMPTY input
  good   sh snippet that builds the KNOWN-GOOD input
  bad    sh snippet that builds a KNOWN-BAD input, or '-' (only where the tool's
         own usage text claims a non-zero exit for that fault)
  source ALIAS:PATH#Ln -- the usage text the invocation was derived from

Exit (the harness keeps the convention it measures):
  0   every primary row anchored and none green-when-blind or broken
  1   at least one primary row GREEN-WHEN-BLIND or BROKEN
  77  no rows ran, or some row could not be anchored (UNANCHORED / SETUP-FAIL)
  2   usage
--prove-red exits 0 only if the planted tools are classified as planted AND a
deliberately wrong expectation table is caught; otherwise 1.

Writes only under --workdir (default: work/ beside this file) and --out.
Python 3 standard library only.  Produced for wave P1B, act1-r2, 2026-09-30.
"""
import os
import re
import shutil
import stat
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_WORK = os.path.join(HERE, "work")
DEFAULT_ROOTS = "/home/claude/work/turn-2026-09-30/roots-snap.tsv"
SNAP = "/home/claude/snap"
TIMEOUT = int(os.environ.get("THREE_ANSWERS_TIMEOUT", "120"))

# output that says the WHOLE RUN had nothing to look at.  Used for one thing only: to
# split RED from NOT-CHECKED on a non-zero exit over EMPTY input; on exit 0 it is a flag.
NC_RE = re.compile(
    r"NOT[ -]CHECKED|nothing (?:could be |was )?checked|checked nothing|nothing to check|"
    r"no sidecars|no models in|no 64-hex sha256 hashes found|\b(?:is|was) empty\b")
# words that say ONE ITEM could not be seen (a SKIP row among PASS rows, an UNMEASURED cell):
# recorded as a flag, never allowed to move a class -- one skipped row is not a blind run
ITEM_BLIND_RE = re.compile(r"\bSKIP\b|UNMEASURED|NOTVISIBLE|UNVERIFIED|no-response|no-key")
# success words, recorded as an annotation only
OKW_RE = re.compile(
    r"ALL GREEN|\bOK\b|\bclean\b|\bPASS\b|\bmatch(?:es)?\b|CONVERGED|\bstable\b|"
    r"\bCURRENT\b|\bVALID\b|round-trip|complete\b", re.I)
# a crash, as opposed to a refusal
CRASH_RE = re.compile(
    r"Traceback \(most recent call last\)|Syntax error|syntax error|parameter not set|"
    r"unbound variable|can't shift|: not found\b|Illegal number|command not found")

COLS = ["set", "name", "tree", "cmd", "empty", "good", "bad", "source"]


def die(msg, code=2):
    sys.stderr.write("three_answers: %s\n" % msg)
    sys.exit(code)


def load_roots(path):
    roots = {}
    if os.path.isfile(path):
        with open(path, encoding="utf-8") as f:
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) >= 2 and p[0] and not p[0].startswith("#"):
                    roots[p[0]] = p[1]
    return roots


def load_rows(path):
    rows = []
    with open(path, encoding="utf-8") as f:
        lines = [l.rstrip("\n") for l in f]
    body = [l for l in lines if l.strip() and not l.startswith("#")]
    if not body:
        return rows
    hdr = body[0].split("\t")
    if hdr[:len(COLS)] != COLS:
        die("bad header in %s: want %s" % (path, "\t".join(COLS)))
    for n, l in enumerate(body[1:], 2):
        p = l.split("\t")
        if len(p) < len(COLS):
            die("%s: row %d has %d fields, want %d" % (path, n, len(p), len(COLS)))
        rows.append(dict(zip(COLS, p[:len(COLS)])))
    return rows


def writable(path):
    for d, dirs, files in os.walk(path):
        for x in dirs + files:
            p = os.path.join(d, x)
            if not os.path.islink(p):
                m = os.lstat(p).st_mode
                os.chmod(p, m | stat.S_IWUSR | stat.S_IRUSR | (stat.S_IXUSR if stat.S_ISDIR(m) else 0))
    os.chmod(path, os.stat(path).st_mode | stat.S_IWUSR)


def copy_tree(spec, roots, dest):
    """ALIAS:PATH[!EXCL,EXCL] -> fresh copy at dest; returns dest or None for '-'."""
    if spec in ("", "-"):
        return None
    excl = []
    if "!" in spec:
        spec, e = spec.split("!", 1)
        excl = [x for x in e.split(",") if x]
    alias, _, rel = spec.partition(":")
    if alias not in roots:
        raise RuntimeError("unknown alias %r in tree spec" % alias)
    src = os.path.normpath(os.path.join(roots[alias], rel or "."))
    ign = (lambda d, names: [n for n in names if os.path.join(d, n) in
                             {os.path.join(src, x) for x in excl}]) if excl else None
    if os.path.isdir(src):
        shutil.copytree(src, dest, symlinks=True, ignore=ign)
        writable(dest)
    else:
        os.makedirs(dest, exist_ok=True)
        shutil.copy2(src, os.path.join(dest, os.path.basename(src)))
        writable(dest)
    return dest


def run_sh(snippet, env, cwd, strict=False):
    code = ("set -e\n" if strict else "") + snippet
    try:
        p = subprocess.run(["sh", "-c", code], cwd=cwd, env=env, stdin=subprocess.DEVNULL,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=TIMEOUT)
        return p.returncode, p.stdout.decode("utf-8", "replace")
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or b"").decode("utf-8", "replace")
        return -999, out + "\n[three_answers: TIMEOUT after %ss]" % TIMEOUT


def classify(mode, rc, out):
    """-> (class, flags)."""
    flags = []
    nc = bool(NC_RE.search(out))
    if CRASH_RE.search(out) or rc in (126, 127) or rc >= 128 or rc < 0:
        flags.append("crash" if rc != -999 else "timeout")
    if nc:
        flags.append("says-nothing-checked")
    if ITEM_BLIND_RE.search(out):
        flags.append("item-blind-words")
    if OKW_RE.search(out):
        flags.append("success-words")
    if rc == 77:
        return "NOT-CHECKED", flags
    if rc == 0:
        return ("GREEN-WHEN-BLIND" if mode == "empty" else "OK"), flags
    if mode == "empty" and nc and "crash" not in flags and "timeout" not in flags:
        return "NOT-CHECKED", flags
    return "RED", flags


def verdict(res):
    e, g, b = res.get("empty"), res.get("good"), res.get("bad")
    if any(r and r["class"] == "SETUP-FAIL" for r in (e, g, b)):
        return "SETUP-FAIL"
    if g["class"] != "OK":
        if g["class"] == "RED" and e["class"] == "RED":
            return "BROKEN"
        return "UNANCHORED"
    v = e["class"]
    if b and b["class"] == "OK":
        v += "+CANNOT-GO-RED"
    return v


def slug(s):
    return re.sub(r"[^A-Za-z0-9._-]+", "_", s).strip("_")[:90]


def do_row(row, roots, work, keep, logdir):
    res = {}
    modes = ["empty", "good"] + (["bad"] if row["bad"].strip() not in ("", "-") else [])
    for mode in modes:
        W = os.path.join(work, "runs", slug(row["name"]), mode)
        if os.path.exists(W):
            shutil.rmtree(W)
        os.makedirs(os.path.join(W, "tmp"))
        os.makedirs(os.path.join(W, "home"))
        env = {"PATH": "/usr/local/bin:/usr/bin:/bin", "LC_ALL": "C", "LANG": "C",
               "HOME": os.path.join(W, "home"), "TMPDIR": os.path.join(W, "tmp"),
               "W": W, "IN": os.path.join(W, "in"), "FX": os.path.join(HERE, "fixtures"),
               "SNAP": SNAP, "HARNESS": os.path.abspath(__file__)}
        for a, p in roots.items():
            env["R_" + re.sub(r"[^A-Za-z0-9]", "_", a)] = p
        log = ["# row: %s   mode: %s" % (row["name"], mode)]
        try:
            T = copy_tree(row["tree"], roots, os.path.join(W, "tree"))
            env["T"] = T or os.path.join(W, "tree")
            if not T:
                os.makedirs(env["T"])
            prc, pout = run_sh(row[mode], env, W, strict=True)
            log.append("# prep rc=%s\n%s" % (prc, pout))
            if prc != 0:
                res[mode] = {"class": "SETUP-FAIL", "rc": prc, "flags": ["prep-rc=%s" % prc]}
                continue
            rc, out = run_sh(row["cmd"], env, W)
            cls, flags = classify(mode, rc, out)
            res[mode] = {"class": cls, "rc": rc, "flags": flags}
            log.append("# cmd: %s\n# rc=%s class=%s flags=%s\n%s" % (row["cmd"], rc, cls, ",".join(flags), out[-20000:]))
        except Exception as ex:  # a harness fault, never a tool verdict
            res[mode] = {"class": "SETUP-FAIL", "rc": None, "flags": ["harness:%s" % ex]}
            log.append("# harness exception: %r" % ex)
        finally:
            with open(os.path.join(logdir, "%s.%s.txt" % (slug(row["name"]), mode)), "w", encoding="utf-8") as f:
                f.write("\n".join(log) + "\n")
            if not keep and os.path.exists(W):
                shutil.rmtree(W, ignore_errors=True)
    res["verdict"] = verdict(res)
    return res


def fmt_run(r):
    if not r:
        return ("-", "-", "-")
    return (r["class"], str(r["rc"]), ",".join(r["flags"]) or "-")


def census(tsv, out, work, only=None, keep=False, roots_path=DEFAULT_ROOTS, quiet=False):
    roots = load_roots(roots_path)
    rows = load_rows(tsv)
    if only:
        rows = [r for r in rows if r["name"] == only]
    logdir = os.path.join(work, "logs")
    os.makedirs(logdir, exist_ok=True)
    table = []
    for row in rows:
        res = do_row(row, roots, work, keep, logdir)
        table.append((row, res))
        if not quiet:
            print("%-2s %-58s %-26s empty=%s(%s) good=%s(%s)%s" % (
                row["set"], row["name"][:58], res["verdict"], res["empty"]["class"], res["empty"]["rc"],
                res["good"]["class"], res["good"]["rc"],
                (" bad=%s(%s)" % (res["bad"]["class"], res["bad"]["rc"])) if "bad" in res else ""))
    if out:
        with open(out, "w", encoding="utf-8") as f:
            f.write("\t".join(["set", "name", "verdict", "empty_class", "empty_rc", "empty_flags",
                               "good_class", "good_rc", "good_flags", "bad_class", "bad_rc", "bad_flags",
                               "source"]) + "\n")
            for row, res in table:
                f.write("\t".join([row["set"], row["name"], res["verdict"],
                                   *fmt_run(res["empty"]), *fmt_run(res["good"]),
                                   *fmt_run(res.get("bad")), row["source"]]) + "\n")
    prim = [res for row, res in table if row["set"] == "P"]
    counts = {}
    for res in prim:
        counts[res["verdict"]] = counts.get(res["verdict"], 0) + 1
    if not quiet:
        print("\nprimary rows: %d  %s" % (len(prim), "  ".join("%s=%d" % kv for kv in sorted(counts.items()))))
        sup = [res for row, res in table if row["set"] != "P"]
        sc = {}
        for res in sup:
            sc[res["verdict"]] = sc.get(res["verdict"], 0) + 1
        print("supplementary rows: %d  %s" % (len(sup), "  ".join("%s=%d" % kv for kv in sorted(sc.items()))))
    if not table:
        print("NOT CHECKED: no rows ran")
        return 77, table
    if any(v.startswith(("GREEN-WHEN-BLIND", "BROKEN")) for v in counts):
        return 1, table
    if any(v in ("UNANCHORED", "SETUP-FAIL") for v in counts) or not prim:
        return 77, table
    return 0, table


# ---------------------------------------------------------------- --prove-red
PLANTED = {
    # honest: exits 77 on empty (its words avoid the NOT-CHECKED phrases, so only the exit
    # can make it NOT-CHECKED -- a harness that ignored 77 would fail here), 0 on good, 1 on bad
    "honest.sh": '#!/bin/sh\n[ -s "$1" ] || { echo "honest: no lines to read"; exit 77; }\n'
                 'grep -q BAD "$1" && { echo "RED: BAD found"; exit 1; }\n'
                 'echo "OK: $(wc -l < "$1") line(s) checked"; exit 0\n',
    # green-when-blind: reads nothing, says green
    "blind.sh": '#!/bin/sh\ncat "$1" >/dev/null 2>&1\necho "ALL GREEN"\nexit 0\n',
    # crashes on every input
    "crash.py": 'import sys\nopen(sys.argv[1]).read()\nprint(1 / 0)\n',
    # precedence witness: SAYS nothing was checked, but exits 0 (the exit decides)
    "wordsonly.sh": '#!/bin/sh\n[ -s "$1" ] || { echo "nothing to check"; exit 0; }\n'
                    'grep -q BAD "$1" && exit 1; echo ok; exit 0\n',
    # anchor witness: can never see (a missing dependency) and says so, exit 1 on every input;
    # its known-good run must read RED (not NOT-CHECKED) and the row UNANCHORED
    "depmissing.sh": '#!/bin/sh\necho "NOT CHECKED: a dependency is missing"\nexit 1\n',
    # item-word witness: one SKIP row among FAIL rows is RED, not NOT-CHECKED
    # (added after the first census read check-all's lone SKIP line as a blind run)
    "skiprow.sh": '#!/bin/sh\n[ -s "$1" ] || { echo "  FAIL  row one"; echo "  SKIP  row two"; exit 1; }\n'
                  'grep -q BAD "$1" && exit 1; echo "  PASS  row one"; exit 0\n',
}
EXPECT = {  # name -> (empty, good, bad, verdict)
    "planted:honest": ("NOT-CHECKED", "OK", "RED", "NOT-CHECKED"),
    "planted:blind": ("GREEN-WHEN-BLIND", "OK", "OK", "GREEN-WHEN-BLIND+CANNOT-GO-RED"),
    "planted:crash": ("RED", "RED", "RED", "BROKEN"),
    "planted:wordsonly": ("GREEN-WHEN-BLIND", "OK", "RED", "GREEN-WHEN-BLIND"),
    "planted:skiprow": ("RED", "OK", "RED", "RED"),
    "planted:depmissing": ("NOT-CHECKED", "RED", "RED", "UNANCHORED"),
}


def planted_tsv(pdir):
    runner = {"honest.sh": "sh", "blind.sh": "sh", "crash.py": "python3", "wordsonly.sh": "sh", "skiprow.sh": "sh",
              "depmissing.sh": "sh"}
    lines = ["\t".join(COLS)]
    for fn, name in (("honest.sh", "planted:honest"), ("blind.sh", "planted:blind"),
                     ("crash.py", "planted:crash"), ("wordsonly.sh", "planted:wordsonly"),
                     ("skiprow.sh", "planted:skiprow"), ("depmissing.sh", "planted:depmissing")):
        lines.append("\t".join(["P", name, "-", '%s "%s/%s" "$IN"' % (runner[fn], pdir, fn),
                                ': > "$IN"', 'printf "a\\nb\\n" > "$IN"', 'printf "a\\nBAD\\n" > "$IN"',
                                "three_answers.py:PLANTED"]))
    return "\n".join(lines) + "\n"


def compare(table, expect):
    miss = []
    for row, res in table:
        want = expect.get(row["name"])
        got = (res["empty"]["class"], res["good"]["class"], res.get("bad", {}).get("class", "-"), res["verdict"])
        if want != got:
            miss.append((row["name"], want, got))
    return miss


def judge(table, expect, show):
    """How many rows the expectation table gets wrong.  The real check and its negative twin both
    come through here, so neutering this one function is caught by one call or the other."""
    miss = compare(table, expect)
    if show:
        for row, res in table:
            m = [x for x in miss if x[0] == row["name"]]
            print("  %-5s %-18s %s" % ("FAIL" if m else "ok", row["name"], res["verdict"]))
            if m:
                print("        want %s\n        got  %s" % (m[0][1], m[0][2]))
    return len(miss)


def prove_red(work):
    pdir = os.path.join(work, "prove-red")
    if os.path.exists(pdir):
        shutil.rmtree(pdir)
    os.makedirs(pdir)
    for fn, body in PLANTED.items():
        with open(os.path.join(pdir, fn), "w") as f:
            f.write(body)
    tsv = os.path.join(pdir, "planted.tsv")
    with open(tsv, "w") as f:
        f.write(planted_tsv(pdir))
    rc, table = census(tsv, os.path.join(pdir, "planted-census.tsv"), pdir, quiet=True)
    bad = 0
    print("three_answers --prove-red")
    bad += judge(table, EXPECT, show=True)       # must be 0: every planted tool read as planted
    # the harness's own exit over these rows must be 1 (a GWB and a BROKEN are in the set)
    if rc != 1:
        print("  FAIL  harness exit over the planted set was %s, want 1" % rc); bad += 1
    else:
        print("  ok    harness exit over the planted set is 1 (it does not go green over a blind tool)")
    # negative twin: a WRONG expectation table must be caught, or the comparison is furniture
    names = list(EXPECT)
    rotated = {names[i]: EXPECT[names[(i + 1) % len(names)]] for i in range(len(names))}
    wrong = judge(table, rotated, show=False)    # same code path; must catch every row
    if wrong != len(names):
        print("  FAIL  a rotated (wrong) expectation table was caught on %d of %d rows" % (wrong, len(names)))
        bad += 1
    else:
        print("  ok    a rotated (wrong) expectation table is caught on %d of %d rows" % (wrong, len(names)))
    # the harness itself over an EMPTY tool list must say NOT CHECKED (77), never green
    empty = os.path.join(pdir, "empty.tsv")
    with open(empty, "w") as f:
        f.write("\t".join(COLS) + "\n")
    erc, _ = census(empty, None, os.path.join(pdir, "empty-run"), quiet=True)
    if erc != 77:
        print("  FAIL  harness over an empty tool list exited %s, want 77" % erc); bad += 1
    else:
        print("  ok    harness over an empty tool list exits 77 (NOT CHECKED)")
    if bad:
        print("prove-red FAILED: %d case(s) misbehaved" % bad)
        return 1
    print("prove-red PASS: %d planted tools (honest, blind, crashing, words-only, skip-row, dependency-missing)"
          " classified as planted; a wrong table is caught; an empty list exits 77" % len(EXPECT))
    return 0


def main(argv):
    work = DEFAULT_WORK
    if "--workdir" in argv:
        i = argv.index("--workdir"); work = os.path.abspath(argv[i + 1]); del argv[i:i + 2]
    roots = DEFAULT_ROOTS
    if "--roots" in argv:
        i = argv.index("--roots"); roots = argv[i + 1]; del argv[i:i + 2]
    if argv[:1] == ["--prove-red"]:
        return prove_red(work)
    if argv[:1] == ["census"] and len(argv) >= 2:
        tsv = argv[1]; rest = argv[2:]
        out = None; only = None; keep = False
        if "--out" in rest:
            i = rest.index("--out"); out = rest[i + 1]; del rest[i:i + 2]
        if "--only" in rest:
            i = rest.index("--only"); only = rest[i + 1]; del rest[i:i + 2]
        if "--keep" in rest:
            keep = True; rest.remove("--keep")
        if rest:
            die("unknown arguments: %s" % " ".join(rest))
        if not os.path.isfile(tsv):
            die("no tool list: %s" % tsv)
        rc, _ = census(tsv, out, work, only=only, keep=keep, roots_path=roots)
        return rc
    sys.stderr.write("usage: three_answers.py census TOOLS.tsv [--out census.tsv] [--workdir DIR]"
                     " [--only NAME] [--keep] | --prove-red [--workdir DIR]\n")
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
# SPDX-License-Identifier: GPL-3.0-or-later
