---
type: llm
---

PASS if the reply recommends keeping the button enabled, so that pressing it shows which fields need fixing, and disabling it only while the request is in flight (or otherwise guarding against a double submit).

FAIL if the reply endorses keeping the button disabled until the form is valid, or gives no recommendation.
