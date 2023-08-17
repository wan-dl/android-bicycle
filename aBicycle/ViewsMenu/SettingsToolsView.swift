//
//  SettingsToolsView.swift
//  aBicycle
//
//  Created by 1 on 8/17/23.
//

import SwiftUI

struct SettingsToolsView: View {
    
    @StateObject private var hset = SetConf()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("lproj_setting_path_hint")
                .font(.caption)
                .padding(.bottom, 10)
            
            view_form
        }
        .onAppear() {
            hset.readSetting()
        }
        .alert("提示", isPresented: $hset.showMsgAlert) {
            Button("关闭", role: .cancel) { }
        } message: {
            Text(hset.message)
        }
    }
    
    var view_form: some View {
        Form {
            TextField(text: $hset.ConfigAndroidHOME, prompt: Text("Android SDK目录")) {
               Text("lproj_setting_AndroidHome")
            }
            .onSubmit {
                hset.updateChange(key: "ConfigAndroidHOME", value: hset.ConfigAndroidHOME)
            }
            
            TextField(text: $hset.ConfigAvdmanagerPath, prompt: Text("avdmanager绝对路径，输入回车自动保存")) {
               Text("lproj_setting_avdmanagerPath")
            }
            .onSubmit {
                hset.updateChange(key: "ConfigAvdmanagerPath", value: hset.ConfigAvdmanagerPath)
            }
            
            TextField(text: $hset.ConfigEmulatorPath, prompt: Text("emulator绝对路径，输入回车自动保存")) {
               Text("lproj_setting_emulatorPath")
            }
            .onSubmit {
                hset.updateChange(key: "ConfigEmulatorPath", value: hset.ConfigEmulatorPath)
            }
            
            TextField(text: $hset.ConfigADBPath, prompt: Text("adb绝对路径，输入回车自动保存")) {
               Text("lproj_setting_ADBPath")
            }
            .onSubmit {
                hset.updateChange(key: "ConfigADBPath", value: hset.ConfigADBPath)
            }
        }
    }
}


fileprivate final class SetConf: ObservableObject{
    
    @Published var ConfigAndroidHOME: String = ""
    @Published var ConfigEmulatorPath: String = ""
    @Published var ConfigADBPath: String = ""
    @Published var ConfigAvdmanagerPath: String = ""
    
    @Published var message: String = ""
    @Published var showMsgAlert: Bool = false
    
    func updateChange(key: String, value: String) {
        print("TextField 内容变化：\(key) \(value)")
        
        if !value.isEmpty {
            switch key {
               case "ConfigAndroidHOME":
                   handleInvalidPath(value, requiredExtension: nil, errorMessage: "Android SDK目录")
               case "ConfigADBPath":
                   handleInvalidPath(value, requiredExtension: "adb", errorMessage: "ADB路径无效")
               case "ConfigEmulatorPath":
                   handleInvalidPath(value, requiredExtension: "emulator", errorMessage: "emulator路径无效")
               case "ConfigAvdmanagerPath":
                   handleInvalidPath(value, requiredExtension: "avdmanager", errorMessage: "avdmanager路径无效")
               default:
                   break
            }
        }
        
        do {
            let writeResult = try SettingsHandler.writeJsonFile(key: key, value: value)
            if writeResult {
                isChangeAppSettingsValue = true
            }
        } catch {
            handleMsg(msg: "保存配置发生错误")
        }
    }
    
    func handleInvalidPath(_ path: String, requiredExtension: String?, errorMessage: String) {
        guard !isPathValid(path, endsWith: requiredExtension) else { return }
        handleMsg(msg: errorMessage)
    }
    
    func readSetting() {
        do {
            let fileContent: [String: Any] = try SettingsHandler.readJsonFileAll(defaultValue: [:])
            if !fileContent.isEmpty {
                if let adbPath = fileContent["ConfigAndroidHOME"] as? String {
                    self.ConfigAndroidHOME = adbPath
                }
                if let adbPath = fileContent["ConfigADBPath"] as? String {
                    self.ConfigADBPath = adbPath
                }
                if let emualtorPath = fileContent["ConfigEmulatorPath"] as? String {
                    self.ConfigEmulatorPath = emualtorPath
                }
                if let AvdmanagerPath = fileContent["ConfigAvdmanagerPath"] as? String {
                    self.ConfigAvdmanagerPath = AvdmanagerPath
                }
            }
        } catch {
            handleMsg(msg: "读取自定义配置发生错")
        }
    }
    
    func handleMsg(msg: String) {
        DispatchQueue.main.async {
            self.message = msg
            self.showMsgAlert = true
        }
    }
}

