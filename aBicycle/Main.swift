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
    case Emulator
    case AdbLogcat
}

struct MainView: View {
    
    @EnvironmentObject private var appDelegate: AppDelegate
    
    @State var isShowSilder: Bool = true
    
    @State var activeNavName: SidebarNavName = .App
    
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
                    
                    DropdownAndroidDevice()
                }
            }
        }
    }
                                
    var left_view: some View {
        VStack(alignment: .leading) {
            sidebar(title: "应用管理", systemImage: "doc.plaintext", help: "应用管理", isActive: activeNavName == .App, action: { self.activeNavName = .App })
            sidebar(title: "Emulator", systemImage: "doc.plaintext", help: "Andriod Studio模拟器", isActive: activeNavName == .Emulator, action: { self.activeNavName = .Emulator })
            //sidebar(title: "Adb Logcat", systemImage: "doc.plaintext", help: "Logcat", isActive: activeNavName == .AdbLogcat, action: { self.activeNavName = .AdbLogcat })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var right_view: some View {
        Section {
            switch(self.activeNavName) {
            case .App:
                AppPackages()
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
