//
//  sidebar.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import SwiftUI

// 左侧导航视图：按钮样式
private struct LeftNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.vertical, 3)
            .padding(.leading, 10)
            .cornerRadius(5)
            .background(.clear)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct sidebar: View {
    let title: String
    let systemImage: String
    let help: String = ""
    let isActive: Bool
    let action: () -> Void
    
    @State private var isHover: Bool = false

    var body: some View {
        Button(action: {
            action()
        }, label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        })
        .help(help)
        .frame(height: 30)
        .buttonStyle(LeftNavButtonStyle())
        // 使用focusable解决应用程序首次启动 此入口出现蓝边的问题
        .focusable(false)
        .foregroundColor(isActive ? .blue : .gray)
        .background(isHover ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(5)
        .onHover { isHovered in
            isHover = isHovered
        }
        
    }
}
