//
//  AdbLogcatView.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import SwiftUI

// adb logcat option priority
enum LogcatOptionPriority: String, CaseIterable, Identifiable {
    case Verbose, Debug, Info, Warn, Error, Fatal, All
    var id: Self { self }
}

struct AdbLogcatView: View {
    
    @StateObject private var logcat = AdbLogcat()
    @State private var logcatOutput: String = ""
    
    @State private var AndroidDeviceList: [AndroidDeviceItem] = []
    @State private var AndroidDevicePickerData: [String] = [""]
    
    @State private var currentSerialno: String = ""
    @State private var currentDeviceAllPackageList: [String] = [""]
    
    @State private var isLaunchLogcat: Bool = false
    
    @State private var selectedDevice: String = ""
    @State private var selectedPriority: LogcatOptionPriority = .All
    @State private var selectedPackageName: String = ""
    
    var body: some View {
        VStack {
            top_view
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    Text(logcatOutput)
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .contextMenu {
            contextMenu_view
        }
        .task {
            getDeivces()
        }
    }
    
    var top_view: some View {
        HStack {
            // 选择设备
            Picker("", selection: $selectedDevice) {
                ForEach(AndroidDevicePickerData, id: \.self) { device in
                    Text(device)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedDevice) { newValue in
                parseCurrentSerialno()
                getCurrentDevicePackageList()
            }
            
            // 选择包名
            Picker("", selection: $selectedPackageName) {
                ForEach(currentDeviceAllPackageList, id: \.self) { item in
                    if item == "No..." {
                        Divider()
                    }
                    Text(item)
                }
            }
            .pickerStyle(.menu)
            
            // 选择日志包名
            Picker("", selection: $selectedPriority) {
                ForEach(LogcatOptionPriority.allCases, id: \.self) { item in
                    Text(item.rawValue)
                }
            }
            .pickerStyle(.menu)
            
            Spacer()
            
            Button(action: clickLogcat) {
                Text( isLaunchLogcat ? "Stop" : "Start" )
            }
            .disabled(selectedDevice.isEmpty ? true : false)
        }
        .padding(.horizontal, 20)
    }
    
    // 右键菜单
    var contextMenu_view: some View {
        Section {
            Button("Refresh Device") {
                getDeivces()
            }
            Divider()
        }
    }
    
    // 获取android设备列表
    func getDeivces() {
        Task(priority: .medium) {
            do {
                let output = try await ADB.adbDevices()
                DispatchQueue.main.async {
                    self.AndroidDeviceList = []
                    if !output.isEmpty {
                        self.AndroidDeviceList = output
                        self.AndroidDevicePickerData = []
                        for i in output {
                            AndroidDevicePickerData.append(i.serialno + " - " + i.model)
                        }
                        if !AndroidDevicePickerData.isEmpty {
                            self.selectedDevice = AndroidDevicePickerData[0]
                        }
                    }
                }
            } catch let error {
                let msg = getADBErrorMessage(etype: error as! ADBError)
                _ = showAlert(title: "Error", msg: msg, ConfirmBtnText: "")
            }
        }
    }
    
    // 获取当前设备包名
    func getCurrentDevicePackageList() {
        if self.currentSerialno.isEmpty {
            return
        }
        Task(priority: .medium) {
            do {
                let output = try await ADB.packageList(serialno: self.currentSerialno)
                self.currentDeviceAllPackageList = [""]
                if !output.isEmpty {
                    self.currentDeviceAllPackageList.append(contentsOf: output)
                }
            } catch {
                let msg = getADBErrorMessage(etype: error as! ADBError)
                _ = showAlert(title: "Error", msg: msg, ConfirmBtnText: "")
            }
        }
    }
    
    // 解析设备ID
    func parseCurrentSerialno() {
        if #available(macOS 13.0, *) {
            let SerialInfo = self.selectedDevice.split(separator: " - ")
            if let firstComponent = SerialInfo.first {
                self.currentSerialno = String(firstComponent)
            }
        } else {
            let SerialInfo = self.selectedDevice.components(separatedBy: " - ")
            if let firstComponent = SerialInfo.first {
                self.currentSerialno = String(firstComponent)
            }
        }
    }
    
    // 点击运行adb logcat
    func clickLogcat() {
        Task {
            if self.isLaunchLogcat == false {
                if self.AndroidDeviceList.isEmpty {
                    return
                }
                
                var logcatOptions: [String] = []
                if self.selectedPriority.rawValue != "All" {
                    if let priority = self.selectedPriority.rawValue.first {
                        logcatOptions.append("':\(String(priority))'")
                    }
                }
                if self.selectedPackageName.contains(".") {
                    logcatOptions.append("-s")
                    logcatOptions.append(self.selectedPackageName)
                }
                
                self.isLaunchLogcat.toggle()
                do {
                    try await logcat.run(serialno: currentSerialno, logcatOptions: logcatOptions)
                    observeLogcatOutput()
                } catch {
                    print("Error: \(error)")
                }
            } else {
                self.isLaunchLogcat.toggle()
                logcat.stop()
            }
        }
    }
    
    func observeLogcatOutput() {
        logcat.$logcatOutput
            .receive(on: DispatchQueue.main)
            .sink { output in
                self.logcatOutput += output
            }
            .store(in: &logcat.cancellables)
    }
}

struct AdbLogcatView_Previews: PreviewProvider {
    static var previews: some View {
        AdbLogcatView()
    }
}
