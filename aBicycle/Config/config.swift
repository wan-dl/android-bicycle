//
//  config.swift
//  aBicycle
//
//  Created by 1 on 8/6/23.
//

import Foundation

// 应用程序配置文件，主要用来存储自定义设置
public let appSettingFileName: String = ".settings.json"


// 应用程序设置是否发生改变
public var isChangeAppSettingsValue: Bool = false


// 定义配置项：命令行工具名称和设置项的关联
var SettingsConfigOptions: [String: String] = [
    "adb": "ConfigADBPath",
    "emulator": "ConfigEmulatorPath",
    "avdmanager": "ConfigAvdmanagerPath",
]
