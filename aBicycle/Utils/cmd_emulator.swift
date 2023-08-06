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
    case emulatorPathValid
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
    case .emulatorPathValid:
        return "Emulator Path is Vaild."
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


class AndroidEmulatorManager {
    static var osEmulatorPath: String?
    
    static func readSetting() -> String? {
        do {
            let fileContent: [String: Any] = try SettingsHandler.readJsonFileAll(defaultValue: [:])
            if !fileContent.isEmpty {
                if let emualtorPath = fileContent["ConfigEmulatorPath"] as? String {
                    return String(emualtorPath)
                }
            }
            return nil
        } catch {
            return nil
        }
    }
    
    // 查找emulator路径
    static func getEmulatorPath() async throws -> String {
        if osEmulatorPath == nil {
            let readResult = readSetting()
            if readResult == nil {
                osEmulatorPath = try runCommand(executableURL: "", arguments: ["-c", "-l", "which emulator"])?.first ?? ""
            } else {
                osEmulatorPath = readResult
            }
            if osEmulatorPath!.isEmpty {
                throw EmulatorError.emulatorPathNotFound
            }
            if !isPathValid(osEmulatorPath!, endsWith: "emulator") {
                throw EmulatorError.emulatorPathValid
            }
            print("path: \(osEmulatorPath!)")
        }
        return osEmulatorPath!
    }
    
    // 获取模拟器列表
    static func getEmulatorList() async throws -> [String] {
        let _ = try await getEmulatorPath()
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
                guard (try runCommand(executableURL: osEmulatorPath!, arguments: args, action: "start")) != nil else {
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

