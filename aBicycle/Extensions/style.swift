//
//  style.swift
//  aBicycle
//
//  Created by 1 on 8/9/23.
//

import SwiftUI

// 启动和停止按钮悬停样式
struct avdBootButtonStyle: ButtonStyle {
    var avd_name: String
    @Binding var isHover: String
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.self.label
            .frame(width: 35, height: 25)
            .background(isHover == avd_name ? Color.gray.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .onHover { isHovered in
                isHover = isHovered ? avd_name : ""
            }
            .opacity(configuration.isPressed ? 0.8 : 1.0) // 按钮按下时降低不透明度
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // 按钮按下时缩小
    }
}
