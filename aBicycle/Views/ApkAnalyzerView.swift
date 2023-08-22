//
//  ApkAnalyzerView.swift
//  aBicycle
//
//  Created by 1 on 8/15/23.
//

import SwiftUI

enum ApkDataTab: String, CaseIterable, Identifiable {
    case BaseInfo, ManifestFile, ApkFileList
    var id: Self { self }
}

struct ApkBaseItem: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let value: String
}

struct ApkAnalyzerView: View {
    @State private var apkFilePath: String = ""
    @State private var isDoing: Bool = false
    
    @State private var ActiveTab: ApkDataTab = .BaseInfo
    
    @StateObject private var ApkInfoModel = GetApkInfo()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SelecteLocalFile(filepath: $apkFilePath, isDoing: $isDoing)
                view_analyze_btn
            }
            .frame(height: 25)
            .padding(.horizontal, 15)
            .padding(.top, 20)
            
            view_tab
            
            ScrollView {
                view_body
            }
            
        }
        .frame(maxWidth: .infinity)
    }
    
    var view_tab: some View {
        HStack {
            ForEach(ApkDataTab.allCases, id: \.self) { item in
                Button(item.rawValue) {
                    ActiveTab = item
                }
                .buttonStyle(apkTabButtonStyle(BtnText: item, ActiveTab: $ActiveTab))
            }
        }
        .frame(maxWidth: .infinity ,alignment: .center)
        .padding(.vertical, 15)
    }
    
    var view_body: some View {
        VStack {
            switch (ActiveTab) {
            case .BaseInfo:
                view_manifest_data
            case .ManifestFile:
                view_manifest_xml
            case .ApkFileList:
                ApkFilesList()
            }
        }
        .padding(.horizontal, 15)
    }
    
    var view_manifest_data: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(ApkInfoModel.ApkManifestData, id: \.self) { item in
                HStack {
                    Text(item.key)
                        .frame(width: 120, alignment: .trailing)
                    Text(":")
                    Text(item.value)
                }
            }
        }
    }
    
    var view_manifest_xml: some View {
        VStack {
            Text(ApkInfoModel.ApkManifestXMLInfo)
                .textSelection(.enabled)
                .padding(.horizontal, 15)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    var view_analyze_btn: some View {
        Button("lproj_apk_analyzer_btn") {
            isDoing.toggle()
            
            if (isDoing) {
                DispatchQueue.main.async {
                    ApkInfoModel.ApkManifestXMLInfo = AttributedString("")
                    ApkInfoModel.ApkManifestData = []
                }
                ApkInfoModel.getApkFileSize(filePath: apkFilePath)
                ApkInfoModel.printManifestAsXml(apkPath: apkFilePath)
            }
        }
    }

}


fileprivate final class GetApkInfo: ObservableObject {
    @Published var ApkManifestXMLInfo: AttributedString = AttributedString("")
    @Published var ApkManifestData: [ApkBaseItem] = []
    
    @Published var showMsgAlert = false
    @Published var message: String = ""
    
    
    private func handlerError(error: AppError) {
        let msg = parseAppError(error)
        DispatchQueue.main.async {
            self.message = msg
            self.showMsgAlert = true
        }
    }
    
    func getApkFileSize(filePath: String) {
        if let fileSizeInKB = getFileSizeInMB(atPath: filePath) {
            let formattedSize = String(format: "%.3f", fileSizeInKB)
            DispatchQueue.main.async {
                self.ApkManifestData.append(ApkBaseItem(key: "ApkSize", value: "\(formattedSize) MB"))
            }
        }
    }
    
    // 基本信息
    func printManifestAsXml(apkPath: String) {
        Task(priority: .medium) {
            do {
                let output = try await ApkAnalyzerManage.printManifest(apkPath: apkPath, isRawOutput: true)
                DispatchQueue.main.async {
                    if !output.isEmpty {
                        self.ApkManifestXMLInfo = AttributedString(output)
                        self.parseManifestXml(xml: output)
                    }
                }
            } catch let error as AppError {
                handlerError(error: error)
            }
        }
    }
    
    func parseManifestXml(xml: String) {
        let DataList = [
            "package","android:versionCode", "android:versionName",
            "android:compileSdkVersion", "android:minSdkVersion", "android:targetSdkVersion"
        ]
        for var key in DataList {
            let value = extractAttributes(from: xml, attributeName: key)
            if let index = key.firstIndex(of: ":") {
                key = String(key[key.index(after: index)...])
            }
            self.ApkManifestData.append(ApkBaseItem(key: key, value: value as! String))
        }
    }
    
}


fileprivate func extractAttributes(from input: String, attributeName: String) -> Any {
    let pattern = #"\#(attributeName)="([^"]+)""#
    let regex = try! NSRegularExpression(pattern: pattern, options: [])

    let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))

    var extractedInfo: String = ""

    for match in matches {
        if let valueRange = Range(match.range(at: 1), in: input) {
            let value = String(input[valueRange])
            extractedInfo = value
        }
    }
    return extractedInfo
}
