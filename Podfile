# Internet Archive Apple TV
# Platform: tvOS 17.0+ (minimum for modern SwiftUI and async/await features)
platform :tvos, '17.0'

target 'Internet Archive' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Internet Archive
  pod 'Alamofire'
  pod 'AlamofireImage', '~> 3.3'
  pod 'SVProgressHUD', :git => 'https://github.com/SVProgressHUD/SVProgressHUD.git'
  pod 'TvOSMoreButton', '~> 1.1.1'
  pod 'TvOSTextViewer', '~> 1.1.1'
  pod 'MBProgressHUD', '~> 1.1.0'

  # Development tools
  pod 'SwiftLint', :configurations => ['Debug']
end

# Post install hook to configure build settings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Set minimum deployment target
      config.build_settings['TVOS_DEPLOYMENT_TARGET'] = '17.0'

      # Disable library evolution/module stability for faster builds
      # Enable (set to 'YES') only if distributing frameworks
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
    end
  end
end

