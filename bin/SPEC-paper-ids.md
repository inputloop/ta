<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# SPEC · paper-ids · which tokens in a paper are entry ids (2026-09-30)

Written after `paper-citations.py` read the line references `L151-153` and `L313-314` as entry ids and went RED.
Its prove-red had no line-reference case.

An entry id is `PREFIX-nnn`, where nnn is exactly three digits and the whole token is bounded by non-word
characters. PREFIX is exactly one of:
- `B<1-9><I|U>`;
- `P<1-2 digits><A|B>`;
- `R<digit>C<digit><A|B>`;
- `R<digit>`;
- `R<2|3><one or more of A-Z0-9>`;
- `L<digits><a letter A-Z><zero or more of A-Z0-9>`.

These are NOT ids:
- `L<digits>-<digits>`, a line range;
- `L<digits>` alone;
- anything with two or four digits after the dash.

Two implementations must list the same ids for the same file: `paper-citations.py`, and `paper-ids.awk`
(POSIX awk; prints one id per occurrence).
