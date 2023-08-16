//
//  AppInstallView.swift
//  aBicycle
//
//  Created by 1 on 8/12/23.
//

import SwiftUI


struct AppInstallView: View {
    @EnvironmentObject var GlobalVal: GlobalObservable
    
    @State private var currentSerialno: String = ""
    @State private var messageList: [String] = []
    
    @StateObject private var ApkModel = GetApk()
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    view_windows_text
                )
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    return ApkModel.dropOperation(providers: providers)
                }
                .onTapGesture {
                    ApkModel.selectedApk()
                }
            if !messageList.isEmpty {
                view_console_output
            }
        }
        .onChange(of: GlobalVal.currentSerialno) { value in
            self.currentSerialno = value
        }
        .onChange(of: ApkModel.ApkFileList) { value in
            Task {
                for package in ApkModel.ApkFileList {
                    adbInstallApkPackage(apkPath: package)
                }
            }
        }
    }
    
    var view_windows_text: some View {
        VStack {
            Label("", systemImage: "plus")
                .labelStyle(.iconOnly)
                .font(.title)
                .padding(.bottom, 16)
            Text("lproj_selecteApkPrompt")
        }
    }
    
    var view_console_output: some View {
        VStack(alignment: .leading) {
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(messageList, id: \.self) { msg in
                        Text(msg)
                    }
                }
                .padding(15)
                .textSelection(.enabled)
            }
        }
        .frame(height: 150, alignment: .leading)
        .contextMenu {
            Button("Clear Log") {
                DispatchQueue.main.async {
                    messageList = []
                }
            }
        }
    }
    
    
    // 安装apk文件。执行的命令行：adb install xxx.apk
    private func adbInstallApkPackage(apkPath: String = "") {
        
        if !isPathValid(apkPath, endsWith: ".apk") {
            DispatchQueue.main.async {
                let preMsg = getCurrentFormattedTime() + " \(apkPath) path is invalid"
                messageList.append(preMsg)
            }
            return
        }
        
        DispatchQueue.main.async {
            let preMsg = getCurrentFormattedTime() + " installing \(apkPath)."
            messageList.append(preMsg)
        }
        
        Task(priority: .medium) {
            do {
                let result = try await ADB.installApp(serialno: currentSerialno, apkPath: apkPath)
                if result {
                    DispatchQueue.main.async {
                        let resultMsg = getCurrentFormattedTime() + " install Success."
                        messageList.append(resultMsg)
                    }
                }
            } catch let error as AppError {
                handlerError(error: error)
            }
        }
    }
    
    private func handlerError(error: AppError) {
        let msg = parseAppError(error)
        DispatchQueue.main.async {
            messageList.append( getCurrentFormattedTime() + " " + msg )
        }
    }
}


fileprivate final class GetApk: ObservableObject {
    
    @Published var ApkFileList: [String] = []
    
    // 从本地finder选择apk文件
    func selectedApk() {
        openAPKFilePicker { filePath in
            if let fpath = filePath {
                self.ApkFileList.append(fpath)
            }
        }
    }
    
    // 拖入apk文件
    func dropOperation(providers: [NSItemProvider]) -> Bool {
        guard let itemProvider = providers.first else { return false }
        
        if itemProvider.canLoadObject(ofClass: URL.self) {
            itemProvider.loadObject(ofClass: URL.self) { url, error in
                if let url = url {
                    var urlString = url.absoluteString
                    if urlString.hasPrefix("file://") {
                        urlString = String(urlString.dropFirst(7))
                    }
                    DispatchQueue.main.async {
                        self.ApkFileList.append(urlString)
                    }
                }
            }
            return true
        } else {
            return false
        }
    }
    
    func openAPKFilePicker(completion: @escaping (String?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose an APK File"
        openPanel.allowedFileTypes = ["apk"]
//        openPanel.allowedContentTypes = []
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let url = openPanel.url {
            completion(url.path)
        } else {
            completion(nil)
        }
    }
}





