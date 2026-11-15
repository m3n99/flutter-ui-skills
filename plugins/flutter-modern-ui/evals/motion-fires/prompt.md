---
description: "A request to smooth out list changes should load the motion skill and use one shared piece, not an ad-hoc controller."
tags: [trigger, motion, reply]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

In my Flutter app, when I add or delete an expense the list just jumps: the new row appears instantly and deleted rows vanish. I want it to feel smooth. The project uses your design system's widgets. What should I use?
