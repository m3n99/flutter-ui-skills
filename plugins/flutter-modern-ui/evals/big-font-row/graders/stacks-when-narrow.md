---
type: llm
---

PASS if the main fix is to change the layout when there is little room for the text, putting the amount under the name (stacking), and the condition takes the text scale into account (for example the width divided by the text scale, an isNarrow check, or a LayoutBuilder decision that reacts to large fonts).

FAIL if the main fix is to clamp or ignore the user's text scale, to shrink the font, or only to add an ellipsis.
