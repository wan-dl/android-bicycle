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
    @State private var lastText: AttributedString = AttributedString("")
    
    @State private var currentDeviceAllPackageList: [String] = [""]
    @State private var isLaunchLogcat: Bool = false
    @State private var isFirstGetLog: Bool = false
    
    @State private var selectedPriority: LogcatOptionPriority = .All
    @State private var selectedPackageName: String = ""
    @State private var filterWord: String = ""
    
    @State private var message: String = ""
    @State private var showMsgAlert: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading) {
            top_view
            
            ScrollViewReader { scrollViewProxy in
               ScrollView {
                   LazyVStack (alignment: .leading) {
                       Text(logcatOutput)
                           .textSelection(.enabled)
                           .lineSpacing(3)
//                           .onChange(of: logcatOutput) { newValue in
//                               withAnimation {
//                                   scrollViewProxy.scrollTo(logcatOutput, anchor: .bottom)
//                               }
//                           }
                       
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
        .onReceive(timer) { _ in
            DispatchQueue.main.async {
                self.logcatOutput += self.lastText
                self.lastText = ""
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
//            Picker("", selection: $selectedPackageName) {
//                ForEach(currentDeviceAllPackageList, id: \.self) { item in
//                    if item == "No..." {
//                        Divider()
//                    }
//                    Text(item)
//                }
//            }
//            .pickerStyle(.menu)
            
            // 选择日志包名
            Picker("", selection: $selectedPriority) {
                ForEach(LogcatOptionPriority.allCases, id: \.self) { item in
                    Text(item.rawValue)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)
            
            SearchTextField(text: $filterWord)
            
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
                        logcatOptions.append("*:\(String(priority))")
                    }
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
    
    // 获取日志输出
    func observeLogcatOutput() {
        logcat.$logcatOutput
            .receive(on: DispatchQueue.main)
            .sink { output in
                let lines = output.split(separator: "\n")
                var processedOutput = AttributedString("")
                
                for line in lines {
                    
                    if !filterWord.isEmpty && !isStringAllWhitespace(String(line)){
                        if !line.contains(filterWord) {
                            continue
                        }
                    }
                    
                    let lintText = String(line) + "\n"
                    if lintText.contains(" W/") {
                        processedOutput += highlightLogText(lintText, .orange.opacity(0.8))
                    } else if line.contains(" E/") {
                        processedOutput += highlightLogText(lintText, .red)
                    } else {
                        processedOutput += AttributedString(lintText)
                    }
                }
                // 不输出10s之前的日志
                if isPrintLog(from: output) {
                    DispatchQueue.main.async {
                        lastText += processedOutput
                    }
                }
            }
            .store(in: &logcat.cancellables)
    }
    
    // 高亮日志文本消息
    private func highlightLogText(_ output: String, _ textColor: Color) -> AttributedString {
        var logText = AttributedString(output)
        logText.foregroundColor = textColor
        return logText
    }
    
    // 判断字符串是否全是空格
    func isStringAllWhitespace(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
    }
    
    private func handlerError(error: AppError) {
        let msg = parseAppError(error)
        DispatchQueue.main.async {
            message = msg
            showMsgAlert = true
        }
    }
}

// 检查日志消息时间，来决定是否输出
fileprivate func isPrintLog(from input: String) -> Bool {
    let dateRegexPattern = #"(\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})"#
    guard let match = input.range(of: dateRegexPattern, options: .regularExpression) else {
        return false
    }

    let extracted = input[match]
    let extractedParts = extracted.split(separator: " ")

    let formattedDatePart = formatDateTime(date: Date(), format: "MM-dd")
    let formattedTimePart = formatDateTime(date: Date(), format: "HH:mm:ss")

    guard extractedParts.count == 2,
          let extractedDate = extractedParts.first,
          let extractedTime = extractedParts.last else {
        return false
    }

    if extractedDate != formattedDatePart {
        return false
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss"
    if let currentTime = dateFormatter.date(from: formattedTimePart),
        let extractedTime = dateFormatter.date(from: String(extractedTime)),
        currentTime.timeIntervalSince(extractedTime) < 10 {
        return true
    }

    return false
}
