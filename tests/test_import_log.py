#!/usr/bin/env python3
"""test_import_log.py -- the second reader of DESIGN-2026-09-30-import-log.md.

Written from the DESIGN's numbered rules (S1-S17), in a different language from the tool (POSIX sh + awk),
so the two can disagree.  Each test names the rule it checks.  Stdlib only.

    python3 tests/test_import_log.py              run the suite against bin/import-log.sh
    python3 tests/test_import_log.py --tool X     run it against another copy
    python3 tests/test_import_log.py --prove-red  run it against planted mutants too; every mutant must be caught

Exit 0 all pass (or, with --prove-red, every mutant caught and the original passing); 1 otherwise.
Copyright (C) 2026 Corwin Brust <corwin@bru.st>.  SPDX-License-Identifier: GPL-3.0-or-later
"""
import hashlib, io, json, os, re, shutil, subprocess, sys, tarfile, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(HERE, '..', 'bin', 'import-log.sh')
COLS = ['id', 'stamp', 'day', 'kind', 'group', 'source', 'dest', 'sha256', 'bytes', 'tags', 'status', 'note']


def sha(path):
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


class Tree:
    """A scratch TA root with a source root aliased 'src'."""

    def __init__(self, tool):
        self.tmp = tempfile.mkdtemp(prefix='il-test-')
        self.src = os.path.join(self.tmp, 'src')
        self.ta = os.path.join(self.tmp, 'ta')
        os.makedirs(os.path.join(self.ta, 'bin'))
        os.makedirs(os.path.join(self.ta, '.import'))
        os.makedirs(self.src)
        shutil.copy(tool, os.path.join(self.ta, 'bin', 'import-log.sh'))
        with open(os.path.join(self.ta, '.import', 'roots.tsv'), 'w') as f:
            f.write('src\t%s\n' % self.src)
        self.log = os.path.join(self.ta, 'IMPORT-LOG.tsv')

    def put(self, rel, text):
        p = os.path.join(self.src, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w') as f:
            f.write(text)
        return p

    def run(self, *args, day=None, env=None):
        e = dict(os.environ)
        e.pop('IMPORT_LOG_MAX_LINES', None)
        if day:
            e['IMPORT_LOG_TODAY'] = day
        if env:
            e.update(env)
        r = subprocess.run(['sh', os.path.join(self.ta, 'bin', 'import-log.sh')] + list(args),
                           capture_output=True, text=True, env=e, cwd=self.tmp)
        return r.returncode, r.stdout, r.stderr

    def rows(self):
        if not os.path.exists(self.log):
            return []
        out = []
        with open(self.log) as f:
            for line in f.read().splitlines():
                if line.startswith('#'):
                    continue
                out.append(dict(zip(COLS, line.split('\t'))))
        return out

    def lines(self):
        with open(self.log) as f:
            return len(f.read().splitlines())

    def slices(self):
        d = os.path.join(self.ta, 'archive', 'import-log')
        return sorted(os.path.join(d, x) for x in os.listdir(d)) if os.path.isdir(d) else []

    def pad(self, n, day):
        """Append n synthetic NOTE records dated `day` straight into the log (volume without the tool)."""
        rows = self.rows()
        start = max([int(r['id'][1:]) for r in rows] or [0]) + 1
        with open(self.log, 'a') as f:
            for i in range(start, start + n):
                f.write('L%06d\t%sT00:00:00Z\t%s\tNOTE\tpad-%s\t-\t-\t-\t-\tpad\t-\tsynthetic\n' % (i, day, day, day))

    def close(self):
        shutil.rmtree(self.tmp, ignore_errors=True)


# ---------------------------------------------------------------- the tests
TESTS = []


def test(rule):
    def wrap(fn):
        TESTS.append((rule, fn))
        return fn
    return wrap


class Fail(Exception):
    pass


def check(cond, msg):
    if not cond:
        raise Fail(msg)


@test('S1 S2 S3')
def t_import_shape(t):
    t.put('a/one.txt', 'one\n')
    rc, out, err = t.run('add', '--group', 'g1', '--tags', 'x,y', 'src', 'a/one.txt', day='2026-02-01')
    check(rc == 0, 'add exit %d: %s' % (rc, err))
    with open(t.log) as f:
        head = f.readline()
    check(head.startswith('#id\t'), 'header line')
    r = t.rows()
    check(len(r) == 1, 'one record')
    r = r[0]
    check(re.fullmatch(r'L\d{6}', r['id']), 'id shape')
    check(re.fullmatch(r'\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ', r['stamp']), 'UTC stamp')
    check(r['day'] == '2026-02-01' and r['kind'] == 'IMPORT' and r['status'] == 'NEW', 'day/kind/status')
    check(r['source'] == 'src:a/one.txt', 'source is ALIAS:path, got %r' % r['source'])
    check(t.src not in open(t.log).read(), 'S2: the machine path of the root never enters the log')
    dest = os.path.join(t.ta, r['dest'])
    check(r['dest'] == 'imports/src/a/one.txt' and sha(dest) == r['sha256'] == sha(os.path.join(t.src, 'a/one.txt')), 'copy hashes like its source')
    check(r['bytes'] == '4' and r['tags'] == 'x,y' and r['group'] == 'g1', 'bytes/tags/group')


@test('S3')
def t_same_and_changed(t):
    t.put('b.txt', 'v1\n')
    t.run('add', 'src', 'b.txt', day='2026-02-01')
    t.run('add', 'src', 'b.txt', day='2026-02-01')
    check(len(t.rows()) == 1, 'identical bytes are not re-logged')
    old = sha(os.path.join(t.src, 'b.txt'))
    t.put('b.txt', 'v2\n')
    rc, out, err = t.run('add', 'src', 'b.txt', day='2026-02-02')
    check(rc == 0, 'changed add ok')
    r = t.rows()[-1]
    check(r['status'] == 'CHANGED' and old[:16] in r['note'], 'CHANGED names the prior hash')
    kept = os.path.join(t.ta, 'imports', '.superseded', '2026-02-02', 'src', 'b.txt.' + old[:16])
    check(os.path.exists(kept) and sha(kept) == old, 'the prior copy is kept, byte for byte')


@test('S3')
def t_directory_and_exclude(t):
    t.put('d/k1.md', 'k1\n'); t.put('d/k2.md', 'k2\n'); t.put('d/skip.log', 's\n'); t.put('d/.git/HEAD', 'ref\n')
    rc, out, err = t.run('add', '--exclude', '*.log', 'src', 'd', day='2026-02-01')
    check(rc == 0, 'dir add')
    srcs = sorted(r['source'] for r in t.rows())
    check(srcs == ['src:d/k1.md', 'src:d/k2.md'], 'dir walk excludes .git and globs: %r' % srcs)


@test('S3')
def t_list_file(t):
    t.put('l/one two.txt', 'sp\n'); t.put('l/b.txt', 'b\n')
    lst = os.path.join(t.tmp, 'list')
    with open(lst, 'w') as f:
        f.write('# comment\nsrc:l/one two.txt\nsrc\tl/b.txt\n\n')
    rc, out, err = t.run('add', '--list', lst, day='2026-02-01')
    check(rc == 0, 'list add: %s' % err)
    check(sorted(r['source'] for r in t.rows()) == ['src:l/b.txt', 'src:l/one two.txt'], 'list lines (colon and tab forms, spaces kept)')


@test('S3 S15')
def t_missing_source_is_red(t):
    rc, out, err = t.run('add', 'src', 'nope.txt', day='2026-02-01')
    check(rc == 1, 'a missing source exits 1, got %d' % rc)
    check(len(t.rows()) == 0, 'nothing logged for a missing source')


def three_days(t):
    """Records on 03-01 (1), 03-02 (2: one run), and nothing yet on 03-03."""
    t.put('a.txt', 'a\n'); t.put('b.txt', 'b\n')
    t.run('add', '--group', 'ga', '--tags', 'ta', 'src', 'a.txt', day='2026-03-01')
    t.run('add', '--group', 'gb', '--tags', 'tb', 'src', 'b.txt', day='2026-03-02')
    t.run('note', '--group', 'gb', 'second', 'record', 'same', 'day', day='2026-03-02')


def eligible(t, day, **kw):
    rc, out, err = t.run('stats', day=day, **kw)
    m = re.search(r'^eligible\s+(\S+)', out, re.M)
    return m.group(1) if m else None


@test('S4 S5')
def t_one_date_is_one_run(t):
    three_days(t)
    check(eligible(t, '2026-03-03') == 'none', 'two records on one earlier date are one run, not two')


@test('S5')
def t_today_never_counts(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    check(eligible(t, '2026-03-03') == 'none', 'a record written today does not make today a passed run')


@test('S5')
def t_two_whole_dates(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    check(eligible(t, '2026-03-04') == 'L000001', 'on 03-04 only the 03-01 record has two whole dates after it')


@test('S5')
def t_future_never_archived(t):
    three_days(t)
    t.pad(1, '2026-12-31')
    rc, out, err = t.run('stats', day='2026-03-09')
    check('after today' in err, 'a future-dated record is warned about')
    check('L000004' not in (re.search(r'^eligible\s+(\S+)', out, re.M).group(1)), 'and never eligible')


@test('S6 S7 S8')
def t_default_threshold_4000(t):
    t.put('a.txt', 'a\n')
    t.run('add', 'src', 'a.txt', day='2026-04-01')
    t.pad(3998, '2026-04-01')                     # header + 3999 records = 4000 lines: at, not over
    check(t.lines() == 4000, 'fixture is 4000 lines')
    rc, out, err = t.run('note', 'at the line', day='2026-04-01')
    check(rc == 0 and not t.slices(), 'at 4000 no archiving (and the note lands): rc %d' % rc)
    # now 4001 lines, nothing old enough: STOP
    rc, out, err = t.run('note', 'over', day='2026-04-02')
    check(rc == 3, 'over the default threshold with nothing eligible: STOP 3, got %d' % rc)
    check('default threshold of 4000' in err, 'the default and its source are said: %s' % err.strip())
    check(t.rows()[-1]['note'] != 'over', 'S8: nothing else was done after STOP')


@test('S6')
def t_threshold_precedence(t):
    three_days(t)
    n = t.lines()
    with open(os.path.join(t.ta, '.import', 'config'), 'w') as f:
        f.write('max_lines=%d\n' % (n - 1))
    rc, out, err = t.run('note', 'x', day='2026-03-03')
    check(rc == 3 and 'config threshold' in err, 'config threshold applies: rc %d %s' % (rc, err))
    rc, out, err = t.run('note', 'x', day='2026-03-03', env={'IMPORT_LOG_MAX_LINES': '1000'})
    check(rc == 0, 'env beats config')
    rc, out, err = t.run('--max-lines', '1', 'note', 'y', day='2026-03-03', env={'IMPORT_LOG_MAX_LINES': '1000'})
    check(rc == 3 and 'cli threshold' in err, 'cli beats env: rc %d' % rc)


@test('S8')
def t_continue_after_stop(t):
    three_days(t)
    rc, out, err = t.run('--max-lines', '2', '--continue-after-stop', 'note', 'anyway', day='2026-03-03')
    check(rc == 0 and t.rows()[-1]['note'] == 'anyway', 'continue-after-stop warns and does the work')
    check('WARN' in err, 'and warns')


@test('S10')
def t_force_bypasses_config_not_cli(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    with open(os.path.join(t.ta, '.import', 'config'), 'w') as f:
        f.write('max_lines=100000\n')
    rc, out, err = t.run('--force-archiving', '--max-lines', '100000', 'note', 'cli-held', day='2026-03-04')
    check(rc == 0 and not t.slices(), 'force obeys a CLI threshold the log is under')
    rc, out, err = t.run('--force-archiving', 'note', 'forced', day='2026-03-04')
    check(rc == 0 and len(t.slices()) == 1, 'force bypasses the configured threshold and archives: rc %d %s' % (rc, err))


@test('S10')
def t_force_suppresses_continue(t):
    three_days(t)
    rc, out, err = t.run('--force-archiving', '--continue-after-stop', 'note', 'no', day='2026-03-03')
    check(rc == 3, 'a forced archive with nothing eligible STOPs even with --continue-after-stop (rc %d)' % rc)
    check('suppressed' in err, 'and says the continue was suppressed')
    check(all(r['note'] != 'no' for r in t.rows()), 'nothing else was done')


@test('S11 S12')
def t_slice_and_archive_record(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    before = [l for l in open(t.log).read().splitlines() if not l.startswith('#')]
    rc, out, err = t.run('--force-archiving', 'note', 'after', day='2026-03-04')
    check(rc == 0, 'forced archive ok: %s' % err)
    sl = t.slices()
    check(len(sl) == 1 and re.search(r'IMPORT-LOG-SLICE-2026-03-04-L000001-L000001\.tar\.gz$', sl[0]), 'slice name %r' % sl)
    with tarfile.open(sl[0]) as tf:
        names = tf.getnames()
        js = [n for n in names if n.endswith('.json')][0]
        doc = json.load(tf.extractfile(js))
        tsv = tf.extractfile([n for n in names if n.endswith('.tsv')][0]).read().decode()
        man = tf.extractfile([n for n in names if n.endswith('MANIFEST.sha256')][0]).read().decode()
    check(doc['format'] == 'ta-import-log-slice/1' and doc['count'] == 1 and doc['days'] == ['2026-03-01'], 'JSON header')
    check(doc['columns'] == COLS, 'JSON columns')
    rec = doc['records'][0]
    check(rec['id'] == 'L000001' and rec['group'] == 'ga' and isinstance(rec['bytes'], int), 'JSON record, bytes numeric')
    check(doc['date_source'] == 'override', 'S16: the override is recorded in the slice')
    check(tsv.splitlines()[1] == before[0], 'verbatim TSV line in the slice')
    check(len(man.splitlines()) == 2, 'manifest names two files')
    rows = t.rows()
    check(all(r['id'] != 'L000001' for r in rows), 'the archived record left the log')
    arch = [r for r in rows if r['kind'] == 'ARCHIVE']
    check(len(arch) == 1, 'one ARCHIVE record')
    a = arch[0]
    check(a['sha256'] == sha(sl[0]) and a['dest'].endswith(os.path.basename(sl[0])), 'ARCHIVE record points at the slice by hash')
    for want in ('ids: L000001', 'days: 2026-03-01', 'groups: ga', 'tags: ta', 'kinds: IMPORT=1', 'sources: src'):
        check(want in a['note'], 'ARCHIVE note names %r: %s' % (want, a['note']))
    check('IMPORT_LOG_TODAY' in a['note'], 'S16: the override is recorded in the ARCHIVE note')
    # S12: kept + archived rebuild the old records
    kept = [l for l in open(t.log).read().splitlines() if not l.startswith('#')]
    kept = [l for l in kept if l.split('\t')[0] != a['id'] and l.split('\t')[12 - 1] != 'after']
    check(sorted(kept + tsv.splitlines()[1:]) == sorted(before), 'kept + archived == the old records')
    ids = [int(r['id'][1:]) for r in t.rows()]
    check(ids == sorted(ids) and len(set(ids)) == len(ids), 'ids strictly increase, never reused')


@test('S12')
def t_note_names_many_values(t):
    for i, (g, tag) in enumerate([('g1', 'red,blue'), ('g2', 'blue'), ('g1', 'green')]):
        t.put('m%d.txt' % i, '%d\n' % i)
        t.run('add', '--group', g, '--tags', tag, 'src', 'm%d.txt' % i, day='2026-05-01')
    t.run('note', '--group', 'g3', 'hello', day='2026-05-01')
    t.pad(1, '2026-05-02'); t.pad(1, '2026-05-03')
    rc, out, err = t.run('--force-archiving', 'ls', day='2026-05-04')
    check(rc == 0, 'archive via ls (anytime): %s' % err)
    a = [r for r in t.rows() if r['kind'] == 'ARCHIVE'][0]
    check('ids: L000001-L000004' in a['note'], 'ids as a range: %s' % a['note'])
    for g in ('g1', 'g2', 'g3'):
        check(g in a['note'].split('groups: ')[1].split(';')[0], 'group %s named' % g)
    for tag in ('red', 'blue', 'green'):
        check(tag in a['note'].split('tags: ')[1].split(';')[0], 'tag %s named' % tag)
    check('IMPORT=3' in a['note'] and 'NOTE=1' in a['note'], 'kinds counted')


@test('S12')
def t_lock_blocks_and_stops(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    os.mkdir(t.log + '.lock')
    rc, out, err = t.run('--force-archiving', 'note', 'blocked', day='2026-03-04')
    check(rc == 3 and 'lock' in err, 'a held lock fails the archive and STOPs: rc %d' % rc)
    check(not t.slices() and all(r['note'] != 'blocked' for r in t.rows()), 'nothing written')


@test('S9')
def t_stats_only_reports(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    rc, out, err = t.run('--max-lines', '2', 'stats', day='2026-03-04')
    check(rc == 0 and not t.slices() and 'OVER' in out, 'stats reports OVER and archives nothing')
    rc, out, err = t.run('--max-lines', '2', 'say', day='2026-03-04')
    check(rc == 0 and len(t.slices()) == 1, 'say (reads the live log) archives first')


@test('S13')
def t_say_in_words(t):
    t.put('w.txt', 'x' * 12345)
    t.run('add', '--tags', 'posterity', 'src', 'w.txt', day='2026-06-01')
    rc, out, err = t.run('say', day='2026-06-01')
    check(rc == 0, 'say ok')
    check('brought in src:w.txt' in out and '12,345 bytes' in out and 'a new copy' in out, 'a sentence, with a readable number: %s' % out)
    check('\t' not in out, 'no tabs in the words')


@test('S13')
def t_slice_say(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    t.run('--force-archiving', 'note', 'go', day='2026-03-04')
    rc, out, err = t.run('slice-say', t.slices()[0], day='2026-03-04')
    check(rc == 0 and 'brought in src:a.txt' in out, 'slice read back in words: %s' % out)


@test('S14 S15')
def t_verify(t):
    rc, out, err = t.run('verify', day='2026-07-01')
    check(rc == 77, 'no log: NOT CHECKED 77, got %d' % rc)
    t.put('v.txt', 'v\n')
    t.run('add', 'src', 'v.txt', day='2026-07-01')
    rc, out, err = t.run('verify', '--sources', day='2026-07-01')
    check(rc == 0 and '1 match' in out and '1 current' in out, 'verify green: %s' % out)
    with open(os.path.join(t.ta, 'imports', 'src', 'v.txt'), 'a') as f:
        f.write('tamper')
    rc, out, err = t.run('verify', day='2026-07-01')
    check(rc == 1 and 'CHANGED' in out, 'one changed byte turns verify red')


@test('S14 S15')
def t_verify_nothing_to_check(t):
    t.run('note', 'only a note', day='2026-07-01')
    rc, out, err = t.run('verify', day='2026-07-01')
    check(rc == 77 and 'NOT CHECKED' in out, 'a log with no imports is NOT CHECKED (77), never OK: rc %d' % rc)


@test('S11 S12 S16')
def t_faults_fire_and_leave_nothing(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    for fault in ('corrupt-slice', 'drop-kept'):
        before = open(t.log).read()
        rc, out, err = t.run('--force-archiving', 'note', 'x', day='2026-03-04', env={'IMPORT_LOG_FAULT': fault})
        check(rc == 3, '%s: the archive fails and STOPs (rc %d)' % (fault, rc))
        check(open(t.log).read() == before, '%s: the log is untouched' % fault)
        d = os.path.join(t.ta, 'archive', 'import-log')
        check(not os.path.isdir(d) or not os.listdir(d), '%s: no slice (and no .part) left behind: %r' % (fault, os.listdir(d) if os.path.isdir(d) else []))


@test('S14')
def t_verify_slice_hash(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    t.run('--force-archiving', 'note', 'go', day='2026-03-04')
    with open(t.slices()[0], 'ab') as f:
        f.write(b'\0')
    rc, out, err = t.run('verify', day='2026-03-04')
    check(rc == 1 and 'SLICE-CHANGED' in out, 'a changed slice turns verify red: %s' % out)


@test('S17')
def t_dry_run_writes_nothing(t):
    three_days(t)
    t.run('note', 'today', day='2026-03-03')
    before = open(t.log).read()
    t.put('new.txt', 'n\n')
    rc, out, err = t.run('--dry-run', '--force-archiving', 'add', 'src', 'new.txt', day='2026-03-04')
    check(rc == 0 and 'dry-run' in out, 'dry run speaks')
    check('1 new' in out and 'would bring in 2 bytes' in out, 'dry run counts what it would do: %s' % out)
    check(open(t.log).read() == before and not t.slices(), 'dry run wrote nothing')
    check(not os.path.exists(os.path.join(t.ta, 'imports', 'src', 'new.txt')), 'dry run copied nothing')


@test('S1')
def t_config_tz_sets_the_run_date(t):
    import datetime
    try:
        from zoneinfo import ZoneInfo
    except ImportError:
        return
    for tz in ('Pacific/Kiritimati', 'Pacific/Pago_Pago'):
        with open(os.path.join(t.ta, '.import', 'config'), 'w') as f:
            f.write('tz=%s\n' % tz)
        want = datetime.datetime.now(ZoneInfo(tz)).strftime('%Y-%m-%d')
        rc, out, err = t.run('note', 'tz', tz)
        got = t.rows()[-1]['day']
        check(rc == 0 and got == want, 'config tz=%s gives day %s, got %s' % (tz, want, got))


@test('S15')
def t_usage(t):
    rc, out, err = t.run('frobnicate')
    check(rc == 2, 'unknown command is usage 2')
    rc, out, err = t.run('--max-lines', 'lots', 'ls')
    check(rc == 2, 'a non-number threshold is usage 2')


# ---------------------------------------------------------------- runner
def run_suite(tool, quiet=False):
    fails = []
    for rule, fn in TESTS:
        t = Tree(tool)
        try:
            fn(t)
            if not quiet:
                print('ok    %-10s %s' % (rule, fn.__name__))
        except Fail as e:
            fails.append((rule, fn.__name__, str(e)))
            if not quiet:
                print('FAIL  %-10s %s: %s' % (rule, fn.__name__, e))
        except Exception as e:  # a crash is a failure, named
            fails.append((rule, fn.__name__, 'crash: %r' % e))
            if not quiet:
                print('FAIL  %-10s %s: crash %r' % (rule, fn.__name__, e))
        finally:
            t.close()
    return fails


# Mutants are defined HERE, independently of the tool's own --prove-red list, by the rule they break.
MUTANTS = [
    ('S5 today counted',        r'if \(d < today\) seen\[d\]=1', 'seen[d]=1'),
    ('S5 one run enough',       r'passed >= 2', 'passed >= 1'),
    ('S4 records not dates',    r'for \(x in seen\) if \(x > day\[i\]\) passed\+\+', 'for (j=1;j<=n;j++) if (day[j] > day[i]) passed++'),
    ('S6 at counts as over',    r'\[ "\$lines" -gt "\$TH" \]', '[ "$lines" -ge "$TH" ]'),
    ('S10 force beats CLI',     r'\[ "\$FORCE" = 1 \] && \[ "\$TH_SRC" != cli \]', '[ "$FORCE" = 1 ]'),
    ('S10 force lets continue', r'if \[ "\$FORCE" = 1 \]; then(\s+# MUT:force-suppresses)', r'if false; then\1'),
    ('S12 note drops groups',   r'groups: \$\{u_groups:--\}; ', ''),
    ('S12 no rebuild proof',    r'\[ "\$a" = "\$b" \] \|\|', 'true ||'),
    ('S11 no read-back',        r'mkdir "\$w/check" && \( cd "\$w/check" && tar -xzf "\$tarf.part" \) 2>/dev/null \|\|', 'true ||'),
    ('S2 machine path leaks',   r'append IMPORT "\$\{GROUP:-import-\$TODAY\}" "\$a:\$p"', 'append IMPORT "${GROUP:-import-$TODAY}" "$src"'),
    ('S14 NOT CHECKED is OK',   r'exit 77; \}\n\t\[ "\$bad" = 0 \]', 'exit 0; }\n\t[ "$bad" = 0 ]'),
]


def prove_red(tool):
    src = open(tool).read()
    rc = 0
    base = run_suite(tool, quiet=True)
    if base:
        print('prove-red: the unmutated tool FAILS %d test(s): %s' % (len(base), ', '.join(f[1] for f in base)))
        rc = 1
    else:
        print('prove-red: the unmutated tool passes all %d tests' % len(TESTS))
    tmp = tempfile.mkdtemp(prefix='il-mut-')
    try:
        for name, pat, rep in MUTANTS:
            mut, n = re.subn(pat, rep, src, count=1)
            if n == 0:
                print('prove-red: mutant %-24s DID NOT APPLY (the rule moved in the tool)' % name)
                rc = 1
                continue
            p = os.path.join(tmp, 'mut.sh')
            with open(p, 'w') as f:
                f.write(mut)
            fails = run_suite(p, quiet=True)
            if fails:
                print('prove-red: mutant %-24s caught by %s' % (name, ', '.join(sorted({f[1] for f in fails}))[:90]))
            else:
                print('prove-red: mutant %-24s SURVIVED -- the suite cannot see this fault' % name)
                rc = 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print('PROVE-RED OK' if rc == 0 else 'PROVE-RED FAILED')
    return rc


def main(argv):
    tool = TOOL
    if '--tool' in argv:
        tool = argv[argv.index('--tool') + 1]
    tool = os.path.abspath(tool)
    if '--prove-red' in argv:
        return prove_red(tool)
    fails = run_suite(tool)
    print('%d/%d passed' % (len(TESTS) - len(fails), len(TESTS)))
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
