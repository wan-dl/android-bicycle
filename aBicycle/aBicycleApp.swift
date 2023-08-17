//
//  aBicycleApp.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import SwiftUI


@main
struct aBicycleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(GlobalObservable())
                //.environment(\.locale, .init(identifier: appDefaultLanguage))
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
