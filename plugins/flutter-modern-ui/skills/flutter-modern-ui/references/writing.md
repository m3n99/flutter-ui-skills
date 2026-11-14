# Interface writing

Words are part of the design: they are how the user finds the way. Generic words ("Submit", "Success", "No data", "Something went wrong") make a careful layout feel templated. Write the strings while building the screen, in the project's localization files, never as placeholders to fix later.

## Principles

1. **The user's words, not the system's.** People manage "reminders", not "notification rules"; they see "Couldn't save", not "PATCH failed (500)". Use the names the audience uses for its own things (the brief's subject line helps).
2. **Say what happens.** A button names its result: "Save changes", "Send invoice", "Delete 3 photos". Not "OK", "Submit", "Confirm", "Yes".
3. **One name per thing, one verb per action, through the whole flow.** The button "Archive" leads to the message "Archived Kinetic Labs" and the filter "Archived". Never "Remove" on one screen and "Delete" on the next for the same act.
4. **Short, plain, sentence case.** One idea per string. No exclamation marks, no "please", no "successfully", no "oops". Capitalize only the first word and names.
5. **Specific beats clever.** Name the record, the amount, the date: "Payment of ₪ 250 recorded for Ahmad Saleh".

## By element

| Element | Write | Avoid |
|---|---|---|
| Screen title | the thing or the task: "Invoices", "New invoice", "Edit INV-1041" | "Invoice Management Screen" |
| Primary button | verb + object: "Add customer", "Save changes" | "Submit", "Done" for a save |
| Destructive button | the act itself: "Delete invoice" | "Yes", "OK" |
| Cancel | "Cancel"; "Discard" when it throws work away; "Keep editing" as its opposite | two buttons that both sound safe |
| Field label | a noun: "Amount", "Due date", "Email (optional)" | questions, colons, placeholders used as labels |
| Hint text | an example of the format: "name@example.com", "0599 123 456" | repeating the label |
| Helper text | what the field is for or its limit, only when needed | restating the label |
| Validation | what to do: "Enter an amount above 0", "Use a date after today" | "Invalid input", "Required" alone |
| Empty state | what will be here + the first step: "No customers yet. Add your first one to start tracking payments." | "No data", "Nothing found" |
| No results | the query + a way out: "Nothing matches “ahmd”. Clear the search or add a new customer." | "0 results" |
| Error | what failed + what to do: "Couldn't load your invoices. Check your connection and try again." | apologies, error codes, blame |
| Confirmation | title = the question with the thing named ("Delete INV-1041?"), body = the consequence in one sentence, buttons = "Cancel" + the act | "Are you sure?" |
| Success message | the result with the thing named: "Saved changes to INV-1041" | "Success!", "Operation completed" |
| Loading | usually no words (a skeleton); for long work, what's happening: "Exporting 240 records…" | "Please wait" |
| Tooltip | the action's name: "Filter", "Close" | sentences |
| Switch label | the thing that's on when it's on: "Due-date reminders" | "Enable/disable reminders" |

## Numbers, dates, counts

- Format through `intl` for the locale: thousands separators, currency position, month names. Relative when it helps ("Due tomorrow", "3 days ago"), exact when it matters (the invoice shows the date).
- Plurals through the localization system's plural rules, never string concatenation ("1 invoice", "3 invoices"; Arabic has six forms).
- Counts and sums sit next to their noun: "12 invoices", not a bare "12" under an icon.

## Voice

Pick it from the brief's feeling words and keep it in every string: a ledger for a shopkeeper is plain and exact; a children's quiz can cheer; a medical log never jokes. Errors and empty states use the same voice as the rest, at a lower volume.

## Arabic interfaces

- **Clear Modern Standard Arabic**, short sentences, the words the audience uses for its trade. Not a word-for-word translation of English strings: "No customers yet" is «لا يوجد زبائن بعد», not a rendering of each English word.
- **Buttons use the verbal noun** (المصدر), the convention across Arabic interfaces, which also avoids gendered imperatives: «حفظ», «إلغاء», «حذف», «إضافة زبون», «تعديل», «التالي», «رجوع», «تم».
- **Plurals**: use all the ICU categories (`zero`, `one`, `two`, `few` for 3–10, `many` for 11–99, `other`): «لا فواتير», «فاتورة واحدة», «فاتورتان», «٣ فواتير», «١١ فاتورة».
- **Punctuation is Arabic**: the comma «،», the semicolon «؛», the question mark «؟», and « » as quotation marks around a quoted search term. No tatweel (ـ) stretching for emphasis; emphasis comes from weight.
- **Optional fields** end with «(اختياري)»; required ones carry no mark.
- Numbers, dates, codes, phone numbers and Latin names stay left-to-right inside the sentence (`Ltr`, `rtl-arabic.md`); choose Western or Arabic-Indic digits once for the whole app.
- Messages name the thing in Arabic order: «تم حفظ التعديلات على الفاتورة 1041», «تعذّر حذف السجل وما زال في القائمة. يُرجى المحاولة مرة أخرى.»

## Check

Read every string on the screen aloud, alone, without the layout around it. Each one should say what it is or what will happen. Then read the flow in order: do the same things keep the same names?
