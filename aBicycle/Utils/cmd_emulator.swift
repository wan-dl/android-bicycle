//
//  cmd_emulator.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import Foundation

enum EmulatorError: Error {
    case executionFailed
    case emulatorPathNotFound
    case NotFoundemulator
    case FailedToGetProcessInfo
    case FailedToGetProcessID
    case FailedToKillProcess
}

func getErrorMessage(etype: EmulatorError) -> String {
    switch(etype) {
    case .executionFailed:
        return "Emulator command execution failed."
    case .emulatorPathNotFound:
        return "Emulator Path Not Found."
    case .NotFoundemulator:
        return "The emulator list is empty."
    case .FailedToGetProcessInfo:
        return "Failed to get process information."
    case .FailedToGetProcessID:
        return "Failed to get process ID."
    case .FailedToKillProcess:
        return "Failed to kill process"
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
//    process.terminationHandler = { (process) in
//       print("\ndidFinish: \(!process.isRunning)")
//    }
    
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
        throw error
    }
}


class AndroidEmulatorManager {
    static var osEmulatorPath: String?
    
    // 获取模拟器列表
    static func getEmulatorList() async throws -> [String] {
        if osEmulatorPath == nil {
            osEmulatorPath = try runCommand(executableURL: "", arguments: ["-c", "-l", "which emulator"])?.first ?? ""
            if osEmulatorPath!.isEmpty {
                throw EmulatorError.emulatorPathNotFound
            }
            print("path: \(osEmulatorPath!)")
        }
        
        guard let emulatorLists = try runCommand(executableURL: osEmulatorPath!, arguments: ["-list-avds"]) else {
            throw EmulatorError.NotFoundemulator
        }
        
        return emulatorLists
    }
    
    // 获取当前已启动的模拟器列表
    static func getActiveEmulatorList(EmulatorList: [String]) async throws -> [String] {
        let args = ["-af", "-o", "command"]
        guard let psList = try runCommand(executableURL: "/bin/ps", arguments: args) else {
            throw EmulatorError.NotFoundemulator
        }
        
        var ActiveEmulatorList: [String] = []
        if !psList.isEmpty {
            ActiveEmulatorList = EmulatorList.filter { el1 in
                psList.contains { el2 in
                    el2.hasSuffix("-avd \(el1)") || el2.hasSuffix("@\(el1)") || el2.contains(" @\(el1) ") || el2.contains(" -avd \(el1) ")
                }
            }
        }
        return ActiveEmulatorList
    }
    
    // 启动模拟器
    static func startEmulator(emulatorName: String,  completion: @escaping (Bool, Error?) -> Void) {
        if (emulatorName.isEmpty) {
            completion(false, EmulatorError.NotFoundemulator)
            return
        }
        let args = ["-dns-server", "223.5.5.5", "-no-snapshot-save", "-avd", emulatorName]
        DispatchQueue.global(qos: .background).async {
            do {
                guard let emulatorLists = try runCommand(executableURL: osEmulatorPath!, arguments: args, action: "start") else {
                    throw EmulatorError.NotFoundemulator
                }
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }
    
    // 停止模拟器
    static func killEmulator(emulatorName: String) throws -> Bool {
        let args = ["-af"]
        guard let psList = try runCommand(executableURL: "/bin/ps", arguments: args) else {
            throw EmulatorError.FailedToGetProcessInfo
        }
        var info: String = ""
        if !psList.isEmpty {
            for i in psList {
                if i.hasSuffix(" -avd \(emulatorName)") || i.hasSuffix("@\(emulatorName)") || i.contains(" @\(emulatorName) ") || i.contains(" -avd \(emulatorName) ") {
                    info = i
                }
            }
        }
        var pid: String = ""
        if info != "" {
            let components = info.split(separator: " ")
            if components.count >= 3 {
                pid = String(components[2])
            }
        }
        if pid == "" {
            throw EmulatorError.FailedToGetProcessID
        }
        let killArgs = ["-9", pid]
        guard (try runCommand(executableURL: "/bin/kill", arguments: killArgs)) != nil else {
            throw EmulatorError.FailedToKillProcess
        }
        return true
    }
}

