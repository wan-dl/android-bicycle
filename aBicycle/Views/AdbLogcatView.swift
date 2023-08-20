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
    @EnvironmentObject var GlobalVal: GlobalObservable
    @State private var currentSerialno: String = ""
    
    @StateObject var logcat = AdbLogcat()
    
    @State private var logcatOutput: AttributedString = AttributedString("")

    @State private var currentDeviceAllPackageList: [String] = [""]
    
    @State private var isLaunchLogcat: Bool = false
    
    @State private var selectedPriority: LogcatOptionPriority = .All
    @State private var selectedPackageName: String = ""
    
    @State private var message: String = ""
    @State private var showMsgAlert: Bool = false
    
    var body: some View {
        VStack {
            top_view
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        Text(logcatOutput)
                            .textSelection(.enabled)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .contextMenu {}
        .onAppear() {
            self.currentSerialno = GlobalVal.currentSerialno
        }
        .onChange(of: GlobalVal.currentSerialno) { value in
            self.currentSerialno = value
            
        }
        .onChange(of: currentSerialno) { value in
            if !self.currentSerialno.isEmpty {
                getCurrentDevicePackageList()
            }
            if self.currentSerialno.isEmpty && self.isLaunchLogcat == true {
                self.isLaunchLogcat.toggle()
                logcat.stop()
            }
        }
        .alert("提示", isPresented: $showMsgAlert) {
            Button("关闭", role: .cancel) { }
        } message: {
            Text(message)
        }
    }
    
    var top_view: some View {
        HStack {
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
            .disabled(currentSerialno.isEmpty ? true : false)
            
            Button("Clear") {
                logcatOutput = AttributedString("")
            }
            .disabled(logcatOutput == "" ? true : false)
        }
        .padding(20)
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
            } catch let error as AppError {
                handlerError(error: error)
            }
        }
    }
    
    // 点击运行adb logcat
    func clickLogcat() {
        Task {
            if self.isLaunchLogcat == false {
                if self.currentSerialno.isEmpty {
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
                self.logcatOutput += AttributedString(output)
            }
            .store(in: &logcat.cancellables)
    }
    
    private func handlerError(error: AppError) {
        let msg = parseAppError(error)
        DispatchQueue.main.async {
            message = msg
            showMsgAlert = true
        }
    }
}
