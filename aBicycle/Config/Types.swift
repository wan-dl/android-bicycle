//
//  Types.swift
//  aBicycle
//
//  Created by 1 on 8/8/23.
//

import Foundation


struct EmulatorItem: Identifiable {
    let name: String
    let id = UUID().uuidString
}


struct AndroidDeviceItem: Identifiable, Hashable {
    var model: String
    var serialno: String
    let id = UUID()
}

// 用于avdmanager list avd输出
struct AvdItem: Identifiable {
    var Name: String
    var Version: String = ""
    var ABI: String = ""
    var Device: String = ""
    var Path: String = ""
    var Target: String = ""
    var Skin: String = ""
    var id = UUID().uuidString
}

// 应用包信息
struct AppPackageInfo: Identifiable, Hashable {
    let name: String
    let id = UUID()
}
