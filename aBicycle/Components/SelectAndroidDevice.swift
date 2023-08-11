//
//  SelectAndroidDevice.swift
//  aBicycle
//
//  Created by 1 on 8/11/23.
//

import SwiftUI

struct SelectAndroidDevice: View {
    
    @State private var DeviceList: [AndroidDeviceItem] = []
    @State private var DevicePickerData: [String] = [""]
    @State private var selectedDevice: String = ""
    
    @Binding var currentSerialno: String
    
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
        .task {
            getDeivces(DeviceList: $DeviceList, DevicePickerData: $DevicePickerData, selectedDevice: $selectedDevice)
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
}


// 获取android设备列表
fileprivate func getDeivces(DeviceList: Binding<[AndroidDeviceItem]>, DevicePickerData: Binding<[String]>, selectedDevice: Binding<String>) {
    Task(priority: .medium) {
        do {
            let output = try await ADB.adbDevices()
            DispatchQueue.main.async {
                DeviceList.wrappedValue = []
                if !output.isEmpty {
                    DeviceList.wrappedValue = output
                    let PickerData: [String] = output.map { $0.serialno + " - " + $0.model }
                    DevicePickerData.wrappedValue = PickerData
                    selectedDevice.wrappedValue = PickerData.isEmpty ? "" : PickerData[0]
                }
            }
        } catch let error {
            DispatchQueue.main.async {
                let msg = getErrorMessage(etype: error as! AppError)
                showAlertOnlyPrompt(title: "Error", msg: msg)
            }
        }
    }
}
