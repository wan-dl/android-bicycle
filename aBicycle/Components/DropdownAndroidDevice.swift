//
//  DropdownAndroidDevice.swift
//  aBicycle
//
//  Created by 1 on 8/11/23.
//

import SwiftUI

struct DropdownAndroidDevice: View {
    
    @EnvironmentObject var GlobalVal: GlobalObservable
    @State private var currentSerialno: String = ""
    
    @State private var isMenuVisible = false
    @State private var isContextMenuVisible = false
    @State private var hoverDeviceItem: String = ""
    
    @State private var DeviceList: [AndroidDeviceItem] = []
    @State private var selectedDevice: AndroidDeviceItem = AndroidDeviceItem(model: "", serialno: "")
    
    var body: some View {
        HStack {
            Image(systemName: "iphone.rear.camera")
            
            VStack(alignment: .leading) {
                if !selectedDevice.model.isEmpty {
                    Text(selectedDevice.model)
                    HStack {
                        Text(selectedDevice.serialno)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                } else {
                    Text("No Device")
                        .help("Click to get device")
                }
            }
        }
        .frame(width: 170, alignment: .trailing)
        .onTapGesture {
            self.isMenuVisible.toggle()
            getDeivceList(DeviceList: $DeviceList, selectedDevice: $selectedDevice)
        }
        .popover(isPresented: $isMenuVisible, arrowEdge: .bottom) {
            view_popover
        }
        .onAppear() {
            getDeivceList(DeviceList: $DeviceList, selectedDevice: $selectedDevice)
        }
        .onChange(of: selectedDevice) { item in
            GlobalVal.currentSerialno = item.serialno
        }
    }
    
    var view_popover: some View {
        VStack(alignment: .leading) {
            ScrollView {
                ForEach(DeviceList) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.model)
                        Text(item.serialno).lineLimit(1)
                            .font(.footnote)
                    }
                    .padding(.leading, 12)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(hoverDeviceItem == item.serialno ? Color.gray.opacity(0.2) : Color.clear)
                    .cornerRadius(3)
                    .onHover { isHovered in
                        hoverDeviceItem = isHovered ? item.serialno : ""
                    }
                    .onTapGesture {
                    }
                }
            }
        }
        .padding(15)
        .cornerRadius(8)
        .background(.gray.opacity(0.01))
        .frame(width: 280)
        .frame(minHeight: 190, maxHeight: 210)
    }
    
    var view_ref_contextMenu: some View {
        Label("", systemImage: "ellipsis.circle")
            .contextMenu {
            }
    }
    
    // 打开下拉列表
    private func open(refname: String) {
        DispatchQueue.main.async {
            isMenuVisible = false
        }
    }
}


// 获取android设备列表
fileprivate func getDeivceList(DeviceList: Binding<[AndroidDeviceItem]>, selectedDevice: Binding<AndroidDeviceItem>) {
    Task(priority: .medium) {
        do {
            let output = try await ADB.adbDevices()
            DispatchQueue.main.async {
                DeviceList.wrappedValue = []
                if !output.isEmpty {
                    DeviceList.wrappedValue = output
                    let _: [String] = output.map { $0.serialno + " - " + $0.model }
                    selectedDevice.wrappedValue = output[0]
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
