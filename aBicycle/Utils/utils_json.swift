//
//  utils_json.swift
//  aBicycle
//
//  Created by 1 on 8/6/23.
//

import Foundation

class UtilsJsonHelper {
    
    static func readJSON(fromFile filePath: String) -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("[文件] JSON文件不存在！")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        } catch {
            print("[文件] 读取JSON文件失败：\(error.localizedDescription)")
            return nil
        }
    }

    static func writeJSON(_ json: [String: Any], toFile filePath: String) -> Bool {
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
            defer {
                fileHandle.closeFile()
            }
            fileHandle.truncateFile(atOffset: 0)
            try fileHandle.write(contentsOf: data)
            print("[文件] 写入JSON文件成功")
            return true
        } catch {
            print("[文件] 写入JSON文件失败：\(error.localizedDescription)")
            return false
        }
    }
}
