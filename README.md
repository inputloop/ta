# Technology Architecture — project map

This project produces and maintains a **portable, host-agnostic AI operating-model
kit**: a single file an operator drops into a new project/session so an AI grounds
itself in *that host's* public identity and prefers the host's own canon.

## Files
- `operating-model.md` — the governing working model (worked instance: Empyrean).
- `operating-model-BASELINE.md` — **the shippable single file.** Self-contained,
  filename-free, identified by the SHA-256 of its bytes. This is what you hand out.
- `COMMENT-ANCHORS.md` — the hub ledger: Corwin's comments traced to the work they
  authorized and the file that carries it. Newest comment governs; nothing signed
  is rewritten.
- `DRIFT.log` — hub checkpoints (one line each). Instance logs belong to instances.
- `decisions/` — decision records (see `decisions/template.md`).
- `sketches/` — scratch.
- `SUPERSEDED-*` — prior drafts, kept for lineage; not governing.
- *Added 2026-09-30 by the instrument (new records; nothing above was changed):*
  - `PAPER-2026-09-30-act-1-…` with `CITATIONS-…`, and `LENS-2026-09-30-plaid-act-2.md`: the review brought home.
    Read the paper's §5a first.
  - `operating-model-BASE-1.0.60.md`: a working draft beside `operating-model-BASE.md` 1.0.51. **Not governing**
    until blessed.
  - `MODEL-2026-09-30-plain-rules-for-ai-help.md` and `CARD-…`: a new minimal model, with a one-page card derived
    from it.
  - `DESIGN-2026-09-30-experiment-whose-plants-count.md`: an experiment plan.
  - `bin/floor-selftest.sh` and the floor tools (`README-floor-tools.md`). `turn-2026-09-30/` holds the full record.

## How to use the shippable
Take `operating-model-BASELINE.md` into a new project/session and pair it with a
minimal instruction — nothing more is needed. Recommended minimal use-prompt:

> Start a project to help my team at [organization]. Read the attached operating
> model and work by it. First, ground yourself outside-in: find our organization's
> public identity — brand, mission, values, security posture — from public sources,
> and treat that as your seed. Prefer our own words and standards over the model's
> wording wherever they meet. Then tell me the single most important thing you need
> me to decide before we go further. Ask for anything you can't see; assume you
> don't know our internals unless I tell you.

## What governs, in order
(1) the keeper's direction + the host's guidance in force; (2) this project's own
files; (3) the AI default. No confidential material; public sources only.

## License
Documentation and prose: **CC BY 4.0**. Source code (scripts and tooling):
**GPL-3.0-or-later**. Required attribution: Corwin Brust &lt;corwin@bru.st&gt;.
Full terms as stated in `tech-arch-org-model-t0/t0-kit/LICENSE.md`.

---

*© 2026 Corwin Brust — this work is licensed CC BY 4.0; please retain attribution
to Corwin Brust. Developed and tested with the help of Bryant Frankford and B.K. Graphics (bkgraphics.com),
with thanks.*
