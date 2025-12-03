# Testing Guide

## Overview

This document describes the testing infrastructure for the Internet Archive Apple TV app. The project uses XCTest for unit and UI tests, with a focus on maintainability, reliability, and code coverage.

## Test Structure

```
Internet ArchiveTests/
├── Mocks/
│   └── MockNetworkService.swift      # Mock network service for testing
├── Fixtures/
│   └── TestFixtures.swift            # Test data fixtures
├── Models/
│   ├── AuthModelsTests.swift         # Authentication model tests
│   ├── FavoritesModelsTests.swift    # Favorites model tests
│   ├── MetadataModelsTests.swift     # Metadata model tests
│   ├── RequestModelsTests.swift      # Request model tests
│   └── SearchModelsTests.swift       # Search model tests
├── ErrorHandling/
│   ├── ErrorHandlingTests.swift      # Error and retry mechanism tests
│   ├── ErrorLoggerTests.swift        # Logging tests
│   ├── ErrorPresenterTests.swift     # User-friendly message tests
│   ├── NetworkMonitorTests.swift     # Network monitoring tests
│   └── NetworkErrorTests.swift       # NetworkError enum tests
├── Utilities/
│   ├── GlobalTests.swift             # Global utility tests
│   └── KeychainManagerTests.swift    # Keychain storage tests
└── Configuration/
    └── AppConfigurationTests.swift   # Configuration loading tests

Internet ArchiveUITests/
└── (UI tests for critical user flows)
```

## Testing Approach

### 1. Protocol-Based Dependency Injection

The app uses `NetworkServiceProtocol` to enable dependency injection for testing:

```swift
protocol NetworkServiceProtocol {
    func search(query: String, options: [String: String]) async throws -> SearchResponse
    func getMetadata(identifier: String) async throws -> ItemMetadataResponse
    // ... other methods
}
```

**Benefits:**
- Easy to mock network layer for tests
- No need to make actual HTTP requests during testing
- Predictable test behavior

### 2. Mock Objects

`MockNetworkService` provides a test double for the networking layer:

```swift
let mockService = MockNetworkService()
mockService.mockSearchResponse = TestFixtures.searchResponse
mockService.shouldThrowError = false

// Use in tests
let result = try await mockService.search(query: "test", options: [:])
XCTAssertTrue(mockService.searchCalled)
```

### 3. Test Fixtures

`TestFixtures` provides pre-configured test data:

```swift
// Use fixtures in tests
let searchResult = TestFixtures.movieSearchResult
let response = TestFixtures.searchResponse
```

### 4. Test Categories

#### Unit Tests

**Data Models (`SearchModelsTests`)**
- Test Codable conformance
- Test custom decoding logic (e.g., year as String or Int)
- Test computed properties
- Test safe accessors

**Error Handling (`ErrorHandlingTests`)**
- Test error localized descriptions
- Test RetryMechanism with different configurations
- Test retry logic for retryable vs non-retryable errors
- Test ErrorContext creation

**Network Monitoring (`NetworkMonitorTests`)**
- Test NetworkMonitor singleton
- Test connection checking
- Test connection type detection

#### UI Tests

Tests for critical user flows:
- Login/registration flow
- Search functionality
- Media playback
- Favorites management

## Running Tests

### Command Line

```bash
# Run all tests
xcodebuild test \
  -workspace "Internet Archive.xcworkspace" \
  -scheme "Internet Archive" \
  -destination "platform=tvOS Simulator,name=Apple TV"

# Run specific test
xcodebuild test \
  -workspace "Internet Archive.xcworkspace" \
  -scheme "Internet Archive" \
  -only-testing:Internet_ArchiveTests/SearchModelsTests/testSearchResultDecoding
```

### Xcode

1. Open `Internet Archive.xcworkspace`
2. Select the test target
3. Press `⌘U` to run all tests
4. Use Test Navigator (⌘6) to run individual tests

## Code Coverage

### Enabling Coverage

1. Edit scheme → Test → Options
2. Check "Gather coverage for: Internet Archive"
3. Run tests with coverage enabled

### Viewing Coverage

1. Show Report Navigator (⌘9)
2. Select the latest test run
3. Click Coverage tab

### Coverage Goals

- **Overall**: 70%+ code coverage
- **Critical paths**: 90%+ (authentication, search, playback)
- **Error handling**: 100% (all error paths tested)

## Best Practices

### 1. Test Naming

Use descriptive test names that explain what is being tested:

```swift
✅ Good:
func testSearchResultDecodesYearAsInteger()
func testRetryMechanismMaxAttemptsReached()

❌ Bad:
func testSearchResult()
func testRetry()
```

### 2. Arrange-Act-Assert Pattern

```swift
func testSearchResultSafeMediaType() {
    // Arrange
    let result = SearchResult(identifier: "test", title: "Test", mediatype: "movies")

    // Act
    let mediaType = result.safeMediaType

    // Assert
    XCTAssertEqual(mediaType, "movies")
}
```

### 3. Test Independence

Each test should:
- Be independent of other tests
- Not rely on test execution order
- Clean up after itself
- Use fresh mocks/fixtures

```swift
override func setUp() {
    super.setUp()
    mockService.reset()
}
```

### 4. Async Testing

Use async/await for testing async code:

```swift
func testAsyncOperation() async throws {
    let result = try await someAsyncFunction()
    XCTAssertEqual(result, expectedValue)
}
```

### 5. Error Testing

Test both success and error paths:

```swift
func testSearchSuccess() async throws {
    mockService.mockSearchResponse = TestFixtures.searchResponse
    let result = try await mockService.search(query: "test", options: [:])
    XCTAssertEqual(result.response.docs.count, 2)
}

func testSearchFailure() async {
    mockService.shouldThrowError = true
    mockService.errorToThrow = NetworkError.timeout

    do {
        _ = try await mockService.search(query: "test", options: [:])
        XCTFail("Should have thrown error")
    } catch {
        XCTAssertTrue(error is NetworkError)
    }
}
```

## Continuous Integration

Tests run automatically on every push and pull request via GitHub Actions.

### CI Workflow

- Runs on macOS 15 runner with Xcode 16.4
- Executes all unit tests
- Reports code coverage
- Fails build if tests fail

See `.github/workflows/tests.yml` for configuration.

## Troubleshooting

### Tests Fail Locally But Pass in CI

- Clean build folder: `⇧⌘K`
- Delete derived data: `~/Library/Developer/Xcode/DerivedData`
- Ensure all schemes are shared

### Slow Tests

- Check for accidental network calls (use mocks instead)
- Reduce sleep/delay durations in tests
- Use `XCTestExpectation` with reasonable timeouts

### Flaky Tests

- Check for race conditions in async code
- Ensure proper actor isolation (@MainActor)
- Use `Task.yield()` if needed for async coordination

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Swift Concurrency Testing](https://developer.apple.com/documentation/swift/concurrency)

## Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Ensure tests pass locally
3. Check code coverage
4. Update this document if adding new test patterns
