//
//  SearchTextField.swift
//  aBicycle
//
//  Created by 1 on 8/11/23.
//

import SwiftUI

struct SearchTextField: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                //.padding(.leading, 10)
                
            TextField("Filter", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }, label: {
                    Label("",systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.black.opacity(0.5))
                })
                .buttonStyle(.plain)
                //.padding(.trailing, 10)
            }
        }
        .padding(.top, 20)
    }
}
