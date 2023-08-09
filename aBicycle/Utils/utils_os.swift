//
//  utils_os.swift
//  aBicycle
//
//  Created by 1 on 8/9/23.
//

import Cocoa
import Foundation


// 打开操作系统finder选择目录
func OpenFinderSelectDirectory() -> URL? {
    let dialog = NSOpenPanel()
    dialog.canChooseFiles = false
    dialog.canChooseDirectories = true
    dialog.allowsMultipleSelection = false
    
    if dialog.runModal() == NSApplication.ModalResponse.OK {
        return dialog.urls.first
    } else {
        return nil
    }
}


// 打开操作系统Finder
func RevealInFinder(at fpath: String) {
    let url = URL(fileURLWithPath: "/")
    NSWorkspace.shared.selectFile(fpath, inFileViewerRootedAtPath: url.path)
}


// 复制文件路径到剪切板
func copyToPasteboard(at data: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(data, forType: .string)
}
