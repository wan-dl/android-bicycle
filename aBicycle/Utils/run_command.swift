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
func run_simple_command(executableURL: String, arguments: [String], action: String = "") async throws -> [String]? {
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
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            return nil
        }

        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
        let outPutList = output?.components(separatedBy: .newlines) ?? []
        return outPutList
    } catch let error {
        throw error
    }
}
