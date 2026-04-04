# Testing Patterns

**Analysis Date:** 2025-07-14

## Project Status

This is a **greenfield Flutter project** with a single default test file. Testing infrastructure needs to be built from scratch as features are added. The patterns below document the existing test and prescribe conventions for the planned Clean Architecture + MVVM + Riverpod architecture.

## Test Framework

**Runner:**
- `flutter_test` (bundled with Flutter SDK, v0.0.0 in lockfile)
- Config: No separate config file — Flutter's built-in test runner is used

**Assertion Library:**
- `flutter_test` matchers (extends `package:test` matchers with widget-specific matchers)
- Key matchers: `findsOneWidget`, `findsNothing`, `findsNWidgets(n)`

**Run Commands:**
```bash
flutter test                    # Run all tests
flutter test --watch            # Watch mode (requires `test` package)
flutter test --coverage         # Generate coverage report
flutter test test/widget_test.dart  # Run specific test file
```

## Test File Organization

**Location:**
- Separate `test/` directory (mirrors `lib/` structure)
- Current file: `test/widget_test.dart`

**Naming:**
- `*_test.dart` suffix for all test files
- Example: `widget_test.dart`

**Prescribed structure as project grows:**
```
test/
├── unit/                      # Pure Dart logic tests
│   ├── models/                # Data model tests
│   ├── services/              # Service/repository tests
│   └── providers/             # Riverpod provider tests
├── widget/                    # Widget/UI tests
│   ├── screens/               # Full screen widget tests
│   └── components/            # Individual component tests
├── integration/               # Integration tests
└── helpers/                   # Test utilities, mocks, fixtures
    ├── mocks.dart
    └── test_helpers.dart
```

## Test Structure

**Suite Organization:**
- Use top-level `void main()` as the entry point
- Use `testWidgets()` for widget tests (provides `WidgetTester`)
- Use `test()` for unit tests (pure Dart logic)
- Use `group()` to organize related tests

**Existing pattern from `test/widget_test.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
```

**Prescribed patterns for new tests:**

```dart
// Unit test pattern
void main() {
  group('ClassName', () {
    late ClassName subject;

    setUp(() {
      subject = ClassName();
    });

    group('methodName', () {
      test('should do X when Y', () {
        final result = subject.methodName(input);
        expect(result, expectedValue);
      });

      test('should throw when invalid input', () {
        expect(() => subject.methodName(badInput), throwsA(isA<SpecificException>()));
      });
    });
  });
}
```

```dart
// Widget test pattern
void main() {
  group('WidgetName', () {
    testWidgets('renders correctly with initial state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WidgetName(),
        ),
      );

      expect(find.text('Expected Text'), findsOneWidget);
    });

    testWidgets('handles user interaction', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: WidgetName()));
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Updated Text'), findsOneWidget);
    });
  });
}
```

## Mocking

**Framework:** Not yet configured. No mocking dependency in `pubspec.yaml`.

**Recommended setup (add to `dev_dependencies`):**
```yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
  # OR for code-generation-free mocking:
  mocktail: ^1.0.0
```

**Prescribed mocking patterns:**

```dart
// Using mocktail (no code generation needed — recommended)
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements Repository {}

void main() {
  late MockRepository mockRepo;

  setUp(() {
    mockRepo = MockRepository();
  });

  test('should fetch data', () async {
    when(() => mockRepo.getData()).thenAnswer((_) async => expectedData);

    final result = await useCase.execute(mockRepo);

    expect(result, expectedData);
    verify(() => mockRepo.getData()).called(1);
  });
}
```

**What to Mock:**
- Repositories and data sources (network, database)
- Platform channels (VpnService, native Xray-core calls)
- External services (subscription URL fetchers)
- Navigation (GoRouter)

**What NOT to Mock:**
- Data models and value objects
- Pure utility/helper functions
- Widget rendering (use `pumpWidget` instead)

## Riverpod Testing (Prescribed)

When Riverpod is added, use `ProviderContainer` for unit tests and `ProviderScope` overrides for widget tests:

```dart
// Unit testing a provider
void main() {
  test('provider returns expected state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(myProvider);
    expect(state, expectedValue);
  });
}

// Widget testing with provider overrides
void main() {
  testWidgets('screen uses overridden provider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProvider.overrideWithValue(mockValue),
        ],
        child: const MaterialApp(home: MyScreen()),
      ),
    );

    expect(find.text('mock data'), findsOneWidget);
  });
}
```

## Fixtures and Factories

**Test Data:**
- Not yet established
- Prescribe: create factory functions in `test/helpers/`

```dart
// test/helpers/factories.dart
import 'package:arma_proxy_vpn_client/models/server_config.dart';

ServerConfig createTestServerConfig({
  String name = 'Test Server',
  String protocol = 'vless',
  String address = '127.0.0.1',
  int port = 443,
}) {
  return ServerConfig(
    name: name,
    protocol: protocol,
    address: address,
    port: port,
  );
}
```

**Location:**
- `test/helpers/` — shared test utilities, mocks, and factories

## Coverage

**Requirements:** None enforced currently.

**View Coverage:**
```bash
flutter test --coverage                  # Generates lcov.info
genhtml coverage/lcov.info -o coverage/html  # HTML report (requires lcov)
open coverage/html/index.html            # View in browser
```

**Prescribed targets:**
- Models/data layer: 90%+
- Business logic/use cases: 85%+
- Widgets: 70%+
- Overall: 80%+

## Test Types

**Unit Tests:**
- Test pure Dart logic: models, services, repositories, parsers
- Location: `test/unit/`
- No Flutter dependencies needed — use `test()` not `testWidgets()`
- Critical for: protocol parsing (`vless://`, `vmess://`, etc.), subscription URL decoding, config model serialization

**Widget Tests:**
- Test UI rendering and interaction
- Location: `test/widget/`
- Use `testWidgets()` with `WidgetTester`
- Wrap widgets in `MaterialApp` (or `ProviderScope` + `MaterialApp` with Riverpod)
- Use `tester.pumpWidget()`, `tester.tap()`, `tester.pump()`, `tester.pumpAndSettle()`

**Integration Tests:**
- Test complete flows across layers
- Location: `integration_test/` (Flutter convention, separate from `test/`)
- Use `integration_test` package
- Run: `flutter test integration_test/`

**E2E Tests:**
- Not yet configured
- Consider `patrol` or Flutter's built-in integration testing for full device tests

## Common Patterns

**Async Testing:**
```dart
test('async operation completes', () async {
  final result = await someAsyncFunction();
  expect(result, expectedValue);
});

testWidgets('async widget update', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: AsyncWidget()));
  
  // Wait for all animations and async operations to complete
  await tester.pumpAndSettle();
  
  expect(find.text('Loaded'), findsOneWidget);
});
```

**Error Testing:**
```dart
test('throws on invalid config', () {
  expect(
    () => parseConfig('invalid://'),
    throwsA(isA<FormatException>()),
  );
});

test('returns error state on failure', () async {
  when(() => mockRepo.fetch()).thenThrow(NetworkException());

  final result = await useCase.execute();

  expect(result, isA<ErrorState>());
});
```

**Finder Patterns (Widget Tests):**
```dart
// By text
find.text('Connect')

// By widget type
find.byType(FloatingActionButton)

// By icon
find.byIcon(Icons.add)

// By key
find.byKey(const Key('connect_button'))

// By predicate
find.byWidgetPredicate((widget) => widget is Text && widget.data == 'Hello')
```

## Current Test Inventory

| File | Type | Tests | Description |
|------|------|-------|-------------|
| `test/widget_test.dart` | Widget | 1 | Default counter increment smoke test |

**Total: 1 test file, 1 test case**

---

*Testing analysis: 2025-07-14*
