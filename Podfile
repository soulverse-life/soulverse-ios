source 'https://github.com/CocoaPods/Specs.git'
# Uncomment the next line to define a global platform for your project
 platform :ios, '14.0'


abstract_target 'Base' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Moya', '~> 15.0'
  pod 'SnapKit', '~> 5.7.0'
  pod 'Kingfisher', '~> 8.3.0'
  pod 'NVActivityIndicatorView'
  pod 'lottie-ios'
  pod 'DateToolsSwift'
  pod 'IQKeyboardManagerSwift'
  pod 'Toaster'
  pod 'DeviceKit', '~> 5.2'
  pod 'SwiftMessages'
  pod 'SwiftRichString'
  pod 'GoogleSignIn'
  
  pod 'UICircularProgressRing'
  pod 'DGCharts', '~> 5.1.0'
  
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Messaging'
  pod 'GoogleUtilities'
  
  
  pod 'Popover'
  pod 'KeychainAccess'
  
  target 'Soulverse'
  target 'Soulverse Dev'
  
  target 'SoulverseTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Firebase'
    pod 'GoogleUtilities'
  end

  target 'SoulverseUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      end
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end

  end
end

