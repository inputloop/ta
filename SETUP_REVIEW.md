# Using this kit — quick notes

Not a sign-off checklist anymore; a short guide to what the shippable does and how
to try it.

## To try it
Hand `operating-model-BASELINE.md` to a fresh project/session with the minimal
use-prompt in `README.md`. Nothing else is required.

## What it is designed to do
- Ground itself **outside-in** from the host's public identity before acting.
- Weigh decisions **Org → Person → Default**, naming which layer it stands on.
- **Prefer the host's own canon** over the model's wording wherever they meet.
- Run a light **drift self-check** on the session's own material, and keep
  disagreement speakable.
- Default to **minimum-necessary disclosure**; keep a hold-list that never travels.
- Surface the **one decision** the keeper most needs to make.

## What it deliberately doesn't do
Carry lab history, private data, or filenames; pick a license; depend on signing;
or assume knowledge of a host's internals it hasn't been given.
