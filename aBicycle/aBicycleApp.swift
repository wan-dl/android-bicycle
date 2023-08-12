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
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}


class GlobalObservable: ObservableObject {
    @Published var currentSerialno: String = ""
    @Published var isEmulatorStart: Int = 0
    @Published var isEmulatorStop: Int = 0
}


class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    @Published var statusBarItem: NSStatusItem?
    var mainWindow: NSWindow? // 存储主窗口的引用
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏项目
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusBarItem?.button {
            // 设置状态栏图标
            button.image = NSImage(named: "StatusBarIcon")
            // 设置状态栏图标的提示信息
            button.toolTip = "Status Bar App"
        }
        
        // 设置状态栏菜单
        let menu = NSMenu()
        menu.addItem(withTitle: "Open App", action: #selector(openApp), keyEquivalent: "")
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        statusBarItem?.menu = menu
    }

    @objc func openApp() {
        NSApp.activate(ignoringOtherApps: true)
        if mainWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.contentView = NSHostingView(rootView: MainView())
            window.makeKeyAndOrderFront(nil)
            mainWindow = window
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
}
