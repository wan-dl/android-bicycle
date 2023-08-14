//
//  command_manager.swift
//  aBicycle
//
//  Created by 1 on 8/8/23.
//

import Foundation


/**
 1. 优先读取配置文件
 2. 如果未配置，则使用which xxx获取
 */
class CommandLineManager {
    
    var toolPath: String?
    var configFileContent: [String: Any] = [:]
    
    func getToolPath(toolName: String) async throws -> String {
        
        try readConfigFile(toolName: toolName)
        
        if toolPath == nil {
            let cmdResult = try await run_simple_command(executableURL: "", arguments: ["-c", "-l", "which \(toolName)"])?.first ?? ""
            if !isPathValid(cmdResult) {
                throw AppError.PathNotFound(message: "\(toolName) path not found")
            }
            toolPath = cmdResult
        }
        
        print("path-->: \(toolPath!)")
        return toolPath!
    }
    
    // 读取配置文件
    private func readConfigFile(toolName: String) throws {
        self.configFileContent = try SettingsHandler.readJsonFileAll(defaultValue: [:])
        
        if configFileContent.isEmpty {
            return
        }
        
        if let cfgName = SettingsConfigOptions[toolName] {
            if let cfgPath = self.configFileContent[cfgName] as? String {
                toolPath = cfgPath
            } else {
                useConfigAndroidHome(toolName: toolName)
            }
        }
        
        if toolPath != nil {
            if !isPathValid(toolPath!, endsWith: toolName) {
                throw AppError.CustomPathVaild
            }
        }
    }
    
    // 使用Android Home拼接工具路径
    private func useConfigAndroidHome(toolName: String) {
        if let AndroidHome = self.configFileContent["ConfigAndroidHOME"] as? String {
            let basePath = URL(string: AndroidHome)!
            let fileName = "platform-tools/adb"
            let fullPath = basePath.appendingPathComponent(fileName).path
            if isPathValid(fullPath) {
                toolPath = fullPath
            }
        }
    }
}
