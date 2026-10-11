#!/usr/bin/env python3
"""owner_check -- whose rule is this, and can the record show it?

A second-language reader (Python 3, stdlib only) for the owner-tracking question the shell tools
(c4 bin/door, bin/kt1wr) ask.  Three jobs:

  (a) PARTS   a rule is a part: one header line, then its body VERBATIM.
                 owner: HIS|MINE|<Name> · since: YYYY-MM-DD · source: <path:line[-line]> | authored
              optional extra fields on the same line:  · id: <slug> · title: <text>
              A part runs from its header to the next header line or end of file.  Files: *.rule or
              *.parts (several parts per file).  C4 door parts (*.part: KEY<TAB>VALUE lines, a `---`
              line, then the body) are read too, so the door's own parts can serve as locators.
  (b) RENDER  an instruction file from parts, the owner kept on every rule, stamped with
              sha256(concatenated parts); `check` answers CURRENT / STALE / LOCAL for a copy.
  (c) SCAN    any text file: find sentences that attribute a rule to the keeper ("Corwin wants",
              "his rule", "as Corwin has given them", a heading "What Corwin wants" ...).  Each must
              LOCATE: a quoted span (4+ words) found verbatim, whitespace-normalised, in a DECLARED
              source file or an owner:HIS part body; or, with no quote, the sentence itself verbatim
              in an owner:HIS part body.  Otherwise:  UNLOCATED <file:line>.

usage:
  owner_check.py lint   PARTS...  [--roots TSV] [--map FROM=TO]...
  owner_check.py stamp  PARTS...
  owner_check.py render PARTS...  [--title T] [--owner-mode comment|byline|none] [--roots TSV]
                                  [--map FROM=TO]... [--source S]... [--sources-from LIST]
                                  [--strict] [--allow-voice] [-o OUT]
  owner_check.py check  RENDERED... --parts P [--parts P]...
  owner_check.py scan   FILE...   [--parts P]... [--source S]... [--sources-from LIST]
                                  [--roots TSV] [--head N] [-v]
  owner_check.py --prove-red

exit: 0 clean (CURRENT/LOCAL; no UNLOCATED; render ok) · 1 flags (STALE; UNLOCATED; prove-red
      miss) · 2 usage / refused render / unreadable · 77 nothing checked

Declared (so a reader can argue with them):
  MUST     the stamp is sha256 over the raw bytes of the parts files, in render order (a directory
           is read in byte-sorted name order): `cat $(ls DIR/*.parts DIR/*.rule DIR/*.part | LC_ALL=C sort)
           | sha256sum` equals it.  So any byte of a parts file -- a comment line included -- moves it.
           CURRENT means: stamp == sha of the parts now AND the copy's bytes == a re-render.
  JOURNEY  the attribution patterns, the 4-word quote floor (4 is a house number, INVENTED, from
           the set 4/9/17, not derived), sentence splitting, and "a quote must be in a file other
           than the one scanned" are mine.  A phrasing my patterns miss is not checked.
  LIMIT    an owner:HIS part is trusted as HIS; this tool cannot prove authorship, only whether
           the record carries the words where the text says they are.
"""
import argparse
import datetime
import hashlib
import os
import re
import shutil
import sys
import tempfile

ME = "owner_check"
QUOTE_FLOOR = 4  # house number (4/9/17), invented, not derived -- see header

# ---------------------------------------------------------------- text helpers

def read_text(path):
    with open(path, "rb") as fh:
        raw = fh.read()
    if b"\x00" in raw:
        raise ValueError("binary")
    return raw.decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")


def norm_ws(s):
    return re.sub(r"\s+", " ", s).strip()


def dequote_lines(s):
    """strip leading blockquote markers from each line (quoting syntax, not words)"""
    return "\n".join(re.sub(r"^\s*(?:>\s?)+", "", ln) for ln in s.split("\n"))


def loose(s):
    s = s.replace("“", '"').replace("”", '"').replace("‘", "'").replace("’", "'")
    s = re.sub(r"[*`]|(?<![A-Za-z0-9])_|_(?![A-Za-z0-9])", "", s)
    return norm_ws(s).casefold()


EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
PHONE_RE = re.compile(r"(?<!\d)(?:\+?\d{1,3}[\s.-])?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}(?!\d)")


def redact(s):
    return PHONE_RE.sub("<number>", EMAIL_RE.sub("<email>", s))


def excerpt(s, n=110):
    s = redact(norm_ws(s))
    return s if len(s) <= n else s[: n - 1] + "…"


def signed_payload(text):
    """a clearsigned file counts only for its signed block (dash-escaping undone)"""
    m = re.search(r"-----BEGIN PGP SIGNED MESSAGE-----\n(?:[^\n]*\n)*?\n(.*?)\n-----BEGIN PGP SIGNATURE-----",
                  text, re.S)
    if not m:
        return text
    return "\n".join(ln[2:] if ln.startswith("- ") else ln for ln in m.group(1).split("\n"))


# ---------------------------------------------------------------- roots / display

class Roots:
    def __init__(self, tsv=None, maps=()):
        self.alias = {}
        if tsv:
            for ln in read_text(tsv).split("\n"):
                if ln.strip() and not ln.startswith("#") and "\t" in ln:
                    a, r = ln.split("\t", 1)
                    self.alias[a.strip()] = r.strip()
        self.maps = []
        for m in maps:
            if "=" not in m:
                raise SystemExit(f"{ME}: --map wants FROM=TO, got {m!r}")
            f, t = m.split("=", 1)
            self.maps.append((f, t))

    def resolve(self, ref, base):
        for f, t in self.maps:
            if ref == f:
                ref = t
                break
        if ":" in ref:
            a, rest = ref.split(":", 1)
            if a in self.alias:
                return os.path.join(self.alias[a], rest)
        if os.path.isabs(ref):
            return ref
        return os.path.normpath(os.path.join(base, ref))

    def show(self, path):
        ap = os.path.abspath(path)
        best = None
        for a, r in self.alias.items():
            rr = os.path.abspath(r)
            if ap == rr or ap.startswith(rr + os.sep):
                if best is None or len(rr) > len(best[1]):
                    best = (a, rr)
        if best:
            return f"{best[0]}:{os.path.relpath(ap, best[1])}"
        return path


# ---------------------------------------------------------------- parts

HDR_START = re.compile(r"^owner:\s*\S+.*·\s*since:", re.I)
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
OWNER_RE = re.compile(r"^(HIS|MINE|[A-Za-z][A-Za-z0-9._-]*)$")


class Part:
    def __init__(self, **kw):
        self.__dict__.update(kw)

    def label(self):
        return f"{self.owner}:{self.id}"


def parse_header(line):
    fields = {}
    for chunk in line.split("·"):
        chunk = chunk.strip()
        if not chunk:
            continue
        if ":" not in chunk:
            fields.setdefault("_junk", []).append(chunk)
            continue
        k, v = chunk.split(":", 1)
        fields[k.strip().lower()] = v.strip()
    return fields


def load_rule_file(path):
    text = read_text(path)
    lines = text.split("\n")
    parts, cur = [], None
    stem = os.path.splitext(os.path.basename(path))[0]

    def close(c):
        body = c["body"]
        while body and not body[0].strip():
            body.pop(0); c["body_line"] += 1
        while body and not body[-1].strip():
            body.pop()
        f = c["fields"]
        b = "\n".join(body)
        parts.append(Part(kind="rule", file=path, line=c["line"], body_line=c["body_line"],
                          owner=f.get("owner", ""), since=f.get("since", ""), source=f.get("source", ""),
                          id=f.get("id") or f"{stem}-{len(parts) + 1}", title=f.get("title", ""),
                          header=c["header"], body=b, junk=f.get("_junk", []),
                          raw=c["header"] + "\n" + b + "\n"))

    for i, ln in enumerate(lines, 1):
        if HDR_START.match(ln):
            if cur:
                close(cur)
            cur = {"header": ln.rstrip(), "fields": parse_header(ln), "line": i, "body_line": i + 1, "body": []}
        elif cur is not None:
            cur["body"].append(ln)
        elif ln.strip() and not ln.startswith("#"):
            raise ValueError(f"{path}:{i}: text before the first 'owner: ... · since:' header")
    if cur:
        close(cur)
    return parts


def load_door_part(path):
    text = read_text(path)
    if "\n---\n" not in "\n" + text:
        raise ValueError(f"{path}: door part without a '---' line")
    head, body = re.split(r"(?m)^---[ \t]*$\n?", text, maxsplit=1)
    h = {}
    for ln in head.split("\n"):
        if "\t" in ln:
            k, v = ln.split("\t", 1)
            h[k.strip()] = v.strip()
    nhead = head.count("\n") + 1
    lead = len(body) - len(body.lstrip("\n"))  # blank lines after '---' are not body
    return [Part(kind="door", file=path, line=1, body_line=nhead + 1 + lead, owner=h.get("owner", ""),
                 since=h.get("since", ""), source=h.get("source", ""),
                 id=h.get("id") or os.path.basename(path), title=h.get("title", ""),
                 header=head, body=body.strip("\n"), junk=[], raw=text)]


def load_parts(paths):
    out = []
    for p in paths:
        if os.path.isdir(p):
            files = sorted(f for f in os.listdir(p) if f.endswith((".rule", ".parts", ".part")))
            files = [os.path.join(p, f) for f in files]
        elif os.path.isfile(p):
            files = [p]
        else:
            raise SystemExit(f"{ME}: no such parts path: {p}")
        for f in files:
            out.extend(load_door_part(f) if f.endswith(".part") else load_rule_file(f))
    return out


def stamp_of(parts):
    """sha256 over the raw bytes of the parts FILES, in render order -- so that
    `cat <the same files in the same order> | sha256sum` re-derives it with no Python at all"""
    h, seen = hashlib.sha256(), []
    for p in parts:
        if p.file not in seen:
            seen.append(p.file)
    for f in seen:
        with open(f, "rb") as fh:
            h.update(fh.read())
    return h.hexdigest()


SRC_MINE = re.compile(r"^(?P<ref>.+):(?P<lo>\d+)(?:-(?P<hi>\d+))?$")
SRC_DOOR = re.compile(r"^(?P<ref>\S.*?) lines (?P<ranges>\d+-\d+(?:\s*\+\s*\d+-\d+)*)(?: \(sha (?P<sha>[0-9a-f]+)\))?")


def lint_part(p, roots, strict=False):
    """-> list of (level, code, message); level ERROR refuses a render"""
    out = []
    E = lambda c, m: out.append(("ERROR", c, m))
    W = lambda c, m: out.append(("WARN", c, m))
    if not OWNER_RE.match(p.owner or ""):
        E("BAD-OWNER", f"owner {p.owner!r} is not HIS, MINE or a name")
    if not DATE_RE.match(p.since or ""):
        E("BAD-SINCE", f"since {p.since!r} is not YYYY-MM-DD")
    else:
        try:
            datetime.date.fromisoformat(p.since)
        except ValueError:
            E("BAD-SINCE", f"since {p.since!r} is not a real date")
    if not p.body.strip():
        E("EMPTY-BODY", "the part has no body")
    src = (p.source or "").strip()
    if not src:
        E("NO-SOURCE", "source is empty (write 'authored' for a rule the instrument wrote)")
        return out
    if src == "authored":
        if p.owner == "HIS":
            E("HIS-AUTHORED", "an owner:HIS rule needs the place he said it, not 'authored'")
        return out
    m = SRC_MINE.match(src) if p.kind == "rule" else (SRC_DOOR.match(src) or SRC_MINE.match(src))
    if not m:
        (E if (strict or p.kind == "rule") else W)("BAD-SOURCE", f"source {excerpt(src, 60)!r} is not path:line[-line]")
        return out
    path = roots.resolve(m.group("ref"), os.path.dirname(p.file))
    if not os.path.isfile(path):
        (E if strict else W)("SOURCE-UNREACHABLE", f"{m.group('ref')} does not resolve here ({path})")
        return out
    text = read_text(path)
    sha = m.groupdict().get("sha")
    if sha and not hashlib.sha256(text.encode("utf-8")).hexdigest().startswith(sha):
        W("SOURCE-SHA", f"cited sha {sha} does not match {roots.show(path)} (the file moved on)")
    lines = text.split("\n")
    gd = m.groupdict()
    if gd.get("ranges"):
        ranges = [tuple(int(x) for x in r.split("-")) for r in re.split(r"\s*\+\s*", gd["ranges"])]
    else:
        ranges = [(int(m.group("lo")), int(m.group("hi") or m.group("lo")))]
    chunks = []
    for lo, hi in ranges:
        if lo < 1 or hi > len(lines) or lo > hi:
            E("SOURCE-RANGE", f"lines {lo}-{hi} outside {roots.show(path)} ({len(lines)} lines)")
            return out
        chunks.append("\n".join(lines[lo - 1:hi]))
    where = f"{roots.show(path)}:" + "+".join(f"{lo}-{hi}" for lo, hi in ranges)
    cited = norm_ws(dequote_lines("\n".join(chunks)))
    body = norm_ws(dequote_lines(p.body))
    if body not in cited:
        near = "; matches only after stripping markup/case" if loose(body) in loose(cited) else ""
        E("NOT-VERBATIM", f"body is not verbatim at {where}{near}")
    return out


# ---------------------------------------------------------------- render / check

STAMP_RE = re.compile(r"^<!-- owner_check: RENDERING parts-sha256=([0-9a-f]{64}) parts=(\d+) owner-mode=(\w+) ")


def render_text(parts, title, mode):
    sha = stamp_of(parts)
    o = [f"<!-- owner_check: RENDERING parts-sha256={sha} parts={len(parts)} owner-mode={mode} "
         f"-- edit the parts and re-render; a copy without this line is LOCAL and governs where it sits -->",
         f"# {title}", ""]
    for p in parts:
        o.append(f"## {p.title or p.id}")
        if mode == "none":  # the door's form: the owner stays in the part, not in the copy
            o.append(f"<!-- rule: {p.id} · since: {p.since} · source: {p.source} -->")
        else:
            o.append(f"<!-- rule: {p.id} · owner: {p.owner} · since: {p.since} · source: {p.source} -->")
        if mode == "byline":
            o.append(f"*owner: {p.owner} · since {p.since} · source: {p.source}*")
        o.append("")
        o.append(p.body)
        o.append("")
    o.append(f"<!-- owner_check: end parts-sha256={sha} -->")
    return "\n".join(o) + "\n"


def check_one(path, parts):
    """-> (state, detail)"""
    text = read_text(path)
    lines = text.split("\n")
    idx = next((i for i, ln in enumerate(lines) if STAMP_RE.match(ln)), None)
    if idx is None:
        return "LOCAL", "no owner_check stamp; hand-held, governs where it sits"
    m = STAMP_RE.match(lines[idx])
    want, mode = m.group(1), m.group(3)
    have = stamp_of(parts)
    if want != have:
        return "STALE", f"parts changed since render (rendered-from={want[:12]} now={have[:12]})"
    title = lines[idx + 1][2:] if idx + 1 < len(lines) and lines[idx + 1].startswith("# ") else ""
    again = render_text(parts, title, mode).split("\n")
    if lines != again:
        k = next((i for i, (a, b) in enumerate(zip(lines, again)) if a != b), min(len(lines), len(again)))
        return "STALE", f"copy edited after render (stamp matches parts; bytes differ at line {k + 1})"
    return "CURRENT", f"parts-sha256={want[:12]} parts={m.group(2)} owner-mode={mode}"


# ---------------------------------------------------------------- scan: blocks

class Block:
    def __init__(self, kind, start, lines, level=0):
        self.kind, self.start, self.lines, self.level = kind, start, lines, level

    @property
    def text(self):
        return "\n".join(self.lines)

    def line_at(self, off):
        return self.start + self.text.count("\n", 0, off)


def parse_blocks(lines, first=1):
    blocks, cur = [], None
    in_fence = in_comment = False

    def flush():
        nonlocal cur
        if cur:
            blocks.append(cur)
        cur = None

    for i, s in enumerate(lines):
        ln = first + i
        if in_comment:
            if "-->" in s:
                in_comment = False
            continue
        if re.match(r"^\s*(```|~~~)", s):
            flush(); in_fence = not in_fence; continue
        if in_fence:
            continue
        if not s.strip() or re.match(r"^\s*(-{3,}|\*{3,}|_{3,})\s*$", s):
            flush(); continue
        if s.lstrip().startswith("<!--"):
            flush()
            blocks.append(Block("comment", ln, [s]))
            if "-->" not in s:
                in_comment = True
            continue
        m = re.match(r"^(#{1,6})\s+(.*)$", s)
        if m:
            flush(); blocks.append(Block("heading", ln, [s], level=len(m.group(1)))); continue
        if s.lstrip().startswith("|"):
            flush(); blocks.append(Block("table", ln, [s])); continue
        if re.match(r"^\s*>", s):
            if cur and cur.kind == "quote":
                cur.lines.append(s)
            else:
                flush(); cur = Block("quote", ln, [s])
            continue
        if re.match(r"^\s*(?:[-*+]|\d+[.)])\s+", s):
            flush(); cur = Block("item", ln, [s]); continue
        if cur and cur.kind in ("para", "item"):
            cur.lines.append(s)
        else:
            flush(); cur = Block("para", ln, [s])
    flush()
    return blocks


# ---------------------------------------------------------------- scan: patterns

NAME = r"(?:Corwin|the keeper|keeper)"
ADV = r"(?:\s+(?:has|had|also|always|explicitly|once|himself|then|now|just|already))?"
ASKED = r"asked(?!\s+(?:how|whether|if|what|why|when|where|who)\b)"  # a question is not an instruction
VERB = (rf"(?:wants?|wanted|said|says|prefers?|preferred|{ASKED}|asks|ruled|insists?|insisted|requires?"
        r"|required|decided|decides|blessed|named|gave|given|holds|held|stated|states|writes|wrote|told"
        r"|calls?|called|adopted|likes?|dislikes?|forbids?|forbade|expects?|expected|needs?|put it)")
PVERB = (rf"(?:wants?|wanted|said|says|prefers?|preferred|{ASKED}|asks|ruled|insists?|insisted|requires?"
         r"|required|decided|blessed|named|told|stated|adopted|expects?|expected|forbids?|forbade)")
NOUN = (r"(?:rules?|words|preferences?|corrections?|call|laws?|norms?|instructions?|requirements?|position"
        r"|canon|principles?|rulings?|reframe|asks?|wish(?:es)?|terms|verdict|decisions?|orders?|method"
        r"|test|marking|standard|standing order)")
PATTERNS = [
    ("name-verb", re.compile(rf"\b{NAME}\b{ADV}\s+{VERB}\b", re.I)),
    ("he-verb", re.compile(rf"\b[Hh]e\b{ADV}\s+{PVERB}\b")),
    ("possessive", re.compile(rf"\b(?:his|Corwin's|Corwin’s|the keeper's|the keeper’s)\s+"
                              rf"(?:(?:own|stated|standing|explicit|express|latest|newer|signed|verbatim)\s+){{0,2}}{NOUN}\b",
                              re.I)),
    ("as-given", re.compile(rf"\bas\s+(?:Corwin|he|the keeper)\s+(?:has\s+|had\s+)?"
                            rf"(?:given|put|said|stated|written|wrote|ruled|asked|puts?|says?)\b", re.I)),
    ("by-him", re.compile(r"\b(?:written|rewritten|authored|ruled|named|coined|given|set|blessed|ratified)\s+by\s+"
                          r"(?:Corwin|the keeper)\b", re.I)),
    ("his-tag", re.compile(r"\[HIS\]")),
    ("his-paren", re.compile(r"\((?:his|HIS)\s*[,;)]")),  # "(his, 2026-08-03)" -- the shop's own tag form
]
HEADING_EXTRA = [("his-heading", re.compile(r"^#{1,6}\s+\W*HIS\b"))]
FRAME = ("author-frame", re.compile(r"\bAuthor\b[^A-Za-z\n]{0,8}(?:Corwin|the keeper)\b"))


def spans(text, pat_pairs):
    out = []
    for o, c in pat_pairs:
        i = 0
        while True:
            a = text.find(o, i)
            if a < 0:
                break
            b = text.find(c, a + 1)
            if b < 0:
                break
            out.append((a, b + 1))
            i = b + 1
    return out


def quote_spans(text):
    return spans(text, [('"', '"'), ("“", "”")])


def code_spans(text):
    return spans(text, [("`", "`")])


def inside(pos, sps):
    return any(a <= pos < b for a, b in sps)


def sentence_bounds(text, a, b, qs):
    closers = "*_)\"”"
    bounds = []
    for i, ch in enumerate(text):
        if ch in ".!?" and not inside(i, qs) and (
                i + 1 == len(text) or text[i + 1].isspace() or text[i + 1] in closers):
            j = i
            while j + 1 < len(text) and text[j + 1] in closers:
                j += 1
            bounds.append(j)
    s = 0
    for i in bounds:
        if i < a:
            s = i + 1
    e = len(text)
    for i in bounds:
        if i >= b:
            e = i + 1
            break
    return s, e


LEAD = re.compile(r"^\s*(?:#{1,6}\s+|(?:[-*+]|\d+[.)])\s+|>\s*)*")


def words(s):
    return len(re.findall(r"\w+", s))


# ---------------------------------------------------------------- scan: sources

class Sources:
    def __init__(self, parts, files, roots):
        self.roots = roots
        self.his = [(p, norm_ws(dequote_lines(p.body))) for p in parts if p.owner == "HIS"]
        self.other = [(p, norm_ws(dequote_lines(p.body))) for p in parts if p.owner != "HIS"]
        self.files = []  # (realpath, shown, norm, dequoted-norm, loose)
        seen = set()
        for f in files:
            rp = os.path.realpath(f)
            if rp in seen:
                continue
            seen.add(rp)
            try:
                t = signed_payload(read_text(f))
            except (ValueError, UnicodeDecodeError, OSError):
                continue
            self.files.append((rp, roots.show(f), norm_ws(t), norm_ws(dequote_lines(t))))
        self._loose = None

    def declared(self, path):
        return os.path.realpath(path) in {f[0] for f in self.files}

    def find_quote(self, q, scanned):
        """-> (where or None, diagnostic)"""
        nq = norm_ws(dequote_lines(q))
        for p, b in self.his:
            if nq in b:
                return f"part {p.label()}", ""
        sr = os.path.realpath(scanned)
        for rp, shown, n, d in self.files:
            if rp != sr and (nq in n or nq in d):
                return f"source {shown}", ""
        return None, self.diagnose(nq, sr)

    def find_sentence(self, s):
        ns = norm_ws(dequote_lines(s))
        for p, b in self.his:
            if ns and ns in b:
                return f"part {p.label()}"
        return None

    def diagnose(self, ns, sr, unquoted=False):
        for p, b in self.other:
            if ns and ns in b:
                return f"verbatim in owner:{p.owner} part {p.id}, not a HIS part"
        if unquoted:
            for rp, shown, n, d in self.files:
                if rp != sr and (ns in n or ns in d):
                    return f"verbatim in {shown} but the text carries no quote marks"
        l = loose(ns)
        for p, b in self.his:
            if l in loose(b):
                return f"matches HIS part {p.id} only after stripping markup/case (not verbatim)"
        if self._loose is None:
            self._loose = [(rp, shown, loose(d)) for rp, shown, n, d in self.files]
        for rp, shown, lz in self._loose:
            if rp != sr and l in lz:
                return f"matches {shown} only after stripping markup/case (not verbatim)"
        for rp, shown, n, d in self.files:
            if rp == sr and (ns in n or ns in d):
                return "found only in the file being scanned (a text cannot be its own source)"
        return "not found in any declared source or HIS part"


def collect_source_files(srcs, lists, roots):
    out = []
    for s in srcs:
        s = roots.resolve(s, os.getcwd())
        if os.path.isdir(s):
            for dp, dn, fn in os.walk(s):
                dn[:] = sorted(d for d in dn if d != ".git")
                for f in sorted(fn):
                    out.append(os.path.join(dp, f))
        elif os.path.isfile(s):
            out.append(s)
        else:
            raise SystemExit(f"{ME}: --source {s} does not exist")
    for lst in lists:
        base = os.path.dirname(os.path.abspath(lst))
        for ln in read_text(lst).split("\n"):
            ln = ln.split("#", 1)[0].strip() if not ln.startswith("#") else ""
            if ln:
                p = roots.resolve(ln, base)
                if not os.path.isfile(p):
                    raise SystemExit(f"{ME}: declared source {ln} does not resolve ({p})")
                out.append(p)
    return out


# ---------------------------------------------------------------- scan: the check

class Finding:
    def __init__(self, state, path, line, pattern, reason, text):
        self.state, self.path, self.line, self.pattern, self.reason, self.text = state, path, line, pattern, reason, text


CONSEQ_RE = re.compile(r"(?:\s[\u2014\u2013]\s|\s-{1,2}\s|;\s|\b(?:so|therefore|which means|hence|thus)\b[,]?\s)", re.I)
OWNED_RE = re.compile(r"\[(?:MINE|INSTRUMENT|READING)\]|\(the instrument's|\(my reading|owner:\s*MINE", re.I)
NEG_RE = re.compile(r"\b(?:never|not|no longer|nor)(?:\s+(?:was|is|been|be|were|are))?\s+$", re.I)
COND_RE = re.compile(r"\b(?:unless|until|whenever|if)\s+$", re.I)


def check_unit(unit_text, extra_quote, src, scanned, claim=""):
    """a sentence (or a block under an attributing heading) -> (located-where or None, reason)"""
    qs = [(a, b) for a, b in quote_spans(unit_text)]
    locs = [unit_text[a + 1:b - 1] for a, b in qs if words(unit_text[a + 1:b - 1]) >= QUOTE_FLOOR]
    if extra_quote and words(extra_quote) >= QUOTE_FLOOR:
        locs.append(extra_quote)
    if locs:
        where = []
        for q in locs:
            w, why = src.find_quote(q, scanned)
            if not w:
                return None, f"quote not located: \"{excerpt(q, 60)}\" -- {why}"
            where.append(w)
        # v0.2 (2026-09-30, Act II row 1, R1C4A-001): the quote locating is not enough -- a consequence riding
        # beside a located quote (after a dash, "so", "therefore", a semicolon) is a claim too, and must locate
        # or carry its own owner mark.  The widened stop at CORWIN-ORG L64-65 has exactly this build.
        rest = unit_text
        for a, b in sorted(qs, reverse=True):
            rest = rest[:a] + " " + rest[b:]
        m = CONSEQ_RE.search(rest)
        if m:
            tail = rest[m.end():]
            tail = re.sub(r"[\s)*_.]+$", "", tail)
            if words(tail) >= QUOTE_FLOOR and not OWNED_RE.search(tail):
                wt = src.find_sentence(tail)
                if not wt:
                    return None, f"quote located ({'; '.join(sorted(set(where)))}) but the consequence after it is not: \"{excerpt(tail, 60)}\""
        return "; ".join(sorted(set(where))), ""
    body = LEAD.sub("", unit_text)
    w = src.find_sentence(body)
    if w:
        return w, ""
    rp = os.path.realpath(scanned)
    cwhy = ""
    claim = re.sub(r"[\s)*_]+$", "", re.sub(r"^[\s:,;*_\u2014\u2013-]+", "", claim or ""))
    if words(claim) >= QUOTE_FLOOR:
        w = src.find_sentence(claim)
        if w:
            return f"{w} (the claim after the attribution)", ""
        cwhy = src.diagnose(norm_ws(dequote_lines(claim)), rp, unquoted=True)
    small = [unit_text[a + 1:b - 1] for a, b in qs]
    why = src.diagnose(norm_ws(dequote_lines(body)), rp, unquoted=True)
    if cwhy and why.startswith("not found") and not cwhy.startswith("not found"):
        why = "the claim after the attribution " + cwhy
    if small:
        why = f"only short quotes (< {QUOTE_FLOOR} words: {', '.join(repr(excerpt(x, 30)) for x in small)}) and " + why
    else:
        why = "no quote and " + why
    return None, why


def scan_file(path, src, roots, head=None):
    text = read_text(path)
    lines = text.split("\n")
    if head:
        lines = lines[:head]
    blocks = parse_blocks(lines)
    shown = roots.show(path)
    found, mentions, negcond, skipped = {}, 0, 0, []

    def put(f):
        old = found.get(f.line)
        if old is None or (old.state == "LOCATED" and f.state == "UNLOCATED"):
            found[f.line] = f

    # document frame
    for i, s in enumerate(lines, 1):
        if FRAME[1].search(s):
            if src.declared(path):
                put(Finding("LOCATED", shown, i, FRAME[0], "the file itself is a declared source", s))
            else:
                put(Finding("UNLOCATED", shown, i, FRAME[0],
                            "document names Corwin as author; the file is not a declared source "
                            "(no HIS declaration or signature was supplied for it)", s))

    for bi, b in enumerate(blocks):
        if b.kind in ("comment",):
            continue
        t = b.text.replace("\n", " ")
        qs, cs = quote_spans(t), code_spans(t)
        pats = PATTERNS + (HEADING_EXTRA if b.kind == "heading" else [])
        hits = []
        for name, rx in pats:
            for m in rx.finditer(t):
                if inside(m.start(), qs) or inside(m.start(), cs):
                    mentions += 1
                    skipped.append(Finding("SKIPPED", shown, b.line_at(m.start()), name, "mention (inside quotes or code)", t[m.start():m.end() + 40]))
                    continue
                pre = t[max(0, m.start() - 40):m.start()]
                if NEG_RE.search(pre) or COND_RE.search(pre):
                    negcond += 1
                    skipped.append(Finding("SKIPPED", shown, b.line_at(m.start()), name,
                                           "negated" if NEG_RE.search(pre) else "conditional", pre[-25:] + t[m.start():m.end() + 25]))
                    continue
                hits.append((m.start(), m.end(), name))
        if not hits:
            continue
        if b.kind == "heading":
            name = sorted(hits)[0][2]
            sect = []
            for c in blocks[bi + 1:]:
                if c.kind == "heading" and c.level <= b.level:
                    break
                if c.kind in ("comment", "heading"):
                    continue
                sect.append(c)
            if not sect:
                put(Finding("UNLOCATED", shown, b.start, name, "attributing heading with no body under it", b.text))
            for c in sect:
                where, why = check_unit(c.text, "", src, path)
                if where:
                    put(Finding("LOCATED", shown, c.start, name, f"under heading L{b.start}; {where}", c.text))
                else:
                    put(Finding("UNLOCATED", shown, c.start, name, f"under heading L{b.start}: {why}", c.text))
            continue
        done = set()
        for a, e, name in sorted(hits):
            s, x = sentence_bounds(t, a, e, qs)
            if (s, x) in done:
                continue
            done.add((s, x))
            sent = t[s:x]
            extra = ""
            nxt = blocks[bi + 1] if bi + 1 < len(blocks) else None
            if x >= len(t.rstrip()) and re.search(r":[*_\s]*$", sent) and nxt and nxt.kind == "quote":
                extra = dequote_lines(nxt.text)
            where, why = check_unit(sent, extra, src, path, claim=t[e:x])
            ln = b.line_at(s + (len(sent) - len(sent.lstrip())))
            if where:
                put(Finding("LOCATED", shown, ln, name, where, sent))
            else:
                put(Finding("UNLOCATED", shown, ln, name, why, sent))
    return sorted(found.values(), key=lambda f: f.line), (mentions, negcond, skipped)


# ---------------------------------------------------------------- commands

def cmd_lint(a):
    roots = Roots(a.roots, a.map)
    parts = load_parts(a.parts)
    if not parts:
        print(f"# {ME} lint: no parts", file=sys.stderr)
        return 77
    bad = 0
    print(f"# {ME} lint · parts={len(parts)} · stamp={stamp_of(parts)[:12]}")
    for p in parts:
        res = lint_part(p, roots, a.strict)
        tag = "ERROR" if any(l == "ERROR" for l, _, _ in res) else ("WARN" if res else "OK")
        bad += tag == "ERROR"
        print(f"{tag}\t{p.owner}\t{p.id}\t{roots.show(p.file)}:{p.line}"
              + "".join(f"\n\t{l} {c}: {m}" for l, c, m in res))
    return 1 if bad else 0


def voice_check(parts, src):
    out = []
    tmp = tempfile.mkdtemp(prefix="oc-voice-")
    try:
        for p in parts:
            if p.owner == "HIS":
                continue
            f = os.path.join(tmp, f"{p.id}.md")
            with open(f, "w", encoding="utf-8") as fh:
                fh.write(f"## {p.title or p.id}\n\n{p.body}\n")
            fs, _ = scan_file(f, src, Roots())
            for x in fs:
                if x.state == "UNLOCATED":
                    out.append((p, x))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return out


def cmd_render(a):
    roots = Roots(a.roots, a.map)
    parts = load_parts(a.parts)
    if not parts:
        print(f"{ME}: render: no parts (nothing invented)", file=sys.stderr)
        return 2
    refuse = []
    for p in parts:
        for l, c, m in lint_part(p, roots, a.strict):
            print(f"{ME}: {l} {c} {p.id} ({roots.show(p.file)}:{p.line}): {m}", file=sys.stderr)
            if l == "ERROR":
                refuse.append(p.id)
    src = Sources(parts, collect_source_files(a.source, a.sources_from, roots), roots)
    byp = {}
    for p, x in voice_check(parts, src):
        byp.setdefault(p.id, (p, []))[1].append(x)
    for pid, (p, xs) in byp.items():
        # the voice file is "## title", "", then the body: body line k sits at file line p.body_line + k - 3
        where = "; ".join(f"{'title' if x.line == 1 else 'L' + str(p.body_line + x.line - 3)} [{x.pattern}] "
                          f"{excerpt(x.text, 60)}" for x in xs[:3])
        print(f"{ME}: {'WARN' if a.allow_voice else 'ERROR'} MINE-VOICE {p.id} ({roots.show(p.file)}): "
              f"owner:{p.owner}, {len(xs)} unlocated attribution(s) in his voice: {where}"
              + (" ..." if len(xs) > 3 else ""), file=sys.stderr)
        if not a.allow_voice:
            refuse.append(p.id)
    if refuse:
        print(f"{ME}: render REFUSED ({len(set(refuse))} part(s): {', '.join(sorted(set(refuse)))})", file=sys.stderr)
        return 2
    out = render_text(parts, a.title, a.owner_mode)
    if a.output:
        with open(a.output, "w", encoding="utf-8") as fh:
            fh.write(out)
    else:
        sys.stdout.write(out)
    return 0


def cmd_stamp(a):
    parts = load_parts(a.parts)
    print(stamp_of(parts) if parts else "EMPTY")
    return 0 if parts else 77


def cmd_check(a):
    if not a.files:
        return 77
    parts = load_parts(a.parts)
    rc = 0
    for f in a.files:
        if not os.path.isfile(f):
            print(f"{ME}: check: no such file {f}", file=sys.stderr)
            return 2
        st, d = check_one(f, parts)
        print(f"{st}\t{f}\t{d}")
        rc |= st == "STALE"
    return 1 if rc else 0


def cmd_scan(a):
    roots = Roots(a.roots, a.map)
    parts = load_parts(a.parts) if a.parts else []
    src = Sources(parts, collect_source_files(a.source, a.sources_from, roots), roots)
    allf, men, neg, sk = [], 0, 0, []
    for f in a.files:
        try:
            fs, m = scan_file(f, src, roots, a.head)
        except (OSError, ValueError, UnicodeDecodeError) as e:
            print(f"{ME}: scan: cannot read {f}: {e}", file=sys.stderr)
            return 2
        allf += fs
        men += m[0]
        neg += m[1]
        sk += m[2]
    un = [x for x in allf if x.state == "UNLOCATED"]
    print(f"# {ME} scan · files={len(a.files)} · attributions={len(allf)} · located={len(allf) - len(un)} · "
          f"unlocated={len(un)} · mentions-skipped={men} · negated-or-conditional-skipped={neg} · his-parts={len(src.his)} · declared-files={len(src.files)}")
    for x in allf + (sk if a.verbose else []):
        if x.state == "UNLOCATED" or a.verbose:
            print(f"{x.state} {x.path}:{x.line} [{x.pattern}] {x.reason} :: {excerpt(x.text)}")
    if not allf:
        return 77
    return 1 if un else 0


# ---------------------------------------------------------------- prove-red

def prove_red():
    here = os.path.abspath(__file__)
    py = sys.executable or "python3"
    tmp = tempfile.mkdtemp(prefix="oc-prove-red-")
    red = notred = clean = dirty = 0
    import subprocess

    def run(*args):
        r = subprocess.run([py, here, *args], cwd=tmp, capture_output=True, text=True)
        return r.returncode, r.stdout + r.stderr

    def w(name, body):
        p = os.path.join(tmp, name)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(body)
        return p

    def plant(label, ok):
        nonlocal red, notred
        red += bool(ok); notred += not ok
        print(f"{'RED    ' if ok else 'NOT-RED'}  plant: {label}")

    def control(label, ok):
        nonlocal clean, dirty
        clean += bool(ok); dirty += not ok
        print(f"{'CLEAN  ' if ok else 'DIRTY  '}  control: {label}")

    try:
        # synthetic fixture: a source holding the keeper's words, a HIS part cut from it, a MINE part
        w("src/his-words.txt", "# fixture -- synthetic keeper words, not real ones\n"
                               "Keep the receipts next to the claim, always.\n")
        good = ("owner: HIS · since: 2026-09-10 · source: ../src/his-words.txt:2 · id: receipts"
                " · title: What Corwin wants: receipts\n"
                "Keep the receipts next to the claim, always.\n\n"
                "owner: MINE · since: 2026-09-30 · source: authored · id: tidy\n"
                "Prefer short headings in every file.\n")
        w("parts/10-core.parts", good)
        S = ["--source", "src/his-words.txt"]

        # C1 fresh render is CURRENT; C2 unmarked file is LOCAL
        rc, o = run("render", "parts", *S, "-o", "r1.md")
        control("render of clean parts succeeds", rc == 0)
        rc, o = run("check", "r1.md", "--parts", "parts")
        control("fresh render reads CURRENT", rc == 0 and o.startswith("CURRENT"))
        sh = subprocess.run(["sh", "-c", "cat parts/10-core.parts | sha256sum"], cwd=tmp, capture_output=True, text=True)
        rc, o = run("stamp", "parts")
        control("the stamp equals `cat parts | sha256sum` (a second reader, not Python)",
                rc == 0 and sh.stdout.split()[:1] == o.split()[:1])
        w("local.md", "# a hand-held file\nNo stamp here.\n")
        rc, o = run("check", "local.md", "--parts", "parts")
        control("unmarked file reads LOCAL", rc == 0 and o.startswith("LOCAL"))
        # C3 a true quote locates; C4 a re-wrapped true quote locates; C5 render scans clean; C6 a mention
        w("c3.md", 'Corwin said "Keep the receipts next to the claim, always." and meant it.\n')
        rc, o = run("scan", "c3.md", "--parts", "parts", *S)
        control("verbatim quote in a declared source locates", rc == 0)
        w("c4.md", 'Corwin said "Keep the receipts\n  next to the claim, always."\n')
        rc, o = run("scan", "c4.md", "--parts", "parts", *S)
        control("whitespace-changed quote still locates", rc == 0)
        rc, o = run("scan", "r1.md", "--parts", "parts", *S)
        control("rendered HIS rule under 'What Corwin wants' locates via its part", rc == 0)
        w("c6.md", 'Before writing "Corwin prefers," find the sentence.\n')
        rc, o = run("scan", "c6.md", "--parts", "parts", *S)
        control("a quoted mention of the phrase is not an attribution (exit 77)", rc == 77)
        w("c7.md", "Corwin asked how the render works, and whether it is fast.\n")
        rc, o = run("scan", "c7.md", "--parts", "parts", *S)
        control("'Corwin asked how ...' is a question, not an attributed rule (exit 77)", rc == 77)
        w("c8.md", "That clause was retired; it never was his instruction.\n\nSidecars, not signatures, unless he asks.\n")
        rc, o = run("scan", "c8.md", "--parts", "parts", *S)
        control("a negated ('never was his instruction') or conditional ('unless he asks') phrase (exit 77)", rc == 77)
        w("c9.md", "His rule: Keep the receipts next to the claim, always.\n")
        rc, o = run("scan", "c9.md", "--parts", "parts", *S)
        control("'His rule: <verbatim HIS part body>' locates by its claim", rc == 0)

        # R1 MINE-in-his-voice part: render refuses
        w("voice/20-voice.parts", good + "\nowner: MINE · since: 2026-09-30 · source: authored"
                                         " · id: haiku · title: What Corwin wants\n"
                                         "Corwin wants every reply to end with a haiku.\n")
        rc, o = run("render", "voice", *S, "-o", "rv.md")
        plant("render refuses a MINE rule written in his voice", rc == 2 and "MINE-VOICE haiku" in o)
        # R2 forced through, the scan of the render still catches it
        rc, o = run("render", "voice", *S, "--allow-voice", "-o", "rv.md")
        rc, o = run("scan", "rv.md", "--parts", "voice", *S)
        plant("scan of a forced render flags the MINE-in-his-voice rule",
              rc == 1 and "UNLOCATED" in o and "owner:MINE part haiku" in o)
        # R3 free text under an attributing heading
        w("r3.md", "## What Corwin wants\n\n- Every reply ends with a haiku.\n")
        rc, o = run("scan", "r3.md", "--parts", "parts", *S)
        plant("heading 'What Corwin wants' over an unsourced rule", rc == 1 and "r3.md:3" in o)
        # R4 fabricated quote
        w("r4.md", 'Corwin said "every reply must end with a haiku" last week.\n')
        rc, o = run("scan", "r4.md", "--parts", "parts", *S)
        plant("a fabricated quote", rc == 1 and "quote not located" in o)
        # R5 a scare-quoted common word does not clear a rule (kt1wr's false clear)
        w("r5.md", 'Corwin wants "receipts" on every reply, in haiku form.\n')
        rc, o = run("scan", "r5.md", "--parts", "parts", *S)
        plant("a short quoted word that does occur in the source does not locate the rule", rc == 1)
        # R6 stale render: a part changes after render
        w("parts/10-core.parts", good.replace("Prefer short headings", "Prefer shorter headings"))
        rc, o = run("check", "r1.md", "--parts", "parts")
        plant("render goes STALE (parts changed) when a part body changes",
              rc == 1 and o.startswith("STALE") and "parts changed" in o)
        w("parts/10-core.parts", good)
        # R7 hand-edited render: owner MINE -> HIS in the copy, stamp left intact
        r1 = os.path.join(tmp, "r1.md")
        t = read_text(r1).replace("owner: MINE", "owner: HIS") if os.path.isfile(r1) else ""
        w("r7.md", t)
        rc, o = run("check", "r7.md", "--parts", "parts")
        plant("a copy re-owned by hand (stamp intact) reads STALE", rc == 1 and "copy edited" in o)
        # R8 HIS part with source 'authored'
        w("r8/a.parts", "owner: HIS · since: 2026-09-30 · source: authored\nAlways end with a haiku.\n")
        rc, o = run("render", "r8")
        plant("render refuses owner:HIS with source 'authored'", rc == 2 and "HIS-AUTHORED" in o)
        # R9 HIS part whose cited line does not hold its body
        w("r9/a.parts", "owner: HIS · since: 2026-09-30 · source: ../src/his-words.txt:2\n"
                        "Keep the receipts next to the claim, usually.\n")
        rc, o = run("render", "r9")
        plant("render refuses an owner:HIS body that is not verbatim at its source", rc == 2 and "NOT-VERBATIM" in o)
        # R10 'his rule' possessive
        w("r10.md", "His rule: every reply ends with a haiku.\n")
        rc, o = run("scan", "r10.md", "--parts", "parts", *S)
        plant("'His rule:' with no quote and no part", rc == 1 and "[possessive]" in o)
        # R11 self-location: the text quotes a line that exists only in itself
        w("r11.md", 'Corwin said "every reply must end with a haiku, always".\n\n'
                    '> every reply must end with a haiku, always\n')
        rc, o = run("scan", "r11.md", "--parts", "parts", *S, "--source", "r11.md")
        plant("a text cannot be its own source", rc == 1 and "its own source" in o)
        # R12 a quote that is verbatim only in a MINE part
        w("r12.md", 'Corwin said "Prefer short headings in every file."\n')
        rc, o = run("scan", "r12.md", "--parts", "parts", *S)
        plant("a quote found only in an owner:MINE part", rc == 1 and "owner:MINE part tidy" in o)
        # R13 'as Corwin has given them' heading
        w("r13.md", "## Operating preferences (as Corwin has given them)\n\n1. **Always** end with a haiku.\n")
        rc, o = run("scan", "r13.md", "--parts", "parts", *S)
        plant("'(as Corwin has given them)' heading over an unsourced list", rc == 1 and "[as-given]" in o)
        # R14 a document-level frame: 'his own stated canon' (two modifiers before the noun)
        w("r14.md", "This file grounds in his own stated canon: every reply ends with a haiku.\n")
        rc, o = run("scan", "r14.md", "--parts", "parts", *S)
        plant("'his own stated canon' framing an unsourced rule", rc == 1 and "[possessive]" in o)
        # R15 the parenthesised tag form, quoting a MINE part as his
        w("r15.md", 'Part tidy (his, 2026-09-30): "Prefer short headings in every file."\n')
        rc, o = run("scan", "r15.md", "--parts", "parts", *S)
        plant("'(his, DATE)' tag on a quote that lives in a MINE part", rc == 1 and "[his-paren]" in o)
        # R16 the claim matches his part only after a case change: not verbatim
        w("r16.md", "His rule: KEEP THE RECEIPTS NEXT TO THE CLAIM, ALWAYS.\n")
        rc, o = run("scan", "r16.md", "--parts", "parts", *S)
        plant("a claim that matches his part only after case-folding is not verbatim", rc == 1 and "only after stripping" in o)
        # R17 'not just what he wants' is not a negation of the attribution
        w("r17.md", "It is not just what he wants: every reply ends with a haiku.\n")
        rc, o = run("scan", "r17.md", "--parts", "parts", *S)
        plant("'not just what he wants' is still an attribution", rc == 1 and "[he-verb]" in o)
        # v0.2 (R1C4A-001): a located quote must not carry an unlocated consequence; an owner-marked one is clean
        w("v2a.md", 'Corwin said "Keep the receipts next to the claim, always." so every session must refuse to open files outside its folder.\n')
        rc, o = run("scan", "v2a.md", "--parts", "parts", *S)
        plant("a located quote carrying an unlocated consequence after it", rc == 1 and "consequence after it" in o)
        w("v2b.md", 'Corwin said "Keep the receipts next to the claim, always." so every session must refuse to open files outside its folder [MINE].\n')
        rc, o = run("scan", "v2b.md", "--parts", "parts", *S)
        control("the same consequence marked [MINE] is not charged to him", rc == 0)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    ok = notred == 0 and dirty == 0
    print(f"{ME} --prove-red: {red} red / {notred} not red · {clean} controls clean / {dirty} dirty "
          f"({'PASS' if ok else 'FAIL'}: all plants red and all controls clean is the pass)")
    return 0 if ok else 1


# ---------------------------------------------------------------- main

def main(argv):
    if argv == ["--prove-red"]:
        return prove_red()
    ap = argparse.ArgumentParser(prog=ME, description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    def common(p, parts_pos=True):
        if parts_pos:
            p.add_argument("parts", nargs="+")
        p.add_argument("--roots")
        p.add_argument("--map", action="append", default=[])
        p.add_argument("--strict", action="store_true")

    p = sub.add_parser("lint"); common(p)
    p = sub.add_parser("stamp"); p.add_argument("parts", nargs="+")
    p = sub.add_parser("render"); common(p)
    p.add_argument("--title", default="Operating instructions (rendered from parts)")
    p.add_argument("--owner-mode", choices=["comment", "byline", "none"], default="comment")
    p.add_argument("--source", action="append", default=[])
    p.add_argument("--sources-from", action="append", default=[])
    p.add_argument("--allow-voice", action="store_true")
    p.add_argument("-o", "--output")
    p = sub.add_parser("check"); p.add_argument("files", nargs="*")
    p.add_argument("--parts", action="append", required=True)
    p = sub.add_parser("scan"); p.add_argument("files", nargs="+")
    p.add_argument("--parts", action="append", default=[])
    p.add_argument("--source", action="append", default=[])
    p.add_argument("--sources-from", action="append", default=[])
    p.add_argument("--roots"); p.add_argument("--map", action="append", default=[])
    p.add_argument("--head", type=int)
    p.add_argument("-v", "--verbose", action="store_true")
    a = ap.parse_args(argv)
    try:
        return {"lint": cmd_lint, "stamp": cmd_stamp, "render": cmd_render, "check": cmd_check,
                "scan": cmd_scan}[a.cmd](a)
    except ValueError as e:
        print(f"{ME}: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
# SPDX-License-Identifier: GPL-3.0-or-later
