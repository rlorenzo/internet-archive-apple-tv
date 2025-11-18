# Internet Archive Apple TV
# Platform: tvOS 26.0 (latest version with newest APIs and features)
platform :tvos, '26.0'

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

  # Development tools
  pod 'SwiftLint', :configurations => ['Debug']
end

# Post install hook to configure build settings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Set minimum deployment target
      config.build_settings['TVOS_DEPLOYMENT_TARGET'] = '26.0'

      # Disable library evolution/module stability for faster builds
      # Enable (set to 'YES') only if distributing frameworks
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
    end
  end

  # Fix deprecated Swift 4 APIs in TvOSTextViewer for Swift 6 compatibility
  text_viewer_file = 'Pods/TvOSTextViewer/TvOSTextViewer/Sources/TvOSTextViewerViewController.swift'
  if File.exist?(text_viewer_file)
    text = File.read(text_viewer_file)

    # Fix UIBlurEffectStyle -> UIBlurEffect.Style
    text.gsub!('UIBlurEffectStyle', 'UIBlurEffect.Style')

    # Fix NSAttributedStringKey -> NSAttributedString.Key
    text.gsub!('NSAttributedStringKey', 'NSAttributedString.Key')

    File.write(text_viewer_file, text)
    puts "✅ Patched TvOSTextViewer for Swift 6 compatibility"
  end
end

