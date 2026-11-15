---
description: "Asking for a review of an existing screen should load the audit skill and report findings before rewriting."
tags: [trigger, audit, reply]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Can you review this Flutter screen and tell me what's wrong with it, most important first? Don't rewrite it yet.

```dart
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orders')),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, i) => Container(
          margin: EdgeInsets.only(left: 10, right: 10, top: 6),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Row(children: [
            Text(orders[i].customer, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Spacer(),
            Text(orders[i].total),
            Container(width: 10, height: 10, color: orders[i].paid ? Colors.green : Colors.red),
          ]),
        ),
      ),
    );
  }
}
```
