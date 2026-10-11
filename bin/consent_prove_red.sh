#!/bin/sh
# consent_prove_red.sh -- planted records for consent_check.sh (SPEC-consent.md section 13).
# Builds a throwaway ed25519 key, a base record that must PASS (the door), and red plants that must
# not. Each plant is hashed by a sed|grep pipeline independent of the awk parser, then signed.
#   sh consent_prove_red.sh [--keep DIR]      exit 0 iff every plant exits as expected
# All identities are synthetic (example.org / example.net / example.com).
# SPDX-License-Identifier: GPL-3.0-or-later
set -u
here=$(cd "$(dirname "$0")" && pwd)
if [ "${1:-}" = "--keep" ]; then d=${2:?--keep DIR}; mkdir -p "$d"; else d=$(mktemp -d) || exit 64; trap 'rm -rf "$d"' EXIT; fi
command -v ssh-keygen >/dev/null 2>&1 || { echo "prove-red: NOT CHECKED -- no ssh-keygen"; exit 77; }
NOW=2026-09-30T12:00:00Z
NL='
'
rm -f "$d/k" "$d/k.pub" "$d/k2" "$d/k2.pub"
ssh-keygen -q -t ed25519 -N '' -C p7b-test -f "$d/k" </dev/null
ssh-keygen -q -t ed25519 -N '' -C p7b-other -f "$d/k2" </dev/null
FP=$(ssh-keygen -lf "$d/k.pub" | awk '{print $2}'); FP2=$(ssh-keygen -lf "$d/k2.pub" | awk '{print $2}')
printf 'p7b-test@example.org namespaces="consent-record" %s\n' "$(cut -d' ' -f1,2 "$d/k.pub")" > "$d/allowed_signers"
U1=https://keys.example.org/p7b.pub
U2=https://archive.example.net/web/2026/https://keys.example.org/p7b.pub
printf '%s\t%s\n%s\t%s\n' "$U1" "$FP" "$U2" "$FP" > "$d/source-keys.tsv"
printf '%s\t%s\n%s\t%s\n' "$U1" "$FP2" "$U2" "$FP" > "$d/source-keys-mismatch.tsv"
printf 'p7b-prove-red-2026-09-30-a\n' > "$d/seen.txt"

cat > "$d/base.tmpl" <<'EOF'
record_id:        p7b-prove-red-2026-09-30-a        # unique
schema:           consent-record/v1
issued:           2026-09-30T06:00:00-05:00
reconfirmed:      2026-09-30T06:17:00-05:00          # MUST be >= issued + 10 min (deferral-detector)
expires:          2026-09-30T18:00:00-05:00

issuer:
  name:           P7B Test Issuer
  principal:      p7b-test@example.org
  key_fingerprint:@FP@
  identity_urls:                               # >=2 INDEPENDENT public sources of THIS key
    - https://keys.example.org/p7b.pub
    - https://archive.example.net/web/2026/https://keys.example.org/p7b.pub

agent:
  authorized:     Claude (Cowork / simply-self)
  session:        p7b-session-0001

grant:                                         # be SPECIFIC — no ALL/ANY/everything/whatever/"full use"
  action:         interactive SSH login, read-only shell
  target_host:    testhost
  target_scope:                                # exact paths/objects, nothing wider
    - /srv/p7b/** (read)
  mode:           read-only                     # explicit: NO write, NO root/sudo, NO package install
  network:        none-beyond-session           # no egress/exfil beyond the stated task
  credential:
    which:        issuer-held
    holder:       issuer
    retention:    agent never receives key
  irreversible_parts: none
  window:         2026-09-30T06:00:00-05:00 .. 2026-09-30T18:00:00-05:00

parties_affected:                              # per-party: nobody consents for another
  - party:        P7B Test Issuer
    status:       signs-this-record
  - party:        co-console user
    status:       "out-of-scope: access limited to issuer-owned /srv/p7b only"

prohibited_category_decision:
  acknowledged:   true
  decision:       "no lift — key stays issuer-held; agent never handles a credential"
  rationale:      read-only look at test data; nothing leaves the host

revocation:
  path:           https://keys.example.org/revoked
  effect:         immediate-on-publish

affirmation:      "Specific, not blanket. Unrushed and uncoerced. I can revoke. This authorizes
                   only the single action above, only within the window."
payload_sha256:   @SHA@
EOF
sed "s|@FP@|$FP|" "$d/base.tmpl" > "$d/base.body"
# P7B_NOCOMMENT=1 strips the template's guidance comments from the base -- used only to compare with a
# tool that scans comments, so the comparison is not swamped by one difference
if [ "${P7B_NOCOMMENT:-0}" = 1 ]; then sed 's/[[:space:]][[:space:]]*#.*$//' "$d/base.body" > "$d/x" && mv "$d/x" "$d/base.body"; fi

seal() { # name [signing-key]
	h=$(grep -v '^[[:space:]]*payload_sha256[[:space:]]*:' "$d/$1.body" | sha256sum | cut -c1-64)
	sed "s/@SHA@/$h/" "$d/$1.body" > "$d/$1.payload"
	ssh-keygen -Y sign -f "${2:-$d/k}" -n consent-record < "$d/$1.payload" > "$d/$1.sig" 2>/dev/null
	{ printf '# prove-red plant %s -- synthetic record, example.* identities only\n' "$1"
	  echo '-----BEGIN CONSENT PAYLOAD-----'; cat "$d/$1.payload"; echo '-----END CONSENT PAYLOAD-----'; } > "$d/$1.rec"
}
total=0 ok=0
check() { # name expect [args...]
	n=$1 want=$2; shift 2
	printf '%s\n' "$want" "$@" > "$d/$n.args"   # expected exit, then the arguments, one per line
	sh "$here/consent_check.sh" --record "$d/$n.rec" "$@" > "$d/$n.out" 2>&1; got=$?
	total=$((total + 1))
	if [ "$got" = "$want" ]; then ok=$((ok + 1)); r=ok; else r=MISS; fi
	printf '%-4s %-24s want %-3s got %-3s %s\n' "$r" "$n" "$want" "$got" "$(tail -n 1 "$d/$n.out")"
}
std() { echo "--now $NOW --sig $d/$1.sig --allowed-signers $d/allowed_signers --source-keys $d/source-keys.tsv"; }
plant() { # name expect sed-script [extra args]
	n=$1 want=$2 scr=$3; shift 3
	sed -e "$scr" "$d/base.body" > "$d/$n.body"; seal "$n"
	check "$n" "$want" $(std "$n") "$@"
}

echo "== door: legitimate records must PASS (exit 0) =="
plant D01-base 0 ''
plant D02-template-values 0 's/^\(  session: *\).*/\1any session presenting this record/; s/^\(  irreversible_parts: \).*/\1none — any write\/delete is OUT OF SCOPE and prohibited/'
plant D03-no4c-mentioned 0 "s/^\(  rationale: *\).*/\1read-only look; the NO4C stop is not raised here/;/^affirmation:/i\\${NL}# NO4C-CARRIED (retained copy of a past envelope)"
plant D04-urgency-framing 0 's/^\(  rationale: *\).*/\1urgent: rotate before noon, noconfirm -- still read-only/'
sed -e '' "$d/base.body" > "$d/D05-crlf.body"; seal D05-crlf; sed 's/$/\r/' "$d/D05-crlf.rec" > "$d/x" && mv "$d/x" "$d/D05-crlf.rec"
check D05-crlf 0 $(std D05-crlf)
plant D06-end-of-session 0 's/^\(expires: *\).*/\1end-of-session/; s/^\(  window: *\).*/\12026-09-30T06:00:00-05:00 .. end-of-session/' --session-end 2026-09-30T20:00:00Z
LIFT='s/^\(    holder: *\).*/\1agent/; s/^\(    retention: *\).*/\1agent does not persist; discarded at expires/; s/^\(  decision: *\).*/\1"agent-held credential — I deliberately lift the park for THIS narrow read-only action, on the record, for the stated window"/'
plant D07-keeper-lift 0 "$LIFT" --keeper p7b-test@example.org

echo "== red: must not PASS =="
plant R01-ALL-action 2 's/^\(  action: *\).*/\1ALL actions on testhost/'
plant R02-full-use 2 's/^\(  action: *\).*/\1full use of my systems/'
plant R03-later-gain 2 's/^\(  action: *\).*/\1keep the login for later gain/'
plant R04-whatever 2 's/^\(  network: *\).*/\1whatever the task needs/'
plant R05-rushed 2 's/^\(reconfirmed: *\)[^ ]*/\12026-09-30T06:05:00-05:00/'
plant R06-expired 1 's/^\(expires: *\).*/\12026-09-30T06:30:00-05:00/; s/^\(  window: *\).*/\12026-09-30T06:00:00-05:00 .. 2026-09-30T06:30:00-05:00/'
sed -e '' "$d/base.body" > "$d/R07-sha-mismatch.body"; seal R07-sha-mismatch; sed 's/read-only shell/read-write shell/' "$d/R07-sha-mismatch.rec" > "$d/x" && mv "$d/x" "$d/R07-sha-mismatch.rec"
check R07-sha-mismatch 1 $(std R07-sha-mismatch)
# R07b: a wrong hash that the issuer then signed -- the signature is GOOD, so only G3 can catch it
sed "s/@SHA@/$(printf 'not the payload' | sha256sum | cut -c1-64)/" "$d/base.body" > "$d/R07b-signed-wrong-hash.payload"
ssh-keygen -Y sign -f "$d/k" -n consent-record < "$d/R07b-signed-wrong-hash.payload" > "$d/R07b-signed-wrong-hash.sig" 2>/dev/null
{ echo '-----BEGIN CONSENT PAYLOAD-----'; cat "$d/R07b-signed-wrong-hash.payload"; echo '-----END CONSENT PAYLOAD-----'; } > "$d/R07b-signed-wrong-hash.rec"
check R07b-signed-wrong-hash 1 $(std R07b-signed-wrong-hash)
plant R08-missing-expires 1 '/^expires:/d'
plant R09-blank-revocation 1 's/^\(  path: *\).*/\1/'
plant R10-same-host 1 's|^    - https://archive.example.net/.*|    - https://keys.example.org/mirror/p7b.pub|'
plant R11-userinfo-host 1 's|^    - https://keys.example.org/p7b.pub|    - https://archive.example.net@keys.example.org/p7b.pub|; s|^    - https://archive.example.net/.*|    - https://keys.example.org/p7b.pub|'
plant R11b-userinfo-ip 1 's|^    - https://keys.example.org/p7b.pub|    - https://keys.example.org@192.0.2.7/p7b.pub|; s|^    - https://archive.example.net/.*|    - https://192.0.2.7/p7b.pub|'
plant R12-subdomain 1 's|^    - https://archive.example.net/.*|    - https://mirror.example.org/p7b.pub|'
plant R13-agent-held-nolift 2 's/^\(    holder: *\).*/\1agent/; s/^\(    retention: *\).*/\1agent does not persist; discarded at expires/'
plant R14-family-attached 2 's/co-console user/my daughter/; s|"out-of-scope: access limited to issuer-owned /srv/p7b only"|"separate signed record attached: d.rec"|'
plant R15-other-signs 1 's|"out-of-scope: access limited to issuer-owned /srv/p7b only"|signs-this-record|'
sed -e '' "$d/base.body" > "$d/R16-no4c-raised.body"; seal R16-no4c-raised; printf 'NO4C: hold this until the keeper lowers it\n' >> "$d/R16-no4c-raised.rec"
check R16-no4c-raised 2 $(std R16-no4c-raised)
plant R17-duplicate-key 1 '/^expires:/p'
plant R18-root-scope 2 's|^    - /srv/p7b/\*\* (read)|    - /** (read)|'
plant R19-third-party-email 2 's/^\(  rationale: *\).*/\1ask jo.example@example.com if unsure/'
sed -e '' "$d/base.body" > "$d/R20-no-sig.body"; seal R20-no-sig
check R20-no-sig 77 --now $NOW --source-keys "$d/source-keys.tsv"
sed -e '' "$d/base.body" > "$d/R21-wrong-key.body"; seal R21-wrong-key "$d/k2"
check R21-wrong-key 1 $(std R21-wrong-key)
plant R22-no-tz 1 's/^\(issued: *\)[^ ]*/\12026-09-30T06:00:00/'
sed -e '' "$d/base.body" > "$d/R23-two-payloads.body"; seal R23-two-payloads
{ echo '-----BEGIN CONSENT PAYLOAD-----'; echo 'grant:'; echo '  action: everything'; echo '-----END CONSENT PAYLOAD-----'; } >> "$d/R23-two-payloads.rec"
check R23-two-payloads 1 $(std R23-two-payloads)
plant R24-ack-false 1 's/^\(  acknowledged: *\).*/\1false/'
plant R25-lift-no-keeper 77 "$LIFT"
plant R26-lift-not-keeper 2 "$LIFT" --keeper someone-else@example.org
plant R27-blanket-lift 2 's/^\(    holder: *\).*/\1agent/; s/^\(    retention: *\).*/\1agent does not persist; discarded at expires/; s/^\(  decision: *\).*/\1"agent-held credential — I lift the park for everything"/' --keeper p7b-test@example.org
plant R28-window-wider 1 's/^\(  window: *\).*/\12026-09-30T06:00:00-05:00 .. 2026-10-01T18:00:00-05:00/'
sed -e '' "$d/base.body" > "$d/R29-key-mismatch-at-source.body"; seal R29-key-mismatch-at-source
check R29-key-mismatch-at-source 1 --now $NOW --sig "$d/R29-key-mismatch-at-source.sig" --allowed-signers "$d/allowed_signers" --source-keys "$d/source-keys-mismatch.tsv"
sed -e '/^expires:/d' "$d/base.body" > "$d/R30-field-outside.body"; seal R30-field-outside
printf 'expires:          2026-09-30T18:00:00-05:00\n' >> "$d/R30-field-outside.rec"
check R30-field-outside 1 $(std R30-field-outside)
plant R31-exclusion-trick 2 's/^\(  action: *\).*/\1read all files (prohibited: none)/'
plant R32-any-host 2 's/^\(  target_host: *\).*/\1any host on the lan/'
plant R33-wildcard-host 2 's/^\(  target_host: *\).*/\1*.example.org/'
plant R34-sudo-nolift 2 's/^\(  mode: *\).*/\1read-only, sudo for one package install/'
plant R35-not-yet-reconfirmed 2 '' --now 2026-09-30T11:10:00Z
plant R36-fp-not-signer 1 "s|^\(  key_fingerprint:\).*|\1$FP2|"
plant R37-replay 1 '' --seen "$d/seen.txt"
cp "$d/seen.txt" "$d/tmp\\new-seen.txt"   # a backslash in the path, as on the keeper's F:\\ inbox
plant R37b-replay-backslash-path 1 '' --seen "$d/tmp\\new-seen.txt"
plant R38-tab-indent 1 's/^  mode:/	mode:/'
plant R39-unknown-grant-key 2 's|^\(  network: .*\)|\1\n  also_scope:     /etc|'
plant R40-placeholder 1 's/^\(  target_host: *\).*/\1<host>/'
plant R41-anything 2 's/^\(  action: *\).*/\1do anything needed on testhost/'
plant R42-blanket-beside-no-lift 2 's/^\(  action: *\).*/\1ALL hosts, no lift needed/'
plant R43-no-reconfirmed 1 '/^reconfirmed:/d'
plant R44-rushed-with-comment 2 's/^\(reconfirmed: *\)[^ ]*.*$/\12026-09-30T06:05:00-05:00   # confirmed by phone/'
plant R45-no-payload-sha 1 '/^payload_sha256:/d'
# R46: the template's own preamble (its prose names both markers) kept above a correct payload
sed -e '' "$d/base.body" > "$d/R46-template-preamble.body"; seal R46-template-preamble
{ printf 'Everything between `-----BEGIN CONSENT PAYLOAD-----` and `-----END CONSENT\nPAYLOAD-----` is the signed payload. Change one byte after signing and\nverification fails (by design).\n\n'; cat "$d/R46-template-preamble.rec"; } > "$d/x" && mv "$d/x" "$d/R46-template-preamble.rec"
check R46-template-preamble 0 $(std R46-template-preamble)

rm -f "$d/k" "$d/k2" "$d/x"   # throwaway private halves: never left on disk; the .pub files stay as receipts
echo "prove-red: $ok/$total plants exited as expected (fixtures in $d)"
[ "$ok" -eq "$total" ]
