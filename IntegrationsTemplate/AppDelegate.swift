//
//  AppDelegate.swift
//  IntegrationsTemplate
//
//  Created by user on 26.03.21.
//

import UIKit
import FBSDKCoreKit
import Adapty
import AppsFlyerLib
import os.log

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // API KEYS & IDs
    private let appUserId: String? = "<app user id> (optional)"
    private let appleAppID = "<apple app id> (e.g. '1234567890')"
    
    private let adaptyApiKey = "<adapty api key>"
    private let appsFlyerDevKey = "<appsflyer dev key>"

    private func setupFacebook(_ application: UIApplication,
                               didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        Settings.setAdvertiserTrackingEnabled(true)
        Settings.isAutoLogAppEventsEnabled = false
        Settings.isAdvertiserIDCollectionEnabled = true
        
        /*
         ВАЖНО: в Info.plist добавить конфигурацию для фэйсбука
         Опционально: Facebook SKAdNetwork IDs
         
         <key>CFBundleURLTypes</key>
         <array>
             <dict>
                <key>CFBundleURLSchemes</key>
                <array>
                    <string>fb123456789000000</string>
                </array>
             </dict>
         </array>
         <key>FacebookAdvertiserIDCollectionEnabled</key>
         <true/>
         <key>FacebookAutoLogAppEventsEnabled</key>
         <false/>
         <key>FacebookAppID</key>
         <string>123456789000000</string>
         <key>FacebookDisplayName</key>
         <string>YOUR APP DISPLAY NAME ON FACEBOOK</string>

         <key>SKAdNetworkItems</key>
         <array>
             <dict>
                 <key>SKAdNetworkIdentifier</key>
                 <string>v9wttpbfk9.skadnetwork</string>
             </dict>
             <dict>
                 <key>SKAdNetworkIdentifier</key>
                 <string>n38lu8286q.skadnetwork</string>
             </dict>
         </array>

         */
    }

    private func setupAdapty() {
        Adapty.activate(adaptyApiKey, observerMode: true, customerUserId: appUserId)
        
        let params = ProfileParameterBuilder()
            .withFacebookAnonymousId(FBSDKCoreKit.AppEvents.anonymousID)
        
        Adapty.updateProfile(params: params)
    }
    
    
    private func setupAppsflyer() {
        let appsflyer = AppsFlyerLib.shared()
        appsflyer.appsFlyerDevKey = appsFlyerDevKey
        appsflyer.appleAppID = appleAppID
        appsflyer.customerUserID = appUserId
        appsflyer.delegate = self
        
        /*
         Set isDebug to true to see AppsFlyer debug logs
         This should only be used in development environment!
         */
        appsflyer.isDebug = true
        
        
        /*
         Вместо подписки на нотификацию можно перегрузить метод applicationDidBecomeActive
         и использовать код ниже (но убедитесь, что он вызывается, бывает, что он не вызывается из-за UIScene
         
         func applicationDidBecomeActive(_ application: UIApplication) {
            AppsFlyerLib.shared().start()
         }
         
         */
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appsflyerStart),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    
    @objc
    private func appsflyerStart() {
        AppsFlyerLib.shared().start()
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 1. Facebook
        setupFacebook(application, didFinishLaunchingWithOptions: launchOptions)

        // 2. Adapty
        setupAdapty()
        
        // 3. Appsflyer
        setupAppsflyer()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

extension AppDelegate: AppsFlyerLibDelegate {
    private func printAppsflyerAttribution(_ data: [AnyHashable: Any]) {
        if let status = data["af_status"] as? String {
            if status == "Non-organic" {
                if let sourceId = data["media_source"] as? String,
                   let campaign = data["campaign"] as? String {
                    os_log("[APPSFLYER] This is a Non-Organic install. Media source: %{public}@ Campaign: %{public}@",
                           sourceId,
                           campaign)
                }
            } else {
                os_log("[APPSFLYER] This is an organic install.")
            }
            
            if let isFirstLaunch = data["is_first_launch"],
               let launchCode = isFirstLaunch as? Int {
                if launchCode == 1 {
                    os_log("[APPSFLYER] First Launch")
                } else {
                    os_log("[APPSFLYER] Not First Launch")
                }
            }
        }
    }
    
    // MARK: AppsFlyerTrackerDelegate implementation
    
    // Handle Conversion Data (Deferred Deep Link)
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        Adapty.updateAttribution(data,
                                 source: .appsflyer,
                                 networkUserId: AppsFlyerLib.shared().getAppsFlyerUID())
        
        printAppsflyerAttribution(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        print("\(error)")
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        print("\(error)")
    }
}
