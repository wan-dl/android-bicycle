//
//  run_command.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import Foundation

/**
 运行简单的一些shell命令。
 即shell命令执行后，立即结束获取到结果。
 */
func run_simple_command(executableURL: String, arguments: [String], action: String = "", isWait: Bool = false) async throws -> [String]? {
    let processInfo = ProcessInfo.processInfo
    let environment = processInfo.environment
    var shellPath = environment["SHELL"]  ?? ""
    if (executableURL != "") {
        shellPath = executableURL
    }
    
    let process = Process()
    process.environment = environment
    process.executableURL = URL(fileURLWithPath: shellPath)
    process.arguments = arguments
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        
        if isWait {
            process.waitUntilExit()
            //try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if !process.isRunning {
            guard process.terminationStatus == 0 else {
                return nil
            }
        }

        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
        let outPutList = output?.components(separatedBy: .newlines) ?? []
        return outPutList
    } catch let error {
        print("[run_simple_command() error] \(error)")
        throw error
    }
}



func runCommand(executableURL: String, arguments: [String], action: String = "") throws -> [String]? {
    let processInfo = ProcessInfo.processInfo
    let environment = processInfo.environment
    var shellPath = environment["SHELL"]  ?? ""
    if (executableURL != "") {
        shellPath = executableURL
    }
    
    let process = Process()
    process.environment = environment
    process.executableURL = URL(fileURLWithPath: shellPath)
    process.arguments = arguments
    
    let pipe = Pipe()
    process.standardOutput = pipe

    do {
        try process.run()
        
        if action != "" {
            let outHandle = pipe.fileHandleForReading
            var outputLines: [String] = []
            
            while process.isRunning {
                let data = outHandle.availableData
                if data.count != 0 {
                    // 将二进制数据data转换成String，并去除开头和结尾的换行符，得到一个可选类型的String?
                    let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
                    if !line.isEmpty {
                        outputLines.append(line)
                        if line.contains("ERROR   | Unknown AVD name") || line.contains("INFO    | Started GRPC server at") {
                            break
                        }
                    }
                }
            }
            return outputLines
        }
        
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            return nil
        }
        
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
        let outPutList = output?.components(separatedBy: .newlines) ?? []
        return outPutList
    } catch let error {
        print("[runCommand() error]-> \(error)")
        throw error
    }
}
