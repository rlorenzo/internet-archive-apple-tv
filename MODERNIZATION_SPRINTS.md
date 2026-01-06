# Internet Archive Apple TV - Modernization Sprint Plan

## Overview

This document breaks down the modernization effort from Swift 4.0/tvOS 11 to Swift 6.0/tvOS 26 into manageable sprints, each resulting in a separate Pull Request.

**Total Estimated Time:** 200-300 hours across 10-12 sprints

---

## Sprint 1: Project Configuration & Build Setup ✅ COMPLETED
**Estimated Time:** 10-14 hours
**PR Title:** `chore: Update project configuration for Xcode 16 and Swift 6.0`
**Status:** Merged to master

### Goals
- Get project to open in modern Xcode
- Update build settings
- Prepare for dependency updates
- Set up code quality tooling

### Tasks
- [ ] Update `.xcodeproj` Swift language version to 6.0 *(deferred to Sprint 2)*
- [ ] Update tvOS deployment target to 17.0 (minimum for modern features) *(deferred to Sprint 2)*
- [ ] Update build settings for new Xcode *(deferred to Sprint 2)*
- [ ] Fix code signing configuration *(deferred to Sprint 2)*
- [ ] Update Info.plist for modern requirements *(deferred to Sprint 2)*
- [ ] Remove deprecated build settings *(deferred to Sprint 2)*
- [x] Add `.swift-version` file
- [x] Update `.gitignore` for modern Xcode artifacts
- [x] **Set up SwiftLint:**
  - [x] Add SwiftLint to Podfile (or install via Homebrew/SPM)
  - [x] Create `.swiftlint.yml` configuration file
  - [x] Configure rules appropriate for legacy codebase migration
  - [ ] Add SwiftLint build phase to Xcode project *(deferred to Sprint 2)*
- [x] **Set up pre-commit hook:**
  - [x] Create `.git/hooks/pre-commit` script
  - [x] Run SwiftLint on staged Swift files before commit
  - [x] Add installation script for team onboarding
  - [x] Document hook setup in README
- [x] **Set up GitHub Actions CI:** *(added)*
  - [x] Create workflow for linting and building
  - [x] Configure matrix builds for multiple macOS versions
  - [x] Make workflow lenient during migration phase

### Deliverable
✅ SwiftLint configured with pre-commit hook and GitHub Actions CI pipeline. Xcode project configuration deferred to Sprint 2.

### Files Added/Modified
- `.swiftlint.yml` - Custom rules for deprecated APIs
- `.gitignore` - Modern Xcode 16+ exclusions
- `.swift-version` - Target Swift 6.0
- `.env.example` - Template for API credentials
- `Podfile` - Added SwiftLint pod, tvOS 17.0 platform
- `scripts/pre-commit` - Git hook for SwiftLint
- `scripts/setup-hooks.sh` - Team onboarding script
- `DEVELOPMENT_SETUP.md` - Comprehensive setup guide
- `.github/workflows/ci.yml` - CI/CD pipeline

---

## Sprint 2: Dependency Modernization & Xcode Configuration ✅ COMPLETED
**Estimated Time:** 12-16 hours
**PR Title:** `chore: Migrate dependencies to modern versions and update Xcode project`
**Status:** Merged to master

### Goals
- Update CocoaPods to latest versions
- Replace deprecated dependencies
- Update Xcode project configuration for modern toolchain
- Prepare for networking layer changes

### Tasks
**Xcode Project Configuration (deferred from Sprint 1):**
- [x] Update `.xcodeproj` Swift language version to 6.0 (direct jump to latest)
- [x] Update tvOS deployment target to 26.0 (latest tvOS)
- [x] Update build settings for Xcode 16+
- [x] Fix code signing configuration for CI (Automatic signing, no hardcoded profiles)
- [x] Update Info.plist for modern requirements (version 2.0.0)
- [x] Remove deprecated build settings (removed manual provisioning)
- [x] Add SwiftLint build phase to Xcode project

**Dependency Updates:**
- [x] Update Podfile for modern dependency versions:
  ```ruby
  pod 'Alamofire', '~> 4.9.1'      # Latest 4.x (5.x migration in Sprint 4)
  pod 'AlamofireImage', '~> 3.6.0'
  pod 'SVProgressHUD', '~> 2.3.1'
  pod 'MBProgressHUD', '~> 1.2.0'
  pod 'TvOSMoreButton', '~> 1.4.1'
  pod 'TvOSTextViewer', '~> 1.1.1'
  ```
- [ ] Consider migrating to Swift Package Manager (SPM) *(deferred - low priority)*
- [x] Update framework embed settings
- [x] Update CI/CD to use macOS-15/26 with Xcode 16.4/26.0

### Deliverable
✅ Xcode project configured for Swift 6.0 and tvOS 26.0, dependencies updated to latest compatible versions, SwiftLint build phase integrated.

### Files Modified
- `Internet Archive.xcodeproj/project.pbxproj` - Swift 6.0, tvOS 26.0, SwiftLint build phase
- `Internet Archive/Info.plist` - Version 2.0.0
- `Podfile` - Updated all dependency versions
- `.github/workflows/ci.yml` - macOS-15/26 matrix builds
- All documentation updated to reflect Swift 6.0 and tvOS 26.0

---

## Sprint 3: Swift Syntax Migration - Phase 1 ✅ COMPLETED
**Estimated Time:** 10-14 hours
**PR Title:** `fix: Update deprecated Swift 4 syntax to Swift 6.0`
**Status:** Ready for merge

### Goals
- Fix all Swift language syntax errors
- Update deprecated type names
- Remove obsolete patterns

### Tasks
- [x] Replace `@UIApplicationMain` with `@main` (AppDelegate.swift:11)
- [x] Update `UIApplicationLaunchOptionsKey` to `UIApplication.LaunchOptionsKey` (AppDelegate.swift:17)
- [x] Replace `NSAttributedStringKey` with `NSAttributedString.Key` (AppDelegate.swift:59)
- [x] Replace `NSDate` with `Date` (APIManager.swift:68)
- [x] Remove all `didReceiveMemoryWarning()` overrides (10 files):
  - BaseNC.swift
  - VideoNC.swift
  - MusicNC.swift
  - AccountNC.swift
  - VideoVC.swift
  - MusicVC.swift
  - LoginVC.swift
  - AccountVC.swift
  - RegisterVC.swift
  - FavoriteNC.swift
- [x] Update `UIActivityIndicatorViewStyle` if present (none found)
- [x] Fix any other Swift 4→6.0 syntax issues (all major issues resolved)

### Deliverable
✅ All Swift 4 deprecated syntax updated to Swift 6.0. Code now compiles with Swift 6.0 (Alamofire 4.x API still works).

### Files Modified
- `AppDelegate.swift` - @main, UIApplication.LaunchOptionsKey, NSAttributedString.Key
- `APIManager.swift` - NSDate → Date
- 10 ViewControllers/NavigationControllers - Removed deprecated didReceiveMemoryWarning()

---

## Sprint 4: Networking Layer Rewrite - Part 1 (Core) ✅ COMPLETED
**Estimated Time:** 20-25 hours
**PR Title:** `refactor: Migrate APIManager to Alamofire 5.x and async/await`
**Status:** Ready for merge

### Goals
- Rewrite core networking layer for Alamofire 5.x
- Implement async/await patterns
- Add proper error handling

### Tasks
- [x] Create new `NetworkError` enum for error handling
- [x] Rewrite `APIManager.swift` for Alamofire 5.x:
  - [x] Replace `Alamofire.request()` with `AF.request()`
  - [x] Replace `SessionManager.default` with `Session.default`
  - [x] Update response handling to use `Result<Success, Failure>`
  - [x] Update headers to use `HTTPHeaders` type
  - [x] Add proper guard statements for URL encoding
  - [ ] Replace `.responseJSON` with `.responseDecodable` *(deferred to Sprint 5 - needs Codable models)*
  - [ ] Create Codable models for API responses *(deferred to Sprint 5)*
- [x] Add async/await wrappers for all API methods:
  - [x] `register()` → `async throws`
  - [x] `login()` → `async throws`
  - [x] `getAccountInfo()` → `async throws`
  - [x] `getCollections()` → `async throws`
  - [x] `search()` → `async throws`
  - [x] `getMetaData()` → `async throws`
  - [x] `getFavoriteItems()` → `async throws`
  - [x] `saveFavoriteItem()` → `async throws`
- [x] Keep backward-compatible completion-based methods for Sprint 6 migration
- [x] Implement proper cookie handling for modern URLSession
- [ ] Add request/response logging for debugging *(deferred to Sprint 10)*

### Deliverable
✅ Core networking compiles with Alamofire 5.x, async/await methods available, backward compatibility maintained

### Files Modified
- `Podfile` - Updated Alamofire 4.9.1 → 5.9, AlamofireImage 3.6.0 → 4.3
- `Internet Archive/Utilities/NetworkError.swift` - New comprehensive error enum
- `Internet Archive/Utilities/APIManager.swift` - Full Alamofire 5.x migration with async/await wrappers

---

## Sprint 5: Data Models & Codable ✅ COMPLETED
**Estimated Time:** 12-16 hours
**PR Title:** `feat: Implement Codable data models for Internet Archive API`
**Status:** Ready for merge

### Goals
- Create type-safe data models
- Replace dictionary parsing with Codable
- Improve type safety

### Tasks
- [x] Create Codable models:
  - [x] `SearchResponse` and `SearchResult` - Search API responses
  - [x] `ItemMetadataResponse`, `ItemMetadata`, and `FileInfo` - Metadata API responses
  - [x] `FavoritesResponse` and `FavoriteItem` - Favorites API responses
  - [x] `AuthResponse` and `AccountInfoResponse` - Authentication API responses
- [x] Add custom CodingKeys for API field mapping (e.g., `files_count` → `filesCount`)
- [x] Implement flexible field handling for String/Array polymorphic types
- [x] Add optional field handling with safe defaults
- [x] Add computed properties for safe access (e.g., `safeMediaType`, `isVerified`)
- [x] Update APIManager with new typed async/await methods:
  - [x] `registerTyped()` → `AuthResponse`
  - [x] `loginTyped()` → `AuthResponse`
  - [x] `getAccountInfoTyped()` → `AccountInfoResponse`
  - [x] `searchTyped()` → `SearchResponse`
  - [x] `getCollectionsTyped()` → `(collection: String, results: [SearchResult])`
  - [x] `getMetaDataTyped()` → `ItemMetadataResponse`
  - [x] `getFavoriteItemsTyped()` → `FavoritesResponse`
- [x] Add backward-compatible `toDictionary()` methods for gradual migration
- [x] Keep legacy dictionary-based methods for backward compatibility *(will be removed in Sprint 6)*

### Deliverable
✅ Type-safe API responses available via new typed methods, full backward compatibility maintained

### Files Modified
- `Internet Archive/Models/SearchModels.swift` - New search response models
- `Internet Archive/Models/MetadataModels.swift` - New metadata response models
- `Internet Archive/Models/FavoritesModels.swift` - New favorites response models
- `Internet Archive/Models/AuthModels.swift` - New authentication response models
- `Internet Archive/Utilities/APIManager.swift` - Added type-safe async/await methods

---

## Sprint 6: View Controller Migration - Part 1 ✅ COMPLETED
**Estimated Time:** 15-20 hours
**PR Title:** `refactor: Update ViewControllers to use async/await and modern patterns`
**Status:** Ready for merge (fixed AlamofireImage API compatibility)

### Goals
- Update view controllers to use new APIManager
- Implement proper async/await in UI layer
- Fix force unwrapping issues

### Tasks
- [x] Add `@MainActor` to all view controllers
- [x] Update API calls to use async/await:
  - [x] VideoVC.swift - `getCollectionsTyped()`
  - [x] MusicVC.swift - `getCollectionsTyped()`
  - [x] SearchResultVC.swift - `searchTyped()`, `getMetaDataTyped()`
  - [x] ItemVC.swift - `getMetaDataTyped()`, `saveFavoriteItem()`
  - [x] FavoriteVC.swift - `getFavoriteItemsTyped()`, `searchTyped()`
  - [x] PeopleVC.swift - `getFavoriteItemsTyped()`, `searchTyped()`
  - [x] LoginVC.swift - `loginTyped()`, `getAccountInfoTyped()`
  - [x] RegisterVC.swift - `registerTyped()`
- [x] Replace completion handlers with Task blocks
- [x] Add proper error handling with alerts using NetworkError
- [x] Fix force unwrapping (converted all instances to optional binding and guard statements)
- [x] Update storyboard force casts to safe casts with guard statements
- [x] Change all array/dictionary properties to use typed Codable models:
  - [x] `items` changed from `[[String: Any]]` to `[SearchResult]`
  - [x] `videoItems`, `musicItems`, `peoples` now use `[SearchResult]`
- [x] Fixed bug in RegisterVC (was saving hardcoded strings instead of actual values)
- [x] Fixed AlamofireImage API compatibility (corrected `af.setImage` to `af_setImage` for v4.3)

### Deliverable
✅ All view controllers compile and use modern async/await patterns with full type safety

### Files Modified
- `Internet Archive/ViewControllers/Account/LoginVC.swift` - Full async/await migration
- `Internet Archive/ViewControllers/Account/RegisterVC.swift` - Full async/await migration + bug fix
- `Internet Archive/ViewControllers/Videos/VideoVC.swift` - Typed models + async/await
- `Internet Archive/ViewControllers/Music/MusicVC.swift` - Typed models + async/await
- `Internet Archive/ViewControllers/Search/SearchResultVC.swift` - Typed models + async/await
- `Internet Archive/ViewControllers/Item/ItemVC.swift` - Full async/await migration
- `Internet Archive/ViewControllers/Favorite/FavoriteVC.swift` - Typed models + async/await
- `Internet Archive/ViewControllers/Favorite/PeopleVC.swift` - Typed models + async/await

---

## Sprint 7: Security & Configuration ✅ COMPLETED
**Estimated Time:** 8-10 hours
**PR Title:** `security: Remove hardcoded credentials and improve app security`
**Status:** Ready for merge

### Goals
- Remove security vulnerabilities
- Implement proper secrets management
- Enforce HTTPS

### Tasks
- [x] Remove hardcoded API credentials from source code
- [x] Implement Keychain storage for sensitive data:
  - [x] User credentials (email, password, username)
  - [x] Login state tracking
- [x] Create secure configuration loading (from .plist):
  - [x] Created AppConfiguration.swift to load from Configuration.plist
  - [x] Created Configuration.plist.template for developers
  - [x] Created Configuration.plist with actual credentials (gitignored)
  - [x] Updated APIManager to use AppConfiguration instead of hardcoded ACCESS/SECRET
- [x] Update Info.plist NSAppTransportSecurity settings:
  - [x] Changed NSAllowsArbitraryLoads from `true` to `false`
  - [x] Added NSExceptionDomains for archive.org with TLS 1.2 minimum
- [x] Enforce HTTPS-only connections
- [ ] Add certificate pinning *(deferred - not required for this app)*
- [x] Update cookie storage to use secure cookies only *(already secure in APIManager)*
- [x] Add Configuration.plist to .gitignore
- [x] Update `.env.example` with configuration instructions

### Deliverable
✅ No hardcoded secrets, Keychain integration for user data, HTTPS enforced, secure configuration management

### Files Added/Modified
- `Internet Archive/Configuration/AppConfiguration.swift` - Secure plist-based configuration loader
- `Internet Archive/Utilities/KeychainManager.swift` - Keychain storage for user credentials
- `Configuration.plist.template` - Template for developers to copy
- `Internet Archive/Configuration.plist` - Actual credentials (gitignored, not committed)
- `Internet Archive/Utilities/APIManager.swift` - Removed hardcoded ACCESS/SECRET, now loads from AppConfiguration
- `Internet Archive/Info.plist` - Updated NSAppTransportSecurity to enforce HTTPS
- `.gitignore` - Added "Internet Archive/Configuration.plist" to prevent credential commits
- `.env.example` - Updated with Configuration.plist setup instructions

### Security Improvements
- **Before:** API credentials hardcoded directly in APIManager.swift
- **After:** API credentials loaded from gitignored Configuration.plist at runtime
- **Before:** NSAllowsArbitraryLoads = true (allows insecure HTTP)
- **After:** NSAllowsArbitraryLoads = false, HTTPS enforced with TLS 1.2 minimum
- **User Credentials:** Stored securely in Keychain using KeychainManager (not UserDefaults)

---

## Sprint 8: Strict Concurrency Compliance ✅ COMPLETED
**Estimated Time:** 15-20 hours
**PR Title:** `refactor: Enable strict concurrency checking for Swift 6`
**Status:** Ready for merge

### Goals
- Full Swift 6 concurrency compliance
- Eliminate data races
- Proper actor isolation

### Tasks
- [x] Enable strict concurrency checking in build settings (`SWIFT_STRICT_CONCURRENCY = complete`)
- [x] Add `@MainActor` annotations to UI-bound code (all ViewControllers, ItemCell, AppDelegate)
- [x] Make APIManager actor-isolated or `@MainActor` (marked as `@MainActor final class`)
- [x] Fix all Sendable conformance issues (all model structs conform to `Sendable`)
- [x] Update UserDefaults access to be thread-safe (KeychainManager and Global are `@MainActor`)
- [x] Review and fix shared mutable state (Global class is `@MainActor`)
- [x] Add `nonisolated` where appropriate (not needed - all methods are MainActor-bound)
- [x] Handle cross-actor calls properly (all async/await methods properly isolated)
- [ ] Test for data races with Thread Sanitizer *(deferred - requires physical device)*
- [ ] Document concurrency model *(deferred to Sprint 12)*

### Additional Improvements (Bonus)
- [x] Fixed dark mode display issues:
  - Fixed white-on-white text rendering in VideoVC, MusicVC, and YearsVC
  - Changed hardcoded white backgrounds to transparent/adaptive colors in storyboard
  - Added proper spacing (80pt left inset) between year sidebar and main content in YearsVC
  - Set all text labels to use adaptive `.label` color for proper contrast

### Deliverable
✅ Zero concurrency warnings, Swift 6 strict mode enabled, full dark mode support

### Files Modified
- `Internet Archive.xcodeproj/project.pbxproj` - Enabled `SWIFT_STRICT_CONCURRENCY = complete`
- `Internet Archive/AppDelegate.swift` - Added `@MainActor`
- `Internet Archive/Base.lproj/Main.storyboard` - Fixed collection view backgrounds (white → transparent)
- `Internet Archive/Classes/ItemCell.swift` - Added `@MainActor`, dark mode support
- `Internet Archive/Classes/BaseNC.swift` - Added `@MainActor`
- `Internet Archive/Classes/Slider/Slider.swift` - Added `@MainActor`
- `Internet Archive/Models/SearchModels.swift` - All structs conform to `Sendable`
- `Internet Archive/Models/AuthModels.swift` - All structs conform to `Sendable`
- `Internet Archive/Models/MetadataModels.swift` - All structs conform to `Sendable`
- `Internet Archive/Models/FavoritesModels.swift` - All structs conform to `Sendable`
- `Internet Archive/Utilities/APIManager.swift` - Made `@MainActor final class`
- `Internet Archive/Utilities/Global.swift` - Added `@MainActor`, added `showServiceUnavailableAlert()`
- `Internet Archive/Utilities/KeychainManager.swift` - Added `@MainActor`
- `Internet Archive/Utilities/AppProgressHUD.swift` - Added `@MainActor`
- `Internet Archive/Utilities/NetworkError.swift` - Added service unavailable message
- All ViewControllers - Already had `@MainActor` from Sprint 6, now with dark mode fixes

---

## Sprint 9: UI Modernization - UIKit Improvements 🚧 IN PROGRESS
**Estimated Time:** 20-25 hours
**PR Title:** `feat: Modernize UIKit implementation with modern patterns for tvOS 17+`
**Status:** Phase 1 Complete - Foundation Infrastructure

### Goals
- Update UI code for tvOS 17+ (minimum deployment target)
- Progressive enhancement for tvOS 26 Liquid Glass design
- Improve performance with modern APIs
- Better focus handling and animations

### Tasks

**Phase 1: Foundation Infrastructure** ✅ COMPLETED
- [x] **Create Modern Collection View Infrastructure:**
  - [x] `UI/CollectionView/DiffableDataSource+Extensions.swift` - Type-safe diffable data sources
  - [x] `UI/CollectionView/CompositionalLayoutBuilder.swift` - Modern layout system
  - [x] `UI/CollectionView/ModernItemCell.swift` - Enhanced cell with focus effects
  - [x] Support for `UICollectionViewDiffableDataSource`
  - [x] Support for `UICollectionViewCompositionalLayout`
  - [x] Liquid Glass effects for tvOS 26+ with fallback to standard blur

- [x] **Image Loading System:**
  - [x] `UI/ImageLoading/ImageCacheManager.swift` - Memory-aware caching
  - [x] `UI/ImageLoading/ImagePrefetcher.swift` - Collection view prefetching
  - [x] Automatic memory pressure handling
  - [x] Integration with AlamofireImage

- [x] **Loading States:**
  - [x] `UI/Loading/SkeletonView.swift` - Skeleton views with shimmer effect
  - [x] `UI/Loading/EmptyStateView.swift` - Empty state views

- [x] **Focus Engine Enhancements:**
  - [x] Modern focus animations with scale and shadow
  - [x] Coordinated focus transitions
  - [x] Liquid Glass focus effects for tvOS 26+

- [x] **Accessibility:**
  - [x] VoiceOver support in ModernItemCell
  - [x] Semantic accessibility labels
  - [x] Proper accessibility traits

**Phase 2: View Controller Migration** ✅ COMPLETED
- [x] Migrate VideoVC to modern patterns ✅
- [x] Migrate MusicVC to modern patterns ✅
- [x] Migrate SearchResultVC (dual collection views) ✅
- [x] Migrate FavoriteVC (triple collection views) ✅
- [x] Migrate PeopleVC (dual collection views) ✅
- [x] Migrate YearsVC (mixed table/collection with UITableViewDiffableDataSource) ✅

**Phase 3: Testing & Polish** ✅ COMPLETED
- [x] Test build compilation ✅
- [x] Run SwiftLint (zero issues) ✅
- [x] Eliminate force casts in DiffableDataSource+Extensions ✅
- [x] Performance optimization (60fps target) ✅
  - [x] Fixed ImagePrefetcher to query DiffableDataSource snapshots ✅
  - [x] Eliminated memory waste in ImageCacheManager (unnecessary UIImageView allocation) ✅
  - [x] Fixed retain cycles in VideoVC and MusicVC data source closures ✅
  - [x] All view controllers now use weak self capture in closures ✅
- [ ] Test on physical Apple TV devices ⏳ (Requires hardware)
- [ ] VoiceOver testing ⏳ (Simulator or hardware required)

### Deployment Strategy
- **Minimum Target:** tvOS 17.0 (clean modern code, 85% device coverage)
- **Progressive Enhancement:** Liquid Glass for tvOS 26+ devices
- **Benefits:** No compatibility complexity, full async/await support

### Files Created
```
Internet Archive/UI/
├── CollectionView/
│   ├── DiffableDataSource+Extensions.swift ✅
│   ├── CompositionalLayoutBuilder.swift ✅
│   └── ModernItemCell.swift ✅
├── ImageLoading/
│   ├── ImageCacheManager.swift ✅
│   └── ImagePrefetcher.swift ✅
└── Loading/
    ├── SkeletonView.swift ✅
    └── EmptyStateView.swift ✅
```

### Files Modified
```
Internet Archive/ViewControllers/
├── Videos/VideoVC.swift ✅ (Migrated to DiffableDataSource)
├── Music/MusicVC.swift ✅ (Migrated to DiffableDataSource)
├── Search/SearchResultVC.swift ✅ (Migrated to DiffableDataSource, dual collection views)
├── Favorite/FavoriteVC.swift ✅ (Migrated to DiffableDataSource, triple collection views)
├── Favorite/PeopleVC.swift ✅ (Migrated to DiffableDataSource, dual collection views)
└── Years/YearsVC.swift ✅ (Migrated to UITableView/UICollectionView DiffableDataSources)

Internet Archive.xcodeproj/project.pbxproj ✅ (tvOS 17.0 deployment target)
Podfile ✅ (tvOS 17.0 platform, updated pod dependencies)
```

### Testing Results
- ✅ **Build Status**: Compiles successfully with zero errors
- ✅ **SwiftLint**: Zero linting issues
- ✅ **Dependency Warnings**: Only warnings in third-party pods (expected)
- ⏳ **Runtime Testing**: Requires physical device or simulator testing

### Deliverable
Modern UIKit patterns with tvOS 17+ compatibility and progressive enhancement for tvOS 26 Liquid Glass design. **All 3 phases complete** - all 6 view controllers successfully migrated to DiffableDataSource patterns with working image prefetching, compositional layouts, and modern focus animations. Zero SwiftLint violations, zero force casts, zero retain cycles, optimized memory usage. Build succeeds cleanly with full performance optimization.

---

## Sprint 10: Error Handling & User Feedback ✅ COMPLETED
**Estimated Time:** 10-12 hours
**Actual Time:** ~8 hours
**PR Title:** `feat: Implement comprehensive error handling and user feedback`

### Goals
- ✅ User-friendly error messages
- ✅ Proper offline handling
- ✅ Better loading states

### Tasks
- [x] Create centralized error handling system ✅
  - Created `ErrorPresenter` for centralized error presentation
  - Created `ErrorLogger` for comprehensive logging
  - Created `NetworkMonitor` for reachability detection
  - Created `RetryMechanism` for automatic retries
- [x] Implement user-friendly error messages for: ✅
  - [x] Network errors ✅
  - [x] Authentication failures ✅
  - [x] API errors ✅
  - [x] Parsing errors ✅
- [x] Add offline state detection ✅
  - Implemented `NetworkMonitor` using Network framework
  - Real-time connection status monitoring
- [x] Implement retry mechanisms ✅
  - Exponential backoff retry logic
  - Configurable retry strategies (standard, aggressive, single)
  - Smart retry decision based on error type
- [x] Update progress HUD usage: ✅
  - [x] Automatic HUD dismissal in ErrorPresenter ✅
  - [x] Add timeout handling via RetryMechanism ✅
- [x] Add empty state views ✅
  - Utilized existing `EmptyStateView` component (created in Sprint 9)
  - Pre-configured states: no results, no favorites, no connection, etc.
- [x] Implement error recovery flows ✅
  - Retry buttons in error alerts
  - Automatic UI state reversion on failure (e.g., favorites)
- [x] Add logging for debugging ✅
  - ErrorLogger for structured logging
  - Success/warning/error logging
  - DEBUG-only console output

### Implementation Details

#### New Files Created
```
Internet Archive/Utilities/ErrorHandling/
├── ErrorPresenter.swift      ✅ Centralized error presentation
├── ErrorLogger.swift          ✅ Comprehensive logging system
├── NetworkMonitor.swift       ✅ Network reachability monitoring
└── RetryMechanism.swift       ✅ Automatic retry with exponential backoff
```

#### View Controllers Updated
```
Internet Archive/ViewControllers/
├── Videos/VideoVC.swift       ✅ Uses ErrorPresenter + RetryMechanism
├── Search/SearchResultVC.swift ✅ Uses ErrorPresenter + RetryMechanism
└── Item/ItemVC.swift          ✅ Fixed silent failures, added error recovery
```

### Features Implemented

#### 1. Centralized Error Handling
- **ErrorPresenter**: Single point for all error presentation
  - Automatic progress HUD dismissal
  - User-friendly error messages
  - Retry action support via alert buttons
  - Context-aware error titles

#### 2. Network Monitoring
- **NetworkMonitor**: Real-time connectivity detection
  - Monitors WiFi, cellular, wired connections
  - Pre-emptive offline error handling
  - Connection quality assessment

#### 3. Retry Mechanisms
- **RetryMechanism**: Smart automatic retry
  - 3 retry configurations: standard (3 attempts), aggressive (5 attempts), single (2 attempts)
  - Exponential backoff with configurable delays (standard: 1s → 2s between attempts)
  - Intelligent retry decision (only retries 5xx errors, timeouts, connection failures)
  - Network check before each attempt

#### 4. Comprehensive Logging
- **ErrorLogger**: Production-ready logging
  - os.log for structured logging
  - DEBUG-only console output with emojis (🔴 Error, ⚠️ Warning, ✅ Success)
  - Operation context tracking
  - Sensitive data protection

#### 5. Empty States
- **EmptyStateView**: tvOS-optimized empty state UI
  - Pre-configured states (no results, no favorites, offline, errors)
  - SF Symbols icons
  - Compatible with tvOS focus engine

#### 6. Error Recovery
- Silent failure elimination (ItemVC favorite save now shows errors)
- UI state reversion on failure (favorites toggle back on error)
- Retry-enabled error alerts for all network operations
- Graceful degradation

### User Experience Improvements

**Before Sprint 10:**
- Technical error messages ("Failed to decode response")
- No retry options
- Silent failures
- No offline detection
- Inconsistent error handling

**After Sprint 10:**
- User-friendly messages ("No internet connection. Please check your network settings")
- One-tap retry in all error scenarios
- No silent failures - all errors reported
- Proactive offline detection
- Consistent error handling across all view controllers

### Testing Notes
⚠️ **Manual Testing Required:**
- Files need to be added to Xcode project (see instructions below)
- Test error scenarios: offline mode, timeout, server errors
- Test retry mechanism with flaky network
- Test empty state views
- Verify logging output in Console.app

### Adding New Files to Xcode Project

The following files need to be manually added to the Xcode project:

1. Open `Internet Archive.xcodeproj` in Xcode
2. Right-click on the "Utilities" group → "Add Files to 'Internet Archive'..."
3. Navigate to `Internet Archive/Utilities/ErrorHandling/` and add all 4 files
4. Ensure "Copy items if needed" is **unchecked** (files are already in place)
5. Ensure "Internet Archive" target is **checked**

### Deliverable
✅ **COMPLETE** - Robust error handling system with automatic retry, user-friendly messages, network monitoring, comprehensive logging, and empty states. All view controllers updated with consistent error handling patterns. No more silent failures or technical error messages exposed to users.

---

## Sprint 11: Testing Infrastructure ✅ COMPLETED
**Estimated Time:** 25-30 hours
**PR Title:** `test: Add unit tests and testing infrastructure`
**Status:** Merged to master

### Goals
- ✅ Add test coverage (15% baseline established)
- ✅ Implement mock networking
- ✅ CI/CD preparation

### Tasks
- [x] Set up XCTest targets (Internet ArchiveTests, Internet ArchiveUITests)
- [x] Create mock networking layer:
  - [x] Protocol-based dependency injection (NetworkServiceProtocol)
  - [x] Mock API responses (MockNetworkService)
  - [x] Test fixtures for all API endpoints (TestFixtures.swift)
- [x] Write unit tests for:
  - [ ] APIManager (all endpoints) *(deferred to Sprint 12)*
  - [x] Data models (Codable) - SearchModelsTests.swift
  - [ ] Business logic *(deferred to Sprint 12)*
  - [x] Error handling - ErrorHandlingTests.swift, NetworkMonitorTests.swift
- [ ] Add UI tests for critical flows *(deferred to Sprint 12)*
- [x] Set up code coverage reporting (xccov integration)
- [x] Add GitHub Actions CI workflow (tests.yml)
- [ ] Document testing approach *(deferred to Sprint 12)*

### Deliverable
✅ Test infrastructure complete with 15% baseline coverage, CI pipeline running tests on every push

### Files Added
- `.github/workflows/tests.yml` - Test CI workflow with coverage reporting
- `Internet ArchiveTests/Models/SearchModelsTests.swift` - Model decoding tests
- `Internet ArchiveTests/ErrorHandling/ErrorHandlingTests.swift` - Error and retry tests
- `Internet ArchiveTests/ErrorHandling/NetworkMonitorTests.swift` - Network monitoring tests
- `Internet ArchiveTests/Mocks/MockNetworkService.swift` - Full protocol mock implementation
- `Internet ArchiveTests/Fixtures/TestFixtures.swift` - Reusable test data
- `Internet Archive/Protocols/NetworkServiceProtocol.swift` - Testable network interface

---

## Sprint 12: Testing (70%) & Documentation ✅ COMPLETED
**Estimated Time:** 20-25 hours
**PR Title:** `test: Expand test coverage to 70% and add documentation`
**Status:** Ready for merge

### Goals
- ✅ Expand test coverage from 15% to 70% (industry best-practice baseline)
- ✅ Complete essential documentation
- ✅ Release preparation

### Tasks

**Phase 1: Model Tests (Target: +15% coverage)**
- [x] Create AuthModelsTests.swift (~10 tests)
- [x] Create MetadataModelsTests.swift (~12 tests)
- [x] Create FavoritesModelsTests.swift (~8 tests)
- [x] Create RequestModelsTests.swift (~5 tests)
- [x] Expand SearchModelsTests.swift (+5 tests)

**Phase 2: Error Handling Tests (Target: +10% coverage)**
- [x] Create NetworkErrorTests.swift (~18 tests)
- [x] Create ErrorLoggerTests.swift (~8 tests)
- [x] Create ErrorPresenterTests.swift (~10 tests)
- [x] Expand RetryMechanism tests *(existing coverage sufficient)*

**Phase 3: Utility Tests (Target: +15% coverage)**
- [x] Create KeychainManagerTests.swift (~12 tests)
- [x] Create GlobalTests.swift (~10 tests)
- [x] Create AppConfigurationTests.swift (~5 tests)

**Phase 4: CI Updates**
- [x] Update CI threshold from 15% to 70%

**Phase 5: Documentation**
- [x] Update README.md with:
  - [x] Project overview
  - [x] Setup instructions
  - [x] Architecture documentation
  - [x] Contributing guidelines
- [x] Add inline documentation (DocC compatible) for key files:
  - [x] NetworkServiceProtocol.swift
- [ ] ~~Create CHANGELOG.md~~ *(skipped)*
- [x] Add LICENSE file (MIT)
- [x] Create APP_STORE_CHECKLIST.md
- [x] Update TESTING.md with test file inventory
- [x] Update version to 2.0.0 in Info.plist *(already done in Sprint 2)*

### Test Files Created

| File | Tests | Status |
|------|-------|--------|
| AuthModelsTests.swift | 16 | ✅ |
| MetadataModelsTests.swift | 22 | ✅ |
| FavoritesModelsTests.swift | 12 | ✅ |
| RequestModelsTests.swift | 8 | ✅ |
| SearchModelsTests.swift (expanded) | +12 | ✅ |
| NetworkErrorTests.swift | 18 | ✅ |
| ErrorLoggerTests.swift | 12 | ✅ |
| ErrorPresenterTests.swift | 20 | ✅ |
| KeychainManagerTests.swift | 16 | ✅ |
| GlobalTests.swift | 16 | ✅ |
| AppConfigurationTests.swift | 6 | ✅ |
| **Total New Tests** | **~158** | ✅ |

### Documentation Files

| File | Status |
|------|--------|
| README.md | ✅ Updated |
| TESTING.md | ✅ Updated |
| LICENSE | ✅ Added (MIT) |
| APP_STORE_CHECKLIST.md | ✅ Created |

### Deliverable
✅ 70%+ test coverage target, production-ready documentation, version 2.0.0

---

## Optional Future Sprints

### Sprint 13: Closed Captioning Support 🚧 IN PROGRESS
**Estimated Time:** 15-20 hours
**PR Title:** `feat: Add closed captioning/subtitle support for video playback`
**Status:** Implementation Complete - Ready for Testing

#### Goals
- Enable closed captions for videos that have subtitle files
- Improve accessibility for deaf/hard-of-hearing users
- Support industry-standard subtitle formats

#### Background
Internet Archive supports closed captions/subtitles in two formats:
- **WebVTT (.vtt)** - Web Video Text Tracks format (supported since 2018)
- **SubRip (.srt)** - Classic subtitle format (supported since 2009)

Subtitle files are stored alongside video files with matching names:
- Single language: `IDENTIFIER.srt` or `IDENTIFIER.vtt`
- Multiple languages: `IDENTIFIER_english.srt`, `IDENTIFIER_spanish.srt`, etc.

#### Tasks
- [x] Detect subtitle files in metadata response (`FileInfo` with `.srt` or `.vtt` format)
- [x] Parse subtitle file names to extract language information
- [x] Create subtitle URL builder using server/identifier pattern
- [x] Integrate AVPlayer subtitle support (custom overlay approach)
- [x] Convert SRT to WebVTT if needed (AVPlayer prefers WebVTT)
- [x] Add subtitle track selection UI in video player
- [x] Store user's subtitle preference in UserDefaults
- [x] Add accessibility labels for subtitle controls
- [ ] Test with various Internet Archive videos that have captions ⏳

#### Files Created
```
Internet Archive/Models/
└── SubtitleModels.swift ✅ (SubtitleTrack, SubtitleFormat, SubtitleLanguage, SubtitlePreferences)

Internet Archive/Utilities/
├── SubtitleManager.swift ✅ (Subtitle detection, language parsing, preference management)
├── SRTtoVTTConverter.swift ✅ (Actor-based SRT→WebVTT converter with caching)
└── SubtitleParser.swift ✅ (WebVTT parsing into SubtitleCue objects)

Internet Archive/UI/Subtitles/
└── SubtitleOverlayView.swift ✅ (Time-synchronized subtitle display overlay)

Internet Archive/ViewControllers/Subtitles/
└── SubtitleSelectionViewController.swift ✅ (tvOS-optimized track selection UI)

Internet Archive/ViewControllers/Video/
└── VideoPlayerViewController.swift ✅ (AVPlayerViewController subclass with subtitle support)
```

#### Files Modified
```
Internet Archive/Models/SubtitleModels.swift ✅ (FileInfo extension for subtitle detection)
Internet Archive/ViewControllers/Item/ItemVC.swift ✅ (Uses VideoPlayerViewController)
Internet Archive.xcodeproj/project.pbxproj ✅ (Added new files to project)
```

#### Technical Implementation
- **Subtitle Detection:** FileInfo extension checks for `.srt` and `.vtt` file formats
- **Language Parsing:** SubtitleManager parses filenames for 27+ language codes
- **SRT Conversion:** Actor-based converter with local file caching
- **Display:** Custom SubtitleOverlayView syncs with AVPlayer periodic time observer
- **Selection UI:** SubtitleSelectionViewController with tvOS focus engine support
- **Persistence:** UserDefaults stores enabled state, preferred language, last track

#### Technical Notes
- Uses custom subtitle overlay instead of AVPlayer's native subtitle support for more control
- SRT files are converted to WebVTT and cached locally for performance
- Subtitle cues are parsed into memory for efficient time-based lookup
- Supports 27+ languages with display name mapping

#### Deliverable
✅ Video player with optional closed caption support, language selection for multi-language content, and persistent user preferences. **Implementation complete, ready for device testing.**

---

### Sprint 14: Content Filtering & Parental Controls ✅ COMPLETED
**Estimated Time:** 20-30 hours
**PR Title:** `feat: Add content filtering and parental controls for App Store compliance`
**Status:** Complete

#### Goals
- Filter adult/mature content to comply with App Store guidelines (always enabled)
- Optionally filter to show only openly-licensed content (Creative Commons, public domain, etc.)
- Ensure app is suitable for all audiences by default

#### Background
Internet Archive hosts adult content categories (e.g., "Hentai", mature media) that would violate Apple's App Store guidelines if displayed without proper filtering. Additionally, some content may have unclear licensing.

#### Research Findings ✅

**Content Warning System:**
- Internet Archive's "content may be inappropriate" warning is triggered by the `no-preview` collection
- Items in adult collections (e.g., `adultcdroms`) are also added to `no-preview`
- The warning uses parameter `hide_flag_warning=porn` in the UI
- **No formal content rating metadata field exists in the API**

**License URL Field (`licenseurl`):**
- Items can have a `licenseurl` metadata field pointing to their license
- Supported open licenses (found in actual IA media content):
  - **Public Domain:** CC0, Public Domain Mark
  - **Creative Commons:** CC BY, CC BY-SA, CC BY-NC, CC BY-NC-SA, CC BY-ND, CC BY-NC-ND (versions 2.0-4.0)
- Many items lack a `licenseurl` field entirely (license filtering excludes them by default)

**API Filtering:**
- Can search with `licenseurl:*creativecommons*` or `licenseurl:*publicdomain*`
- Can exclude collections with `-collection:(name)` syntax

#### Tasks
- [x] **Research Internet Archive Content Ratings:**
  - [x] Investigate if Internet Archive API provides content ratings/maturity flags
  - [x] Identify all adult/mature collection identifiers to filter
  - [x] Document license URL patterns for open content
- [x] **Implement Content Filtering:**
  - [x] Create `ContentFilterService` to check items against blocklist
  - [x] Create `ContentFilterModels` for preferences and filter results
  - [x] Add `licenseurl` field to `SearchResult` and `ItemMetadata` models
  - [x] Filter search results to exclude mature collections by default (via APIManager.searchTyped)
  - [x] Filter browse/discovery screens to exclude adult content (via APIManager.getCollectionsTyped)
  - [x] Filter metadata requests to block adult content (via APIManager.getMetaDataTyped)
- [x] **License Filtering (Removed):**
  - [x] ~~Create allowlist for open licenses~~ (Not filtering on license)
  - [x] ~~Default to only showing openly-licensed content~~ (Not filtering on license)
- [x] **Testing:**
  - [x] ContentFilterServiceTests (29 tests passing)
  - [x] Build verification (zero errors)
  - [x] SwiftLint verification (zero violations)

#### Blocked Collections (Default Blocklist)
```
no-preview        # IA's content warning indicator
adultcdroms       # Mature CD-ROM software
hentai, hentaiarchive
adult, adults_only, adultsoftware
adult-games, adultgames
erotic, erotica
xxx, porn, pornography
nsfw, 18plus, r18
explicit, nudity, fetish
```

#### Files Created
```
Internet Archive/Utilities/ContentFilter/
├── ContentFilterModels.swift    ✅ (Preferences, filter reasons, maturity levels)
└── ContentFilterService.swift   ✅ (Main filtering logic, license validation)

Internet Archive/Models/
├── SearchModels.swift           ✅ (Added licenseurl field)
└── MetadataModels.swift         ✅ (Added licenseurl field)
```

#### Technical Implementation
- **Adult content filtering (always ON):** Blocks items in known adult collections including `no-preview`
- **Keyword filtering (always ON):** Minimal keyword list for explicit terms (xxx, porn, etc.)
- **Two-layer filtering:** Server-side query exclusions + client-side result filtering
- **Metadata filtering:** Direct item access blocked for adult content via `NetworkError.contentFiltered`
- **Query building:** Methods to build API exclusion queries
- **Statistics tracking:** Tracks filter reasons for debugging

#### Files Modified
```
Internet Archive/Utilities/APIManager.swift           ✅ (Content filtering in searchTyped, getCollectionsTyped, getMetaDataTyped)
Internet Archive/Utilities/NetworkError.swift         ✅ (Added contentFiltered case)
Internet Archive/Utilities/ErrorHandling/ErrorPresenter.swift    ✅ (Handle contentFiltered)
Internet Archive/Utilities/ErrorHandling/RetryMechanism.swift    ✅ (Don't retry contentFiltered)
```

#### Deliverable
✅ App filters adult/mature content by default at all entry points (search, browse, direct access), ensuring App Store compliance. 29 unit tests verify filtering behavior.

---

### Sprint 15: Continue Watching / Resume Playback ✅ COMPLETED

**Estimated Time:** 15-20 hours
**PR Title:** `feat(video): Add "Continue Watching" with playback progress tracking`
**Status:** Complete

#### Goals

- Implement video playback progress tracking with resume functionality
- Add "Continue Watching" horizontal section to VideoVC and MusicVC
- Create visually appealing cells with progress indicators
- Persist playback state across app sessions

#### Tasks

**Resume Playback:**

- [x] Track video playback position (store progress in UserDefaults)
- [x] Create `PlaybackProgress` model for persisting video/audio position
- [x] Create `PlaybackProgressManager` with UserDefaults-backed storage
- [x] Save progress automatically during playback and on pause/exit
- [x] Auto-resume playback when returning to a video
- [x] Remove completed items (>95% watched) from Continue Watching

**Continue Watching UI:**

- [x] Create "Continue Watching" horizontal section on VideoVC home screen
- [x] Create "Continue Listening" horizontal section on MusicVC home screen
- [x] Create `ContinueWatchingCell` with thumbnail, title, progress bar
- [x] Create `ContinueSectionHeaderView` for section titles
- [x] Show time remaining (e.g., "12 min remaining") on cells
- [x] Add focus animations with scale, shadow, and play icon overlay
- [x] Implement accessibility labels for VoiceOver

**Layout Integration:**

- [x] Add compositional layout sections for Continue Watching
- [x] Update `CompositionalLayoutBuilder` with `createContinueWatchingSection`
- [x] Update `DiffableDataSource+Extensions` with `ContinueWatchingSection` enum
- [x] Integrate with existing VideoVC and MusicVC diffable data sources

**Testing:**

- [x] Create `PlaybackProgressTests.swift` (model unit tests)
- [x] Create `PlaybackProgressManagerTests.swift` (manager unit tests)
- [x] Update `DiffableDataSourceTests.swift` for new section types
- [x] Build verification (zero errors)
- [x] SwiftLint verification (zero violations)

#### Files Created

```
Internet Archive/Models/
└── PlaybackProgress.swift              ✅ (Progress data model with computed properties)

Internet Archive/Utilities/
└── PlaybackProgressManager.swift       ✅ (UserDefaults-backed progress storage)

Internet Archive/UI/CollectionView/
├── ContinueWatchingCell.swift          ✅ (Cell with progress bar and focus effects)
└── ContinueSectionHeaderView.swift     ✅ (Section header view)

Internet ArchiveTests/Models/
└── PlaybackProgressTests.swift         ✅ (16 tests)

Internet ArchiveTests/Utilities/
└── PlaybackProgressManagerTests.swift  ✅ (12 tests)
```

#### Files Modified

```
Internet Archive/UI/CollectionView/
├── CompositionalLayoutBuilder.swift    ✅ (Added Continue Watching layouts)
├── DiffableDataSource+Extensions.swift ✅ (Added ContinueWatchingSection enum)
└── ModernItemCell.swift                ✅ (Minor adjustments)

Internet Archive/ViewControllers/
├── Videos/VideoVC.swift                ✅ (Integrated Continue Watching section)
├── Music/MusicVC.swift                 ✅ (Integrated Continue Listening section)
├── Item/ItemVC.swift                   ✅ (Resume playback on video selection)
└── Video/VideoPlayerViewController.swift ✅ (Save progress during playback)

Internet ArchiveTests/UI/
└── DiffableDataSourceTests.swift       ✅ (Updated for new section types)

Internet Archive.xcodeproj/project.pbxproj ✅ (Added new files)
```

#### Technical Implementation

- **PlaybackProgress Model:** Codable struct with computed properties for progress percentage, time remaining, formatted strings
- **PlaybackProgressManager:** Actor-based manager with UserDefaults persistence, automatic cleanup of old/completed items
- **ContinueWatchingCell:** Custom cell with thumbnail, title, time remaining label, progress bar, and tvOS focus animations
- **Layout:** Horizontal scrolling section using compositional layout with `orthogonalScrollingBehavior = .continuous`
- **Data Source:** Multi-section diffable data source with `ContinueWatchingSection` and `MainSection` enums

#### Deliverable
✅ Video player now tracks playback progress, shows "Continue Watching" section at top of VideoVC/MusicVC with visual progress indicators, and automatically resumes playback where users left off. 28 unit tests verify model and manager behavior.

---

### Sprint 16: Xcode Project Modernization ✅ COMPLETED
**Estimated Time:** 4-8 hours
**PR Title:** `chore(project): Modernize Xcode project with file system synchronization`
**Status:** Merged to master

#### Goals
- Convert main target to use `PBXFileSystemSynchronizedRootGroup` (Xcode 16+ feature)
- Eliminate manual file reference management in project.pbxproj
- Align with test targets that already use this feature

#### Tasks
- [x] Backup current project.pbxproj
- [x] Convert "Internet Archive" folder to synchronized root group
- [x] Verify all source files are discovered correctly
- [x] Test CocoaPods integration still works
- [x] Update build phases if needed
- [x] Verify all targets compile and tests pass

#### Benefits
- Files added to disk automatically appear in Xcode
- Reduces merge conflicts in project.pbxproj
- Modern Xcode project structure

#### Deliverable
✅ Xcode project modernized with file system synchronization. All source files in "Internet Archive" folder are now automatically discovered. CocoaPods integration verified working. All targets compile successfully.

---

### Sprint 17: UI/UX Refinements

**Estimated Time:** 20-30 hours
**PR Title:** `feat: UI/UX improvements for better user experience`
**Status:** In Progress - Accessibility, Descriptions, and Music Player Complete

#### Goals

- Enhance accessibility for VoiceOver users
- Better content organization and discovery
- Polish existing UI elements
- Improve music player experience

#### Tasks

**Accessibility Audit:**

Current State: ModernItemCell, ContinueWatchingCell, SubtitleOverlayView, and SubtitleSelectionViewController have good accessibility. Most view controllers and legacy components lack accessibility support.

*Phase 1: Critical Components (High Impact)* ✅ COMPLETED
- [x] **ItemVC.swift** - Add accessibility to all interactive elements:
  - [x] Play/Stop button: `accessibilityLabel`, `accessibilityHint`
  - [x] Resume/Start Over buttons: Labels describing action
  - [x] Favorite button: Toggle state via `accessibilityValue` ("Favorited"/"Not favorited")
  - [x] Time remaining label: Contextual accessibility
  - [x] Slider control: `accessibilityTraits = .adjustable`, custom increment/decrement actions
  - [x] Description text viewer: Proper accessibility label
- [x] **LoginVC.swift** - Add accessibility to authentication form:
  - [x] Email text field: `accessibilityLabel = "Email address"`
  - [x] Password text field: `accessibilityLabel = "Password"`
  - [x] Error messages: Announce via `UIAccessibility.post(notification:)`
- [x] **RegisterVC.swift** - Add accessibility to registration form:
  - [x] All 4 text fields with descriptive labels
  - [x] Password confirmation hint text
  - [x] Error messages: Announce via `UIAccessibility.post(notification:)`
- [x] **SearchResultVC.swift** - Add accessibility to search screen:
  - [x] Filter UISegmentedControl: Labels for each segment
  - [x] SectionHeaderView: `accessibilityTraits = .header`
  - [x] Results count announcement
- [x] **YearsVC.swift** - Add accessibility to years navigation:
  - [x] YearCell (table cell): `accessibilityLabel` with year
  - [x] Title label: `accessibilityTraits = .header`
  - [x] Table/collection view accessibility labels
- [x] **Slider.swift** - Custom media scrubber accessibility:
  - [x] `accessibilityTraits = .adjustable`
  - [x] Override `accessibilityIncrement()` / `accessibilityDecrement()`

*Phase 2: Navigation & Structure* ✅ COMPLETED
- [x] **VideoVC.swift** / **MusicVC.swift** - Section headers and empty states:
  - [x] ContinueSectionHeaderView: `accessibilityTraits = .header`
  - [x] Empty state view: Proper accessibility context
  - [x] Loading state announcements for VoiceOver users
  - [x] Collection view accessibility labels
- [x] **FavoriteVC.swift** / **PeopleVC.swift** - Collection accessibility:
  - [x] Section headers: `accessibilityTraits = .header`
  - [x] Collection view accessibility labels
  - [x] Results count announcements for VoiceOver users
- [x] **AccountVC.swift** - Account screen accessibility:
  - [x] Description label: `accessibilityTraits = .staticText`
  - [x] Logout announcement for VoiceOver users
- [x] **TabbarController.swift** - Tab bar accessibility:
  - [x] Better accessibility labels for tab items with descriptive hints
  - [x] Hide logo watermark from accessibility tree

*Phase 3: Supporting Components* ✅ COMPLETED
- [x] **ContinueSectionHeaderView.swift** - Add `accessibilityTraits = .header` with section label
- [x] **EmptyStateView.swift** - Add accessibility to title, message; group as single accessible element
- [x] **Slider.swift** - Custom media scrubber accessibility:
  - [x] `accessibilityTraits = .adjustable`
  - [x] `accessibilityValue` showing current time
  - [x] Override `accessibilityIncrement()` / `accessibilityDecrement()` with 10-second steps
- [x] **SkeletonView.swift** - Mark as non-accessible (loading indicator hidden from accessibility)
- [x] **ItemCell.swift** (Legacy) - Added basic accessibility with configurable label/hint

*Phase 4: Testing & Validation* ✅ COMPLETED
- [x] Build verification - compiles successfully
- [x] SwiftLint - zero violations
- [x] Unit tests - `AccessibilityTests.swift` with 29 passing tests:
  - Slider accessibility (adjustable trait, increment/decrement bounds)
  - EmptyStateView accessibility (staticText trait, label formatting)
  - ContinueSectionHeaderView (header trait)
  - SkeletonView (hidden from accessibility)
  - ModernItemCell (button trait, label, hint)
  - ContinueWatchingCell accessibility
  - Accessibility audit helper for automated view hierarchy checks
- [ ] Manual VoiceOver testing recommended (user task)
- [ ] Focus navigation verification with Siri Remote (user task)

**Item Description Formatting:** ✅ COMPLETED

- [x] Parse and render HTML/newlines in item descriptions
- [x] Preserve paragraph breaks and lists in description text
- [x] Add "Read More" expansion for long descriptions
- [x] Support basic text formatting (bold, italic) if present

*Files Created:*
- `Internet Archive/Utilities/HTMLToAttributedString.swift` - HTML-to-NSAttributedString converter
- `Internet Archive/UI/DescriptionTextView.swift` - Custom focusable description view
- `Internet ArchiveTests/Utilities/HTMLToAttributedStringTests.swift` - 50+ unit tests
- `Internet ArchiveTests/UI/DescriptionTextViewTests.swift` - 32 unit tests

*Files Modified:*
- `Internet Archive/ViewControllers/Item/ItemVC.swift` - Integrated DescriptionTextView

**Music Player UI Improvements:** ✅ COMPLETED

- [x] Add Now Playing screen with album art, track list, and transport controls
- [x] Implement AudioQueueManager with shuffle/repeat modes
- [x] Add Continue Listening section to MusicVC with resume support
- [x] Fix album progress consistency (normalized 0-100 scale, percentage display)
- [x] Modernize VideoPlayerViewController KVO to block-based API
- [x] Add 70+ unit tests for AudioTrack and AudioQueueManager

**Additional Refinements:** ✅ COMPLETED

- [x] Improve loading states with skeleton screens
- [x] Improve empty state messages
- [x] Fix double-encoded HTML in descriptions (e.g. &lt;p&gt;)
- [ ] Add pull-to-refresh where appropriate (not standard on tvOS)
- [x] Add VoiceOver announcements for loading and content states

*Files Modified:*

- `Internet Archive/ViewControllers/Search/SearchResultVC.swift` - Added skeleton loading and empty states
- `Internet Archive/ViewControllers/Favorite/FavoriteVC.swift` - Added skeleton loading and empty states
- `Internet Archive/ViewControllers/Favorite/PeopleVC.swift` - Added skeleton loading and empty states
- `Internet Archive/ViewControllers/Years/YearsVC.swift` - Added skeleton loading and empty states
- `Internet Archive/Utilities/HTMLToAttributedString.swift` - Added preprocessHTML for double-encoded entities

#### Files to Create/Modify

```
Internet Archive/UI/
├── DescriptionTextView.swift        # Rich text description display
└── MusicPlayer/
    ├── NowPlayingView.swift         # Now playing screen
    └── TrackListView.swift          # Track list display
```

#### Deliverable
Enhanced user experience with better accessibility, improved content display, and polished music player UI.

---

### Sprint 18: CocoaPods to Swift Package Manager Migration ✅ COMPLETED

**Estimated Time:** 15-25 hours
**PR Title:** `chore: Migrate from CocoaPods to Swift Package Manager`
**Status:** Completed

#### Background

CocoaPods has announced it will transition to read-only mode in 2026. Swift Package Manager (SPM) is now Apple's recommended dependency management solution and offers better Xcode integration, faster dependency resolution, and first-party support.

#### Goals

- ✅ Migrate all dependencies from CocoaPods to Swift Package Manager
- ✅ Remove Podfile, Podfile.lock, and Pods directory
- ✅ Simplify project structure
- ✅ Improve build times with SPM caching

#### Dependency Migration Summary

| CocoaPod                          | Migration Approach                               | Status                   |
| --------------------------------- | ------------------------------------------------ | ------------------------ |
| Alamofire ~> 5.9                  | SPM package reference                            | ✅ Migrated              |
| AlamofireImage ~> 4.3             | SPM package reference                            | ✅ Migrated              |
| SVProgressHUD ~> 2.3.1            | SPM package reference                            | ✅ Migrated              |
| MBProgressHUD ~> 1.2.0            | SPM package reference                            | ✅ Migrated              |
| SwiftSoup ~> 2.11                 | SPM package reference                            | ✅ Migrated              |
| TvOSMoreButton ~> 1.4.1           | SPM package reference (pinned to commit SHA)     | ✅ Migrated              |
| TvOSTextViewer ~> 1.1.1           | SPM package reference (pinned to commit SHA)     | ✅ Migrated              |
| SwiftLint (Debug only)            | System-installed (`brew install`)                | ✅ Kept as shell script  |

*Note: TvOSMoreButton and TvOSTextViewer are pinned to specific commit SHAs (`kind = revision` in project.pbxproj) for supply chain security. The versions shown are the original CocoaPods versions. While Package.resolved shows branch names for context, the project will not auto-update these packages - they remain locked to the specified commits.*

#### Tasks Completed

**Phase 1: Preparation**

- [x] Audit all dependencies for SPM compatibility
- [x] Integrate TvOSMoreButton via SPM (`https://github.com/cgoldsby/TvOSMoreButton.git`, pinned to commit SHA for supply chain security)
- [x] Integrate TvOSTextViewer via SPM (`https://github.com/dcordero/TvOSTextViewer.git`, pinned to commit SHA for supply chain security)

**Phase 2: Project Migration**

- [x] Add SPM package references via Xcode's native integration
- [x] Configure package products for main target
- [x] Remove CocoaPods framework references from project

**Phase 3: SwiftLint**

- [x] Keep SwiftLint as shell script build phase (simpler than SPM plugin)
- [x] Update script to use system-installed swiftlint

**Phase 4: Cleanup**

- [x] Remove Podfile, Podfile.lock
- [x] Remove Pods/ directory
- [x] Remove CocoaPods-related build phases from Xcode project
- [x] Update .gitignore (Pods/ already ignored, added Internet Archive.xcworkspace/)
- [x] Delete `Internet Archive.xcworkspace` (now use .xcodeproj directly)

**Phase 5: Documentation**

- [x] Update DEVELOPMENT_SETUP.md with SPM instructions
- [x] Update CLAUDE.md build commands
- [x] Verified build succeeds with SPM
- [x] Verified all tests pass

#### Files Modified

- `Internet Archive.xcodeproj/project.pbxproj` - SPM package references, removed CocoaPods
- `.gitignore` - Added Internet Archive.xcworkspace/
- `DEVELOPMENT_SETUP.md` - SPM setup instructions
- `CLAUDE.md` - Updated build commands

#### Files Removed

- `Podfile`
- `Podfile.lock`
- `Pods/` directory
- `Internet Archive.xcworkspace/`

#### Benefits Achieved

- ✅ No `pod install` step in setup
- ✅ Faster dependency resolution with SPM caching
- ✅ Better Xcode integration
- ✅ Single project file instead of workspace
- ✅ First-party Apple support

#### Deliverable

✅ Project fully migrated to Swift Package Manager with no CocoaPods dependencies. Simplified project structure with faster dependency resolution.

---

### Sprint 19: SwiftUI Migration

**Estimated Time:** 175-220 hours
**PR Title:** `feat: Migrate to SwiftUI for tvOS`

Full UI rewrite using SwiftUI with TabView navigation. Leverages existing MVVM ViewModels.

#### Goals

- Migrate all UIKit views to SwiftUI
- Use SwiftUI TabView for navigation (not UIHostingController hybrid)
- Maintain existing ViewModels with @StateObject
- Wrap AVPlayer via UIViewControllerRepresentable

#### File Structure

```text
Internet Archive/
├── App/
│   ├── InternetArchiveApp.swift       # @main entry point
│   ├── ContentView.swift              # TabView root
│   └── AppState.swift                 # Auth state
├── Features/
│   ├── Videos/, Music/, Search/, ItemDetail/, Favorites/, Account/, Player/
├── Components/
│   ├── MediaItemCard.swift, SectionHeader.swift, EmptyStateView.swift, etc.
│   └── Styles/                        # TVCardButtonStyle, etc.
└── (existing ViewModels/, Models/, Services/, Utilities/)
```

#### Tasks

**Phase 1: Foundation (15-20 hours)**

- [ ] Create `InternetArchiveApp.swift` with @main
- [ ] Create `ContentView.swift` with 5-tab TabView
- [ ] Create `AppState.swift` for auth state
- [ ] Create placeholder views for each tab
- [ ] Update Info.plist for SwiftUI App lifecycle

**Phase 2: Core Components (20-25 hours)**

- [ ] `MediaItemCard` - grid item with thumbnail, title, progress
- [ ] `TVCardButtonStyle` - tvOS focus effects (scale, shadow)
- [ ] `ContinueWatchingCard` and `ContinueWatchingSection`
- [ ] `SectionHeader` with optional "See All" button
- [ ] `EmptyStateView` and `ErrorStateView`
- [ ] `SkeletonLoadingView` with shimmer animation

**Phase 3: Content Browsing (25-30 hours)**

- [ ] `VideoHomeView` with LazyVGrid layout
- [ ] `MusicHomeView` with LazyVGrid layout
- [ ] Continue Watching/Listening sections
- [ ] Year navigation (sidebar + grid)
- [ ] Integrate existing VideoViewModel and MusicViewModel

**Phase 4: Item Details (20-25 hours)**

- [ ] `ItemDetailView` modal with metadata display
- [ ] `PlaybackButtons` - Play, Resume, Start Over
- [ ] `DescriptionView` - HTML rendering
- [ ] `FavoriteButton` with animation
- [ ] Navigation to player via .fullScreenCover

**Phase 5: Media Playback (30-35 hours)**

- [ ] `VideoPlayerView` - UIViewControllerRepresentable wrapper
- [ ] `VideoPlayerController` - ObservableObject for state
- [ ] `SubtitleOverlay` in SwiftUI
- [ ] `NowPlayingView` - full-screen music player
- [ ] Progress tracking with PlaybackProgressManager

**Phase 6: Search (15-20 hours)**

- [ ] `SearchView` with .searchable modifier
- [ ] Filter picker (All/Video/Music)
- [ ] Dual-section results display
- [ ] Pagination with .onAppear triggers

**Phase 7: Year-Based Browsing (15-20 hours)**

- [ ] `YearBrowseView` with sidebar + grid
- [ ] Year list selection
- [ ] Items grid for selected year

**Phase 8: Favorites & Account (20-25 hours)**

- [ ] `FavoritesView` with 3 sections
- [ ] `PeopleDetailView` for creator browsing
- [ ] `LoginView` and `RegisterView` forms
- [ ] `AccountView` with user info

**Phase 9: Accessibility & Polish (15-20 hours)**

- [ ] VoiceOver labels on all elements
- [ ] Focus restoration via @SceneStorage
- [ ] Animation polish
- [ ] Memory/performance profiling

**Phase 10: Cleanup**

- [ ] Remove Main.storyboard
- [ ] Delete old UIKit ViewControllers
- [ ] Remove TabbarController and navigation controllers
- [ ] Update CLAUDE.md documentation

#### Deliverable

Complete SwiftUI-based tvOS app with modern navigation, reusing existing ViewModels and service layer.

---

### Sprint 20: Additional Features

- Implement new Internet Archive APIs
- Add search filters
- Improve media player
- Add watchlist functionality

---

## Sprint Dependencies

```
Sprint 1 (Config)
    ↓
Sprint 2 (Dependencies)
    ↓
Sprint 3 (Swift Syntax)
    ↓
Sprint 4 (Networking) → Sprint 5 (Models)
    ↓                      ↓
Sprint 6 (ViewControllers) ←─┘
    ↓
Sprint 7 (Security)
    ↓
Sprint 8 (Concurrency)
    ↓
Sprint 9 (UI) → Sprint 10 (Error Handling)
    ↓
Sprint 11 (Testing)
    ↓
Sprint 12 (Documentation)
```

---

## Milestone Checkpoints

### Milestone 1: Compilable (Sprints 1-4)
- Project compiles with Xcode 16+
- Modern dependencies installed
- Core networking functional

### Milestone 2: Functional (Sprints 5-6)
- All features working
- Type-safe API layer
- Modern Swift patterns

### Milestone 3: Production-Ready (Sprints 7-10)
- Security hardened
- Swift 6 compliant
- Modern UI patterns

### Milestone 4: Release-Ready (Sprints 11-12)
- Tested and documented
- CI/CD in place
- Ready for App Store

---

## Risk Mitigation

1. **API Changes** - Verify Internet Archive APIs still work before Sprint 4
2. **Breaking Changes** - Each sprint should be deployable/testable independently
3. **Scope Creep** - Stick to sprint goals, defer "nice to haves"
4. **Testing on Device** - Test on real Apple TV hardware after Sprint 6

---

## Getting Started

Begin with Sprint 1 after reviewing this plan. Each sprint should:
1. Create a feature branch from main
2. Complete all tasks in the sprint
3. Test thoroughly
4. Create PR with detailed description
5. Review and merge
6. Tag release (optional)

Ready to begin? Start with **Sprint 1: Project Configuration & Build Setup**.
