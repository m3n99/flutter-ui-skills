---
description: "A Flutter question with no interface in it (a build failure). None of the plugin's skills should load."
tags: [trigger, negative, reply]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

My Flutter app builds fine in debug, but `flutter build apk --release` fails with "Execution failed for task ':app:minifyReleaseWithR8'" and a line saying "Missing classes detected while running R8". What causes this and how do I fix it?
