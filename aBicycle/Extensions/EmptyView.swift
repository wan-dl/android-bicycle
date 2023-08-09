//
//  EmptyView.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import SwiftUI

struct EmptyView: View {
    var text: String
    
    var body: some View {
        VStack {
            Spacer()
            Image("android")
                .resizable()
                .frame(width: 24, height: 24)
            Text(text)
                .font(.title2)
                .fontWeight(.light)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
