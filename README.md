# Internet Archive tvOS App

A native tvOS application for browsing and streaming video and audio content from the [Internet Archive](https://archive.org).

## Features

- Browse curated video and audio collections
- Search the Internet Archive catalog
- Stream movies, concerts, audiobooks, and more
- Save favorites for quick access
- User account authentication

## Requirements

- Xcode 16.0+
- tvOS 17.0+
- Apple TV (4th generation or later)

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/internetarchive/internet-archive-apple-tv.git
   cd internet-archive-apple-tv
   ```

2. **Configure API credentials** (optional - required for login/favorites)
   ```bash
   cp Configuration.plist.template "Internet Archive/Configuration.plist"
   ```
   Edit `Configuration.plist` and add your Internet Archive S3 API keys from [archive.org/account/s3.php](https://archive.org/account/s3.php).

3. **Set up Git hooks**
   ```bash
   bash scripts/setup-hooks.sh
   ```
   This installs a pre-commit hook that runs SwiftLint on staged files.

4. **Open and run**
   ```bash
   open "Internet Archive.xcodeproj"
   ```
   SPM dependencies resolve automatically. Select the "Internet Archive" scheme and run on Apple TV Simulator or device.

See [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) for full setup details including SwiftLint configuration.

## Project Structure

```
Internet Archive/
├── App/                        # SwiftUI app entry point (@main)
├── Features/                   # Feature modules (SwiftUI views)
├── Models/                     # Codable data models
├── Protocols/                  # Protocol definitions
├── UI/                         # UIKit components (cells, image loading)
├── Utilities/                  # API manager, helpers, error handling
└── ViewControllers/            # UIKit controllers (player only)
```

## Architecture

- **Swift 6.0** with strict concurrency checking
- **SwiftUI** (primary) with UIKit wrappers for video/audio playback
- **Async/await** networking with Alamofire 5.11
- **Protocol-based dependency injection** for testability
- **Codable models** for type-safe API responses

## Testing

Run the test suite:
```bash
xcodebuild test \
  -project "Internet Archive.xcodeproj" \
  -scheme "Internet Archive" \
  -destination "platform=tvOS Simulator,name=Apple TV"
```

See [TESTING.md](TESTING.md) for detailed testing documentation.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Run SwiftLint before committing (`swiftlint`)
4. Commit your changes
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Internet Archive](https://archive.org) for providing free access to digital content
- [Alamofire](https://github.com/Alamofire/Alamofire) for networking
- [AlamofireImage](https://github.com/Alamofire/AlamofireImage) for image loading
- [SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD) for progress indicators
