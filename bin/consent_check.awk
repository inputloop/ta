# consent_check.awk -- P7B consent-record gate, written from SPEC-consent.md (POSIX awk, no gawk-isms)
#
#   CC_MODE=extract CC_OUT=DIR awk -f consent_check.awk RECORD
#       writes DIR/hashin (G3.1) and DIR/sigin (G7.1); prints issuer.principal; exit 0, or 3 if P1 fails
#   CC_MODE=check [CC_SHA=HEX|NA] [CC_SIG=GOOD|BAD|NA] [CC_SIGWHY=TEXT] [CC_SIGFP=FP] [CC_NOW=ISO]
#       [CC_SESSEND=ISO] [CC_KEEPER=PRINCIPAL] [CC_SRCKEYS=FILE] [CC_SEEN=FILE] awk -f consent_check.awk RECORD
#   (inputs come through ENVIRON, never -v: -v rewrites backslashes in Windows paths)
#       exit 0 PASS / 1 FAIL / 2 PARK / 77 NOT CHECKED / 64 usage
#
# Rule ids (P1..P7, G0..G7, N1, HL3) are the SPEC's; every result line names one.
# SPDX-License-Identifier: GPL-3.0-or-later

BEGIN {
	n = 0; crseen = 0
	# string inputs arrive through the environment, not -v: awk -v rewrites backslash escapes,
	# which would corrupt a Windows path such as F:\claude\Inbox\consent\seen.txt
	split("mode out sha sig sigwhy sigfp now sessend keeper srckeys seen", EV, " ")
	for (i = 1; i <= 11; i++) if (("CC_" toupper(EV[i])) in ENVIRON) cc[EV[i]] = ENVIRON["CC_" toupper(EV[i])]
	mode = cc["mode"]; out = cc["out"]; sha = cc["sha"]; sig = cc["sig"]; sigwhy = cc["sigwhy"]; sigfp = cc["sigfp"]
	now = cc["now"]; sessend = cc["sessend"]; keeper = cc["keeper"]; srckeys = cc["srckeys"]; seen = cc["seen"]
}
{
	line = $0
	if (sub(/\r$/, "", line)) crseen = 1
	L[++n] = line
}

function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function unq(s) { s = trim(s); if (length(s) >= 2 && substr(s,1,1) == "\"" && substr(s,length(s),1) == "\"") s = substr(s, 2, length(s)-2); return trim(s) }

# ---------- results ----------
function rank(v) { return v == "FAIL" ? 4 : v == "PARK" ? 3 : v == "NOTCHECKED" ? 2 : v == "NOTE" ? 1 : 0 }
function res(gate, verdict, msg,   g) {
	printf "%-5s %-11s %s\n", gate, (verdict == "NOTCHECKED" ? "NOT-CHECKED" : verdict), msg
	g = gate; sub(/\..*/, "", g)
	if (rank(verdict) > rank(worst[g])) worst[g] = verdict
	if (verdict != "NOTE" && rank(verdict) > rank(overall)) overall = verdict
	if (verdict == "FAIL" || verdict == "PARK" || verdict == "NOTCHECKED") { if (index(" " blamed " ", " " g " ") == 0) blamed = blamed (blamed == "" ? "" : " ") g }
}

# ---------- parsing (P1-P7) ----------
function skip(g, why) { if (!skipped[g]) printf "%-5s %-11s %s\n", g, "SKIPPED", why; skipped[g] = 1 }
function curpath(   i, p) {
	p = ""
	for (i = 1; i <= sp; i++) {
		if (substr(skey[i], 1, 1) == "[") p = p skey[i]
		else p = (p == "" ? skey[i] : p "." skey[i])
	}
	return p
}
function setval(path, v, ln) {
	if (path in val) { dup[path] = ln; ndup++ }
	val[path] = v; lineof[path] = ln; last = path
	order[++norder] = path
}
function parse(   i, s, t, ind, k, v, rest, p) {
	sp = 0; last = ""; norder = 0; ndup = 0; tabline = 0; strayline = 0
	for (i = bi + 1; i < ei; i++) {
		s = L[i]
		t = s; sub(/^[ \t]+/, "", t)
		if (t == "" || substr(t, 1, 1) == "#") continue
		if (s ~ /^ *\t/) { if (!tabline) tabline = i }
		if (match(s, /[ \t]#/)) s = substr(s, 1, RSTART - 1)
		sub(/[ \t]+$/, "", s)
		if (s ~ /^[ \t]*$/) continue
		match(s, /^[ \t]*/); ind = RLENGTH
		t = substr(s, ind + 1)
		if (t == "-" || substr(t, 1, 2) == "- ") {
			rest = trim(substr(t, 2))
			while (sp > 0 && (sind[sp] > ind || (sind[sp] == ind && substr(skey[sp], 1, 1) == "["))) sp--
			p = curpath()
			cnt[p]++
			if (rest ~ /^[A-Za-z_][A-Za-z0-9_]*:[ \t]/ || rest ~ /^[A-Za-z_][A-Za-z0-9_]*:$/) {
				k = rest; sub(/:.*/, "", k); v = rest; sub(/^[^:]*:[ \t]*/, "", v)
				sp++; sind[sp] = ind; skey[sp] = "[" cnt[p] "]"
				setval(curpath() "." k, v, i)
			} else {
				setval(p "[" cnt[p] "]", rest, i)
			}
			continue
		}
		if (t ~ /^[A-Za-z_][A-Za-z0-9_]*:/ && t !~ /^[A-Za-z_][A-Za-z0-9_]*:\/\//) {
			k = t; sub(/:.*/, "", k); v = t; sub(/^[^:]*:[ \t]*/, "", v)
			while (sp > 0 && sind[sp] >= ind) sp--
			p = curpath(); p = (p == "" ? k : p "." k)
			setval(p, v, i)
			if (v == "") { sp++; sind[sp] = ind; skey[sp] = k }
			continue
		}
		if (last != "") val[last] = trim(val[last] " " trim(t))
		else if (!strayline) strayline = i
	}
}
function V(p) { return (p in val) ? unq(val[p]) : "" }
function has(p) { return (p in val) }
function isph(s) { return substr(s, 1, 1) == "<" }

# ---------- time (G2) ----------
function dfc(y, m, d,   era, yoe, doy, doe) {
	y -= (m <= 2); era = int((y >= 0 ? y : y - 399) / 400); yoe = y - era * 400
	doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
	doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
	return era * 146097 + doe - 719468
}
function dim(y, m) { if (m == 2) return ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0) ? 29 : 28; return (m == 4 || m == 6 || m == 9 || m == 11) ? 30 : 31 }
# returns epoch seconds, or "" when s is not ISO-8601 with a zone
function iso(s,   y, mo, d, h, mi, se, rest, z, sg, oh, om) {
	s = trim(s)
	if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]/) return ""
	y = substr(s, 1, 4) + 0; mo = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
	h = substr(s, 12, 2) + 0; mi = substr(s, 15, 2) + 0; se = 0
	rest = substr(s, 17)
	if (rest ~ /^:[0-9][0-9]/) { se = substr(rest, 2, 2) + 0; rest = substr(rest, 4); if (rest ~ /^\.[0-9]+/) { sub(/^\.[0-9]+/, "", rest) } }
	if (rest == "Z") { oh = 0; om = 0; sg = 1 }
	else if (rest ~ /^[+-][0-9][0-9]:[0-9][0-9]$/) { sg = (substr(rest,1,1) == "-") ? -1 : 1; oh = substr(rest, 2, 2) + 0; om = substr(rest, 5, 2) + 0 }
	else if (rest ~ /^[+-][0-9][0-9][0-9][0-9]$/) { sg = (substr(rest,1,1) == "-") ? -1 : 1; oh = substr(rest, 2, 2) + 0; om = substr(rest, 4, 2) + 0 }
	else return ""
	if (mo < 1 || mo > 12 || d < 1 || d > dim(y, mo) || h > 23 || mi > 59 || se > 60 || oh > 14 || om > 59) return ""
	return dfc(y, mo, d) * 86400 + h * 3600 + mi * 60 + se - sg * (oh * 3600 + om * 60)
}

# ---------- words (G1, G6.5) ----------
# fills global W[1..nw] with lower-case words of clause c ("/" becomes the word "/")
function words(c,   i, m, tmp) {
	c = tolower(c); gsub(/\//, " / ", c); gsub(/[^a-z0-9_\/]+/, " ", c)
	m = split(c, tmp, / +/); nw = 0
	for (i = 1; i <= m; i++) if (tmp[i] != "") W[++nw] = tmp[i]
}
function isterm1(w) { return w ~ /^(all|any|everything|whatever|anything|anyone|anywhere|everyone|everywhere|unlimited|unrestricted|blanket)$/ }
# length of term starting at W[j] (0 if none)
function termat(j) {
	if (isterm1(W[j])) return 1
	if (W[j] == "full" && W[j+1] == "use") return 2
	if (W[j] == "carte" && W[j+1] == "blanche") return 2
	if (W[j] == "for" && W[j+1] == "later" && W[j+2] == "gain") return 3
	return 0
}
function negbefore(j,   k) {
	k = j - 1
	while (k >= 1 && (W[k] == "/" || W[k] == "or" || W[k] == "nor" || W[k] == "and" || termat(k) == 1 || W[k] == "root" || W[k] == "sudo")) k--
	return (k >= 1 && W[k] ~ /^(no|not|never|none|without)$/)
}
function exclafter(j, len,   k, s) {
	s = ""
	for (k = j + len; k <= nw; k++) s = s " " W[k]
	s = s " "
	return (s ~ / (is|are|remain|remains|stay|stays) (out of scope|prohibited|forbidden|excluded|denied|not permitted|not allowed) /)
}
# scan value v of path p for blanket terms (G1.2/G1.3)
function g1scan(p, v,   nc, C, i, j, len, term, k) {
	gsub(/—|–/, ";", v)
	nc = split(v, C, /[;,()]/)
	for (i = 1; i <= nc; i++) {
		words(C[i])
		for (j = 1; j <= nw; j++) {
			len = termat(j); if (!len) continue
			term = W[j]; for (k = 1; k < len; k++) term = term " " W[j+k]
			if (negbefore(j) || exclafter(j, len)) res("G1.3", "NOTE", p ": \"" term "\" in exclusion context -- not a grant")
			else res("G1.2", "PARK", p ": blanket term \"" term "\"")
			j += len - 1
		}
	}
}

# ---------- hosts (G4) ----------
function hostof(u,   a) {
	u = tolower(trim(u))
	if (u !~ /^[a-z][a-z0-9+.-]*:\/\/[^\/?#]/) return ""
	a = u; sub(/^[a-z][a-z0-9+.-]*:\/\//, "", a); sub(/[\/?#].*$/, "", a)
	sub(/^.*@/, "", a); sub(/:[0-9]*$/, "", a); sub(/\.$/, "", a)
	return a
}
function regdom(h,   m, H) { m = split(h, H, "."); if (h ~ /^[0-9.]+$/ || m < 2) return h; return H[m-1] "." H[m] }

# ---------- main ----------
END {
	overall = "PASS"; blamed = ""
	nb = 0; ne = 0; bi = 0; ei = 0
	for (i = 1; i <= n; i++) {
		t = L[i]; sub(/[ \t]+$/, "", t)
		if (t == "-----BEGIN CONSENT PAYLOAD-----") { nb++; if (!bi) bi = i }
		if (t == "-----END CONSENT PAYLOAD-----") { ne++; if (!ei) ei = i }
	}
	okm = (nb == 1 && ne == 1 && bi < ei)

	if (mode == "extract") {
		if (!okm) exit 3
		hf = out "/hashin"; sf = out "/sigin"
		printf "" > hf; printf "" > sf
		for (i = bi + 1; i < ei; i++) {
			printf "%s\n", L[i] > sf
			if (L[i] !~ /^[ \t]*payload_sha256[ \t]*:/) printf "%s\n", L[i] > hf
		}
		close(hf); close(sf)
		parse(); print V("issuer.principal")
		exit 0
	}
	if (mode != "check") { print "consent_check.awk: CC_MODE=extract|check" > "/dev/stderr"; exit 64 }

	nowe = iso(now)
	if (nowe == "") { print "consent_check.awk: --now does not parse as ISO-8601 with zone: " now > "/dev/stderr"; exit 64 }

	# ---- N1: whole file ----
	for (i = 1; i <= n; i++) {
		if (L[i] ~ /^[ \t]*#?[ \t]*N[O0]4C([ \t:.,;!]|$)/) res("N1.1", "PARK", "line " i ": NO4C raised (line-anchored)")
		else if (L[i] ~ /N[O0]4C/) res("N1.2", "NOTE", "line " i ": NO4C mentioned, not raised")
	}
	if (crseen) res("P7", "NOTE", "CR line endings seen; hashed and verified with CR removed")

	if (!okm) {
		res("P1", "FAIL", "payload markers: BEGIN x" nb ", END x" ne (nb == 1 && ne == 1 ? " (END before BEGIN)" : ""))
		split("P4 P6 G0 G1 G2 G3 G4 G5 G6 G7 HL3", SK0, " "); for (i = 1; i <= 11; i++) skipped[SK0[i]] = 1
		finish()
	}
	parse()
	if (tabline) res("P4", "FAIL", "line " tabline ": TAB in indentation")
	if (strayline) res("P4", "FAIL", "line " strayline ": continuation with nothing to continue")
	for (p in dup) res("P6", "FAIL", p ": key appears more than once (again at line " dup[p] ")")

	# ---- G0 ----
	nreq = split("record_id schema issued reconfirmed expires issuer.name issuer.principal issuer.key_fingerprint agent.authorized agent.session grant.action grant.target_host grant.mode grant.network grant.credential.which grant.credential.holder grant.credential.retention grant.irreversible_parts grant.window prohibited_category_decision.acknowledged prohibited_category_decision.decision prohibited_category_decision.rationale revocation.path revocation.effect affirmation payload_sha256", REQ, " ")
	for (i = 1; i <= nreq; i++) {
		p = REQ[i]
		if (!has(p)) res("G0", "FAIL", p ": missing")
		else if (V(p) == "") res("G0", "FAIL", p ": blank")
		else if (isph(V(p))) res("G0", "FAIL", p ": unfilled placeholder")
		isreq[p] = 1
	}
	nl = split("issuer.identity_urls grant.target_scope", LST, " ")
	for (i = 1; i <= nl; i++) {
		p = LST[i]
		if (!(p in cnt) || cnt[p] < 1) res("G0", "FAIL", p ": list missing or empty")
		else for (j = 1; j <= cnt[p]; j++) {
			q = p "[" j "]"
			if (!has(q) || V(q) == "") res("G0", "FAIL", q ": blank item")
			else if (isph(V(q))) res("G0", "FAIL", q ": unfilled placeholder")
		}
	}
	np = ("parties_affected" in cnt) ? cnt["parties_affected"] : 0
	if (np < 1) res("G0", "FAIL", "parties_affected: list missing or empty")
	for (j = 1; j <= np; j++) {
		q = "parties_affected[" j "]"
		if (!has(q ".party") || V(q ".party") == "") res("G0", "FAIL", q ".party: missing or blank")
		else if (isph(V(q ".party"))) res("G0", "FAIL", q ".party: unfilled placeholder")
		if (!has(q ".status") || V(q ".status") == "") res("G0", "FAIL", q ".status: missing or blank")
		else if (isph(V(q ".status"))) res("G0", "FAIL", q ".status: unfilled placeholder")
	}
	if (has("schema") && V("schema") != "consent-record/v1" && !isph(V("schema"))) res("G0.1", "FAIL", "schema is not consent-record/v1")
	fp = V("issuer.key_fingerprint")
	if (fp != "" && !isph(fp) && (fp !~ /^SHA256:[A-Za-z0-9+\/]+=?$/ || length(fp) < 50 || length(fp) > 51)) res("G0.2", "FAIL", "issuer.key_fingerprint is not SHA256:<43 base64>")
	ps = tolower(V("payload_sha256"))
	if (ps != "" && !isph(ps) && (ps !~ /^[0-9a-f]+$/ || length(ps) != 64)) res("G0.3", "FAIL", "payload_sha256 is not 64 hex")
	hold = V("grant.credential.holder")
	if (hold != "" && !isph(hold) && hold != "agent" && hold != "issuer") res("G0.4", "FAIL", "grant.credential.holder is neither agent nor issuer")
	known = " record_id schema issued reconfirmed expires issuer issuer.name issuer.principal issuer.key_fingerprint issuer.identity_urls agent agent.authorized agent.session grant grant.action grant.target_host grant.target_scope grant.mode grant.network grant.credential grant.credential.which grant.credential.holder grant.credential.retention grant.irreversible_parts grant.window parties_affected prohibited_category_decision prohibited_category_decision.acknowledged prohibited_category_decision.decision prohibited_category_decision.rationale revocation revocation.path revocation.effect affirmation payload_sha256 "
	for (i = 1; i <= norder; i++) {
		p = order[i]; q = p; gsub(/\[[0-9]+\]/, "", q)
		if (q ~ /^parties_affected\.(party|status)$/) continue
		if (isph(V(p)) && !isreq[p] && p !~ /^(issuer\.identity_urls|grant\.target_scope)\[/ && p !~ /^parties_affected\[/) res("G0.5", "FAIL", p ": unfilled placeholder")
		if (index(known, " " q " ") == 0) {
			if (q ~ /^grant\./) res("G1.7", "PARK", p ": key under grant.* the template does not name")
			else res("G0.6", "NOTE", p ": key the template does not name")
		}
	}
	if (seen != "") {
		rid = V("record_id"); hit = 0
		while ((getline sl < seen) > 0) if (trim(sl) == rid && rid != "") hit = 1
		close(seen)
		if (hit) res("G0.R", "FAIL", "record_id already seen (replay)")
	} else res("G0.R", "NOTE", "record_id uniqueness not checked (no --seen)")

	# ---- G1 ----
	for (i = 1; i <= norder; i++) {
		p = order[i]
		if (isph(V(p))) { if (p ~ /^grant\./ || p ~ /^agent\./ || p == "prohibited_category_decision.decision") g1ph++; continue }
		if (p ~ /^grant\./ || p == "agent.authorized" || p == "prohibited_category_decision.decision") g1scan(p, V(p))
		else if (p == "agent.session") {
			if (tolower(V(p)) == "any session presenting this record") res("G1.4", "NOTE", "agent.session is the template's bearer value (\"any session presenting this record\")")
			else g1scan(p, V(p))
		}
	}
	if (g1ph) res("G1", "NOTE", g1ph " placeholder value(s) in G1's scope not scanned (already FAIL under G0)")
	if (("grant.target_scope" in cnt)) for (j = 1; j <= cnt["grant.target_scope"]; j++) {
		s = V("grant.target_scope[" j "]"); sub(/[ \t]*\([^)]*\)[ \t]*$/, "", s); s = trim(s)
		if (s ~ /^(\*|\*\*|\/|\/\*|\/\*\*|~|~\/|~\/\*|~\/\*\*)$/ || s ~ /^[A-Za-z]:[\\\/]?\**$/) res("G1.5", "PARK", "grant.target_scope[" j "]: root or bare wildcard \"" s "\"")
	}
	if (index(V("grant.target_host"), "*")) res("G1.5", "PARK", "grant.target_host: wildcard host")
	for (i = 1; i <= norder; i++) {
		p = order[i]; s = " " tolower(V(p)) " "; gsub(/[^a-z0-9-]+/, " ", s)
		if (s ~ / (urgent|urgently|asap|hurry|rush|rushed|immediately|noconfirm|no-confirm|override|overriding) / || s ~ / right now | without confirmation | skip verification | no need to verify | trust me | as the keeper | on my authority | i order /)
			res("G1.6", "NOTE", p ": urgency/authority framing -- ignored for the verdict (strip the urgency and ask again)")
	}

	# ---- G2 ----
	ei_ = iso(V("issued")); er = iso(V("reconfirmed")); exv = V("expires"); ee = iso(exv); eos = (exv == "end-of-session")
	if (has("issued") && !isph(V("issued")) && V("issued") != "" && ei_ == "") res("G2.1", "FAIL", "issued does not parse as ISO-8601 with zone")
	if (has("reconfirmed") && !isph(V("reconfirmed")) && V("reconfirmed") != "" && er == "") res("G2.1", "FAIL", "reconfirmed does not parse as ISO-8601 with zone")
	if (exv != "" && !isph(exv) && ee == "" && !eos) res("G2.1", "FAIL", "expires does not parse as ISO-8601 with zone (nor end-of-session)")
	if (ei_ == "" || er == "" || (ee == "" && !eos)) skip("G2", "issued/reconfirmed/expires not all usable; freshness not evaluated (see G0/G2.1)")
	if (eos && sessend != "") { ee = iso(sessend); if (ee == "") res("G2.7", "FAIL", "--session-end does not parse") }
	if (ei_ != "" && ee != "" && ee <= ei_) res("G2.2", "FAIL", "expires is not after issued")
	if (ei_ != "" && er != "" && er - ei_ < 600) res("G2.3", "PARK", "reconfirmed only " (er - ei_) "s after issued (< 600s): rushed")
	if (er != "" && ee != "" && er > ee) res("G2.4", "FAIL", "reconfirmed after expires")
	if (ei_ != "" && nowe < ei_) res("G2.5", "FAIL", "issued is in the future")
	else if (ei_ != "" && er != "" && nowe < er) res("G2.6", "PARK", "not yet reconfirmed at now")
	if (ee != "" && nowe >= ee) res("G2.7", "FAIL", "expired")
	if (eos && sessend == "") res("G2.7", "NOTCHECKED", "expires is end-of-session and no --session-end was given")
	w = V("grant.window")
	if (w != "" && !isph(w)) {
		wa = w; wb = w; sub(/[ \t]*\.\.[ \t]*.*$/, "", wa); sub(/^.*\.\.[ \t]*/, "", wb)
		if (index(w, "..") && iso(wa) != "" && iso(wb) != "") {
			if ((ei_ != "" && iso(wa) < ei_) || (ee != "" && iso(wb) > ee)) res("G2.8", "FAIL", "grant.window is wider than issued..expires")
		} else res("G2.8", "NOTE", "grant.window not parsed as ISO .. ISO; not compared")
	}
	if (has("revocation.effect") && V("revocation.effect") != "" && V("revocation.effect") != "immediate-on-publish" && !isph(V("revocation.effect"))) res("G2.9", "NOTE", "revocation.effect is not immediate-on-publish")
	if (ei_ != "" && ee != "" && ee - ei_ > 86400) res("G2.10", "NOTE", "window longer than 24h (the template's example of short)")

	# ---- G3 ----
	if (ps == "" || isph(ps) || length(ps) != 64) skip("G3", "payload_sha256 not usable; hash not compared (see G0)")
	else if (sha == "" || sha == "NA") res("G3.3", "NOTCHECKED", "no sha256 tool")
	else { if (tolower(sha) != ps) res("G3.2", "FAIL", "payload_sha256 does not match the payload (computed " substr(sha, 1, 12) "...)") }

	# ---- G4 ----
	nu = ("issuer.identity_urls" in cnt) ? cnt["issuer.identity_urls"] : 0
	if (nu < 2) res("G4.1", "FAIL", "fewer than two identity_urls (" nu ")")
	nrd = 0; npu = 0
	for (j = 1; j <= nu; j++) {
		u = V("issuer.identity_urls[" j "]"); if (u == "" || isph(u)) continue
		h = hostof(u)
		if (h == "") { res("G4.2", "FAIL", "identity_urls[" j "] does not parse as scheme://host"); continue }
		if (tolower(u) !~ /^https:/) res("G4.2", "NOTE", "identity_urls[" j "] is not https")
		rd = regdom(h); U[j] = u; RD[j] = rd; npu++
		if (!(rd in rdseen)) { rdseen[rd] = 1; nrd++ }
	}
	if (npu < 2 && nu >= 2) skip("G4", "fewer than two usable identity_urls; independence not evaluated (see G0/G4.2)")
	if (npu >= 2 && nrd < 2) res("G4.3", "FAIL", "identity_urls are not on two independent registrable domains")
	if (srckeys == "") res("G4.4", "NOTCHECKED", "no --source-keys: the 2/2 fetch was not evidenced")
	else {
		nsk = 0
		while ((getline sl < srckeys) > 0) { if (split(sl, SK, "\t") >= 2) { skfp[trim(SK[1])] = trim(SK[2]); nsk++ } }
		close(srckeys)
		if (nsk == 0) res("G4.4", "NOTCHECKED", "--source-keys is empty or unreadable")
		else {
			nok = 0; bad4 = 0
			for (j = 1; j <= nu; j++) {
				if (!(j in U)) continue
				if (!(U[j] in skfp)) continue
				if (skfp[U[j]] != fp) { res("G4.4", "FAIL", "identity_urls[" j "] served a different key"); bad4 = 1 }
				else if (!(RD[j] in okrd)) { okrd[RD[j]] = 1; nok++ }
			}
			if (!bad4 && nok < 2) res("G4.4", "NOTCHECKED", "fetch evidence covers " nok " independent source(s), need 2/2")
		}
	}

	# ---- G5 ----
	iname = tolower(V("issuer.name")); iprin = tolower(V("issuer.principal")); issuersigns = 0
	for (j = 1; j <= np; j++) {
		pa = V("parties_affected[" j "].party"); st = V("parties_affected[" j "].status")
		if (pa == "" || st == "" || isph(pa) || isph(st)) { g5gap = 1; continue }
		lp = tolower(pa); ls = tolower(st)
		isiss = (lp == iname || lp == iprin || lp == "issuer" || (iname != "" && index(lp, iname " (") == 1))
		fam = (" " lp " " ~ /[^a-z](wife|husband|spouse|son|daughter|child|children|kid|kids|mother|father|mom|dad|parent|parents|brother|sister|sibling|grandmother|grandfather|grandparent|aunt|uncle|cousin|niece|nephew|family|non-participant)[^a-z]/)
		if (ls == "signs-this-record") {
			if (isiss) issuersigns = 1
			else if (fam) res("G5.5", "PARK", "parties_affected[" j "]: family/non-participant party (hard line)")
			else res("G5.4", "FAIL", "parties_affected[" j "]: a non-issuer party marked signs-this-record (nobody consents for another)")
		} else if (ls ~ /^out-of-scope:/) {
			r = st; sub(/^[^:]*:/, "", r); if (trim(r) == "") res("G5.2", "FAIL", "parties_affected[" j "]: out-of-scope with no reason")
		} else if (ls ~ /^separate signed record attached:/) {
			r = st; sub(/^[^:]*:/, "", r)
			if (trim(r) == "") res("G5.2", "FAIL", "parties_affected[" j "]: attached record not named")
			else if (fam) res("G5.5", "PARK", "parties_affected[" j "]: family/non-participant party (hard line; not the keeper's to waive)")
			else res("G5.6", "NOTCHECKED", "parties_affected[" j "]: attached record must pass this gate on its own run")
		} else res("G5.2", "FAIL", "parties_affected[" j "]: status is not one of the three template forms")
	}
	if (g5gap) skip("G5", "a party or status is blank/unfilled; issuer-signs not evaluated (see G0)")
	else if (np >= 1 && !issuersigns) res("G5.3", "FAIL", "no party that is the issuer has signs-this-record")

	# ---- G6 ----
	ack = V("prohibited_category_decision.acknowledged"); dec = tolower(V("prohibited_category_decision.decision")); ret = tolower(V("grant.credential.retention"))
	if (ack != "" && !isph(ack) && ack != "true") res("G6.1", "FAIL", "acknowledged is not true")
	cls = ""
	if (dec == "" || isph(dec) || hold == "" || isph(hold) || ret == "" || isph(ret)) skip("G6", "decision/holder/retention not all usable; prohibited-category not fully evaluated (see G0)")
	if (dec != "" && !isph(dec)) {
		if (dec ~ /^no lift/) cls = "NOLIFT"
		else if (index(dec, "lift the park")) cls = "LIFT"
		else res("G6.2", "FAIL", "decision is neither \"no lift ...\" nor \"... lift the park ...\"")
	}
	if (hold == "issuer" && ret != "" && !isph(ret) && index(ret, "never receives") == 0) res("G6.3", "FAIL", "holder issuer but retention does not say the agent never receives the key")
	if (hold == "agent" && ret != "" && !isph(ret) && index(ret, "does not persist") == 0) res("G6.3", "FAIL", "holder agent but retention does not say the agent does not persist it")
	if (hold == "agent" && cls == "NOLIFT") res("G6.4", "PARK", "agent-held credential with no lift (prohibited category)")
	rootm = 0; words(V("grant.mode"))
	for (j = 1; j <= nw; j++) if ((W[j] == "root" || W[j] == "sudo") && !negbefore(j)) rootm = 1
	if (rootm && cls == "NOLIFT") res("G6.5", "PARK", "grant.mode names root/sudo with no lift (prohibited category)")
	if (cls == "LIFT") {
		if (keeper == "") res("G6.6", "NOTCHECKED", "a park-lift is present; --keeper not given, so whose lift it is was not checked")
		else if (tolower(keeper) != iprin) res("G6.6", "PARK", "park-lift signed by someone other than the keeper")
		if (hold == "issuer" && !rootm) res("G6.7", "NOTE", "park-lift present but nothing in the grant needs it")
	}

	# ---- G7 ----
	if (sig == "" || sig == "NA") res("G7.4", "NOTCHECKED", "signature not verified" (sigwhy != "" ? " (" sigwhy ")" : ""))
	else if (sig == "BAD") res("G7.2", "FAIL", "ssh-keygen -Y verify rejected the signature" (sigwhy != "" ? " (" sigwhy ")" : ""))
	else if (sig == "GOOD") {
		if (sigfp == "") res("G7.3", "NOTCHECKED", "could not fingerprint the allowed-signers key")
		else if (sigfp != fp) res("G7.3", "FAIL", "allowed-signers key fingerprint differs from issuer.key_fingerprint")
	}

	# ---- HL3 ----
	for (i = 1; i <= norder; i++) {
		p = order[i]; s = V(p)
		while (match(s, /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z][A-Za-z]+/)) {
			e = tolower(substr(s, RSTART, RLENGTH)); s = substr(s, RSTART + RLENGTH)
			if (e != iprin) res("HL3.1", "PARK", p ": third-party email address in the record (value withheld)")
		}
		s = " " V(p) " "
		if (s ~ /[^0-9](\+?1[ .-]?)?\(?[2-9][0-9][0-9]\)?[ .-]?[2-9][0-9][0-9][ .-][0-9][0-9][0-9][0-9][^0-9]/) res("HL3.1", "PARK", p ": phone-number shape in the record (value withheld)")
	}
	finish()
}
function finish(   g, i, G) {
	split("P1 P4 P6 P7 G0 G1 G2 G3 G4 G5 G6 G7 N1 HL3", G, " ")
	printf "----\n"
	for (i = 1; i <= 14; i++) { g = G[i]; printf "%s=%s ", g, (worst[g] == "" ? (skipped[g] ? "SKIPPED" : "PASS") : worst[g] == "NOTCHECKED" ? "NOT-CHECKED" : worst[g]) }
	printf "\n"
	if (overall == "PASS") { print "VERDICT: PASS (exit 0)"; exit 0 }
	if (overall == "FAIL") { print "VERDICT: FAIL (exit 1) -- " blamed; exit 1 }
	if (overall == "PARK") { print "VERDICT: PARK (exit 2) -- CLAUD_QA_HOLD -- " blamed; exit 2 }
	print "VERDICT: NOT CHECKED (exit 77) -- " blamed; exit 77
}
