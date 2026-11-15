---
description: "Builds a screen in a project that has its own design system. Graded on the file it writes: the project's tokens, no second system, every state, text that can't overflow, and no intake round for what DESIGN.md already answers."
tags: [build]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add the customers list screen to this Flutter project, in `lib/features/customers/customers_screen.dart`. It takes a `CustomersRepository`, loads the customers and shows each one with their name, phone and what they owe; tapping one calls an `onOpen(Customer)` callback. Write the file; I'll wire the route myself. Flutter isn't installed in this environment, so don't try to run anything.
