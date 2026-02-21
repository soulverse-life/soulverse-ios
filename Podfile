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
  pod 'Hero'
  pod "PostHog", "~> 3.0"
  
  pod 'UICircularProgressRing'
  pod 'DGCharts', '~> 5.1.0'
  
  # Add the Firebase pod for Google Analytics
  pod 'FirebaseAnalytics'

  # Add the pods for any other Firebase products you want to use in your app
  # For example, to use Firebase Authentication and Cloud Firestore
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Messaging'
  pod 'FirebaseStorage'
  pod 'GoogleUtilities'
  
  
  pod 'Popover'
  pod 'KeychainAccess'
  pod 'AlignedCollectionViewFlowLayout'

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
          # Suppress warnings from Pods
          config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
          config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
      end
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end

  end
end

