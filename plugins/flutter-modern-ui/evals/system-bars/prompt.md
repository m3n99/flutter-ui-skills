---
description: "A save button flush against the bottom edge. The skill should catch the missing safe area and padding."
tags: [layout, smoke]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Is anything wrong with this Flutter screen on a real phone?

```dart
class EditCustomerScreen extends StatelessWidget {
  const EditCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit customer')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [NameField(), PhoneField(), NotesField()],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}
```
