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
    case emulatorCustomPathValid
    case NotFoundEmulator
    case NotFoundActiveEmulator
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
    case .emulatorCustomPathValid:
        return "In the application settings, the custom emulator path is invalid."
    case .NotFoundEmulator:
        return "The emulator list is empty."
    case .NotFoundActiveEmulator:
        return "Not Found Active Emulator"
    case .FailedToGetProcessInfo:
        return "Failed to get process information."
    case .FailedToGetProcessID:
        return "Failed to get process ID."
    case .FailedToKillProcess:
        return "Failed to kill process"
    default:
        return "Unknown error."
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
        //print("------------->", osEmulatorPath, !isChangeAppSettingsValue)
        if let path = osEmulatorPath, !isChangeAppSettingsValue {
            return path
        }
        
        let readResult = readSetting()
        if readResult == nil {
            osEmulatorPath = try await run_simple_command(executableURL: "", arguments: ["-c", "-l", "which emulator"])?.first ?? ""
        } else {
            osEmulatorPath = readResult
            if !isPathValid(osEmulatorPath!, endsWith: "emulator") {
                throw EmulatorError.emulatorCustomPathValid
            }
        }
        if osEmulatorPath!.isEmpty {
            throw EmulatorError.emulatorPathNotFound
        }
        print("path: \(osEmulatorPath!)")
        return osEmulatorPath!
    }
    
    // 获取模拟器列表
    static func getEmulatorList() async throws -> [String] {
        let _ = try await getEmulatorPath()
        guard let emulatorLists = try await run_simple_command(executableURL: osEmulatorPath!, arguments: ["-list-avds"]) else {
            throw EmulatorError.NotFoundEmulator
        }
        
        return emulatorLists
    }
    
    // 获取当前已启动的模拟器列表
    static func getActiveEmulatorList(EmulatorList: [String]) async throws -> [String] {
        let args = ["-Af", "-o", "command"]
        guard let psList = try await run_simple_command(executableURL: "/bin/ps", arguments: args) else {
            throw EmulatorError.NotFoundActiveEmulator
        }
        //print("--->\(psList)")
        
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
            completion(false, EmulatorError.NotFoundEmulator)
            return
        }
        let args = ["-dns-server", "223.5.5.5", "-no-snapshot-save", "-avd", emulatorName]
        DispatchQueue.global(qos: .background).async {
            do {
                guard (try runCommand(executableURL: osEmulatorPath!, arguments: args, action: "start")) != nil else {
                    throw EmulatorError.NotFoundEmulator
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
    static func killEmulator(emulatorName: String) async throws -> Bool {
        let args = ["-Af", "-o", "command"]
        guard let psList = try await run_simple_command(executableURL: "/bin/ps", arguments: args) else {
            throw EmulatorError.FailedToGetProcessInfo
        }
        //print("----->\(psList)")
        
        var info: String = ""
        if !psList.isEmpty {
            for i in psList {
                if i.hasSuffix(" -avd \(emulatorName)") || i.hasSuffix("@\(emulatorName)") || i.contains(" @\(emulatorName) ") || i.contains(" -avd \(emulatorName) ") {
                    info = i
                }
            }
        }
        //print("--->\(info)")
        
        var pid: String = ""
        if info != "" {
            let components = info.split(separator: " ")
            if components.count >= 3 {
                pid = String(components[1])
            }
        }
        print("[PID] -> \(emulatorName) \(pid)")
        
        if pid == "" {
            throw EmulatorError.FailedToGetProcessID
        }
        let killArgs = ["-9", pid]
        guard (try await run_simple_command(executableURL: "/bin/kill", arguments: killArgs)) != nil else {
            throw EmulatorError.FailedToKillProcess
        }
        return true
    }
}

