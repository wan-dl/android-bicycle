//
//  SettingsView.swift
//  aBicycle
//
//  Created by 1 on 8/4/23.
//

import SwiftUI

struct SettingsView: View {
    
    private enum Tabs: Hashable {
        case general
        case tools
    }
    
    var body: some View {
        TabView {
            SettingsGeneralView()
                .tabItem {
                    Label(LocalizedStringKey("lproj_setting_menu_General"), systemImage: "gear")
                }
                .tag(Tabs.general)
            
            SettingsToolsView()
                .tabItem {
                    Label(LocalizedStringKey("lproj_setting_menu_tool"), systemImage: "square.and.pencil")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
        .environment(\.locale, .init(identifier: appDefaultLanguage))
    }
    
}
