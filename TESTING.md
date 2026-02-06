# Testing Guide

## Overview

This document describes the testing infrastructure for the Internet Archive Apple TV app. The project uses **Swift Testing** for all unit tests and **XCTest** for UI tests (required by XCUIApplication).

## Test Structure

```text
Internet ArchiveTests/
├── Mocks/
│   ├── MockNetworkService.swift          # Mock network service
│   ├── MockFavoritesService.swift        # Mock favorites service
│   ├── MockKeychainManager.swift         # Mock keychain manager
│   ├── MockPlaybackProgressManager.swift # Mock playback progress
│   └── MockNetworkMonitor.swift          # Mock network monitor
├── Fixtures/
│   └── TestFixtures.swift                # Shared test data factories
├── Helpers/
│   ├── TestHelpers.swift                 # General test utilities
│   └── TestHelpers+SwiftTesting.swift    # Swift Testing-specific helpers
├── Accessibility/
│   └── AccessibilityTests.swift          # Accessibility audit tests
├── App/
│   ├── AppStateTests.swift               # App-wide state tests
│   ├── ContentViewTests.swift            # Root TabView tests
│   ├── ContinueWatchingCardTests.swift   # Continue watching component tests
│   ├── PlaceholderCardTests.swift        # Placeholder card tests
│   ├── SectionHeaderTests.swift          # Section header tests
│   ├── SkeletonLoadingViewTests.swift    # Skeleton loading animation tests
│   ├── StateViewsTests.swift             # Loading/error/empty state tests
│   ├── TVCardButtonStyleTests.swift      # tvOS card button style tests
│   └── AppInfoFooterTests.swift          # App info footer tests
├── Configuration/
│   └── AppConfigurationTests.swift       # Configuration loading tests
├── ErrorHandling/
│   ├── ErrorHandlingTests.swift          # Error and retry mechanism tests
│   ├── ErrorLoggerTests.swift            # Logging tests
│   ├── ErrorPresenterTests.swift         # User-friendly message tests
│   ├── NetworkErrorTests.swift           # NetworkError enum tests
│   └── RetryMechanismTests.swift         # Retry with backoff tests
├── Features/
│   ├── DescriptionViewTests.swift        # Description view tests
│   ├── FavoriteButtonTests.swift         # Favorite button tests
│   ├── FavoritesViewTests.swift          # Favorites view tests
│   ├── ItemDetailPlaceholderViewTests.swift # Placeholder view tests
│   ├── MediaHomeErrorViewTests.swift     # Error view tests
│   ├── MediaThumbnailViewTests.swift     # Thumbnail view tests
│   ├── MusicHomeViewTests.swift          # Music home tests
│   ├── NowPlayingViewTests.swift         # Now playing tests
│   ├── PeopleDetailViewTests.swift       # People detail tests
│   ├── PlaybackButtonsTests.swift        # Playback button tests
│   ├── SearchResultCardTests.swift       # Search result card tests
│   ├── SearchResultsGridViewTests.swift  # Search results grid tests
│   ├── SearchResultsHelpersTests.swift   # Search results helpers tests
│   ├── SearchViewTests.swift             # Search view tests
│   ├── SharedViewsTests.swift            # Shared view component tests
│   ├── VideoHomeViewTests.swift          # Video home tests
│   ├── VideoPlayerViewTests.swift        # Video player tests
│   ├── YearBrowseHelpersTests.swift      # Year browse helpers tests
│   ├── YearBrowseViewTests.swift         # Year browse view tests
│   └── Player/
│       └── VideoPlayerViewFromMetadataTests.swift
├── Models/
│   ├── AuthModelsTests.swift             # Authentication model tests
│   ├── FavoritesModelsTests.swift        # Favorites model tests
│   ├── MetadataModelsTests.swift         # Metadata model tests
│   ├── PlaybackProgressTests.swift       # Playback progress tests
│   ├── RequestModelsTests.swift          # Request model tests
│   └── SearchModelsTests.swift           # Search model tests
├── Protocols/
│   └── NetworkServiceProtocolTests.swift # Protocol conformance tests
├── Subtitles/
│   ├── SRTtoVTTConverterTests.swift      # SRT to VTT conversion tests
│   ├── SubtitleManagerTests.swift        # Subtitle manager tests
│   ├── SubtitleModelsTests.swift         # Subtitle model tests
│   └── SubtitleParserTests.swift         # Subtitle parser tests
├── UI/
│   ├── CompositionalLayoutBuilderTests.swift
│   ├── DescriptionTextViewTests.swift
│   ├── DiffableDataSourceTests.swift
│   ├── EmptyStateViewTests.swift
│   ├── ImageCacheManagerTests.swift
│   ├── ImagePrefetcherTests.swift
│   ├── MediaItemCardTests.swift
│   ├── ModernItemCellTests.swift
│   ├── SkeletonViewTests.swift
│   ├── SliderTests.swift
│   └── TrackListCellTests.swift
├── Utilities/
│   ├── APIManagerTests.swift
│   ├── AppProgressHUDTests.swift
│   ├── ContentFilter/
│   ├── GlobalTests.swift
│   ├── HTMLToAttributedStringTests.swift
│   ├── ItemDetailHelpersTests.swift
│   ├── KeychainManagerTests.swift
│   ├── MediaCardHelpersTests.swift
│   ├── MockAPIManagerTests.swift
│   ├── NetworkMonitorTests.swift
│   ├── PlaybackProgressManagerTests.swift
│   ├── SearchHelpersTests.swift
│   ├── UITestingHelperTests.swift
│   └── ValidationHelperTests.swift
├── ViewControllers/
│   ├── NowPlayingViewControllerTests.swift
│   ├── SubtitleSelectionViewControllerTests.swift
│   └── VideoPlayerViewControllerTests.swift
└── ViewModels/
    ├── CollectionViewModelTests.swift
    ├── FavoritesViewModelTests.swift
    ├── ItemDetailViewModelTests.swift
    ├── LoginViewModelTests.swift
    ├── MusicViewModelTests.swift
    ├── PeopleViewModelTests.swift
    ├── SearchViewModelTests.swift
    ├── VideoViewModelTests.swift
    └── YearsViewModelTests.swift

Internet ArchiveUITests/
├── Internet_ArchiveUITests.swift         # Original UI test suite
├── Internet_ArchiveUITestsLaunchTests.swift
├── UITestHelper.swift                    # UI test utilities
├── FocusNavigationTests.swift            # tvOS focus state tests
├── RemoteInteractionTests.swift          # Apple TV remote tests
├── AccessibilityTests.swift              # Accessibility verification
└── BackgroundAudioTests.swift            # Background audio lifecycle
```

## Framework Strategy

| Test Category | Framework | Rationale |
| ------------- | --------- | --------- |
| Unit Tests | Swift Testing | Modern API, parameterized tests, better diagnostics |
| UI Tests | XCTest | Required by XCUIApplication (Apple requirement) |

All unit tests use Swift Testing (`@Test`, `@Suite`, `#expect`). UI tests remain XCTest because `XCUIApplication` only works with XCTest.

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
        mockService.mockResponse = TestFixtures.makeSearchResponse()
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

| Mock | Purpose |
| ---- | ------- |
| `MockNetworkService` | Network layer test double |
| `MockFavoritesService` | Favorites persistence test double |
| `MockKeychainManager` | Keychain storage test double |
| `MockPlaybackProgressManager` | Playback progress test double |
| `MockNetworkMonitor` | Network connectivity test double |

All mocks are marked `@unchecked Sendable` for Swift 6 concurrency compatibility.

```swift
let mockService = MockNetworkService()
mockService.mockSearchResponse = TestFixtures.makeSearchResponse()
mockService.shouldThrowError = false

let result = try await mockService.search(query: "test", options: [:])
#expect(mockService.searchCalled)
```

### 3. Test Fixtures

`TestFixtures` provides factory methods for test data:

```swift
// Factory methods
let item = TestFixtures.makeArchiveItem(identifier: "test-1", title: "Test Movie")
let response = TestFixtures.makeSearchResponse(count: 5)
let progress = TestFixtures.makePlaybackProgress(identifier: "vid-1", progress: 0.5)
let favorite = TestFixtures.makeFavoriteItem(identifier: "fav-1")
```

### 4. Test Categories

#### Unit Tests (Swift Testing)

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

See `.github/workflows/tests.yml` for configuration.

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
2. Write tests using Swift Testing (`@Test`, `@Suite`, `#expect`)
3. Place mocks in `Internet ArchiveTests/Mocks/`
4. Use `TestFixtures` factory methods for test data
5. Ensure tests pass locally before pushing
6. Check code coverage for new code
