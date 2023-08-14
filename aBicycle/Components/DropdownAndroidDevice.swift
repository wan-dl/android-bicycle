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
    
    @State private var message: String = ""
    @State private var showMsgAlert: Bool = false
    
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
        .popover(isPresented: $isMenuVisible, arrowEdge: .bottom) {
            view_popover
        }
        .onTapGesture {
            self.isMenuVisible.toggle()
            getDevices()
        }
        .onAppear() {
            getDevices()
        }
        .onChange(of: selectedDevice) { item in
            GlobalVal.currentSerialno = item.serialno
        }
        .onChange(of: GlobalVal.isEmulatorStop) { value in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                getDevices()
            }
        }
        .onChange(of: GlobalVal.isEmulatorStart) { value in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                getDevices()
            }
        }.alert("提示", isPresented: $showMsgAlert) {
            Button("关闭", role: .cancel) { }
        } message: {
            Text(message)
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
    
    // 获取android设备列表
    private func getDevices() {
        Task(priority: .medium) {
            do {
                let output = try await ADB.adbDevices()
                DispatchQueue.main.async {
                    DeviceList = []
                    selectedDevice = AndroidDeviceItem(model: "", serialno: "")
                    if !output.isEmpty {
                        DeviceList = output
                        let _: [String] = output.map { $0.serialno + " - " + $0.model }
                        selectedDevice = output[0]
                    }
                }
            } catch {
                print("--->", error)
                handlerError(error: error as! AppError)
            }
        }
    }
    
    private func handlerError(error: AppError) {
        if case .ExecutionFailed(let output) = error {
            message = output
        } else {
            message = getErrorMessage(etype: error)
        }
        DispatchQueue.main.async {
            showMsgAlert = true
        }
    }
}



