#!/bin/sh
# write a consent record to $1 in the shape verify_consent.sh reads (its prove_red rec(), L22-40);
# issued 1h ago, reconfirmed 40m ago, expires in 1h; $2 is the grant action.
now=$(date +%s); ts() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ; }
cat > "$1" <<EOR
-----BEGIN CONSENT PAYLOAD-----
record_id:        p1b-fixture
schema:           consent-record/v1
issued:           $(ts $((now-3600)))
reconfirmed:      $(ts $((now-2400)))
expires:          $(ts $((now+3600)))
issuer:
  name:           Fixture Keeper
  principal:      keeper@example.org
grant:
  action:         ${2:-read one log file}
  target_host:    fixture-host
  mode:           read-only
affirmation:      "Specific, not blanket. Unrushed and uncoerced."
-----END CONSENT PAYLOAD-----
EOR
# SPDX-License-Identifier: GPL-3.0-or-later
