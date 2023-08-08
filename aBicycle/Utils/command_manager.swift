//
//  command_manager.swift
//  aBicycle
//
//  Created by 1 on 8/8/23.
//

import Foundation


class CommandLineManager {
    var toolPath: String?
    
    func getToolPath(toolName: String, settingKey: String) async throws -> String {
        let readResult = getSettingValue(key: settingKey)
        if readResult == nil {
            toolPath = try await run_simple_command(executableURL: "", arguments: ["-c", "-l", "which \(toolName)"])?.first ?? ""
        } else {
            toolPath = readResult
            if !isPathValid(toolPath!, endsWith: toolName) {
                throw AppError.CustomPathVaild
            }
        }
        
        if toolPath!.isEmpty {
            throw AppError.PathNotFound
        }
        print("path: \(toolPath!)")
        return toolPath!
    }
}
