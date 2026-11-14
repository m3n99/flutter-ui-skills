# UX: the flow before the pixels

A screen can pass every visual check and still make its user tap six times, retype what the app already knew, and wonder whether the save worked. Decide these things before laying out widgets; most of them cost nothing to build and are expensive to retrofit.

## Start from the task

- For each screen, write one sentence: **who arrives, from where, to do what, and where they go next.** If you can't, the screen has no job yet.
- Count the taps for the three most frequent tasks. The daily one takes two or fewer from launch. A task that takes more gets a shortcut (a row action, a FAB, a home-screen card), not a tutorial.
- **Home answers the question the user opens the app with** ("who is due today?", "what's next?"), with the action beside the answer. A menu of features is a sitemap, not a home.
- One primary action per screen, **where the thumb is**: the bottom third on phones (FAB, `SaveBar`, a sheet's footer). The app bar holds secondary and rare actions. Destructive actions are never the easiest thing to hit.
- Show what matters first and let the rest be reached: the common fields, then "More options"; the summary, then the breakdown.

## Navigation

- Pick the model from the content: **flat** (3–5 peer areas: `NavigationBar` / rail), **hub and spoke** (a home that pushes to tasks and returns), **drill-down** (list → detail → sub-detail). Five destinations at most; a "More" tab means the areas weren't decided.
- **Push** to go deeper into content. **Modal** (a sheet, or a full-screen dialog with ✕ and Save) for a self-contained task that ends: create, edit, filter, pick. The user should always know which one they're in by how it closes.
- Back never loses work (`PopScope` on dirty forms) and never surprises: on Android it closes the sheet, then clears a selection or search, then pops the route, then leaves the app.
- Tabs keep their state and scroll position (`IndexedStack` or `StatefulShellRoute.indexedStack`, `PageStorageKey` on lists). Returning from a detail lands on the same row.
- Titles say where you are; the selected destination, row and filter are visibly selected. Anything reachable only by a gesture or a long-press is reachable from a visible control too.

## Less typing, fewer decisions

- **Default the likely answer**: today's date, the last customer, the usual currency, the previous filter and sort. Remember choices per user, per screen.
- **Choose instead of type**: up to 4 options as chips, 5–12 in a pick-one sheet, more in a searchable list; autocomplete from what the user has entered before; a stepper for small counts.
- **Don't ask for what you can work out or postpone**: the total from the lines, the country from the locale, the account until there's something worth saving, a permission until the moment it's needed (with one sentence saying why, and a working path when it's refused).
- **Forgive the format**: accept `٠-٩` and `0-9`, comma or dot, spaces in a pasted phone or IBAN; trim; show the formatted result, never an error about formatting the app could have done.
- The right keyboard, `textInputAction`, autofill hints and capitalization on every field (`forms.md`). Next moves on, Done submits or closes the keyboard.

## Feedback and speed

| The wait | Show |
|---|---|
| under 100 ms | the press state itself (always) |
| up to 1 s | keep the screen; a spinner inside the control that was pressed |
| 1–10 s | a skeleton shaped like the content (after 150 ms, so fast loads don't flash); progress when it can be measured |
| longer | let the user leave; tell them when it's done |

- **Every action answers where the user is looking**: the row changes, the button confirms, and a message names the thing (`messages.md`). A save that shows nothing gets pressed twice.
- Be optimistic with what can be undone (toggle, favourite, reorder, delete with Undo) and roll back with a reason if it fails (`states.md`).
- Feel fast: draw from cache first and refresh behind it; keep old content visible while reloading; fixed aspect ratios so nothing jumps when images arrive; never block the whole screen for one part of it.
- Haptics on touch for confirmation only: `selectionClick` on a pick or toggle, `lightImpact` when something completes. Not on scroll, not on every tap, never on desktop.

## Forgiveness

- **Undo for what can be reversed; confirm only what can't**, naming the thing and the consequence; typed confirmation for wiping everything.
- **Never lose what the user typed**: a failed save leaves the form filled with the error beside the action; a long form survives rotation, backgrounding and a phone call (keep the draft in state that outlives the widget, or persist it); leaving a dirty form asks first.
- Prevent the error before reporting it: limit the picker to valid dates, disable what can't be done and say why, validate as the user leaves the field. Then the message says what to do next.
- An empty list is a state with a next step, not an error.

## First run

- **Value before commitment**: let people see or do something real before sign-up when the product allows it.
- Prefer no onboarding to a tour: a first-use empty state that teaches by doing ("Add your first customer", or sample data that can be cleared). If there are onboarding pages, three at most, each about what the user gains, with Skip from the first.
- Ask for the account, the notification permission and the rating after the user has got something, not on launch.

## Search, filter, sort

- Lists that grow past a screen or two get a search field at the top, filtering as the user types, with their recent searches.
- Active filters stay visible as chips with a count and one tap to clear them all; the sort is a pick-one sheet; both are remembered.
- No results: say what was searched and offer the way out ("Clear filters", "Add *Ahmad* as a new customer").

## Gestures and platforms

- Swipe, long-press, drag and pull-to-refresh are shortcuts: each has a visible twin (a menu, a button, a refresh action on desktop).
- Keep the system's gestures: iOS's back swipe from the edge and Android's predictive back both work on every route; no horizontal swipe areas at the screen edges.
- Each platform gets its own habits (`adaptive.md`): adaptive switches and dialogs, hover and shortcuts and right-click on desktop, the keyboard never covering the field or the action.

## Walk it before and after

Before building, write the steps of the top three tasks as a numbered list and cut one step from each. After building, do them: a `UiCase(act:)` in the harness that taps through the flow, or the screenshots read in order. Note every place the user had to think, remember or type something the app knew, and fix the worst one.
