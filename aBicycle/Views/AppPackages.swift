//
//  AppPackages.swift
//  aBicycle
//
//  Created by 1 on 8/10/23.
//

import SwiftUI

struct AppPackages: View {
    
    @State private var DeviceList: [AndroidDeviceItem] = []
    @State private var DevicePickerData: [String] = [""]
    @State private var selectedDevice: String = ""
    
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    
    @State private var currentSerialno: String = ""
    @State private var currentDeviceAllPackageList: [AppPackageInfo] = []
    
    var body: some View {
        ScrollView {
            view_top
            
            if !currentDeviceAllPackageList.isEmpty {
                view_app_package_list
            }
        }
        .task {
            getAdbDevices()
        }
    }
    
    // 视图：设备下拉选择
    var view_top: some View {
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
                getDeviceAllPackage()
            }
        }
        .padding(15)
    }
    
    // 视图：App应用包
    var view_app_package_list: some View {
        VStack(alignment: .leading) {
            ForEach(currentDeviceAllPackageList, id: \.id) { item in
                VStack(alignment: .leading) {
                    Text(item.name)
                        
                }
                .padding(.horizontal, 10)
                .frame(height: 35)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .background(selectedItem == item.name  ? Color.cyan.opacity(0.05) : Color.clear)
                .cornerRadius(3)
                .onTapGesture {
                    selectedItem = item.name
                }
            }
        }
        .padding(.horizontal, 15)
        .contextMenu {
            view_context_menu
        }
    }
    
    // 视图：右键菜单
    var view_context_menu: some View {
        Section {
            
            Divider()
            Button("Refresh") {
                getAdbDevices()
            }
            Button("Refresh Package List") {
                getDeviceAllPackage()
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
    
    // 获取adb连接的设备
    private func getAdbDevices() {
        getDeivces(DeviceList: $DeviceList, DevicePickerData: $DevicePickerData, selectedDevice: $selectedDevice)
    }
    
    private func getDeviceAllPackage() {
        getCurrentDevicePackageList(Serialno: $currentSerialno, AllPackageList: $currentDeviceAllPackageList)
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


// 获取当前设备包名
fileprivate func getCurrentDevicePackageList(Serialno: Binding<String>, AllPackageList: Binding<[AppPackageInfo]>) {
    Task(priority: .medium) {
        do {
            let output = try await ADB.packageList(serialno: Serialno.wrappedValue)
            DispatchQueue.main.async {
                AllPackageList.wrappedValue = []
                if !output.isEmpty {
                    AllPackageList.wrappedValue = output.map { AppPackageInfo(name: $0) }
                }
            }
        } catch {
            DispatchQueue.main.async {
                let msg = getErrorMessage(etype: error as! AppError)
                showAlertOnlyPrompt(title: "Error", msg: msg)
            }
        }
    }
}
