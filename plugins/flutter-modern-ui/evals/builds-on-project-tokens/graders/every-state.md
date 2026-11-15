---
type: llm
focus: { source: file, path: lib/features/customers/customers_screen.dart }
---

PASS if the screen handles all four states: loading (a placeholder or skeleton, not nothing), an empty list (text that says what will appear or what to do, using the project's BrandEmpty or equivalent), a load failure (what failed and a way to retry) and the loaded list.

FAIL if any of the four is missing, or the failure state shows raw exception text or only "Something went wrong".
