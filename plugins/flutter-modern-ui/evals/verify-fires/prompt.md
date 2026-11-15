---
description: "Asking how to check a screen before shipping should load the verify skill and lead to rendering it."
tags: [trigger, verify, reply]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

I just finished a new settings screen in my Flutter app. Before I ship it I want to be sure it doesn't break with large fonts, in Arabic, in dark mode or on a tablet. What's the fastest reliable way to check all of that without clicking through a device for each one?
