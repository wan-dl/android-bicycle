//
//  ContentView.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import SwiftUI

// 应用程序左侧导航入口
enum SidebarNavName {
    case App
    case install
    case Emulator
    case AdbLogcat
    case apkanalyzer
}


struct MainView: View {
    
    @EnvironmentObject private var appDelegate: AppDelegate
    @EnvironmentObject var GlobalVal: GlobalObservable
    
    @State var isShowSilder: Bool = true
    
    @State var activeNav: SidebarNavName = .apkanalyzer
    
    var body: some View {
        HSplitView {
            if isShowSilder {
                left_view
                    .padding()
                    .frame(width: 240, alignment: .topLeading)
                    .frame(minWidth: 200, maxWidth: 240, minHeight: 200 ,maxHeight: .infinity, alignment: .topLeading)
                    .background(.gray.opacity(0.01))
            }
            right_view
                .frame(minWidth: 500, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity, alignment: .topLeading)
                .background(.white)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                HStack {
                    // 工具栏：折叠图标
                    showSilder
                    // 当前连接的设备
                    DropdownAndroidDevice()
                }
            }
        }
        .environment(\.locale, .init(identifier: appDefaultLanguage))
    }
                                
    var left_view: some View {
        VStack(alignment: .leading) {
            sidebar(title: "lproj_NavApkAnalyzer", systemImage: "waveform.and.magnifyingglass", isActive: activeNav == .apkanalyzer, action: { self.activeNav = .apkanalyzer })
            sidebar(title: "lproj_NavAppInstall", systemImage: "wrench.and.screwdriver", isActive: activeNav == .install, action: { self.activeNav = .install })
            sidebar(title: "lproj_NavAppManagement", systemImage: "gearshape.2", isActive: activeNav == .App, action: { self.activeNav = .App })
            sidebar(title: "lproj_NavEmulator", systemImage: "list.bullet.below.rectangle", isActive: activeNav == .Emulator, action: { self.activeNav = .Emulator })
            sidebar(title: "Adb Logcat", systemImage: "doc.text", isActive: activeNav == .AdbLogcat, action: { self.activeNav = .AdbLogcat })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var right_view: some View {
        Section {
            switch(self.activeNav) {
            case .App:
                AppPackagesView()
            case .install:
                AppInstallView()
            case .Emulator:
                EmulatorView()
            case .AdbLogcat:
                AdbLogcatView()
            case .apkanalyzer:
                ApkAnalyzerView()
            }
        }
    }
    
    // 工具栏：折叠图标
    var showSilder: some View {
        Button {
            self.isShowSilder.toggle()
        } label: {
            Label("", systemImage: "sidebar.left")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
