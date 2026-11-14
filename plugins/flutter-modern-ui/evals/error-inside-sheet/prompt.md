---
description: "A SnackBar from a modal sheet opens behind it. The error belongs inside the sheet."
tags: [sheets]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

In my Flutter app, saving from a modal bottom sheet sometimes fails. I call ScaffoldMessenger.of(context).showSnackBar with the error, but users say nothing happens and the sheet just sits there. Why, and what should I do instead?
