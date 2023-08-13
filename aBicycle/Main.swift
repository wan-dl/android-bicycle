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
}


struct MainView: View {
    
    @EnvironmentObject private var appDelegate: AppDelegate
    @EnvironmentObject var GlobalVal: GlobalObservable
    
    @State var isShowSilder: Bool = true
    
    @State var activeNav: SidebarNavName = .install
    
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
    }
                                
    var left_view: some View {
        VStack(alignment: .leading) {
            sidebar(title: "应用管理", systemImage: "doc.plaintext", isActive: activeNav == .App, action: { self.activeNav = .App })
            sidebar(title: "应用安装", systemImage: "doc.plaintext", isActive: activeNav == .install, action: { self.activeNav = .install })
            sidebar(title: "Emulator", systemImage: "doc.plaintext", isActive: activeNav == .Emulator, action: { self.activeNav = .Emulator })
            //sidebar(title: "Adb Logcat", systemImage: "doc.plaintext", isActive: activeNav == .AdbLogcat, action: { self.activeNav = .AdbLogcat })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var right_view: some View {
        Section {
            switch(self.activeNav) {
            case .App:
                AppPackages()
            case .install:
                AppInstall()
            case .Emulator:
                EmulatorView()
            case .AdbLogcat:
                AdbLogcatView()
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
