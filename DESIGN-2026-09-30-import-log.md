# DESIGN · 2026-09-30 · import-log — bringing material home with its provenance

**Status:** BUILT AS A TOOL, NOT A GATE. Working version `0.1.0` (three parts: working). Implementation
`bin/import-log.sh` (POSIX sh + awk); independent tests `tests/test_import_log.py` (Python 3, stdlib), written
from this document and not from the script. Signing is Corwin's pen; nothing here gates on a signature.

## What the source asked for, in his words (verbatim, 2026-09-30)

> (prep) bring in materials related to our work thinking in terms of posterity; create a IMPORT-LOG.tsv and
> tooling to make it easy to work with; create compaction capabilities so that it can write a JSON log containing
> records from more than two runs ago as tar.gz compressed slices of removed records, adding a LOG entry upon
> success that includes in its note unique and grouping identifier/tag values which are represented in the set of
> records truncated from the IMPORT-LOG before rotating in the truncated file, using the system date to ensure that
> records are not archived until two runs have passed since a IMPORT-LOG entry was added considering several runs
> on a single calendar date as a single run, and performing this check anytime the import-log.tsv contains greater
> than a given/configured (default: 4k) lines, doing that archiving work first before attempting the actual work
> with a plan to STOP in case the archiving step is required but cannot be completed unless a
> --continue-after-stop is given.  Support a --force-archiving option which suppresses the behavior of continue
> after stop as well as bypassing any configured or default (but not expressly given by command line option)
> threshold before triggering log archiving.

His word on the reading (2026-09-30): "that's all bless: excellent reading … especially good: 'whole earlier
dates' and the edit 3 design".

## The rules (each numbered so a test can cite it)

- **S1 · The log.** `IMPORT-LOG.tsv` at the TA root: one header line beginning `#`, then one record per line,
  twelve tab-separated fields: `id stamp day kind group source dest sha256 bytes tags status note`. `id` is
  `L` + six digits, strictly increasing, never reused. `stamp` is UTC. `day` is the **system's local date**
  (`date +%Y-%m-%d`), in the zone named by `tz=` in `.import/config` when one is set — the run key is the
  keeper's calendar date, so a shell that runs on UTC (a VM, a container) must not open tomorrow's run early. `kind` ∈ IMPORT · ARCHIVE · NOTE. A field never carries a tab or a line break.
- **S2 · Sources are named, not located.** `source` is `ALIAS:tree-relative-path`. The alias → directory map
  lives in `.import/roots.tsv` (or `--roots FILE`) and is never written into the log, so the log names where a
  thing lives in the work and never where one machine keeps it.
- **S3 · Import.** A file is copied to `imports/ALIAS/PATH`, re-hashed, and logged only if the copy hashes like its
  source. Identical bytes already home are not re-logged. Different bytes are status `CHANGED`: the prior copy is
  kept at `imports/.superseded/DAY/ALIAS/PATH.<sha16>` and the note says what it was (the observable tear). A
  directory imports every regular file under it except `.git/` and `--exclude` globs.
- **S4 · A run is a calendar date.** Several runs on one date are one run. The runs known to the log are the
  distinct `day` values it holds.
- **S5 · Two whole earlier dates.** A record is *eligible* for archiving when at least two distinct dates in the
  log fall strictly after its own date **and strictly before today**. Today is the run in progress and never
  counts as passed. A record with no usable date, or dated after today, is never eligible and is warned about.
  *Default kept loser:* count today as passed. *Flip:* his word that the current run counts.
- **S6 · Threshold.** The log's physical line count (header included) is compared with a threshold chosen, in
  order: `--max-lines N` on the command line; else `$IMPORT_LOG_MAX_LINES`; else `max_lines=` in
  `.import/config`; else **4000**. The source of the threshold is always reported (`cli`, `env`, `config`,
  `default`). A log *at* the threshold is not over it.
- **S7 · Archive first.** When the log is over the threshold, archiving is *required* and runs **before** the
  command's own work.
- **S8 · STOP.** If archiving is required and cannot be completed — nothing is eligible, or any step fails — the
  tool does nothing else and exits **3** (STOP), unless `--continue-after-stop`, which warns and does the work.
  *Default kept loser:* nothing-eligible is a quiet success. *Flip:* his word that an over-threshold log with
  nothing old enough should not stop work.
- **S9 · Which commands check.** Every command that reads or writes the live log (`add`, `note`, `say`, `ls`,
  `verify`, `archive`) runs the check first — "anytime". `stats` only reports what the check would do, so there
  is one way to look without acting. *Kept loser:* `stats` archives too. *Flip:* his word.
- **S10 · Force.** `--force-archiving` makes archiving required whatever the **configured or default** threshold
  says; a threshold **given on the command line** still decides. A forced archive that cannot be completed
  always STOPs: `--continue-after-stop` is suppressed, and the tool says so.
- **S11 · The slice.** Eligible records go into `archive/import-log/IMPORT-LOG-SLICE-<today>-<first>-<last>.tar.gz`,
  holding one directory with: the **JSON log** (`format: ta-import-log-slice/1`, the rule, the threshold and its
  source, whether forced, whether the date was overridden, `columns`, `count`, `days`, and `records` — one
  object per record, `bytes` as a number), the verbatim TSV lines under the same header, and `MANIFEST.sha256`.
  The slice is read back (extract, manifest check, TSV byte-compare, JSON record count) before it is trusted.
- **S12 · The ARCHIVE record, then the rotate.** The truncated log is: the header, the kept records in their
  original order, and one new `ARCHIVE` record whose `dest` is the slice, `sha256` the slice's hash, and whose
  **note names the values represented in the slice**: the unique ids (as ranges), the days, the groups, the tags,
  the kinds with counts, and the source aliases. Kept + archived must rebuild the old records exactly, and the log
  must not have changed while archiving (a currency pull); only then is the truncated file rotated into place
  (write beside, then rename). A lock directory `IMPORT-LOG.tsv.lock` keeps two archivers apart.
- **S13 · Reading it back.** `say` renders records as sentences (the keeper does not read TSV); `slice-say` does the
  same for an archived slice; `ls` is one short line per record; `stats` shows size, threshold and source, days,
  kinds, groups, and what is eligible now.
- **S14 · Verify.** `verify` re-hashes the latest imported copy of every destination (MATCH / CHANGED / MISSING),
  checks every ARCHIVE record's slice by hash, and with `--sources` re-hashes the origins (current / moved on /
  gone / no root). Exit 0 when everything checked matches, 1 on any mismatch, **77 NOT CHECKED** when the log has
  no imports — never OK.
- **S15 · Exit codes.** 0 ok · 1 red or failed · 2 usage · 3 STOP · 77 not checked.
- **S16 · Test-only hooks.** `IMPORT_LOG_TODAY=YYYY-MM-DD` replaces the system date for tests; a slice and its
  ARCHIVE record both say when it was used. `IMPORT_LOG_FAULT=corrupt-slice|drop-kept` plants a fault inside
  archiving so the read-back and the rebuild proof can be *seen* to fire: each must STOP with the log untouched
  and no slice (or `.part`) left behind. (Found by the Python reader on its first `--prove-red`: without the
  hook, the rebuild proof was a guard nobody could watch go red, and a mutant that deleted it survived.)
- **S17 · Dry run.** `--dry-run` writes nothing — not the log, not a slice, not a copy — and says what it would do.

## How it can fail (falsifiers)

- The selftest cannot see a broken rule: `sh bin/import-log.sh selftest --prove-red` plants six faults (today
  counted, one run enough, records counted instead of dates, `>=` for `>`, force overriding a CLI threshold, force
  not suppressing continue) and must end `PROVE-RED OK`.
- The two implementations of the rules agree by accident: `python3 tests/test_import_log.py --prove-red` runs the
  Python suite against eleven mutants of its own (defined in the test file, independently of the tool's six); a
  mutant the Python suite does not catch is a hole in this spec's tests. First run: 2 of 10 survived (no rebuild
  proof; NOT CHECKED reported as OK) — both fixed the same hour; now 11 of 11 caught.
- A slice cannot be read by anything but this tool: open one with `tar -xzf` and any JSON reader; the count and
  the TSV must agree without the tool.
- The log drifts from the files: `verify` must go red when one imported byte changes (the Python suite does it).

## Files

`bin/import-log.sh` · `tests/test_import_log.py` · `.import/roots.tsv` (local; names this machine's directories)
· `.import/config` (optional: `max_lines=N`) · `archive/import-log/` (slices) · `imports/` (the copies).

---
*© 2026 Corwin Brust — documentation CC BY 4.0, code GPL-3.0-or-later; please retain attribution to Corwin
Brust. Developed and tested with the help of Bryant Frankford and B.K. Graphics (bkgraphics.com), with thanks.*
