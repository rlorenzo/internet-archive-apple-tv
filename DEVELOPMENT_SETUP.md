# Development Setup Guide

This guide explains how to set up your development environment for the Internet Archive Apple TV project.

## Prerequisites

- **Xcode 16.0+** (for Swift 6.0 support)
- **tvOS 26.0 SDK**
- **SwiftLint** (`brew install swiftlint`)

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/internet-archive-apple-tv.git
cd internet-archive-apple-tv
```

### 2. Open the Project

Open the project file (not workspace):

```bash
open "Internet Archive.xcodeproj"
```

Xcode will automatically resolve Swift Package Manager dependencies:

- Alamofire (HTTP networking)
- AlamofireImage (Image caching)
- SVProgressHUD (Progress indicators)
- MBProgressHUD (Alternative progress HUD)
- SwiftSoup (HTML parsing)
- TvOSMoreButton (tvOS UI component)
- TvOSTextViewer (Text display)

### 3. Set Up Git Hooks

Run the setup script to install the pre-commit hook:

```bash
./scripts/setup-hooks.sh
```

This will:
- Install the pre-commit hook that runs SwiftLint
- Verify SwiftLint is available
- Check for configuration files

### 4. Configure API Credentials

⚠️ **Security Note:** Never commit API credentials to the repository.

Create a configuration file for your API keys:

```bash
cp Config.example.plist Config.plist
```

Edit `Config.plist` with your Internet Archive API credentials. This file is gitignored and will not be committed.

## SwiftLint

SwiftLint is configured to enforce code quality standards. The configuration is in `.swiftlint.yml`.

### Running SwiftLint Manually

```bash
# Lint all Swift files
swiftlint

# Lint with auto-correction
swiftlint --fix

# Lint specific file
swiftlint lint --path "Internet Archive/AppDelegate.swift"
```

### Pre-commit Hook

The pre-commit hook automatically runs SwiftLint on staged Swift files before each commit:

- **During migration phase:** Warnings are reported but commits are allowed
- **After Sprint 3:** Will become strict (block commits with lint errors)

To bypass the hook (not recommended):
```bash
git commit --no-verify
```

### Custom Rules

The SwiftLint configuration includes custom rules to catch:
- Deprecated `didReceiveMemoryWarning()` usage
- Deprecated type names (UIApplicationLaunchOptionsKey, NSAttributedStringKey)
- NSDate usage (should be Date)
- Hardcoded credentials

## Build Configuration

### Swift Version
- **Target:** Swift 6.0
- **Strict Concurrency:** Enabled (after Sprint 8)

### tvOS Deployment Target
- **Target:** tvOS 26.0

### Code Signing
Configure your development team in Xcode:
1. Select the project in Xcode
2. Go to "Signing & Capabilities"
3. Select your team
4. Enable "Automatically manage signing"

## Project Structure

```
internet-archive-apple-tv/
├── Internet Archive/           # Main app source code
│   ├── AppDelegate.swift
│   ├── Classes/               # Reusable components
│   ├── Utilities/             # API manager, helpers
│   └── ViewControllers/       # Feature modules
├── Internet ArchiveTests/      # Unit tests
├── scripts/                   # Development scripts
│   ├── pre-commit            # Git pre-commit hook
│   └── setup-hooks.sh        # Hook installation script
├── .swiftlint.yml            # SwiftLint configuration
├── .swift-version            # Swift version file
├── Internet Archive.xcodeproj # Xcode project (with SPM package refs)
└── MODERNIZATION_SPRINTS.md  # Migration plan
```

## Troubleshooting

### SwiftLint Not Found

If the pre-commit hook reports SwiftLint is not found:

```bash
# Install via Homebrew (recommended)
brew install swiftlint
```

### SPM Package Resolution Fails

If Swift Package Manager fails to resolve dependencies:

1. Clean build folder (Cmd+Shift+K)
2. Close Xcode
3. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/Internet_Archive-*`
4. Reopen the project and let Xcode resolve packages

### Build Errors

During the migration phase, you may encounter build errors. See `MODERNIZATION_SPRINTS.md` for the planned migration path.

## Contributing

1. Create a feature branch from `master`
2. Make your changes
3. Ensure SwiftLint passes: `swiftlint`
4. Commit your changes (pre-commit hook will run)
5. Create a Pull Request

## Next Steps

After setup, refer to:
- `MODERNIZATION_SPRINTS.md` - Detailed migration plan
- Sprint 2 tasks - Dependency modernization
- Sprint 3 tasks - Swift syntax migration
