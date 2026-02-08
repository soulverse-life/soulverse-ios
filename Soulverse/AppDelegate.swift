//
//  AppDelegate.swift
//
import FirebaseCore
import IQKeyboardManagerSwift
import IQKeyboardToolbar
import IQKeyboardToolbarManager
import PostHog
import Toaster
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var appTracker: CoreTracker?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        initSDK()
        setTrackingAgent()

        application.beginReceivingRemoteControlEvents()

        UNUserNotificationCenter.current().delegate = self

        //UIApplication.shared.registerForRemoteNotifications()

        setDefaultToastAppearance()
        checkNotificationPermission()

        // Enable IQKeyboardManager
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true

        // Enable toolbar with chevron down button
        IQKeyboardToolbarManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.toolbarConfiguration.doneBarButtonConfiguration = IQBarButtonItemConfiguration(systemItem: .done)

        return true
    }
    
    private func initSDK() {
        setupFirebase()
        setupPosthog()
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
    
    private func setupPosthog() {
        let POSTHOG_API_KEY = "phc_ckwtsY0ZYVnJVzhTtANgsWfyesA2zK9AP1fyvphg9eD"
        let POSTHOG_HOST = "https://us.i.posthog.com"

        let config = PostHogConfig(apiKey: POSTHOG_API_KEY, host: POSTHOG_HOST)

#if DEBUG
        config.sessionReplay = false
#else
        // Session replay only enabled in release builds
        // check https://posthog.com/docs/session-replay/installation?tab=iOS
        config.sessionReplay = true
        config.sessionReplayConfig.maskAllImages = false
        config.sessionReplayConfig.maskAllTextInputs = false
        config.sessionReplayConfig.screenshotMode = true
#endif

        PostHogSDK.shared.setup(config)
    }
    
    func setTrackingAgent() {
        // TODO: Use factory to build the tracker for individual target
        appTracker = TrackingService.shared
    }
    

    private func setDefaultToastAppearance() {
        
        let appearance = ToastView.appearance()
        appearance.backgroundColor = .primaryWhite
        appearance.textColor = .primaryBlack
        appearance.bottomOffsetPortrait = 80
        appearance.shadowColor = .black
        appearance.shadowOpacity = 0.4
        appearance.shadowOffset = CGSize(width: 0, height: 2)
        appearance.shadowRadius = 4
        
    }
    
    
    private func checkNotificationPermission() {

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .denied {
                // Todo: Handle the user not enable the notification
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            
#if DEBUG
        let deviceTokenString = deviceToken.reduce("") {
            $0 + String(format: "%02x", $1)
        }
        print("deviceToken", deviceTokenString)
#endif
        
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle user tapping remote notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        AppCoordinator.inAppRouting(userInfo as? [String: Any])
        //print(content.userInfo)
        completionHandler()
    }
    
    // show the notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner])
        } else {
            // Fallback on earlier versions
        }
    }
}
