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

struct SettingsGeneralView: View {
    @State var ConfigAndroidHOME: String = ""
    @State var ConfigEmulatorPath: String = ""
    @State var ConfigADBPath: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Form {
                TextField(text: $ConfigAndroidHOME, prompt: Text("")) {
                    Text("Android_HOME")
                }
                TextField(text: $ConfigEmulatorPath, prompt: Text("")) {
                    Text("emulator路径")
                }
                TextField(text: $ConfigADBPath, prompt: Text("")) {
                    Text("ADB路径")
                }
            }
        }
    }
}
