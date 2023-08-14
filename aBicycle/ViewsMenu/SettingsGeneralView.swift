//
//  SettingsGeneralView.swift
//  aBicycle
//
//  Created by 1 on 8/14/23.
//

import SwiftUI

struct SettingsGeneralView: View {
    
    @StateObject private var hset = SetConf()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("提示：如果此处您自定义了emulator和adb路径，会优先使用自定义配置。相反，则使用操作系统环境变量中已配置Android SDK环境变量，")
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
               Text("Android SDK目录")
            }
            .onSubmit {
                hset.updateChange(key: "ConfigAndroidHOME", value: hset.ConfigAndroidHOME)
            }
            
            TextField(text: $hset.ConfigAvdmanagerPath, prompt: Text("avdmanager绝对路径，输入回车自动保存")) {
               Text("avdmanager路径")
            }
            .onSubmit {
                hset.updateChange(key: "ConfigAvdmanagerPath", value: hset.ConfigAvdmanagerPath)
            }
            
            TextField(text: $hset.ConfigEmulatorPath, prompt: Text("emulator绝对路径，输入回车自动保存")) {
               Text("emulator路径")
            }
            .onSubmit {
                hset.updateChange(key: "ConfigEmulatorPath", value: hset.ConfigEmulatorPath)
            }
            
            TextField(text: $hset.ConfigADBPath, prompt: Text("adb绝对路径，输入回车自动保存")) {
               Text("ADB路径")
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
        
        if key == "ConfigAndroidHOME" && !isDirectoryValid(atPath: value) {
            handleMsg(msg: "Android SDK目录")
            return
        }
        
        if key == "ConfigADBPath" && !isPathValid(value, endsWith: "adb") {
            handleMsg(msg: "ADB路径无效")
            return
        }
        
        if key == "ConfigEmulatorPath" && !isPathValid(value, endsWith: "emulator") {
            handleMsg(msg: "emulator路径无效")
            return
        }
        
        if key == "ConfigAvdmanagerPath" && !isPathValid(value, endsWith: "avdmanager") {
            handleMsg(msg: "avdmanager路径无效")
            return
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
    
    func readSetting() {
        do {
            let fileContent: [String: Any] = try SettingsHandler.readJsonFileAll(defaultValue: [:])
            if !fileContent.isEmpty {
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

