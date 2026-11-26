#!/usr/bin/env python3
"""CI only: the start room in examples/cheque_pdf.dart is what keeps a
leading «ا». The same longest values, with and without the room: without
it, the FittedBox clips the first letter at the box's edge, so the ink
ends short of where it reaches with the room.

    python3 ci/cheque_room_check.py build/sandbox/test/pdf/out
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "plugins/flutter-modern-ui/skills/flutter-ui-verify/scripts"))
import measure_pdf  # noqa: E402


def right_edges(folder, name):
    spec = json.loads((folder / f"{name}.measure.json").read_text(encoding="utf-8"))
    fitz = measure_pdf._fitz()
    edges = {}
    with fitz.open(folder / spec["pdf"]) as document:
        page = document[0]
        for field in spec["fields"]:
            if field["name"] in ("payee", "words"):
                edges[field["name"]] = measure_pdf.measure(page, field["window"], 600, 110)["right"]
    return edges


def main():
    folder = Path(sys.argv[1])
    room = right_edges(folder, "cheque_longest")
    bare = right_edges(folder, "cheque_longest_no_room")
    failures = []
    for name in ("payee", "words"):
        lost = room[name] - bare[name]
        print(f"{name}: with room {room[name]:.3f} cm, without {bare[name]:.3f} cm ({lost:.3f} cm of the first letter clipped)")
        if lost < 0.02:
            failures.append(name)
    if failures:
        print(f"FAIL: no clipping without the room for {', '.join(failures)}: the pdf package may have changed; re-check preprinted-forms.md › start room")
        return 1
    print("The start room keeps the leading «ا»; without it the FittedBox clips it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
