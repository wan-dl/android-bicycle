//
//  cmd_avdmanager.swift
//  aBicycle
//
//  Created by 1 on 8/8/23.
//

import Foundation


class AVDManager {
    static var avdmanagerPath: String?
    
    // 获取avdmanager路径
    static func getAvdmanagerPathPath() async throws -> String {
        if let path = avdmanagerPath, !isChangeAppSettingsValue {
            return path
        }
        
        do {
            let cmd = CommandLineManager()
            let toolPath = try await cmd.getToolPath(toolName: "avdmanager", settingKey: "ConfigAvdmanagerPath")
            avdmanagerPath = toolPath
            return toolPath
        } catch {
            throw error
        }
    }
    
    // 获取avd列表
    static func getAvdList() async throws -> [AvdItem] {
        let _ = try await getAvdmanagerPathPath()
        guard let output = try await run_simple_command(executableURL: avdmanagerPath!, arguments: ["list", "avd"]) else {
            throw AppError.ExecutionFailed(message: "Failed to execute the command")
        }
        
        let outputStr = output.joined(separator: ", ")
        if !output.isEmpty && outputStr.contains("Name:") && outputStr.contains("Path:") {
            return try await ParseAvdmanagerOutput.parseAvdList(lines: output)
        }
        return []
    }
    
    // 删除
    static func delete(name: String) async throws -> Bool {
        guard let output = try await run_simple_command(executableURL: avdmanagerPath!, arguments: ["delete", "avd3", "-n", name]) else {
            throw AppError.ExecutionFailed(message: "Failed to execute the command")
        }
        let outputStr = output.joined(separator: ", ")
        print("[删除结果] \(outputStr)")
        if !output.isEmpty && !outputStr.contains("deleted") {
            throw AppError.FailedToDeleteAvd
        }
        return true
    }
}


// 解析avdmanager list avd命令行输出
class ParseAvdmanagerOutput {
    
    static func parseAvdList(lines: [String]) async throws -> [AvdItem] {
        var avdLastList: [AvdItem] = []
        var avdList: [[String: String]] = []
        
        do {
            var currentAvd: [String: String] = [:]
            for (index, line) in lines.enumerated() {
                if line.contains("Name:") {
                    if !currentAvd.isEmpty {
                        avdList.append(currentAvd)
                    }
                    currentAvd = [:]
                }
                let keyValue = extractKeyValue(from: line)
                if keyValue != nil, let tuple = keyValue {
                    currentAvd[tuple.key] = tuple.value
                }
                if line.contains("Based on:") {
                    let baseOnInfo = extractStringAndroidVersion(prefix: "Based on: ", suffix: " Tag/ABI: ", from: line)
                    if let version = baseOnInfo {
                        currentAvd["AndroidVersion"] = version
                    }
                }
                if line.contains("Tag/ABI:") {
                    if let range = line.range(of: "Tag/ABI:") {
                        let startIndex = range.upperBound
                        let ABI = String(line[startIndex...])
                        currentAvd["ABI"] = ABI
                    }
                }
                if index == lines.count - 1 {
                    if !currentAvd.isEmpty {
                        avdList.append(currentAvd)
                    }
                }
            }
        } catch let error {
            throw error
        }
        
        if !avdList.isEmpty {
            avdLastList = avdList.compactMap { avdData in
                guard let name = avdData["Name"],
                      let device = avdData["Device"],
                      let path = avdData["Path"],
                      let ABI = avdData["ABI"],
                      let Version = avdData["AndroidVersion"],
                      let target = avdData["Target"],
                      let skin = avdData["Skin"] else {
                          return nil
                }
                return AvdItem(Name: name, Version: Version, ABI: ABI, Device: device, Path: path, Target: target, Skin: skin)
            }
        }
        return avdLastList
    }
    
    private static func extractKeyValue(from line: String) -> (key: String, value: String)? {
        let components = line.split(separator: ":", maxSplits: 1)
        guard components.count == 2 else {
            return nil
        }
        let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let value = String(components[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (key, value)
    }
    
    private static func extractStringAndroidVersion(prefix: String, suffix: String, from input: String) -> String? {
        do {
            let pattern = "\(prefix)(.*?)(\(suffix))"
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                let range = Range(match.range(at: 1), in: input)!
                return String(input[range])
            }
        } catch {
            print("Error creating regular expression: \(error)")
        }
        return nil
    }
}

