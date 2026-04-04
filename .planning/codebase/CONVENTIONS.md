# Coding Conventions

**Analysis Date:** 2025-07-14

## Project Status

This is a **greenfield Flutter project** at the default template stage. Only `lib/main.dart` and `test/widget_test.dart` exist. The planned architecture is **Clean Architecture + MVVM** with **Riverpod** state management (per `happ_clone_specs.md`). Conventions below combine Flutter/Dart standards enforced by the linter with prescriptive guidance aligned to the spec.

## Naming Patterns

**Files:**
- Use `snake_case.dart` for all Dart files (Flutter/Dart standard)
- Example: `lib/main.dart`

**Classes:**
- Use `PascalCase` for classes, enums, typedefs, and extensions
- Widget classes: `MyHomePage`, `MyApp`
- State classes: `_MyHomePageState` (prefixed with underscore for private)

**Functions & Methods:**
- Use `camelCase` for functions, methods, and named parameters
- Private methods prefixed with underscore: `_incrementCounter()`
- Example from `lib/main.dart`: `void _incrementCounter()`, `Widget build(BuildContext context)`

**Variables:**
- Use `camelCase` for local variables and instance fields
- Private fields prefixed with underscore: `int _counter = 0`
- Constants use `camelCase` (Dart convention, not SCREAMING_SNAKE): `const MyApp({super.key})`

**Types:**
- Use `PascalCase` for type names
- Generic type parameters: single uppercase letter (`State<MyHomePage>`)

## Code Style

**Formatting:**
- Tool: `dart format` (built into Dart SDK)
- Line length: 80 characters (Dart default)
- Trailing commas on widget trees for clean diffs and auto-formatting
- Run: `dart format lib/ test/`

**Linting:**
- Tool: `flutter_lints` v6.0.0 (via `package:flutter_lints/flutter.yaml`)
- Config: `analysis_options.yaml`
- No custom lint rules enabled or disabled — uses the default recommended set
- Run: `flutter analyze`

**Key lint rules enforced by `flutter_lints`:**
- `prefer_const_constructors` — use `const` wherever possible
- `avoid_print` — enabled (use proper logging, not `print()`)
- `prefer_final_fields` — mark fields `final` when not reassigned
- `use_key_in_widget_constructors` — always accept a `Key` parameter in widgets
- `sized_box_for_whitespace` — use `SizedBox` instead of `Container` for spacing
- `prefer_const_literals_to_create_immutables` — use `const` for immutable collection literals

## Widget Patterns

**Const Constructors:**
- Always use `const` constructors for stateless widgets and immutable widget instances
- Pattern from `lib/main.dart`:
```dart
const MyApp({super.key});
const MyHomePage({super.key, required this.title});
```

**Super Parameters:**
- Use Dart 3 `super.key` syntax instead of `Key? key` + `super(key: key)`
```dart
// DO:
const MyApp({super.key});
// DON'T:
const MyApp({Key? key}) : super(key: key);
```

**StatefulWidget Pattern:**
- Separate widget class from state class
- Widget holds configuration (`final` fields), State holds mutable state
- Pattern from `lib/main.dart`:
```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(/* ... */);
  }
}
```

**Enum-like shorthand (Dart 3):**
- The codebase uses Dart 3 shorthand for enum/static member access:
```dart
colorScheme: .fromSeed(seedColor: Colors.deepPurple),
mainAxisAlignment: .center,
```

## Import Organization

**Order (follow Dart conventions):**
1. `dart:` SDK imports
2. `package:flutter/` framework imports
3. `package:<other>/` third-party package imports
4. `package:arma_proxy_vpn_client/` project imports (relative or package)

**Example from `lib/main.dart`:**
```dart
import 'package:flutter/material.dart';
```

**Path Aliases:**
- Use `package:arma_proxy_vpn_client/` for cross-package imports
- Use relative imports within the same feature/directory

## Error Handling

**Current state:** No error handling implemented yet (template app).

**Prescribed patterns for new code:**
- Use `try-catch` for async operations (network, file I/O)
- Use custom exception classes for domain errors
- Avoid catching generic `Exception` — catch specific types
- For Riverpod: use `AsyncValue` pattern for loading/error/data states

## Logging

**Framework:** Not yet configured.

**Prescribed:**
- Do NOT use `print()` — the linter enforces `avoid_print`
- Use `debugPrint()` for development-only logging
- For production logging, use the `logging` package or a custom logger

## Comments

**Current style observed in `lib/main.dart`:**
- Inline comments explaining Flutter framework behavior (tutorial-style)
- `// This widget is the root of your application.`
- `// TRY THIS:` comments are template boilerplate — remove when building real features

**Prescribed for new code:**
- Use `///` doc comments for public APIs (classes, methods, properties)
- Use `//` for implementation notes
- Remove all default template comments when replacing boilerplate

## Function Design

**Size:** Keep `build()` methods short. Extract sub-widgets into separate methods or classes when a build method exceeds ~50 lines.

**Parameters:** Use named parameters with `required` keyword for widget constructors. Positional parameters for utility functions with 1-2 args.

**Return Values:** Widget methods return `Widget`. Use `@override` annotation on all overridden methods.

## Module Design

**Exports:**
- Each feature directory should have a barrel file (e.g., `features/dashboard/dashboard.dart`)
- Export only the public API of each module

**Barrel Files:**
- Not yet used (single-file project)
- Prescribe: create barrel files per feature directory as the project grows

## Dart Version Features

**SDK:** `^3.11.4` — use modern Dart 3 features:
- Pattern matching and switch expressions
- Records and destructuring
- Sealed classes for state modeling
- `super.key` shorthand in constructors
- Enhanced enums
- Static member shorthand (`.center`, `.fromSeed()`)

---

*Convention analysis: 2025-07-14*
