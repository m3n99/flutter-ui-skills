---
description: "The project has a design system. New UI uses its names and adds no second system or raw values."
tags: [system, smoke]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

My Flutter project already has its own design system: spacing in `Gaps` (`Gaps.s8`, `Gaps.s16`, `Gaps.s24`), colors through `context.brand` (`context.brand.textMuted`, `context.brand.surfaceSoft`), text styles through `context.type` (`context.type.title`, `context.type.body`), a `BrandCard` widget and a `BrandButton.primary(label:, onPressed:)`.

Write the empty state widget for the orders list, shown when there are no orders yet, with a button that starts a new order. Just the widget code.
