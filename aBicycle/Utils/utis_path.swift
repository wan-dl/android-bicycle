//
//  utis_path.swift
//  aBicycle
//
//  Created by 1 on 8/6/23.
//

import Foundation
import SwiftUI

// 判断路径是否有效，且以特定字符结束
func isPathValid(_ path: String, endsWith suffix: String? = nil) -> Bool {
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: path) {
        if let suffix = suffix {
            return path.hasSuffix(suffix)
        } else {
            return true
        }
    }
    
    return false
}


// 判断目录是否有效
func isDirectoryValid(atPath path: String) -> Bool {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    
    if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
        return isDirectory.boolValue
    } else {
        return false
    }
}

//  从本地选择apk文件
func openAPKFilePicker(completion: @escaping (String?) -> Void) {
    let openPanel = NSOpenPanel()
    openPanel.title = "Choose an APK File"
    openPanel.allowedFileTypes = ["apk"]
//        openPanel.allowedContentTypes = []
    openPanel.allowsMultipleSelection = false

    if openPanel.runModal() == .OK, let url = openPanel.url {
        completion(url.path)
    } else {
        completion(nil)
    }
}

// 获取文件大小，单位MB
func getFileSizeInMB(atPath filePath: String) -> Double? {
    guard let fileSize = try? FileManager.default.attributesOfItem(atPath: filePath)[.size] as? Double else {
        return nil
    }
    return fileSize / 1024.0 / 1024.0
}

