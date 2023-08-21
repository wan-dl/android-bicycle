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
    let help: String
    let isActive: Bool
    let action: () -> Void
    
    @State private var isHover: Bool = false
    @State private var imgBgColor: Color = .white
    
    init(title: String, systemImage: String, help: String = "", isActive: Bool, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.help = help
        self.isActive = isActive
        self.action = action
        _imgBgColor = State(initialValue: Self.getColor(for: systemImage))
    }
       
    private static func getColor(for systemImage: String) -> Color {
        if systemImage == "list.bullet.below.rectangle" {
            return .orange
        } else if systemImage == "doc.text" {
            return .indigo
        } else {
            return .blue
        }
    }

    var body: some View {
        HStack() {
            Button(action: {
                action()
            }, label: {
                HStack {
                    Image(systemName: self.systemImage)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(imgBgColor)
                        .cornerRadius(5)
                        .padding(.leading, 10)
                        
                    Text(LocalizedStringKey(title))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            })
            .help(help)
            .buttonStyle(.plain)
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .background(isActive ? Color.gray.opacity(0.2) : Color.clear)
            .cornerRadius(5)
            .focusable(false)
            .onHover { isHovered in
                isHover = isHovered
            }
        }
        .padding(.horizontal, 17)
    }
}
