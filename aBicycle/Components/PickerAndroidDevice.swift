//
//  PickerAndroidDevice.swift
//  aBicycle
//
//  Created by 1 on 8/11/23.
//

import SwiftUI

struct PickerAndroidDevice: View {
    
    @State private var DeviceList: [AndroidDeviceItem] = []
    @State private var DevicePickerData: [String] = [""]
    @State private var selectedDevice: String = ""
    
    @Binding var currentSerialno: String
    
    @State private var message: String = ""
    @State private var showMsgAlert: Bool = false
    
    var body: some View {
        HStack {
            Picker("", selection: $selectedDevice) {
                ForEach(DevicePickerData, id: \.self) { device in
                    Text(device)
                }
            }
            .pickerStyle(.menu)
            .focusable(false)
            .onChange(of: selectedDevice) { newValue in
                parseCurrentSerialno()
            }
        }
        .padding(15)
        .alert("提示", isPresented: $showMsgAlert) {
            Button("关闭", role: .cancel) { }
        } message: {
            Text(message)
        }
        .task {
            getDeivces()
        }
    }
    
    // 解析设备ID
    private func parseCurrentSerialno() {
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
    
    // 获取android设备列表
    private func getDeivces() {
        Task(priority: .medium) {
            do {
                let output = try await ADB.adbDevices()
                DispatchQueue.main.async {
                    DeviceList = []
                    if !output.isEmpty {
                        DeviceList = output
                        let PickerData: [String] = output.map { $0.serialno + " - " + $0.model }
                        DevicePickerData = PickerData
                        selectedDevice = PickerData.isEmpty ? "" : PickerData[0]
                    }
                }
            } catch let error as AppError {
                DispatchQueue.main.async {
                    message = error.description
                    showMsgAlert = true
                }
            }
        }
    }
}



