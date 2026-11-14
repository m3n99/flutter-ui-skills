# Screen types: what each one is for and how it's built

Most apps are made of the same dozen screens. Each has a job, an anatomy that works, and a usual way of going wrong. Start from the anatomy, then make it this app's with the brief (`identity.md`). Lists, forms and dashboards have their own references; this file covers the rest and links them.

| Screen | Job | Details |
|---|---|---|
| Home | answer the question the user opens the app with | below; dashboards: `data-display.md` |
| List | find one record among many | `layout.md` › List screens |
| Detail | understand one record and act on it | below |
| Create / edit | get data in with the least effort | `forms.md` |
| Sign in / sign up | get through the door | below; `assets/examples/sign_in_screen.dart` |
| Onboarding | reach first value | below |
| Settings | change how the app behaves | below; `assets/examples/settings_screen.dart` |
| Profile / account | see and edit who I am | below |
| Search | find by typing | below |
| Notifications / inbox | see what changed, clear it | below |
| Paywall / checkout | decide and pay with confidence | below |
| Article / media | read or watch without distraction | below |

## Home

- Top to bottom: the answer to the daily question (a short list, a number with its context, the next thing to do), the primary action, then two or three secondary blocks, each with a way to see more.
- Not a KPI grid by reflex: tiles suit an owner checking a business; a field worker's home is today's jobs; a reader's home is the next article.
- First use has its own home: the empty state with the first action, or sample content. Greet by name only when there's an account and something to say.
- Wrong when: it's a menu of features; four numbers with no next step; the primary action lives in the app bar.

## Detail

- Header: what it is (title), its state (status pill), the one number or fact that matters, set large. Then facts in groups (a card per group, label and value rows), then history.
- The main action sits in a bottom bar or FAB; edit, share and delete go in the app bar, delete last and in a menu.
- From a list on wide windows it's the detail pane, with a close button and Esc (`adaptive.md`); on phones a pushed page that returns to the same row.
- States: loading keeps the header from the list row (no blank flash), "not found" offers the way back, a failed action leaves the page as it was.
- Wrong when: every field has the same weight; labels are longer than values; the page is an edit form in disguise.

## Sign in / sign up

- One column, capped at the form width and centered on wide windows; scrolls, so the keyboard never covers a field or the button.
- Top to bottom: the brand moment (logo or the signature, the product's name, one line saying what it does), the fields, the primary button, then the lesser paths (forgot password, create account, other providers) as text buttons.
- Fields: email with `TextInputType.emailAddress`, `AutofillHints.email` / `username`; password with `AutofillHints.password` (`newPassword` when signing up), a show / hide button with a tooltip, Done submits. Wrap them in `AutofillGroup`; finish with `TextInput.finishAutofillContext()` so the password manager offers to save.
- Sign-up asks for the minimum: no "confirm password" (the show button does that job), no fields that can wait; password rules shown before typing, ticking off as they're met.
- Errors are specific and stay near the button, inside the form: "That email and password don't match. Try again or reset your password." The fields keep what was typed. Lock the button while it's working (`SubmitButton`).
- Phone-number sign-in: country code picker with the local default, digits LTR, a code field with `AutofillHints.oneTimeCode`, a resend timer.
- Wrong when: a full-bleed gradient with a floating card; social buttons louder than the main path; errors in a SnackBar that vanishes; the keyboard hides the button.

## Onboarding

- Prefer none (`ux.md` › First run). If needed: three pages at most, one idea each, about what the user gains; Skip from the first page; page dots; the last page's button starts the first real task.
- Permission priming belongs to the moment of need, not here.
- Each page: one picture or motif (the signature works), a headline, one sentence. `PageView` with `SafeArea`, the button pinned in a `SaveBar`.
- Wrong when: it's a feature tour; there's no skip; it reappears.

## Settings

- Groups as cards with a heading (Account, Appearance, Notifications, Data, About), most used first. Each row: a leading icon only if it helps scanning, a title, the current value at the end or a one-line description under the title.
- Row types: a **switch** that applies at once (`SwitchListTile.adaptive`); a **pick-one** that shows its value and opens `showAppPicker` (theme, language, currency); a **navigation** row with a chevron to a sub-page; an **action** (export, sign out).
- No Save button for toggles and picks. Text settings edit on their own page or sheet.
- The destructive group is last, apart, in the error color, and confirms; "delete everything" asks for typed confirmation.
- The footer has the version and build in `bodySmall`; legal and support links live under About.
- Wide windows: cap the width (form width); don't stretch rows across the monitor.
- Wrong when: everything is one long undivided list; a toggle needs Save; the value of a pick-one is hidden until opened; language choice doesn't show each language in its own script.

## Profile / account

- Header: avatar (initials fallback), name, the identifier (email or phone, LTR). Then what belongs to the person: details, security, plan, devices. Sign out at the end; delete account apart from it, with confirmation.
- Editing is a separate page or a sheet per field group, not always-open fields.
- Wrong when: it duplicates Settings; stats nobody asked for fill the top half.

## Search

- The field has focus on arrival, a clear button, and the keyboard's Search action. Before typing: recent searches and suggestions. While typing: results as rows (debounced when remote), the matched part of each result emphasized.
- Results are tappable rows that say what kind of thing they are when kinds mix. No results names the query and offers the next step.
- Wrong when: a blank page waits for Enter; results rearrange under the finger while loading.

## Notifications / inbox

- Newest first, grouped by day; unread shown by weight and a dot, not color alone; each row says what happened and to what, and opens that thing.
- Mark all read in the app bar; swipe to dismiss has a menu twin; empty is calm ("You're all caught up").

## Paywall / checkout

- Paywall: what you get (three concrete lines), the plans side by side or stacked with the price and period in plain words, the recommended plan marked by more than color, one primary button stating the commitment ("Start 7-day free trial, then $4.99/month"), restore purchases, terms. Close is always visible.
- Checkout: the order summary stays visible, amounts are tabular and LTR, totals are computed for the user, errors name the field, the pay button repeats the amount.
- Wrong when: the price is smaller than the marketing; the close button is hidden or delayed; a pre-ticked upsell.

## Article / media

- Reading: one column capped near 65 characters (`AppSize.readingMaxWidth`), body 17 / 1.6, a serif or a reading sans, images at a fixed ratio with captions, generous space above headings. The app bar gets out of the way on scroll; progress shows quietly.
- Media: artwork large with a fixed ratio, controls in the thumb zone with the main one largest, the scrubber showing elapsed and remaining in tabular figures.
- Wrong when: text runs edge to edge on a tablet; controls sit over busy artwork without a scrim.
