# Internet Archive Apple TV
# Platform: tvOS 17.0 (minimum deployment target for Sprint 9)
# Progressive enhancement for tvOS 26.0 Liquid Glass features
platform :tvos, '17.0'

target 'Internet Archive' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Internet Archive
  # Updated to Alamofire 5.x for Sprint 4 (networking layer rewrite)
  # Alamofire 5.x provides modern async/await support and better Swift 6 compatibility
  pod 'Alamofire', '~> 5.9'
  pod 'AlamofireImage', '~> 4.3'
  pod 'SVProgressHUD', '~> 2.3.1'
  pod 'TvOSMoreButton', '~> 1.4.1'
  pod 'TvOSTextViewer', '~> 1.1.1'
  pod 'MBProgressHUD', '~> 1.2.0'
  pod 'SwiftSoup', '~> 2.11'  # HTML parsing for description text

  # Development tools
  pod 'SwiftLint', :configurations => ['Debug']

  # Test targets
  target 'Internet ArchiveTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

# UI tests are kept separate - they don't need pod dependencies
# since they test the app via XCUIApplication which already has frameworks embedded
target 'Internet ArchiveUITests' do
  use_frameworks!
end

# Post install hook to configure build settings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Set minimum deployment target to tvOS 17.0
      config.build_settings['TVOS_DEPLOYMENT_TARGET'] = '17.0'

      # Disable library evolution/module stability for faster builds
      # Enable (set to 'YES') only if distributing frameworks
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
    end
  end

  # Fix deprecated Swift 4 APIs in TvOSTextViewer for Swift 6 compatibility
  text_viewer_file = 'Pods/TvOSTextViewer/TvOSTextViewer/Sources/TvOSTextViewerViewController.swift'
  if File.exist?(text_viewer_file)
    # Make file writable
    File.chmod(0644, text_viewer_file)

    text = File.read(text_viewer_file)

    # Fix UIBlurEffectStyle -> UIBlurEffect.Style
    text.gsub!('UIBlurEffectStyle', 'UIBlurEffect.Style')

    # Fix NSAttributedStringKey -> NSAttributedString.Key
    text.gsub!('NSAttributedStringKey', 'NSAttributedString.Key')

    # Fix UITouchType -> UITouch.TouchType
    text.gsub!('UITouchType.indirect', 'UITouch.TouchType.indirect')

    File.write(text_viewer_file, text)
    puts "✅ Patched TvOSTextViewer for Swift 6 compatibility"
  end

  # Fix deprecated languageCode in TvOSMoreButton for tvOS 16+
  bundle_loader_file = 'Pods/TvOSMoreButton/Source/Private/Helpers/BundleLoader.swift'
  if File.exist?(bundle_loader_file)
    # Make file writable
    File.chmod(0644, bundle_loader_file)

    text = File.read(bundle_loader_file)

    # Fix Locale.current.languageCode -> Locale.current.language.languageCode.identifier
    text.gsub!('Locale.current.languageCode', 'Locale.current.language.languageCode?.identifier')

    File.write(bundle_loader_file, text)
    puts "✅ Patched TvOSMoreButton for tvOS 16+ compatibility"
  end
end

