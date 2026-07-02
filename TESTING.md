# Testing Guide

## Overview

This document describes the testing infrastructure for the Internet Archive Apple TV app. Unit tests are a mix of **XCTest** (the majority of existing files) and **Swift Testing**; the policy is to **prefer Swift Testing for new unit tests** (matching `CLAUDE.md`). UI tests use **XCTest** (required by XCUIApplication).

## Test Structure

Test files mirror the production source layout. Directory-level summary (run
`find "Internet ArchiveTests" -name "*.swift"` for the current full list):

```text
Internet ArchiveTests/
├── Mocks/               # Shared test doubles: MockFavoritesService,
│                        # MockNetworkMonitor, MockNetworkService
├── Fixtures/            # TestFixtures.swift — shared test data factories
├── Helpers/             # TestHelpers.swift — AtomicCounter utility
├── Accessibility/       # Accessibility audit tests
├── App/                 # App state, root view, and shared component tests
├── Configuration/       # Configuration loading tests
├── ErrorHandling/       # Error, logger, presenter, retry tests
├── Features/            # SwiftUI feature view + helper tests (incl. Player/)
├── Models/              # Codable model tests
├── Protocols/           # Protocol conformance tests
├── Subtitles/           # Subtitle parsing/conversion/manager tests
├── UI/                  # UIKit component and image loading tests
├── Utilities/           # API manager, helpers, keychain, content filter tests
├── ViewControllers/     # UIKit player controller tests
├── ViewModels/          # View model tests
└── (top level)          # AudioQueueManagerTests, AudioTrackTests

Internet ArchiveUITests/
├── UITestHelper.swift   # Shared launch/navigation helpers (mock-data launch)
├── AccessibilityTests.swift
├── BackgroundAudioTests.swift
├── FocusNavigationTests.swift
├── Internet_ArchiveUITests.swift
├── Internet_ArchiveUITestsLaunchTests.swift
├── RemoteInteractionTests.swift
└── TouchSmokeTests.swift
```

## Framework Strategy

| Test Category | Framework | Notes |
| ------------- | --------- | ----- |
| Unit Tests (existing) | Mixed: XCTest (majority) and Swift Testing | Older suites use XCTest; newer suites use Swift Testing |
| Unit Tests (new) | Swift Testing preferred | Modern API, parameterized tests, better diagnostics |
| UI Tests | XCTest | Required by XCUIApplication (Apple requirement) |

The unit test target contains both frameworks side by side (roughly two thirds
XCTest, one third Swift Testing at the time of writing). **Prefer Swift Testing
(`@Test`, `@Suite`, `#expect`) for new unit tests**; there is no requirement to
migrate existing XCTest suites. UI tests remain XCTest because
`XCUIApplication` only works with XCTest.

## Swift Testing Patterns

### Basic Test Structure

```swift
import Testing
@testable import Internet_Archive

@Suite("Feature Name Tests")
struct FeatureNameTests {

    @Test func basicBehavior() {
        let sut = MyType()
        #expect(sut.value == expectedValue)
    }

    @Test func asyncBehavior() async throws {
        let result = try await someAsyncFunction()
        #expect(result != nil)
    }
}
```

### Setup with init (replaces setUp/tearDown)

```swift
@Suite("ViewModel Tests")
struct ViewModelTests {
    let sut: MyViewModel
    let mockService: MockNetworkService

    init() {
        mockService = MockNetworkService()
        sut = MyViewModel(service: mockService)
    }

    @Test func loadsData() async {
        mockService.mockSearchResponse = TestFixtures.makeSearchResponse(
            docs: TestFixtures.makeVideoResults(count: 2)
        )
        await sut.loadData()
        #expect(sut.items.count == 2)
    }
}
```

### Assertions

```swift
// Equality
#expect(actual == expected)
#expect(actual != unexpected)

// Boolean
#expect(condition)
#expect(!condition)

// Nil checks
#expect(value == nil)
#expect(value != nil)

// Optional unwrapping (replaces XCTUnwrap)
let unwrapped = try #require(optionalValue)

// Approximate equality for floating point
#expect(abs(actual - expected) < 0.001)

// Error throwing
#expect(throws: MyError.self) { try riskyOperation() }

// Record failure (replaces XCTFail)
Issue.record("Unexpected state reached")
```

### Parameterized Tests

Use `@Test(arguments:)` to run the same test logic with multiple inputs:

```swift
@Test(arguments: [
    ("movies", "Movies"),
    ("etree", "Music"),
    ("texts", "Texts"),
])
func mediaTypeDisplayName(type: String, expected: String) {
    #expect(MediaType(type).displayName == expected)
}
```

For complex arguments, use named tuples or dedicated types for clarity:

```swift
struct TimestampCase {
    let srt: String
    let vtt: String
}

@Test(arguments: [
    TimestampCase(srt: "00:01:30,500", vtt: "00:01:30.500"),
    TimestampCase(srt: "01:00:00,000", vtt: "01:00:00.000"),
])
func convertsTimestamp(testCase: TimestampCase) {
    #expect(convert(testCase.srt) == testCase.vtt)
}
```

### MainActor Tests

Tests that call `@MainActor`-isolated code need the `@MainActor` annotation:

```swift
@Suite("UI State Tests")
@MainActor
struct UIStateTests {

    @Test func viewModelUpdatesState() async {
        let vm = MyViewModel()
        await vm.load()
        #expect(vm.isLoading == false)
    }
}
```

### Skipping Tests

```swift
@Test(.disabled("Requires physical device"))
func backgroundAudioPlayback() { }
```

### Async Confirmation (replaces XCTestExpectation)

```swift
@Test func callbackFires() async {
    await confirmation { confirm in
        myObject.onComplete = { confirm() }
        myObject.start()
    }
}
```

## Testable Helpers Pattern

SwiftUI view bodies are difficult to unit test directly. Instead of testing views, we extract pure logic into `enum *Helpers` types and test those:

```swift
// In production code: FavoritesViewHelpers.swift
enum FavoritesViewHelpers {
    static func filterItems(_ items: [Item], by type: MediaType) -> [Item] {
        items.filter { $0.mediaType == type.rawValue }
    }
}

// In test code: FavoritesViewHelpersTests.swift
@Suite("FavoritesViewHelpers Tests")
struct FavoritesViewHelpersTests {
    @Test func filtersMovies() {
        let items = [makeItem(type: "movies"), makeItem(type: "etree")]
        let result = FavoritesViewHelpers.filterItems(items, by: .movies)
        #expect(result.count == 1)
    }
}
```

Existing helper types:

- `ContinueWatchingHelpers` — progress formatting, time remaining calculations
- `SRTConversionHelpers` — subtitle timestamp parsing
- `FavoritesViewHelpers` — favorites filtering and sorting
- `ItemDetailPlaceholderHelpers` — placeholder layout logic
- `YearBrowseHelpers` — year browse destination and state logic
- `SearchResultsHelpers` — search result formatting
- `PlaybackButtonHelpers` — playback button state logic
- `ItemDetailHelpers` — item detail formatting and media URL building
- `MediaCardHelpers` — media card display logic
- `SearchHelpers` — search query building

## Testing Approach

### 1. Protocol-Based Dependency Injection

The app uses protocols to enable dependency injection for testing:

```swift
protocol NetworkServiceProtocol {
    func search(query: String, options: [String: String]) async throws -> SearchResponse
    func getMetadata(identifier: String) async throws -> ItemMetadataResponse
}
```

### 2. Mock Objects

Mocks are stored in `Internet ArchiveTests/Mocks/` for reuse across test suites:

| Mock | Purpose | Concurrency |
| ---- | ------- | ----------- |
| `MockNetworkService` | Network layer test double | `@MainActor` |
| `MockFavoritesService` | Favorites persistence test double | `@unchecked Sendable` |
| `MockNetworkMonitor` | Network connectivity test double | `@MainActor` |

Mocks are made Swift 6-safe either by isolating them to the main actor
(`@MainActor`) or, for simple lock-free mocks, by marking them
`@unchecked Sendable`.

```swift
let mockService = MockNetworkService()
mockService.mockSearchResponse = TestFixtures.searchResponse
mockService.shouldThrowError = false

let result = try await mockService.search(query: "test", options: [:])
#expect(mockService.searchCalled)
```

### 3. Test Fixtures

`TestFixtures` (`Internet ArchiveTests/Fixtures/TestFixtures.swift`) provides
static fixtures (`movieSearchResult`, `audioSearchResult`, `searchResponse`,
`authResponse`, `itemMetadataResponse`, `favoritesResponse`, ...) plus factory
methods:

```swift
// Single search result (all parameters have defaults)
let result = TestFixtures.makeSearchResult(identifier: "test-1", title: "Test Movie")

// Search response wrapping a list of docs
let response = TestFixtures.makeSearchResponse(docs: [result])
let paged = TestFixtures.makeSearchResponse(numFound: 100, docs: [result])

// Batches of typed results
let videos = TestFixtures.makeVideoResults(count: 5)          // mediatype "movies"
let concerts = TestFixtures.makeMusicResults(count: 5)        // mediatype "etree"

// Music metadata with a given track count
let album = TestFixtures.makeMusicMetadataResponse(trackCount: 3)
```

### 4. Test Categories

#### Unit Tests (XCTest and Swift Testing)

**Models** — Codable conformance, computed properties, safe accessors
**ViewModels** — State management, data loading, error handling
**Utilities** — Network, retry, keychain, content filtering
**Helpers** — Pure logic extracted from SwiftUI views
**UI Components** — UIKit cell configuration, layout, accessibility

#### UI Tests (XCTest)

**Focus Navigation** — Tab bar focus, grid navigation, focus restoration
**Remote Interaction** — Play/pause, menu button, seek gestures
**Accessibility** — Labels, hints, VoiceOver navigation
**Background Audio** — Playback lifecycle, now playing, remote commands

## tvOS-Specific Testing Guidelines

### Focus State Testing

tvOS apps rely on focus-based navigation. Key patterns:

```swift
// Verify focus via selection state (tabs)
let tab = app.tabBars.buttons["Videos"]
XCTAssertTrue(tab.isSelected)

// Verify focus via hittability (grid cells)
let cell = app.cells.firstMatch
XCTAssertTrue(cell.isHittable)

// Navigate using remote
XCUIRemote.shared.press(.right)
XCUIRemote.shared.press(.down)
```

### Remote Interaction Testing

```swift
// Select focused item
XCUIRemote.shared.press(.select)

// Play/pause toggle
XCUIRemote.shared.press(.playPause)

// Go back (menu button)
XCUIRemote.shared.press(.menu)

// Wait for element after navigation
let element = app.staticTexts["Title"]
XCTAssertTrue(element.waitForExistence(timeout: 5))
```

### Important tvOS Differences

- `tap()` is **unavailable** on tvOS — use `XCUIRemote.shared.press(.select)` instead
- Focus guides control navigation paths between non-adjacent elements
- Test focus restoration after dismissing overlays (alerts, modals, full-screen video)
- The app uses AVKit's built-in remote command handling — full background audio tests require physical hardware

### Simulator Limitations

- Background audio does not persist like on physical devices
- Hardware button behavior may differ from simulator
- Network throttling not available in tvOS simulator
- Remote touch surface gestures have limited simulation support

## Running Tests

### Command Line

```bash
# Run all unit tests
xcodebuild test \
  -project "Internet Archive.xcodeproj" \
  -scheme "Internet Archive" \
  -destination "platform=tvOS Simulator,name=Apple TV" \
  -only-testing:"Internet ArchiveTests"

# Run with coverage
xcodebuild test \
  -project "Internet Archive.xcodeproj" \
  -scheme "Internet Archive" \
  -destination "platform=tvOS Simulator,name=Apple TV" \
  -enableCodeCoverage YES \
  -resultBundlePath /tmp/coverage_result.xcresult \
  -only-testing:"Internet ArchiveTests"

# Run specific test suite
xcodebuild test \
  -project "Internet Archive.xcodeproj" \
  -scheme "Internet Archive" \
  -destination "platform=tvOS Simulator,name=Apple TV" \
  -only-testing:"Internet ArchiveTests/SearchViewModelTests"

# Generate coverage report
xcrun xccov view --report /tmp/coverage_result.xcresult

# Check for 0% files
xcrun xccov view --report /tmp/coverage_result.xcresult | grep "0.00%"
```

### Xcode

1. Open `Internet Archive.xcodeproj`
2. Select the test target
3. Press `Cmd+U` to run all tests
4. Use Test Navigator (`Cmd+6`) to run individual tests

## Code Coverage

### Coverage by Category (as of Sprint 6)

| Category | Coverage | Lines |
| -------- | -------- | ----- |
| **Overall** | **49.6%** | 9,226 / 18,599 |
| ViewModels | 95.8% | 1,192 / 1,244 |
| Models | 98.0% | 445 / 454 |
| Helpers | 98.9% | 829 / 838 |
| Utilities | 70.6% | 1,237 / 1,752 |
| UIKit Controllers | 67.4% | 1,008 / 1,495 |
| UI Components | 62.0% | 1,056 / 1,704 |
| SwiftUI Views | 25.8% | 2,240 / 8,668 |

### Coverage Notes

- **ViewModels, Models, Helpers** are at or above 95% — all business logic is well tested
- **SwiftUI Views** have low coverage because `body` computations require runtime rendering. Testable logic has been extracted to Helpers (98.9% covered)
- **11 files remain at 0%** — all are SwiftUI views or view components whose logic is tested through extracted helpers and view models
- Improving SwiftUI view coverage would require integration testing with `UIHostingController` or a tool like ViewInspector

### Coverage Goals

| Category | Target | Actual | Status |
| -------- | ------ | ------ | ------ |
| ViewModels | 95% | 95.8% | Achieved |
| Models | 90% | 98.0% | Achieved |
| Helpers | 95% | 98.9% | Achieved |
| Utilities | 70% | 70.6% | Achieved |
| UI Components | 70% | 62.0% | Close |
| UIKit Controllers | 75% | 67.4% | Close |
| SwiftUI Views | 65% | 25.8% | Gap |

## Swift 6 Concurrency in Tests

### Thread Safety for Mocks

Swift Testing runs tests in parallel. Mocks with mutable state must be thread-safe:

```swift
// Use @unchecked Sendable for simple mocks
final class MockService: ServiceProtocol, @unchecked Sendable {
    var called = false
    // ...
}

// Use @MainActor for UI-related test suites
@Suite("UI Tests")
@MainActor
struct UITests { }
```

### Common Concurrency Gotchas

- `withThrowingTaskGroup` requires `T.Output: Sendable` — add the constraint
- Capturing non-Sendable types in `@Sendable` closures fails — use `@unchecked Sendable` wrapper
- `withCheckedThrowingContinuation` + Combine `sink` needs a thread-safe state wrapper
- Mark test suites `@MainActor` when testing `@MainActor`-isolated view methods

## Continuous Integration

Tests run automatically on every push and pull request via GitHub Actions.

### CI Workflow

- Runs on macOS runner with latest Xcode
- Executes all unit tests
- Reports code coverage
- Fails build if tests fail

See `.github/workflows/tests.yml` for test and coverage configuration (and `.github/workflows/ci.yml` for SwiftLint and build configuration).

## Troubleshooting

### Tests Fail Locally But Pass in CI

- Clean build folder: `Shift+Cmd+K`
- Delete derived data: `~/Library/Developer/Xcode/DerivedData`
- Ensure all schemes are shared

### Slow Tests

- Check for accidental network calls (use mocks instead)
- Reduce sleep/delay durations in tests
- Use `async/await` directly instead of polling

### Flaky Tests

- Check for race conditions in async code
- Ensure proper actor isolation (`@MainActor`)
- Use `Task.yield()` if needed for async coordination
- Swift Testing runs tests in parallel — ensure test isolation

### Common Swift Testing Migration Issues

- Missing `import Foundation` alongside `import Testing` when using `URL`, `Date`, etc.
- `@MainActor` needed on test suites calling MainActor-isolated methods
- `try #require` for optional unwrapping (replaces `XCTUnwrap`)
- No `setUp`/`tearDown` — use `init` for setup, rely on struct deallocation for cleanup

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [Migrating from XCTest](https://developer.apple.com/documentation/testing/migratingfromxctest)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest) (UI tests)
- [Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

## Contributing

When adding new features:

1. Extract testable logic into `*Helpers` enum types
2. Write new unit tests with Swift Testing (`@Test`, `@Suite`, `#expect`); existing XCTest suites can stay as they are
3. Place mocks in `Internet ArchiveTests/Mocks/`
4. Use `TestFixtures` factory methods for test data
5. Ensure tests pass locally before pushing
6. Check code coverage for new code
