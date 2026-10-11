# drift_line.awk 0.1.0 --- the drift line's gate: a checkpoint line is accepted only if it can say no.
#
# A line (fields separated by " · "):
#   <UTC> · checkpoint · on-bearing? <yes|no> — <what it was checked against>
#         · still-arguing? <yes|no> · pushed-back: <noun phrase | NONE> · grader: <self | other:<who>>
#         · note: <text>
# NONE (upper case, alone) is the "no": nothing was pushed back on this stretch.
#
# Refusal codes (a line may carry several):
#   FORMAT          no UTC stamp, no "checkpoint", a missing on-bearing/still-arguing/note field,
#                   an unknown field, or an empty note
#   ANSWER          an on-bearing? or still-arguing? answer that is not yes or no (e.g. "?")
#   NO-PUSHBACK     no pushed-back: field, or an empty one
#   VAGUE-PUSHBACK  pushed-back names no concrete thing (only filler words), or a lower-case
#                   none / nothing / n/a where the literal NONE is meant
#   NO-GRADER       no grader: field
#   BAD-GRADER      grader is not "self" or "other:<who>"
#   RUBBER-STAMP    a "yes" with no named object: on-bearing? yes with nothing concrete after it;
#                   still-arguing? yes whose object (pushed-back, else the text after the dash) is
#                   empty, filler, or NONE
#   CONTRADICTION   still-arguing? no beside a named pushed-back (the "no" is spelled NONE)
#   ORDER           (append only) the new stamp is earlier than the latest stamp already in the log
#
# Variables (-v):
#   mode=check    (default) one verdict per non-comment line; exit 0 all accepted, 1 any refused,
#                 77 no line read
#   mode=audit    the same verdicts plus a tally; never refuses to finish; exit as check
#   mode=lastts   print the latest UTC stamp in the input (for the wrapper's ORDER check)
#   legacy=1      historic reading: where pushed-back: is absent, read the still-arguing object as it
#   last=<UTC>    refuse ORDER if a line's stamp is earlier than this
#
# The concreteness test is lexical: after dropping filler words, at least one word of three or more
# characters with a letter in it must remain. It cannot tell a true object from a plausible one.

BEGIN {
	SEP = " · "; DASH = "—"
	if (mode == "") mode = "check"
	nf = split("a an the of on to in at by for with and or but not no yes ok okay sure fine good " \
	    "great done did do does was were is are be been it its this that these those all any some " \
	    "everything anything nothing none thing things stuff misc various etc same above below as " \
	    "usual per my our his her their see n/a na tbd tba work just also still more much very " \
	    "nope yep yeah ack noted n", fw, " ")
	for (i = 1; i <= nf; i++) FILLER[fw[i]] = 1
	nlines = 0; nacc = 0; nref = 0; nout = 0; prevts = ""
}

function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

# concrete: at least one non-filler token of >= 3 chars containing a letter
function concrete(s,    t, n, i, w, parts) {
	t = tolower(s)
	gsub(/[^a-z0-9_.\/-]+/, " ", t)
	n = split(t, parts, " ")
	for (i = 1; i <= n; i++) {
		w = parts[i]; sub(/^[.\/-]+/, "", w); sub(/[.\/-]+$/, "", w)
		if (length(w) >= 3 && w ~ /[a-z]/ && !(w in FILLER)) return 1
	}
	return 0
}

# split "yes — object" into ANS and OBJ
function answer(s,    a, k) {
	s = trim(s)
	a = s; sub(/[^A-Za-z?].*$/, "", a)
	ANS = tolower(a)
	OBJ = substr(s, length(a) + 1)
	k = index(OBJ, DASH)
	if (k > 0) OBJ = substr(OBJ, k + length(DASH))
	else sub(/^[ \t]*[-:;,][ \t]*/, "", OBJ)
	OBJ = trim(OBJ)
}

function add(code) { codes = (codes == "" ? code : codes "," code); CNT[code]++ }

function isstamp(s) {
	return s ~ /^[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9](:[0-5][0-9])?Z$/
}

/^[ \t]*#/ || /^[ \t]*$/ { next }

mode == "lastts" {
	split($0, f0, SEP); ts0 = trim(f0[1])
	if (isstamp(ts0) && ts0 > maxts) maxts = ts0
	next
}

{
	nlines++; codes = ""
	n = split($0, f, SEP)
	ts = trim(f[1])
	has_ob = 0; has_sa = 0; has_pb = 0; has_gr = 0; has_note = 0
	obA = ""; obO = ""; saA = ""; saO = ""; pb = ""; gr = ""; note = ""
	if (!isstamp(ts) || trim(f[2]) != "checkpoint") add("FORMAT")
	for (i = 3; i <= n; i++) {
		fld = f[i]
		if (fld ~ /^note:/) {
			note = substr(fld, 6)
			for (j = i + 1; j <= n; j++) note = note SEP f[j]
			has_note = 1; break
		} else if (fld ~ /^on-bearing\?/) {
			has_ob = 1; answer(substr(fld, 12)); obA = ANS; obO = OBJ
		} else if (fld ~ /^still-arguing\?/) {
			has_sa = 1; answer(substr(fld, 15)); saA = ANS; saO = OBJ
		} else if (fld ~ /^pushed-back:/) {
			has_pb = 1; pb = trim(substr(fld, 13))
		} else if (fld ~ /^grader:/) {
			has_gr = 1; gr = trim(substr(fld, 8))
		} else {
			unknown = 1
		}
	}
	if (!has_ob || !has_sa || !has_note || trim(note) == "" || unknown) { if (codes !~ /FORMAT/) add("FORMAT") }
	unknown = 0
	if ((has_ob && obA != "yes" && obA != "no") || (has_sa && saA != "yes" && saA != "no")) add("ANSWER")

	# the noun: what was pushed back on (legacy reading borrows the still-arguing object)
	if (!has_pb && legacy == 1 && saO != "") { has_pb = 1; pb = saO }
	if (!has_pb || pb == "") add("NO-PUSHBACK")
	else if (pb != "NONE" && !concrete(pb)) add("VAGUE-PUSHBACK")

	if (!has_gr) add("NO-GRADER")
	else if (gr != "self" && gr !~ /^other:[A-Za-z0-9._@+-]+$/) add("BAD-GRADER")

	# the rubber stamp: a yes with no named object
	saobj = (has_pb && pb != "") ? pb : saO
	if (obA == "yes" && !concrete(obO)) add("RUBBER-STAMP")
	else if (saA == "yes" && (saobj == "NONE" || !concrete(saobj))) add("RUBBER-STAMP")
	if (saA == "no" && has_pb && pb != "" && pb != "NONE") add("CONTRADICTION")

	if (last != "" && isstamp(ts) && ts < last) add("ORDER")

	# tallies (audit)
	OB[obA == "yes" || obA == "no" ? obA : "other"]++
	SA[saA == "yes" || saA == "no" ? saA : "other"]++
	if (pb == "NONE") nnone++
	if (has_gr) GR[gr == "self" ? "self" : "other"]++
	if (isstamp(ts) && prevts != "" && ts < prevts) nout++
	if (isstamp(ts)) prevts = ts

	if (codes == "") { nacc++; print "ACCEPT L" FNR }
	else { nref++; print "REFUSE L" FNR " " codes }
}

END {
	if (mode == "lastts") { print maxts; exit 0 }
	if (mode == "audit") {
		printf "audit %s: %d line(s) read; %d accepted, %d refused%s\n", FILENAME, nlines, nacc, nref, (legacy == 1 ? " (legacy reading)" : "")
		printf "  refused by rule:"
		split("FORMAT ANSWER NO-PUSHBACK VAGUE-PUSHBACK NO-GRADER BAD-GRADER RUBBER-STAMP CONTRADICTION ORDER", R, " ")
		for (i = 1; i <= 9; i++) printf " %s %d", R[i], CNT[R[i]] + 0
		printf "\n"
		printf "  answers: on-bearing yes %d / no %d / other %d; still-arguing yes %d / no %d / other %d; pushed-back NONE %d\n", \
		    OB["yes"] + 0, OB["no"] + 0, OB["other"] + 0, SA["yes"] + 0, SA["no"] + 0, SA["other"] + 0, nnone + 0
		printf "  grader: self %d / other %d / absent %d; order: %d line(s) stamped earlier than the line above\n", \
		    GR["self"] + 0, GR["other"] + 0, nlines - GR["self"] - GR["other"], nout
	}
	if (nlines == 0) { print "NOT CHECKED: no checkpoint line read"; exit 77 }
	exit (nref > 0 ? 1 : 0)
}
# SPDX-License-Identifier: GPL-3.0-or-later
