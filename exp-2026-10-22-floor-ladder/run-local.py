#!/usr/bin/env python3
# run-local.py -- put each case to a local Ollama model under one condition; append one JSON line per
#   answer to the results file.  Resumable: a (model, condition, id) already in the results is skipped,
#   so a run cut off by a time limit is finished by running it again.
# Copyright 2026 Corwin Brust <corwin@bru.st> and Contributors.
# SPDX-License-Identifier: GPL-3.0-or-later
# Written by Mentat (for Corwin, claude-opus-5-5), 2026-10-22.
# usage: python3 run-local.py MODEL COND CASES RESULTS [--host URL] [--max N]
#   COND: A (no rules), B (the card), C (the floor).  Card and floor are read from beside this script.
import json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
THREE = ("Answer on the first line with exactly one of: OK, RED, NOT CHECKED. "
         "Then give one sentence saying why.")

SPLIT = ("Answer with exactly two lines and nothing before them:\n"
         "PRESENT: yes or no  (is what you would need to look at, to apply the rule, shown in the scenario?)\n"
         "MET: yes or no  (if it is shown, is the rule met?)\n"
         "Then one sentence saying why.")

def decide(text):
    """Condition D: the code, not the model, makes the verdict from the two answers."""
    p = m = None
    for ln in text.splitlines():
        u = ln.strip().strip("*").upper()
        if u.startswith("PRESENT:"): p = u.split(":", 1)[1].strip(" *.").split(" ")[0]
        elif u.startswith("MET:"): m = u.split(":", 1)[1].strip(" *.").split(" ")[0]
    if p == "NO": return "NOT CHECKED"
    if p == "YES" and m == "YES": return "OK"
    if p == "YES" and m == "NO": return "RED"
    return "UNPARSED"

def system_for(cond):
    if cond == "D":
        with open(os.path.join(HERE, "FLOOR.md"), encoding="utf-8") as f:
            return f.read().split("\n", 1)[1].lstrip() + "\n\n" + SPLIT
    if cond == "A":
        return ("You judge records of AI-assisted work in a small organization. OK means the rule is met, "
                "RED means it is broken, NOT CHECKED means you cannot tell from what you were given. " + THREE)
    name = {"B": "CARD.md", "C": "FLOOR.md"}[cond]
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read() + "\n\n" + THREE

def main(a):
    if len(a) < 4: print(__doc__ or "usage", file=sys.stderr); return 2
    model, cond, cases_p, out_p = a[:4]
    host = "http://host.docker.internal:11434"; mx = 10**9
    if "--host" in a: host = a[a.index("--host") + 1]
    if "--max" in a: mx = int(a[a.index("--max") + 1])
    if cond not in "ABCD" or len(cond) != 1: print("COND is A, B, C or D", file=sys.stderr); return 2
    done = set()
    if os.path.exists(out_p):
        for ln in open(out_p, encoding="utf-8"):
            r = json.loads(ln); done.add((r["model"], r["cond"], r["id"]))
    sysmsg = system_for(cond); n = 0
    for ln in open(cases_p, encoding="utf-8"):
        c = json.loads(ln)
        if (model, cond, c["id"]) in done: continue
        if n >= mx: break
        user = "Rule %d applies.\n\nScenario: %s" % (c["rule"], c["scenario"])
        body = json.dumps({"model": model, "stream": False, "think": False,
                           "options": {"temperature": 0, "num_ctx": 8192, "num_predict": 160},
                           "messages": [{"role": "system", "content": sysmsg},
                                        {"role": "user", "content": user}]}).encode()
        t0 = time.time()
        req = urllib.request.Request(host + "/api/chat", body, {"Content-Type": "application/json"})
        try:
            resp = json.load(urllib.request.urlopen(req, timeout=170))
            text = resp.get("message", {}).get("content", "")
        except Exception as e:
            text = "ERROR %s" % e
        rec = {"model": model, "cond": cond, "id": c["id"], "answer": text,
               "secs": round(time.time() - t0, 1)}
        if cond == "D":   # the verdict the code made leads; the model's own words are kept beside it
            rec["raw"] = text; rec["answer"] = decide(text) + "\n" + text
        with open(out_p, "a", encoding="utf-8") as f: f.write(json.dumps(rec) + "\n")
        n += 1
    print("run-local: %s %s: %d new answer(s)" % (model, cond, n))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
