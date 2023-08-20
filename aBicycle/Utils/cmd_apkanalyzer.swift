//
//  cmd_apkanalyzer.swift
//  aBicycle
//
//  Created by 1 on 8/17/23.
//

import Foundation


class ApkAnalyzerManage {
    static var apkanalyzerPath: String?
    
    // 获取apkanalyzer路径
    static func getApkanalyzerPathPath() async throws -> String {
        if let path = apkanalyzerPath, !isChangeAppSettingsValue {
            return path
        }
        
        do {
            let cmd = CommandLineManager()
            let toolPath = try await cmd.getToolPath(toolName: "apkanalyzer")
            apkanalyzerPath = toolPath
            return toolPath
        } catch {
            throw error
        }
    }
    
    // 获取apk基本信息
    static func printManifest(apkPath: String, isRawOutput: Bool = false) async throws -> String {
        let _ = try await getApkanalyzerPathPath()
        let args = ["manifest", "print", apkPath]
        guard let outputList = try await run_simple_command(executableURL: apkanalyzerPath!, arguments: args) else {
            throw AppError.ExecutionFailed(message: "Failed to execute the command")
        }
        if isRawOutput {
            return outputList.joined(separator: "\n")
        }
        return ""
    }
    
}
