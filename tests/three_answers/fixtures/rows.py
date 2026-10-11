#!/usr/bin/env python3
"""rows.py -- the P1B tool list, written as readable Python, emitted as tools.tsv for three_answers.py.

Every invocation below was derived from the tool's OWN usage text (the `source` column names the lines).
Snippets never carry a literal tab: where a tab is data, they write $(printf '\\t') or printf '\\t'.
usage: python3 fixtures/rows.py > tools.tsv
"""
import sys

TAB = "$(printf '\\t')"
KIT = "t0:t0-kit"
TA = "ta:.!imports"
BOOKHDR = 'head -1 "$FX/t2-book.tsv"'
VT_PREP = 'mkdir -p "$W/bin" && cp "$FX/fake-curl" "$W/bin/curl" && chmod +x "$W/bin/curl"'
SUMLINE = 'printf \'%s *artifact.zip\\n\' "$(printf a | sha256sum | cut -d\' \' -f1)" > "$IN"'
XROOT = 'mkdir -p "$IN" "$W/root" && printf \'fx\\t%s\\n\' "$W/root" > "$W/roots.tsv"'
XEXISTS = 'printf \'### FX-002: Second entry\\nx\\n\' > "$W/root/exists.md"'
T2ASOF = 'mkdir -p "$T/records" && echo 2026-09-16 > "$T/records/ASOF"'
INTAKE_ENV = 'INTAKE_LEDGER="$W/intake.tsv" INTAKE_TUNNELS="$W/tunnels" INTAKE_PROVENANCE="$W/prov.tsv"'
INTAKE_GOOD = ('mkdir -p "$IN" && printf \'tester\\n\' > "$IN/SOURCE" && '
               'printf \'a bundle file; its falsifier: run --prove-red\\n\' > "$IN/a.txt" && '
               '(cd "$IN" && sha256sum a.txt > SHA256SUMS) && '
               'printf \'tester\\t^evidence/intake\\\\.tsv$\\tappend\\tx\\tx\\tin-force\\n\' > "$W/tunnels"')
SEAT_GOOD = ('mkdir -p "$IN" && printf -- \'---\\nname: real\\ndescription: x\\nmetadata:\\n  type: user\\n---\\nbody\\n\' > "$IN/real.md"'
             ' && printf \'# MEMORY\\n- [real](real.md) -- ok\\n\' > "$IN/MEMORY.md"')
RISKHDR = 'head -1 "$T/risks-lab-teardown.tsv" > "$IN"'
BEARHDR = 'head -1 "$T/bearing-lab-teardown.tsv" > "$IN"'
MG_GOOD = ('head -1 "$T/measures.tsv" > "$W/m.tsv" && grep "^guess_delta' + TAB + '" "$T/measures.tsv" >> "$W/m.tsv" && '
           'grep "^guess_calib' + TAB + '" "$T/measures.tsv" >> "$W/m.tsv" && head -1 "$T/probes.tsv" > "$W/p.tsv" && '
           'grep "^guess_delta' + TAB + '" "$T/probes.tsv" >> "$W/p.tsv" && grep "^guess_calib' + TAB + '" "$T/probes.tsv" >> "$W/p.tsv"')
SELFHDR = "printf 'set\\tname\\ttree\\tcmd\\tempty\\tgood\\tbad\\tsource\\n' > \"$IN\""

ROWS = [
    # set, name, tree, cmd, empty, good, bad, source
    # ---- t0 kit: the four top-level scripts
    ("P", "t0:t0-kit/check-all.sh", KIT, 'sh "$T/check-all.sh"',
     'find "$T" -mindepth 1 -maxdepth 1 ! -name check-all.sh -exec rm -rf {} +', ':',
     'printf \'tamper\\n\' >> "$T/operating-model-BASELINE.md"', "t0:t0-kit/check-all.sh#L2-L6"),
    ("P", "t0:t0-kit/selftest.sh", KIT, 'sh "$T/selftest.sh"', ': > "$T/SHA256SUMS"', ':',
     '{ cat "$T/operating-model-BASELINE.md"; printf \'\\n# tamper\\n\'; } | sha256sum | sed \'s/-$/operating-model-BASELINE.md/\' > "$W/s" && cp "$W/s" "$T/SHA256SUMS"',
     "t0:t0-kit/selftest.sh#L2-L4"),
    ("P", "t0:t0-kit/verify.sh", KIT, 'sh "$T/verify.sh"', ': > "$T/SHA256SUMS"', ':',
     'printf \'tamper\\n\' >> "$T/operating-model-BASELINE.md"', "t0:t0-kit/verify.sh#L6"),
    ("P", "t0:t0-kit/ship.sh check", KIT, 'sh "$T/ship.sh" check "$IN"', 'mkdir -p "$IN"',
     'sh "$T/ship.sh" stage "$T" "$IN" >/dev/null', 'cp -r "$T" "$IN"', "t0:t0-kit/ship.sh#L10-L12"),
    # ---- t0 kit: module checks
    ("P", "t0:t0-kit/portability/portable-check.sh scan", KIT, 'sh "$T/portability/portable-check.sh" scan "$IN"',
     'mkdir -p "$IN"', 'mkdir -p "$IN" && cp "$T/portability/fixtures/good.sh" "$IN/"',
     'mkdir -p "$IN" && cp "$T/portability/fixtures/bad.sh" "$IN/"', "t0:t0-kit/portability/portable-check.sh#L10-L12"),
    ("P", "t0:t0-kit/test-tiers/tier-gate.sh check", KIT, 'sh "$T/test-tiers/tier-gate.sh" check T2 "$(cat "$IN")"',
     ': > "$IN"', "printf 'T0 T1 T2' > \"$IN\"", "printf 'T0 T1' > \"$IN\"", "t0:t0-kit/test-tiers/tier-gate.sh#L9-L13"),
    ("P", "t0:t0-kit/cartridge/cartridge-check.sh", KIT, 'sh "$T/cartridge/cartridge-check.sh"',
     ': > "$T/cartridge/CARTRIDGE.md" && : > "$T/operating-model-BASELINE.md"', ':',
     'grep -v "Name the opening" "$T/cartridge/CARTRIDGE.md" > "$W/c" && cp "$W/c" "$T/cartridge/CARTRIDGE.md"',
     "t0:t0-kit/cartridge/cartridge-check.sh#L9-L10"),
    ("P", "t0:t0-kit/router/router.sh route", KIT, 'sh "$T/router/router.sh" route "$IN"', ': > "$IN"',
     'cp "$T/router/fixtures/steps.tsv" "$IN"', '-', "t0:t0-kit/router/router.sh#L11-L13"),
    ("P", "t0:t0-kit/methodclean/methodclean-check.sh scan", KIT, 'sh "$T/methodclean/methodclean-check.sh" scan "$IN"',
     'mkdir -p "$IN"', 'mkdir -p "$IN" && printf \'# example\\nThe host grounds outside-in in its own public identity.\\n\' > "$IN/good.md"',
     'mkdir -p "$IN" && printf \'This names C4 and our lab directly in shipped prose.\\n\' > "$IN/bad.md"',
     "t0:t0-kit/methodclean/methodclean-check.sh#L10-L12"),
    ("P", "t0:t0-kit/org-kinds/org-kind.sh selftest", KIT, 'sh "$T/org-kinds/org-kind.sh" selftest',
     ': > "$T/org-kinds/org-kinds.tsv"', ':', '-', "t0:t0-kit/org-kinds/org-kind.sh#L9-L11"),
    ("P", "t0:t0-kit/ceremony/ceremony-gen.sh emit+run", KIT,
     'sh "$T/ceremony/ceremony-gen.sh" emit demo "$(cat "$IN")" "echo ran" > "$W/card.sh" && sh "$W/card.sh"',
     ': > "$IN"', 'printf \'[ -f "%s/flag" ]\' "$W" > "$IN" && : > "$W/flag"', 'printf \'[ -f "%s/absent" ]\' "$W" > "$IN"',
     "t0:t0-kit/ceremony/ceremony-gen.sh#L9-L10"),
    ("P", "t0:t0-kit/tags/tag-resolve.sh lint", KIT, 'sh "$T/tags/tag-resolve.sh" lint "$IN"', ': > "$IN"',
     'cp "$T/tags/tags.tsv" "$IN"',
     "printf 'tag\\tvalue\\tappropriate_use\\tsource_of_truth\\trelevance\\tcurrency\\tverification\\tcategory\\nx\\t9\\tuse\\t\\t\\t\\t\\t\\n' > \"$IN\"",
     "t0:t0-kit/tags/tag-resolve.sh#L13-L16"),
    ("P", "t0:t0-kit/tension/tension-grade.sh", KIT, 'sh "$T/tension/tension-grade.sh" "$IN"', ': > "$IN"',
     'cp "$T/tension/fixtures/scores-converged.tsv" "$IN"', 'cp "$T/tension/fixtures/scores-divergent.tsv" "$IN"',
     "t0:t0-kit/tension/tension-grade.sh#L16-L18"),
    ("P", "t0:t0-kit/provenance/provenance-check.sh scan", KIT, 'sh "$T/provenance/provenance-check.sh" scan "$IN"',
     ': > "$IN"', 'cp "$T/provenance/fixtures/claims-good.tsv" "$IN"', 'cp "$T/provenance/fixtures/claims-bad.tsv" "$IN"',
     "t0:t0-kit/provenance/provenance-check.sh#L11"),
    ("P", "t0:t0-kit/coverage/coverage-gate.sh check", KIT, 'sh "$T/coverage/coverage-gate.sh" check "$T" "$IN"',
     ': > "$IN"', 'cp "$T/coverage/fixtures/clauses-good.tsv" "$IN"', 'cp "$T/coverage/fixtures/clauses-bad.tsv" "$IN"',
     "t0:t0-kit/coverage/coverage-gate.sh#L9-L15"),
    ("P", "t0:t0-kit/dispositive/independence-check.sh", KIT, 'sh "$T/dispositive/independence-check.sh" "$IN"',
     ': > "$IN"', 'cp "$T/dispositive/fixtures/run-independent.tsv" "$IN"', 'cp "$T/dispositive/fixtures/run-selfgraded.tsv" "$IN"',
     "t0:t0-kit/dispositive/independence-check.sh#L14"),
    ("P", "t0:t0-kit/dispositive/score.py", KIT, 'python3 "$T/dispositive/score.py" "$T/dispositive/KEY.tsv" "$IN"',
     "printf 'token\\tfidelity\\tcomprehension\\n' > \"$IN\"", 'cp "$T/dispositive/GRADES_pass_SYNTH.tsv" "$IN"', '-',
     "t0:t0-kit/dispositive/score.py#L2-L7"),
    ("P", "t0:t0-kit/precedence/precedence-check.sh scan", KIT, 'sh "$T/precedence/precedence-check.sh" scan "$IN"',
     ': > "$IN"', 'cp "$T/precedence/fixtures/rule-good.md" "$IN"', 'cp "$T/precedence/fixtures/rule-bad.md" "$IN"',
     "t0:t0-kit/precedence/precedence-check.sh#L13-L15"),
    ("P", "t0:t0-kit/epmo/epmo-check.sh reconcile", KIT, 'sh "$T/epmo/epmo-check.sh" reconcile "$T/epmo/fixtures/tree" "$IN"',
     ': > "$IN"', 'cp "$T/epmo/fixtures/ledger-good.tsv" "$IN"', 'cp "$T/epmo/fixtures/ledger-bad.tsv" "$IN"',
     "t0:t0-kit/epmo/epmo-check.sh#L11"),
    ("P", "t0:t0-kit/retro/retro.sh link", KIT, 'sh "$T/retro/retro.sh" link "$IN" "$T/coverage/clauses.tsv"',
     ': > "$IN"', 'cp "$T/retro/fixtures/corrections-good.tsv" "$IN"', 'cp "$T/retro/fixtures/corrections-bad.tsv" "$IN"',
     "t0:t0-kit/retro/retro.sh#L10"),
    ("P", "t0:t0-kit/git/git-deference-proof.sh status", KIT, 'cd "$IN" && sh "$T/git/git-deference-proof.sh" status',
     'mkdir -p "$IN"', 'mkdir -p "$IN" && git -C "$IN" init -q', '-', "t0:t0-kit/git/git-deference-proof.sh#L22-L26"),
    ("P", "t0:t0-kit/test-synthesis/guard.test.sh", KIT, 'sh "$T/test-synthesis/guard.test.sh"', ':',
     'mkdir -p "$W/dist" && printf zip-bytes > "$W/dist/kit.zip" && cp "$FX/preflight-sign.sh" "$T/test-synthesis/preflight-sign.sh"',
     'mkdir -p "$W/dist" && printf zip-bytes > "$W/dist/kit.zip" && printf \'#!/bin/sh\\nexit 0\\n\' > "$T/test-synthesis/preflight-sign.sh"',
     "t0:t0-kit/test-synthesis/guard.test.sh#L2-L7"),
    ("P", "t0:t0-kit/test-synthesis/hold-filter.test.sh", KIT, 'sh "$T/test-synthesis/hold-filter.test.sh"',
     ': > "$T/test-synthesis/hold-filter.sh"', ':',
     'printf \'#!/bin/sh\\ncat\\necho "withheld: 2 item(s)" >&2\\n\' > "$T/test-synthesis/hold-filter.sh"',
     "t0:t0-kit/test-synthesis/hold-filter.test.sh#L2"),
    # ---- t0 intermediary: the citation gate
    ("P", "t0:intermediary/bin/xref-check.sh check", "t0:intermediary",
     'XREF_ROOTS="$W/roots.tsv" sh "$T/bin/xref-check.sh" check "$IN"', XROOT,
     XROOT + ' && ' + XEXISTS + ' && cp "$T/bin/fixtures/good.md" "$IN/"',
     XROOT + ' && ' + XEXISTS + ' && cp "$T/bin/fixtures/bad.md" "$IN/"', "t0:intermediary/bin/xref-check.sh#L2-L6"),
    # ---- ta: the home tools
    ("P", "ta:bin/measure-guard.sh", TA, 'sh "$T/bin/measure-guard.sh" "$W/m.tsv" "$W/p.tsv"',
     'head -1 "$T/measures.tsv" > "$W/m.tsv" && head -1 "$T/probes.tsv" > "$W/p.tsv"', MG_GOOD,
     'cp "$T/measures.tsv" "$W/m.tsv" && cp "$T/probes.tsv" "$W/p.tsv"', "ta:bin/measure-guard.sh#L16-L17"),
    ("P", "ta:bin/riskcell.sh", TA, 'sh "$T/bin/riskcell.sh" "$IN" 75', RISKHDR,
     RISKHDR + " && printf 'X4\\tsomething bad\\t40\\ttwo of five prior runs, logged\\t200\\t-\\treplacement part, whole dollars\\t1\\tDRIFT.log 2026-08-28\\n' >> \"$IN\"",
     RISKHDR + " && printf 'X1\\tsomething bad\\tUNMEASURED\\t-\\t100\\t-\\ta named fee\\t0\\tsomewhere\\n' >> \"$IN\"",
     "ta:bin/riskcell.sh#L15-L16"),
    ("P", "ta:bin/bearing.sh", TA, 'sh "$T/bin/bearing.sh" "$IN" 20', BEARHDR,
     BEARHDR + " && printf 'OK1\\tcalibrated claim\\t1\\t3\\t4\\t3\\t4\\tread\\tlogged prior runs\\n' >> \"$IN\"",
     BEARHDR + " && printf 'X6\\tno rung declared\\t\\t3\\t4\\t3\\t4\\tread\\tsomething\\n' >> \"$IN\"",
     "ta:bin/bearing.sh#L22-L23"),
    ("P", "ta:bin/selftest.sh", TA, 'sh "$T/bin/selftest.sh" "$IN"', 'mkdir -p "$IN"', 'ln -s "$T" "$IN"', '-',
     "ta:bin/selftest.sh#L13-L14"),
    ("P", "ta:CHECK-baseline.sh", TA, 'sh "$T/CHECK-baseline.sh"',
     'find "$T" -mindepth 1 -maxdepth 1 ! -name CHECK-baseline.sh -exec rm -rf {} +', ':',
     'printf x >> "$T/RISK-CANON.md"', "ta:CHECK-baseline.sh#L4-L5"),
    ("P", "ta:bin/import-log.sh verify", "ta:.", 'sh "$T/bin/import-log.sh" verify',
     'head -1 "$T/IMPORT-LOG.tsv" > "$W/h" && cp "$W/h" "$T/IMPORT-LOG.tsv"', ':',
     'printf x >> "$T/imports/t0/intermediary/OFFERING-2026-09-30.md"', "ta:bin/import-log.sh#L9"),
    # ---- publications
    ("P", "pub-new:papers/every-rule-carries-its-ring/ring-dry-run.sh check", "pub-new:papers/every-rule-carries-its-ring",
     'sh "$T/ring-dry-run.sh" check "$W/door" "$IN"', 'mkdir -p "$W/door" && : > "$IN"',
     'cp -r "$R_c4/d/door" "$W/door" && cp "$W/door/RINGS.tsv" "$IN"',
     'cp -r "$R_c4/d/door" "$W/door" && sed "/^keeper-top-block' + TAB + '/d" "$W/door/RINGS.tsv" > "$IN"',
     "pub-new:papers/every-rule-carries-its-ring/ring-dry-run.sh#L6-L11"),
    ("P", "pub-claude:CSDW/csdw.sh --init P DICT, --to-format P tsv", "pub-claude:CSDW",
     'sh "$T/csdw.sh" --init "$W/proj" "$IN" && sh "$T/csdw.sh" --to-format "$W/proj" tsv', ': > "$IN"',
     "printf 'term\\tgloss\\nalpha\\tthe first letter\\n' > \"$IN\"", '-', "pub-claude:CSDW/csdw.sh#L40-L47"),
    # ---- polygram
    ("P", "polygram:skills/consent-gate/scripts/verify_consent.sh", "polygram:skills/consent-gate/scripts",
     'sh "$T/verify_consent.sh" --record "$IN"', ': > "$IN"', 'sh "$FX/consent-rec.sh" "$IN"',
     'sh "$FX/consent-rec.sh" "$IN" ALL', "polygram:skills/consent-gate/scripts/verify_consent.sh#L12-L13"),
    ("P", "polygram:bin/dl2-verify.sh", "polygram:bin", 'sh "$T/dl2-verify.sh" "$IN"', 'mkdir -p "$IN"',
     'python3 "$FX/dl2_mkchain.py" "$IN" 2', 'python3 "$FX/dl2_mkchain.py" "$IN" 2 --tamper', "polygram:bin/dl2-verify.sh#L24-L30"),
    ("P", "polygram:bin/ms1dg", "polygram:bin", 'sh "$T/ms1dg" --seat "$IN" --auto none', 'mkdir -p "$IN"', SEAT_GOOD,
     SEAT_GOOD + ' && printf \'%s\\n\' \'- [ghost](ghost.md) -- missing\' >> "$IN/MEMORY.md"', "polygram:bin/ms1dg#L21"),
    # ---- c4 instruments
    ("P", "c4:bin/door check", "c4:.", 'sh "$T/bin/door" check "$IN"', ': > "$IN"',
     'sh "$T/bin/door" render --scope global > "$IN"',
     'sh "$T/bin/door" render --scope global > "$IN" && printf \'\\nedited after render\\n\' >> "$T/d/door/00-keeper-top-block.part"',
     "c4:bin/door#L53"),
    ("P", "c4:bin/kt1wr --unsourced", "c4:.", 'sh "$T/bin/kt1wr" --unsourced "$IN"', ': > "$IN"',
     "printf 'Corwin: a reader is named before any signature is asked for -- his words, never skipped.\\n' > \"$IN\"", '-',
     "c4:bin/kt1wr#L42-L48"),
    ("P", "c4:bin/whose", "c4:.", 'sh "$T/bin/whose" "$IN"', ': > "$IN"', 'cp "$T/bin/door" "$IN"', '-',
     "c4:bin/whose#L34-L37"),
    ("P", "c4:bin/sw1ng open", "c4:.",
     'SWING_FILE="$W/SWING" sh "$T/bin/sw1ng" open TASK --design "$IN.design" --qaplan "$IN.qa"',
     ': > "$IN.design" && : > "$IN.qa"',
     "printf 'design: a real design\\n' > \"$IN.design\" && printf 'qa: run the whole plan\\n' > \"$IN.qa\"",
     ': > "$IN.qa"', "c4:bin/sw1ng#L93-L94"),
    ("P", "c4:bin/da1te stamp", "c4:.", 'DA1TE_TOP="$IN" sh "$T/bin/da1te" stamp "$IN"', 'mkdir -p "$IN" && : > "$IN/DATE"',
     "mkdir -p \"$IN\" && printf '%s\\t%sT00:00Z\\tp1b\\tfrom=-\\n' \"$(date -u +%F)\" \"$(date -u +%F)\" > \"$IN/DATE\"",
     "mkdir -p \"$IN\" && printf '%s\\t%sT00:00Z\\tp1b\\tfrom=-\\n' \"$(date -u -d yesterday +%F)\" \"$(date -u -d yesterday +%F)\" > \"$IN/DATE\"",
     "c4:bin/da1te#L78-L81"),
    ("P", "c4:bin/intake check", "c4:.", INTAKE_ENV + ' sh "$T/bin/intake" check "$IN"', 'mkdir -p "$IN"', INTAKE_GOOD,
     INTAKE_GOOD + ' && printf y >> "$IN/a.txt"', "c4:bin/intake#L4-L9"),
    ("P", "c4:bin/rc1rn next", "c4:.", 'sh "$T/bin/rc1rn" "$IN" next', ': > "$IN"',
     'cp "$FX/card-good.rc" "$IN" && : > "$W/marker"', 'cp "$FX/card-needfail.rc" "$IN"', "c4:bin/rc1rn#L18-L24"),
    # ---- t2 ops instruments
    ("P", "t2:ops/bin/bc0mf --verify", "t2:ops", 'sh "$T/bin/bc0mf" --verify',
     "printf 'path\\tsha256\\tbytes\\n' > \"$T/ledger/MANIFEST.tsv\"", 'sh "$T/bin/bc0mf" --write >/dev/null',
     'sh "$T/bin/bc0mf" --write >/dev/null && printf x >> "$T/README.md"', "t2:ops/bin/bc0mf#L3"),
    ("P", "t2:ops/bin/bc1in --say", "t2:ops", 'sh "$T/bin/bc1in" --say -a 2026-09-16 -f "$IN"', BOOKHDR + ' > "$IN"',
     'cp "$FX/t2-book.tsv" "$IN"', '-', "t2:ops/bin/bc1in#L7-L10"),
    ("P", "t2:ops/bin/bc2ck --say", "t2:ops", 'perl "$T/bin/bc2ck" --say -a 2026-09-16 -f "$IN"', BOOKHDR + ' > "$IN"',
     'cp "$FX/t2-book.tsv" "$IN"', 'sed "s/inquiry-unanswered/a-kind-nobody-agreed-to/" "$FX/t2-book.tsv" > "$IN"',
     "t2:ops/bin/bc2ck#L12-L13"),
    ("P", "t2:ops/bin/bc3x --say", "t2:ops", 'sh "$T/bin/bc3x" --say -f "$IN"', T2ASOF + ' && ' + BOOKHDR + ' > "$IN"',
     T2ASOF + ' && cp "$FX/t2-book.tsv" "$IN"',
     T2ASOF + ' && awk -F"' + TAB + '" -v OFS="' + TAB + '" \'$1=="BC-101"{$4="OPEN";$6="2020-13-45"} {print}\' "$FX/t2-book.tsv" > "$IN"',
     "t2:ops/bin/bc3x#L16"),
    ("P", "t2:ops/bin/bc4st", "t2:ops", 'sh "$T/bin/bc4st"', T2ASOF + ' && ' + BOOKHDR + ' > "$T/records/intake.tsv"',
     T2ASOF + ' && cp "$FX/t2-book.tsv" "$T/records/intake.tsv"', '-', "t2:ops/bin/bc4st#L2-L9"),
    # ---- t1
    ("P", "t1:fabel-alt/out/A2/vt-hashcheck.sh --fail-on 1", "t1:fabel-alt/out/A2",
     'PATH="$W/bin:$PATH" VT_API_KEY=fake FAKE_VT_BODY="$W/body.json" sh "$T/vt-hashcheck.sh" --fail-on 1 "$IN"',
     VT_PREP + ' && : > "$IN"', VT_PREP + ' && ' + SUMLINE + ' && cp "$FX/vt-clean.json" "$W/body.json"',
     VT_PREP + ' && ' + SUMLINE + ' && cp "$FX/vt-flagged.json" "$W/body.json"',
     "t1:fabel-alt/out/A2/vt-hashcheck.sh#L33-L36"),

    # ================= supplementary probes: half-empty inputs, blind evidence, documented usage
    ("S", "S:cartridge-check, model file absent", KIT, 'sh "$T/cartridge/cartridge-check.sh"',
     'rm -f "$T/operating-model-BASELINE.md"', ':', '-', "t0:t0-kit/cartridge/cartridge-check.sh#L25-L27"),
    ("S", "S:precedence-check scan, named file does not exist", KIT, 'sh "$T/precedence/precedence-check.sh" scan "$IN"',
     'rm -f "$IN"', 'cp "$T/precedence/fixtures/rule-good.md" "$IN"', '-', "t0:t0-kit/precedence/precedence-check.sh#L29"),
    ("S", "S:ship.sh check, named dir does not exist", KIT, 'sh "$T/ship.sh" check "$IN"', 'rm -rf "$IN"',
     'sh "$T/ship.sh" stage "$T" "$IN" >/dev/null', '-', "t0:t0-kit/ship.sh#L20-L26"),
    ("S", "S:independence-check, manifest names only a grader", KIT, 'sh "$T/dispositive/independence-check.sh" "$IN"',
     "printf 'grader\\tcarol\\n' > \"$IN\"", 'cp "$T/dispositive/fixtures/run-independent.tsv" "$IN"', '-',
     "t0:t0-kit/dispositive/independence-check.sh#L5-L7"),
    ("S", "S:score.py, empty KEY with real grades", KIT, 'python3 "$T/dispositive/score.py" "$IN" "$T/dispositive/GRADES_pass_SYNTH.tsv"',
     "printf 'token\\tkind\\tref\\ttag\\tweight\\texpect\\n' > \"$IN\"", 'cp "$T/dispositive/KEY.tsv" "$IN"', '-',
     "t0:t0-kit/dispositive/score.py#L2-L4"),
    ("S", "S:score.py, known-VOID grades as the bad input", KIT, 'python3 "$T/dispositive/score.py" "$T/dispositive/KEY.tsv" "$IN"',
     "printf 'token\\tfidelity\\tcomprehension\\n' > \"$IN\"", 'cp "$T/dispositive/GRADES_pass_SYNTH.tsv" "$IN"',
     'cp "$T/dispositive/GRADES_void_SYNTH.tsv" "$IN"', "t0:t0-kit/dispositive/score.py#L2-L4"),
    ("S", "S:tag-resolve inlined, empty dictionary", KIT, 'sh "$T/tags/tag-resolve.sh" inlined "$W/target.md" "$IN"',
     ': > "$IN" && cp "$T/tags/fixtures/inline-bad.md" "$W/target.md"',
     'cp "$T/tags/tags.tsv" "$IN" && cp "$T/tags/fixtures/ref-good.md" "$W/target.md"',
     'cp "$T/tags/tags.tsv" "$IN" && cp "$T/tags/fixtures/inline-bad.md" "$W/target.md"', "t0:t0-kit/tags/tag-resolve.sh#L15"),
    ("S", "S:xref-check, models dir holding one file with no entries", "t0:intermediary",
     'XREF_ROOTS="$W/roots.tsv" sh "$T/bin/xref-check.sh" check "$IN"',
     XROOT + ' && printf \'# a model file with no entries\\n\' > "$IN/none.md"',
     XROOT + ' && ' + XEXISTS + ' && cp "$T/bin/fixtures/good.md" "$IN/"', '-', "t0:intermediary/bin/xref-check.sh#L2-L3"),
    ("S", "S:measure-guard, zero-byte measures file with real probes", TA, 'sh "$T/bin/measure-guard.sh" "$W/m.tsv" "$W/p.tsv"',
     ': > "$W/m.tsv" && cp "$T/probes.tsv" "$W/p.tsv"', MG_GOOD, '-', "ta:bin/measure-guard.sh#L58-L64"),
    ("S", "S:intake check, bundle with an empty SHA256SUMS", "c4:.", INTAKE_ENV + ' sh "$T/bin/intake" check "$IN"',
     INTAKE_GOOD + ' && : > "$IN/SHA256SUMS"', INTAKE_GOOD, '-', "c4:bin/intake#L10-L12"),
    ("S", "S:kt1wr trace, empty record", "c4:.", 'C4_ROOT="$IN" SEAT="$IN/seat" sh "$T/bin/kt1wr" widgetfoo',
     'mkdir -p "$IN"', "mkdir -p \"$IN/facts\" && printf 'widgetfoo is his -- Corwin: his words, 2026-06-29.\\n' > \"$IN/facts/a.md\"",
     '-', "c4:bin/kt1wr#L44-L48"),
    ("S", "S:vt-hashcheck, empty response body", "t1:fabel-alt/out/A2",
     'PATH="$W/bin:$PATH" VT_API_KEY=fake FAKE_VT_BODY="$W/body.json" sh "$T/vt-hashcheck.sh" --fail-on 1 "$IN"',
     VT_PREP + ' && ' + SUMLINE, VT_PREP + ' && ' + SUMLINE + ' && cp "$FX/vt-clean.json" "$W/body.json"', '-',
     "t1:fabel-alt/out/A2/vt-hashcheck.sh#L96-L97"),
    ("S", "S:vt-hashcheck, API key empty", "t1:fabel-alt/out/A2",
     'PATH="$W/bin:$PATH" VT_API_KEY="$(cat "$W/key")" FAKE_VT_BODY="$W/body.json" sh "$T/vt-hashcheck.sh" --fail-on 1 "$IN"',
     VT_PREP + ' && : > "$W/key" && cp "$FX/vt-flagged.json" "$W/body.json" && ' + SUMLINE,
     VT_PREP + ' && echo fake > "$W/key" && cp "$FX/vt-clean.json" "$W/body.json" && ' + SUMLINE, '-',
     "t1:fabel-alt/out/A2/vt-hashcheck.sh#L28-L34"),
    ("S", "S:CSDW documented example --init P --dict FILE", "pub-claude:CSDW",
     'sh "$T/csdw.sh" --init "$W/proj" --dict "$IN"', ': > "$IN"', "printf 'term\\tgloss\\nalpha\\tthe first letter\\n' > \"$IN\"",
     '-', "pub-claude:CSDW/csdw.sh#L60"),
    ("S", "S:bc3x --tsv (the mode bc4st case 20 tests)", "t2:ops", 'sh "$T/bin/bc3x" --tsv -f "$IN"',
     T2ASOF + ' && ' + BOOKHDR + ' > "$IN"', T2ASOF + ' && cp "$FX/t2-book.tsv" "$IN"',
     T2ASOF + ' && awk -F"' + TAB + '" -v OFS="' + TAB + '" \'$1=="BC-101"{$4="OPEN";$6="2020-13-45"} {print}\' "$FX/t2-book.tsv" > "$IN"',
     "t2:ops/bin/bc3x#L16"),
    ("S", "S:door render, empty parts dir", "c4:.", 'DOOR_PARTS="$IN" sh "$T/bin/door" render --scope global',
     'mkdir -p "$IN"', 'cp -r "$T/d/door" "$IN"', '-', "c4:bin/door#L52"),
    ("S", "S:three_answers.py itself (census over a tool list)", "-", 'python3 "$HARNESS" census "$IN" --workdir "$W/hw"',
     SELFHDR,
     SELFHDR + " && printf '#!/bin/sh\\n[ -s \"$1\" ] || exit 77\\necho ok\\n' > \"$W/h.sh\" && "
     "printf 'P\\tself:honest\\t-\\tsh %s/h.sh \"$IN\"\\t: > \"$IN\"\\tprintf x > \"$IN\"\\t-\\tself\\n' \"$W\" >> \"$IN\"",
     SELFHDR + " && printf 'P\\tself:blind\\t-\\ttrue\\t:\\t:\\t-\\tself\\n' >> \"$IN\"",
     "three_answers.py (module docstring, Exit)"),
]

COLS = ["set", "name", "tree", "cmd", "empty", "good", "bad", "source"]
out = sys.stdout
out.write("# P1B tool list -- generated by fixtures/rows.py; edit that file, not this one.\n")
out.write("\t".join(COLS) + "\n")
for r in ROWS:
    assert len(r) == 8, r
    for x in r:
        assert "\t" not in x and "\n" not in x, r
    out.write("\t".join(r) + "\n")
# SPDX-License-Identifier: GPL-3.0-or-later
