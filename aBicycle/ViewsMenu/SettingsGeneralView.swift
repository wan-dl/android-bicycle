//
//  SettingsGeneralView.swift
//  aBicycle
//
//  Created by 1 on 8/14/23.
//

import SwiftUI


struct SettingsGeneralView: View {
    
    @State private var selectedLanguage = "en"
    
    let languages = ["en", "zh-Hans"]
    
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
                
            }
        }
        .padding()
    }
    
    func updateAppLanguage(newLanguage: String) {
    }
    
}


