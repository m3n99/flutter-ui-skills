# Messages, errors and Undo

## One component

The app has exactly one message component. In the template it is `AppMessenger` (floating SnackBar through a global `ScaffoldMessengerKey`, callable from anywhere, including blocs and route helpers). If the project already has one (`CustomToastMessage`, `showToast`), use and extend that instead; screens never build SnackBars directly.

```dart
MaterialApp(scaffoldMessengerKey: AppMessenger.key, …)

AppMessenger.success('Created INV-1043 for Blue Harbor Café');
AppMessenger.error("Couldn't export the report. Check that the folder is writable.");
AppMessenger.showFailure(failure, whatFailed: "Couldn't save the payment. Your input is still here; try again.");
```

## Anatomy and timing

- Icon + text in every message. Success and info: `inverseSurface` with a check / info icon. Errors: `errorContainer` with an error icon.
- Plain messages: 4 s, with a close ✕. With an action (Undo, Open folder, Print receipt): 6 s, then they close by themselves.
- **`persist: false` on messages with an action.** Since Flutter 3.38 a SnackBar with an action no longer auto-dismisses by default, so every "Undo" / "Open" message otherwise stays until closed by hand. Set it once in the message component.
- Floating; 420 px wide on desktop (theme), full width on phones; bottom.
- A new message replaces the current one (`hideCurrentSnackBar` first) instead of queueing behind it.
- `fluttertoast` has no Windows support; SnackBars work everywhere.

## Copy

- **Name the thing**: "Added record 1042 for Ahmad Saleh", "Saved changes to record 1042", "Payment of 250 ₪ recorded on bill 3". Not "Success".
- **Errors say what failed and what to do**: "Couldn't delete the record. It's back in the list; try deleting again." Never raw exception text; never the repository's generic "Unexpected error".
- **Validation passes through**: messages meant for the user (amount larger than the remaining balance) are shown as written. `AppMessenger.userMessageOf` recognizes them; everything else is replaced by the operation-specific `whatFailed`.
- One sentence, plain words, no exclamation marks, no blame.

## Delete with Undo

`AppMessenger.deleteWithUndo` + `PendingDeletes`. Reference: `assets/examples/records_screen.dart`.

1. Confirm dialog first for anything that matters (skip for trivial, easily recreated items).
2. **Hide the item at once**: `PendingDeletes.hide(id)`; lists filter with `pending.visible(items, keyOf)` and rebuild through `ListenableBuilder`.
3. Show "Deleted INV-1042" with **Undo** (6 s).
4. Undo → release the key; the item reappears where it was.
5. Any other close (timeout, swipe, another message replacing it) → **commit**, then **reload**, then release the key.

Three pitfalls this order avoids:

- **Release only after the list has reloaded**, or the deleted row flashes back for a frame.
- **Never keep keys forever**: SQLite and other stores can reuse the last deleted id, and a stale hidden key would hide the new record.
- **Commit by explicit id**, never "the currently open record": the open record can change during the Undo window (the user taps another row).

Notes:
- Closing the app during the Undo window keeps the item (the delete never ran). That's the safe failure.
- "Delete all data" is the exception: typed confirmation, no Undo.
- A failed commit releases the key and shows "Couldn't delete …; it's back in the list".

## Which surface

| Situation | Surface |
|---|---|
| Result of an action (saved, deleted, sent) | Message (SnackBar) |
| Action failed | Message with what failed + what to do (Retry action when useful) |
| Destructive action | Confirm dialog → Undo message |
| Load failed for the whole screen | Error state in the screen (`EmptyState.error`) |
| Persistent condition (offline, read-only, trial) | Banner at the top, content stays |
| Field invalid | Inline error text under the field |
| Unusual but valid input | Inline warning helper text |

## Busy states

- Saving: `SubmitButton` (spinner, disabled, keeps width) so a second press does nothing.
- Long operations (export, backup): progress in a dialog or a persistent bottom bar with Cancel, then a message with "Open folder".
- Settings toggles apply instantly and need no message unless they fail.

## Accessibility

- SnackBars are announced by screen readers; keep the text self-contained (don't rely on the icon).
- When accessible navigation is on, SnackBars with an action don't time out; that's expected.
- Results that happen without a message (filters applied) can be announced with `SemanticsService.announce`.
