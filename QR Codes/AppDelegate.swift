//
//  AppDelegate.swift
//  QR Codes
//
//  Created by Kyle Howells on 31/12/2019.
//  Copyright © 2019 Kyle Howells. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		// - Fix stupid default transparent iOS 15 tab bar
		if #available(iOS 13.0, *) {
			let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
			tabBarAppearance.configureWithOpaqueBackground()
			UITabBar.appearance().standardAppearance = tabBarAppearance
			
			if #available(iOS 15.0, *) {
				UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
			}
		}
		
		// - Fix stupid default transparent iOS 15 navigation bar
		if #available(iOS 14, *) {
			let appearance: UINavigationBarAppearance = UINavigationBarAppearance()
			appearance.configureWithOpaqueBackground()
			
			UINavigationBar.appearance().standardAppearance = appearance
			UINavigationBar.appearance().scrollEdgeAppearance = appearance
		}
		
		return true
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

}
