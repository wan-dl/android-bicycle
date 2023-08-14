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
    }
    
    var body: some View {
        TabView {
            SettingsGeneralView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
    }
    
}
