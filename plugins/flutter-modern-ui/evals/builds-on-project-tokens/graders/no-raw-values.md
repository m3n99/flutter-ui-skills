---
type: regex
target: { source: file, path: lib/features/customers/customers_screen.dart }
pattern: 'Colors\.(?!transparent)[a-z]|Color\(0x|fontSize:\s*\d|EdgeInsets\.(all|symmetric|only)\([^)]*?(?<![\w.])[1-9]\d*\b|BorderRadius\.circular\(\s*[1-9]'
match: not_contains
---
