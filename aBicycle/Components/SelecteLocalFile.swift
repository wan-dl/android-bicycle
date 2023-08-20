//
//  SelecteLocalFile.swift
//  aBicycle
//
//  Created by 1 on 8/17/23.
//

import SwiftUI

struct SelecteLocalFile: View {
    @Binding var filepath: String
    @Binding var isDoing: Bool
    
    var body: some View {
        HStack {
                
            TextField("Selecte Local APK File", text: $filepath)
                .textFieldStyle(PlainTextFieldStyle())
                .disabled(isDoing)
                .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .padding(.top, 25)
                            .foregroundColor(.gray.opacity(0.3))
                    )
            
            
            if !filepath.isEmpty {
                Button(action: {
                    self.filepath = ""
                }, label: {
                    Label("",systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                })
                .buttonStyle(.plain)
                .disabled(isDoing)
            }
            
            Button("lproj_apk_analyzer_select_btn") {
                selectedApk()
            }
            .buttonStyle(.automatic)
            .disabled(isDoing)
        }
    }
    
    private func selectedApk() {
        openAPKFilePicker { filePath in
            if let fpath = filePath {
                filepath = fpath
            }
        }
    }
}

