//
//  SettingsGeneralView.swift
//  aBicycle
//
//  Created by 1 on 8/14/23.
//

import SwiftUI


struct SettingsGeneralView: View {
    
    let languages = ["en", "zh-Hans"]
    
    @State var selectedLanguage: String
    @State var message: String = ""
    @State var showMsgAlert: Bool = false
    
    
    init() {
        self.selectedLanguage = appDefaultLanguage
    }
    
    var body: some View {
        VStack {
            Picker("lproj_setting_SelectLanguage", selection: $selectedLanguage) {
                ForEach(languages, id: \.self) { lang in
                    Text(lang)
                }
            }
            .pickerStyle(.menu)
            .focusable(false)
            .onChange(of: selectedLanguage) { newIndex in
                updateAppLanguage()
            }
        }
        .padding()
        .alert("提示", isPresented: $showMsgAlert) {
            Button("关闭", role: .cancel) { }
        } message: {
            Text(message)
        }
    }
    
    func updateAppLanguage() {
        do {
            _ = try SettingsHandler.writeJsonFile(key: "appDefaultLanguage", value: selectedLanguage)
        } catch {
            DispatchQueue.main.async {
                showMsgAlert = true
                message = NSLocalizedString("lproj_setting_general_fail_message", comment: "")
            }
        }
    }
    
}


