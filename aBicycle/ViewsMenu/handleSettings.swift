//
//  handleSettings.swift
//  aBicycle
//
//  Created by 1 on 8/6/23.
//

import Cocoa
import Foundation

enum AppSettingsError: Error {
    case getAppNameError
    case createAppSupportDirectoryError
    case getAppSupportDirectoryPathError
}

// 获取应用名称
func getApplicationName() -> String? {
    return Bundle.main.infoDictionary?["CFBundleName"] as? String
}

// 创建应用程序支持目录
func createAppSupportDirectory(at url: URL) throws {
    do {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    } catch {
        throw AppSettingsError.createAppSupportDirectoryError
    }
}

// 获取应用程序支持目录路径
func getAppSupportDirectoryPath() throws -> String {
    guard let appName = getApplicationName() else {
        throw AppSettingsError.getAppNameError
    }
    
    do {
        let applicationSupportURLs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let applicationSupportURL = applicationSupportURLs.first {
            let appSupportURL = applicationSupportURL.appendingPathComponent(appName)
            
            if FileManager.default.fileExists(atPath: appSupportURL.path) {
                return appSupportURL.path
            } else {
                try createAppSupportDirectory(at: appSupportURL)
                return appSupportURL.path
            }
        } else {
            throw AppSettingsError.getAppSupportDirectoryPathError
        }
    } catch {
        throw error
    }
}

class SettingsHandler {
    
    static func getSettingsJsonFilePath() -> String {
        do {
            let appSupportPath = try getAppSupportDirectoryPath()
            let settingsFilePath = (appSupportPath as NSString).appendingPathComponent(appSettingFileName)
            return settingsFilePath
        } catch {
            return ""
        }
    }
    
    static func writeJsonFile(key: String, value: String) throws -> Bool {
        let settingsFilePath = getSettingsJsonFilePath()
        if settingsFilePath.isEmpty {
            throw AppSettingsError.getAppSupportDirectoryPathError
        }
        
        var fileContent = [String : Any]()
        var readFileContent = UtilsJsonHelper.readJSON(fromFile: settingsFilePath)
        
        if readFileContent != nil {
            readFileContent?[key] = value
            fileContent = readFileContent!
        } else {
            fileContent[key] = value
        }
        let writeResult = UtilsJsonHelper.writeJSON(fileContent, toFile: settingsFilePath)
        return writeResult
    }
    
    static func readJsonFile<T>(key: String, defaultValue: T) -> T {
        let settingsFilePath = getSettingsJsonFilePath()

        guard let fileContent = UtilsJsonHelper.readJSON(fromFile: settingsFilePath),
              let result = fileContent[key] as? T else {
            return defaultValue
        }

        return result
    }
    
    static func readJsonFileAll(defaultValue: [String: Any]) throws -> [String: Any] {
        let settingsFilePath = getSettingsJsonFilePath()
        
        guard let jsonData = FileManager.default.contents(atPath: settingsFilePath) else {
            return defaultValue
        }
        
        do {
            let decodedValue = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
            return decodedValue ?? defaultValue
        } catch {
            throw error
        }
    }
}



