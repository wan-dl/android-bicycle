//
//  utis_path.swift
//  aBicycle
//
//  Created by 1 on 8/6/23.
//

import Foundation

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
