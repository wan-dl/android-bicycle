//
//  cmd_emulator.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import Foundation


class AndroidEmulatorManager {
    static var osEmulatorPath: String?
    
    // 查找emulator路径
    static func getEmulatorPath() async throws -> String {
        if let path = osEmulatorPath, !isChangeAppSettingsValue {
            return path
        }
        
        do {
            let cmd = CommandLineManager()
            let toolPath = try await cmd.getToolPath(toolName: "emulator")
            osEmulatorPath = toolPath
            return toolPath
        } catch {
            throw error
        }
    }
    
    // 获取模拟器列表
    static func getEmulatorList() async throws -> [String] {
        let _ = try await getEmulatorPath()
        guard let emulatorLists = try await run_simple_command(executableURL: osEmulatorPath!, arguments: ["-list-avds"]) else {
            throw AppError.NotFoundEmulator
        }
        return emulatorLists
    }
    
    // 获取当前已启动的模拟器列表
    static func getActiveEmulatorList(EmulatorList: [String]) async throws -> [String] {
        let args = ["-Af", "-o", "command"]
        guard let psList = try await run_simple_command(executableURL: "/bin/ps", arguments: args) else {
            throw AppError.NotFoundActiveEmulator
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
            completion(false, AppError.NotFoundEmulator)
            return
        }
        let args = ["-dns-server", "223.5.5.5", "-no-snapshot-save", "-avd", emulatorName]
        DispatchQueue.global(qos: .background).async {
            do {
                guard (try runCommand(executableURL: osEmulatorPath!, arguments: args, action: "start")) != nil else {
                    throw AppError.NotFoundEmulator
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
            throw AppError.FailedToGetProcessInfo
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
            throw AppError.FailedToGetProcessID
        }
        let killArgs = ["-9", pid]
        guard (try await run_simple_command(executableURL: "/bin/kill", arguments: killArgs)) != nil else {
            throw AppError.FailedToKillProcess
        }
        return true
    }
}

