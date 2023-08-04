//
//  cmd_adb.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import Foundation
import Combine


struct AndroidDeviceItem: Identifiable, Hashable {
    var model: String
    var serialno: String
    let id = UUID()
}


enum ADBError: Error {
    case NotFoundADB
    case AdbExecutionFailed
}


func getADBErrorMessage(etype: ADBError) -> String {
    switch(etype) {
    case .NotFoundADB:
        return "ADB Path Not Found."
    case .AdbExecutionFailed:
        return "adb command execution failed"
    }
}


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
    static func getAdbPath() throws -> String {
        if let path = osAdbPath {
            return path
        }
        let adbPath = try run_simple_command(executableURL: "", arguments: ["-c", "-l", "which adb"])?.first ?? ""
        if adbPath.isEmpty {
            throw ADBError.NotFoundADB
        }
        osAdbPath = adbPath
        return osAdbPath!
    }
    
    // 执行：adb devices -l
    static func adbDevices() throws -> [AndroidDeviceItem] {
        let adbPath = try getAdbPath()
        
        guard let outputList = try run_simple_command(executableURL: adbPath, arguments: ["devices", "-l"]) else {
            throw ADBError.AdbExecutionFailed
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
    static func packageList(serialno: String) throws -> [String] {
        let adbPath = try getAdbPath()
        let args = ["-s", serialno, "shell", "pm", "list", "packages"]
        guard let outputList = try run_simple_command(executableURL: adbPath, arguments: args) else {
            throw ADBError.AdbExecutionFailed
        }
        
        if outputList.count == 0 {
            return []
        }
        
        var allPackageList: [String] = []
        allPackageList = outputList.map { $0.hasPrefix("package:") ? String($0.dropFirst("package:".count)) : $0 }
        var lastData = allPackageList.sorted().filter { $0 != "" }.reversed()
        return Array(lastData)
    }
}


class AdbLogcat: ObservableObject {
    @Published var logcatOutput: String = ""
    
    private var task: Process?
    private var fileHandle: FileHandle?
    internal var cancellables = Set<AnyCancellable>()
    private var throttledSubject = PassthroughSubject<String, Never>()
    
    init() {
        throttledSubject
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] output in
                self?.logcatOutput = output
            }
            .store(in: &cancellables)
    }

    func run(serialno: String, logcatOptions: [String]) throws {
        
        var args: [String] = ["-s", serialno, "logcat", "-v", "color"]
        if !logcatOptions.isEmpty {
            args.append(contentsOf: logcatOptions)
        }
        
        let adbPath = try ADB.getAdbPath()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: adbPath)
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        self.fileHandle = pipe.fileHandleForReading
        
        do {
            try task.run()
            self.task = task
            
            DispatchQueue.global(qos: .background).async {
                self.fileHandle?.readabilityHandler = { fileHandle in
                    let data = fileHandle.availableData
                    if let output = String(data: data, encoding: .utf8) {
                        self.throttledSubject.send(output)
                    }
                }
            }
        } catch {
            throw error
        }
    }
    
    func stop() {
        self.task?.terminate()
    }
}

