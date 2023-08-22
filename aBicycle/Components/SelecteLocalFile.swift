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
                .modifier(ClearButton(text: $filepath))
                .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .padding(.top, 25)
                            .foregroundColor(.gray.opacity(0.3))
                    )
            
            Spacer()
            
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


fileprivate struct ClearButton: ViewModifier {
    @Binding var text: String

    public func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            content

            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Label("", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding(.trailing, 8)
                .buttonStyle(.plain)
            }
        }
    }
}
