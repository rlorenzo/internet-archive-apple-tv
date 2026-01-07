# Claude Code Guidelines for Internet Archive Apple TV

## Project Overview

This is a tvOS app for Apple TV that provides access to the Internet Archive's media collections (movies, music, etc.).

## Git Rules

**CRITICAL - Always follow these rules:**

- **NEVER amend commits** - Always create new commits for additional changes
- **NEVER force push** unless explicitly requested by the user
- **NEVER rebase** without explicit user approval
- **NEVER use interactive git commands** (-i flag) as they require user input
- Stage files and show the user what will be committed before committing
- Always ask before pushing to remote
- Always ask before staging files

## Build Commands

```bash
# Build the project (SPM packages resolve automatically)
xcodebuild -project "Internet Archive.xcodeproj" \
  -scheme "Internet Archive" \
  -destination "platform=tvOS Simulator,name=Apple TV" \
  build

# Run tests
xcodebuild test \
  -project "Internet Archive.xcodeproj" \
  -scheme "Internet Archive" \
  -destination "platform=tvOS Simulator,name=Apple TV"

# Run SwiftLint (system-installed)
swiftlint lint
```

## Project Structure

```
Internet Archive/
├── AppDelegate.swift           # App entry point
├── Base.lproj/                 # Storyboards (Main.storyboard, LaunchScreen.storyboard)
├── Classes/                    # Reusable UI components (ItemCell, Slider)
├── Configuration/              # App configuration
├── Models/                     # Data models (Codable structs)
├── Protocols/                  # Protocol definitions
├── UI/                         # Modern UI components
│   ├── CollectionView/         # ModernItemCell, DiffableDataSource helpers
│   └── ImageLoading/           # ImageCacheManager
├── Utilities/                  # Helpers and services
│   ├── APIManager.swift        # Network API calls
│   ├── ErrorHandling/          # Error logging, retry mechanism, network monitor
│   └── Global.swift            # Global constants and helpers
├── ViewControllers/            # All view controllers by feature
│   ├── Item/                   # ItemVC (media playback)
│   ├── Search/                 # SearchResultVC
│   └── ...
└── Assets.xcassets/            # Asset catalog (images, app icons)

Internet ArchiveTests/          # Unit tests
Internet ArchiveUITests/        # UI tests
Config/                         # Build configurations
```

## Technology Stack

- **Platform:** tvOS 17.0+ (deployment target)
- **Language:** Swift 6.0 with strict concurrency
- **UI:** UIKit with Storyboards (Main.storyboard)
- **Networking:** Alamofire 5.11, AlamofireImage 4.3
- **Dependencies:** Swift Package Manager (SPM)
- **Testing:** XCTest

## Key Patterns

### Concurrency
- Use `@MainActor` for UI-related classes and methods
- Use `Task { @MainActor in }` for async UI updates
- Mark shared mutable state as `nonisolated(unsafe)` when needed for compatibility

### Networking
- All API calls go through `APIManager.swift`
- Use `RetryMechanism` for automatic retry with exponential backoff
- Use `NetworkMonitor` for connectivity status
- Content filtering is automatically applied to all API calls (adult content blocked)

### Error Handling
- Use `ErrorLogger` for consistent error logging
- Show user-friendly error messages via `ErrorPresenter`
- Suppress verbose logging during tests with `isRunningTests` checks

### Image Loading
- Use `ImageCacheManager` for cached image loading
- Use AlamofireImage's `af.setImage()` for collection view cells

## Code Style

- Follow SwiftLint rules defined in `.swiftlint.yml`
- Use `// MARK: -` for code organization
- Prefer `let` over `var` when possible
- Use trailing closure syntax
- Keep functions focused and small

## Important Files

- `MODERNIZATION_SPRINTS.md` - Detailed sprint plan and progress
- `TESTING.md` - Testing documentation
- `DEVELOPMENT_SETUP.md` - Setup instructions
- `.swiftlint.yml` - Linting rules
- `Internet Archive.xcodeproj` - Xcode project (includes SPM package references)

## Common Issues

### Launch Screen Caching
tvOS caches launch screens aggressively. To see changes:
1. Delete the app from the simulator
2. Clean build folder (Cmd+Shift+K)
3. Rebuild and run

### SPM Package Issues

If SPM packages fail to resolve:

1. Clean build folder (Cmd+Shift+K)
2. Close Xcode
3. Delete `~/Library/Developer/Xcode/DerivedData/Internet_Archive-*`
4. Reopen and let Xcode resolve packages

### Test Target Build Issues
Ensure `Config/Tests.xcconfig` is properly configured with framework search paths.
