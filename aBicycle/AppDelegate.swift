//
//  AppDelegate.swift
//  aBicycle
//
//  Created by 1 on 8/17/23.
//

import Foundation
import SwiftUI


class GlobalObservable: ObservableObject {
    @Published var currentSerialno: String = ""
    @Published var isEmulatorStart: Int = 0
    @Published var isEmulatorStop: Int = 0
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    @Published var statusBarItem: NSStatusItem?
    var mainWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] --> applicationWillFinishLaunching")
        do {
            let fileContent: [String: Any] = try SettingsHandler.readJsonFileAll(defaultValue: [:])
            if !fileContent.isEmpty {
                if let configLanguage = fileContent["appDefaultLanguage"] as? String {
                    appDefaultLanguage = configLanguage
                }
            }
        } catch {
            print("[applicationWillFinishLaunching] 读取自定义配置发生错误")
        }
    }
    
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
    
    // 在应用关闭时执行的方法
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("-->", AdbLogcat().stop())
        print("App is closing. Perform cleanup here.")
        return .terminateNow
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



