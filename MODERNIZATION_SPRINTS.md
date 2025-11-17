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

## Sprint 4: Networking Layer Rewrite - Part 1 (Core)
**Estimated Time:** 20-25 hours
**PR Title:** `refactor: Migrate APIManager to Alamofire 5.x and async/await`

### Goals
- Rewrite core networking layer for Alamofire 5.x
- Implement async/await patterns
- Add proper error handling

### Tasks
- [ ] Create new `NetworkError` enum for error handling
- [ ] Rewrite `APIManager.swift` for Alamofire 5.x:
  - [ ] Replace `Alamofire.request()` with `AF.request()`
  - [ ] Replace `SessionManager.default` with `AF`
  - [ ] Update response handling to use `Result<Success, Failure>`
  - [ ] Replace `.responseJSON` with `.responseDecodable`
  - [ ] Create Codable models for API responses
- [ ] Add async/await wrappers for all API methods:
  - [ ] `register()` → `async throws`
  - [ ] `login()` → `async throws`
  - [ ] `getAccountInfo()` → `async throws`
  - [ ] `getCollections()` → `async throws`
  - [ ] `search()` → `async throws`
  - [ ] `getMetaData()` → `async throws`
  - [ ] `getFavoriteItems()` → `async throws`
  - [ ] `saveFavoriteItem()` → `async throws`
- [ ] Implement proper cookie handling for modern URLSession
- [ ] Add request/response logging for debugging

### Deliverable
Core networking compiles with Alamofire 5.x, async/await methods available

---

## Sprint 5: Data Models & Codable
**Estimated Time:** 12-16 hours
**PR Title:** `feat: Implement Codable data models for Internet Archive API`

### Goals
- Create type-safe data models
- Replace dictionary parsing with Codable
- Improve type safety

### Tasks
- [ ] Create Codable models:
  ```swift
  struct SearchResponse: Codable
  struct SearchResult: Codable
  struct ItemMetadata: Codable
  struct FileInfo: Codable
  struct FavoritesResponse: Codable
  struct AuthResponse: Codable
  struct AccountInfo: Codable
  ```
- [ ] Add custom CodingKeys for API field mapping
- [ ] Implement date parsing strategies
- [ ] Add optional field handling with defaults
- [ ] Create DTOs vs Domain models if needed
- [ ] Update APIManager to return typed models
- [ ] Remove all `as! [String: Any]` force casts

### Deliverable
Type-safe API responses, no more dictionary parsing

---

## Sprint 6: View Controller Migration - Part 1
**Estimated Time:** 15-20 hours
**PR Title:** `refactor: Update ViewControllers to use async/await and modern patterns`

### Goals
- Update view controllers to use new APIManager
- Implement proper async/await in UI layer
- Fix force unwrapping issues

### Tasks
- [ ] Add `@MainActor` to all view controllers
- [ ] Update API calls to use async/await:
  - [ ] VideoVC.swift - `getCollections()`
  - [ ] MusicVC.swift - `getCollections()`
  - [ ] YearsVC.swift - `getCollections()`
  - [ ] SearchResultVC.swift - `search()`, `getMetaData()`
  - [ ] ItemVC.swift - `getMetaData()`, `saveFavoriteItem()`
  - [ ] FavoriteVC.swift - `getFavoriteItems()`, `search()`
  - [ ] PeopleVC.swift - `getFavoriteItems()`, `search()`
  - [ ] LoginVC.swift - `login()`, `getAccountInfo()`
  - [ ] RegisterVC.swift - `register()`
- [ ] Replace completion handlers with Task blocks
- [ ] Add proper error handling with alerts
- [ ] Fix force unwrapping (convert 80+ instances to optional binding)
- [ ] Update storyboard force casts to safe casts

### Deliverable
All view controllers compile and use modern async patterns

---

## Sprint 7: Security & Configuration
**Estimated Time:** 8-10 hours
**PR Title:** `security: Remove hardcoded credentials and improve app security`

### Goals
- Remove security vulnerabilities
- Implement proper secrets management
- Enforce HTTPS

### Tasks
- [ ] Remove hardcoded API credentials from source code
- [ ] Implement Keychain storage for sensitive data:
  - [ ] API access/secret keys
  - [ ] User credentials
  - [ ] Session tokens
- [ ] Create secure configuration loading (from .plist or environment)
- [ ] Update Info.plist to remove NSAppTransportSecurity exceptions
- [ ] Enforce HTTPS-only connections
- [ ] Add certificate pinning (optional)
- [ ] Update cookie storage to use secure cookies only
- [ ] Add `.env.example` for required configuration
- [ ] Document security setup in README

### Deliverable
No hardcoded secrets, Keychain integration, HTTPS enforced

---

## Sprint 8: Strict Concurrency Compliance
**Estimated Time:** 15-20 hours
**PR Title:** `refactor: Enable strict concurrency checking for Swift 6`

### Goals
- Full Swift 6 concurrency compliance
- Eliminate data races
- Proper actor isolation

### Tasks
- [ ] Enable strict concurrency checking in build settings
- [ ] Add `@MainActor` annotations to UI-bound code
- [ ] Make APIManager actor-isolated or `@MainActor`
- [ ] Fix all Sendable conformance issues
- [ ] Update UserDefaults access to be thread-safe
- [ ] Review and fix shared mutable state
- [ ] Add `nonisolated` where appropriate
- [ ] Handle cross-actor calls properly
- [ ] Test for data races with Thread Sanitizer
- [ ] Document concurrency model

### Deliverable
Zero concurrency warnings, Swift 6 strict mode enabled

---

## Sprint 9: UI Modernization - UIKit Improvements
**Estimated Time:** 20-25 hours
**PR Title:** `feat: Modernize UIKit implementation with modern patterns`

### Goals
- Update UI code for tvOS 17+
- Improve performance
- Better focus handling

### Tasks
- [ ] Update collection view implementations:
  - [ ] Use `UICollectionViewDiffableDataSource`
  - [ ] Implement `UICollectionViewCompositionalLayout`
- [ ] Improve image loading:
  - [ ] Add proper caching
  - [ ] Implement prefetching
  - [ ] Handle memory warnings properly
- [ ] Update focus engine usage for tvOS 17+
- [ ] Implement modern cell registration
- [ ] Add accessibility improvements
- [ ] Update colors for dark mode support
- [ ] Improve loading states with skeleton views
- [ ] Add pull-to-refresh where appropriate
- [ ] Update navigation patterns

### Deliverable
Modern UIKit patterns, better performance, tvOS 17+ compatibility

---

## Sprint 10: Error Handling & User Feedback
**Estimated Time:** 10-12 hours
**PR Title:** `feat: Implement comprehensive error handling and user feedback`

### Goals
- User-friendly error messages
- Proper offline handling
- Better loading states

### Tasks
- [ ] Create centralized error handling system
- [ ] Implement user-friendly error messages for:
  - [ ] Network errors
  - [ ] Authentication failures
  - [ ] API errors
  - [ ] Parsing errors
- [ ] Add offline state detection
- [ ] Implement retry mechanisms
- [ ] Update progress HUD usage:
  - [ ] Use native tvOS loading indicators where possible
  - [ ] Add timeout handling
- [ ] Add empty state views
- [ ] Implement error recovery flows
- [ ] Add logging for debugging

### Deliverable
Robust error handling, better UX for failure cases

---

## Sprint 11: Testing Infrastructure
**Estimated Time:** 25-30 hours
**PR Title:** `test: Add unit tests and testing infrastructure`

### Goals
- Add test coverage
- Implement mock networking
- CI/CD preparation

### Tasks
- [ ] Set up XCTest targets
- [ ] Create mock networking layer:
  - [ ] Protocol-based dependency injection
  - [ ] Mock API responses
  - [ ] Test fixtures for all API endpoints
- [ ] Write unit tests for:
  - [ ] APIManager (all endpoints)
  - [ ] Data models (Codable)
  - [ ] Business logic
  - [ ] Error handling
- [ ] Add UI tests for critical flows:
  - [ ] Login flow
  - [ ] Search functionality
  - [ ] Media playback
- [ ] Set up code coverage reporting
- [ ] Add GitHub Actions CI workflow
- [ ] Document testing approach

### Deliverable
70%+ code coverage, CI pipeline ready

---

## Sprint 12: Documentation & Polish
**Estimated Time:** 10-12 hours
**PR Title:** `docs: Add comprehensive documentation and project polish`

### Goals
- Complete documentation
- Code quality tools
- Release preparation

### Tasks
- [ ] Update README.md with:
  - [ ] Project overview
  - [ ] Setup instructions
  - [ ] Architecture documentation
  - [ ] API documentation
  - [ ] Contributing guidelines
- [ ] Add inline documentation (DocC compatible)
- [ ] Set up SwiftLint with configuration
- [ ] Add SwiftFormat for consistent styling
- [ ] Create CHANGELOG.md
- [ ] Add LICENSE file
- [ ] Create release checklist
- [ ] Update version to 2.0.0
- [ ] Add screenshots/demo GIFs
- [ ] Create App Store submission checklist

### Deliverable
Production-ready, well-documented codebase

---

## Optional Future Sprints

### Sprint 13: SwiftUI Migration (Optional)
**Estimated Time:** 80-120 hours
**PR Title:** `feat: Migrate to SwiftUI for tvOS`

Full UI rewrite using SwiftUI, recommended for long-term maintainability.

### Sprint 14: Additional Features
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
