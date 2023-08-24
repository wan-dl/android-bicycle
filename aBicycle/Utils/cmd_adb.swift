//
//  cmd_adb.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import Foundation
import Combine


// 使用正则匹配Android设备ID
func extractAndroidDeviceID(from input: String) -> String? {
    let pattern = "^(.*?)\\s"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return nil
    }
    
    let range = NSRange(input.startIndex..., in: input)
    if let match = regex.firstMatch(in: input, options: [], range: range) {
        let extractedString = (input as NSString).substring(with: match.range(at: 1))
        return extractedString
    } else {
        return nil
    }
}


// 使用正则提取adb devices -l输出中的Model信息
func extractAndroidModel(from input: String) -> String? {
    let pattern = "model:(.*?)\\s"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return nil
    }
    
    let range = NSRange(input.startIndex..., in: input)
    if let match = regex.firstMatch(in: input, options: [], range: range) {
        let extractedString = (input as NSString).substring(with: match.range(at: 1))
        return extractedString
    } else {
        return nil
    }
}



class ADB {
    static var osAdbPath: String?
    
    // 查找adb路径
    static func getAdbPath() async throws -> String {
        if let path = osAdbPath, !isChangeAppSettingsValue {
            return path
        }
        
        do {
            let cmd = CommandLineManager()
            let toolPath = try await cmd.getToolPath(toolName: "adb")
            osAdbPath = toolPath
            return toolPath
        } catch {
            throw error
        }
    }
    
    // 执行：adb devices -l
    static func adbDevices() async throws -> [AndroidDeviceItem] {
        let adbPath = try await getAdbPath()
        guard let outputList = try await run_simple_command(executableURL: adbPath, arguments: ["devices", "-l"]) else {
            throw AppError.ExecutionFailed(message: "Failed to execute the command")
        }
        if outputList.count == 1 {
            return []
        }
        
        var DeivceList: [AndroidDeviceItem] = []
        for i in outputList {
            if i.contains("model:") && i.contains("device:") && i.contains("transport_id:") && i.contains("product:") {
                var tmp: AndroidDeviceItem = AndroidDeviceItem(model: "", serialno: "")
                if let stringID = extractAndroidDeviceID(from: i) {
                    tmp.serialno = stringID
                }
                if let stringModel = extractAndroidModel(from: i) {
                    tmp.model = stringModel
                }
                DeivceList.append(tmp)
            }
        }
        return DeivceList
    }
    
    // 通过设备ID获取所有包名
    static func packageList(serialno: String, cmdOption: String = "-a") async throws -> [String] {
        let adbPath = try await getAdbPath()
        let args = ["-s", serialno, "shell", "pm", "list", "packages", cmdOption]
        guard let outputList = try await run_simple_command(executableURL: adbPath, arguments: args) else {
            throw AppError.ExecutionFailed(message: "Failed to execute the command")
        }
        
        if outputList.count == 0 {
            return []
        }
        
        var allPackageList: [String] = []
        allPackageList = outputList.map { $0.hasPrefix("package:") ? String($0.dropFirst("package:".count)) : $0 }
        let lastData = allPackageList.sorted().filter { $0 != "" }.reversed()
        return Array(lastData)
    }
    
    // 卸载App
    static func uninstallApp(serialno: String, packageName: String) async throws -> Bool {
        let args = ["-s", serialno, "uninstall", packageName]
        guard let outputList = try await run_simple_command(executableURL: osAdbPath!, arguments: args) else {
            throw AppError.ExecutionFailed(message: "Failed to execute the command")
        }
        let outputStr = outputList.joined(separator: "")
        print("[uninstallApp] \(outputStr)")
        if !outputStr.contains("Success") {
            let errorMessage = "Uninstall failed. Output: \(outputStr)"
            throw AppError.ExecutionFailed(message: errorMessage)
        }
        return true
    }
    
    // 安装App
    static func installApp(serialno: String = "", apkPath: String) async throws -> Bool {
        var args = ["install", apkPath]
        if !serialno.isEmpty {
            args = ["-s", serialno, "install", apkPath]
        }
        guard let outputList = try await run_simple_command(executableURL: osAdbPath!, arguments: args) else {
            throw AppError.ExecutionFailed(message: "Failed to execute the command")
        }
        
        let outputStr = outputList.joined(separator: ". ")
        print("[installApp] \(outputStr)")
        if !outputStr.contains("Success") {
            let errorMessage = "installation failed. Reason: \(outputStr)"
            throw AppError.ExecutionFailed(message: errorMessage)
        }
        return true
    }
}


var globalAdbLogcatTask: Process?

class AdbLogcat: ObservableObject {
    @Published var logcatOutput: String = ""
    
    private var fileHandle: FileHandle?
    internal var cancellables = Set<AnyCancellable>()
    private var throttledSubject = PassthroughSubject<String, Never>()
    
    init() {
        throttledSubject
//            .debounce(for: .milliseconds(1), scheduler: DispatchQueue.main)
//            .debounce(for: .milliseconds(1), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                self?.logcatOutput = output
            }
            .store(in: &cancellables)
    }

    func run(serialno: String, logcatOptions: [String]) async throws {
        Task {
            do {
                var args: [String] = ["-s", serialno, "logcat", "-v", "time"]
                if !logcatOptions.isEmpty {
                    args.append(contentsOf: logcatOptions)
                }
                print("[adb logcat] args: \(args)")
                
                let adbPath = try await ADB.getAdbPath()
                let task = Process()
                task.executableURL = URL(fileURLWithPath: adbPath)
                task.arguments = args
                
                let pipe = Pipe()
                task.standardOutput = pipe
                self.fileHandle = pipe.fileHandleForReading
                
                do {
                    try task.run()
                    globalAdbLogcatTask = task
                    
                    fileHandle?.readabilityHandler = { [weak self] fileHandle in
                        let data = fileHandle.availableData
                        if let output = String(data: data, encoding: .utf8) {
                            self?.throttledSubject.send(output)
                        }
                    }
                } catch {
                    throw error
                }
            }
        }
    }
    
    func stop() {
        globalAdbLogcatTask?.terminate()
        globalAdbLogcatTask = nil
    }
}
