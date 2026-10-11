#!/usr/bin/env python3
"""mutants_consent.py -- does consent_check.sh --prove-red notice when a rule is switched off?

Each mutant disables one rule in a scratch copy of consent_check.awk and runs --prove-red there.
A mutant that still gets exit 0 has SURVIVED: no plant pins that rule.
  python3 mutants_consent.py [SCRATCH_DIR]     exit 0 iff every mutant is killed
SPDX-License-Identifier: GPL-3.0-or-later
"""
import os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
MUTANTS = [  # (rule, text in consent_check.awk, replacement)
    ("G1.2 blanket parks", 'res("G1.2", "PARK"', 'res("G1.2", "NOTE"'),
    ("G2.3 600s deferral", "er - ei_ < 600", "er - ei_ < 60"),
    ("G3.2 hash compare", "if (tolower(sha) != ps)", "if (0)"),
    ("G4.3 independence", 'nrd < 2) res("G4.3"', 'nrd < 1) res("G4.3"'),
    ("G4.2 userinfo strip", 'sub(/^.*@/, "", a); ', ""),
    ("G4.4 served-key compare", "if (skfp[U[j]] != fp)", "if (0)"),
    ("G5.4 other-signs", 'res("G5.4", "FAIL"', 'res("G5.4", "NOTE"'),
    ("G6.4 agent-held no lift", 'res("G6.4", "PARK"', 'res("G6.4", "NOTE"'),
    ("N1.1 NO4C raise", 'N[O0]4C([ \\t:.,;!]|$)/) res("N1.1"', 'N[O0]4CX/) res("N1.1"'),
    ("P6 duplicate key", 'res("P6", "FAIL"', 'res("P6", "NOTE"'),
    ("HL3 third-party email", 'if (e != iprin) res("HL3.1", "PARK"', 'if (0) res("HL3.1", "PARK"'),
]

def main():
    base = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
    src = open(os.path.join(HERE, "consent_check.awk")).read()
    survivors = 0
    for rule, a, b in MUTANTS:
        if a not in src:
            print(f"STALE  {rule}: mutation text not found"); survivors += 1; continue
        w = os.path.join(base, "w"); shutil.rmtree(w, ignore_errors=True); os.makedirs(w)
        for f in ("consent_check.sh", "consent_prove_red.sh"):
            shutil.copy(os.path.join(HERE, f), w)
        open(os.path.join(w, "consent_check.awk"), "w").write(src.replace(a, b, 1))
        r = subprocess.run(["sh", os.path.join(w, "consent_check.sh"), "--prove-red"], capture_output=True, text=True)
        miss = [l.split()[1] for l in r.stdout.splitlines() if l.startswith("MISS")]
        if r.returncode == 0:
            survivors += 1; print(f"SURVIVED {rule}")
        else:
            print(f"killed   {rule}: caught by {', '.join(miss)}")
    print(f"mutants: {len(MUTANTS) - survivors}/{len(MUTANTS)} killed")
    return 0 if survivors == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
