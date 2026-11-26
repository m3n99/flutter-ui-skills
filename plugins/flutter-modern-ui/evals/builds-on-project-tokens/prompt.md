---
description: "Builds a screen in a project that has its own design system. Graded on the file it writes: the project's tokens, no second system, every state, text that can't overflow, and no intake round for what DESIGN.md already answers."
tags: [build]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add the members list screen to this Flutter project, in `lib/features/members/members_screen.dart`. It takes a `MembersRepository`, loads the members and shows each one with their name, phone and how many books they have out; tapping one calls an `onOpen(Member)` callback. Write the file; I'll wire the route myself. Flutter isn't installed in this environment, so don't try to run anything.
