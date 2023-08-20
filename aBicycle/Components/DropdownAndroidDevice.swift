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
    
    @State private var isOnAppear: Bool = false
    @State private var isRefresh: Bool = false
    
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
                    Text("lproj_NoDevice")
                        .help("Click to get device")
                }
            }
            view_refresh_btn
        }
        .frame(width: 170, alignment: .trailing)
        .popover(isPresented: $isMenuVisible, arrowEdge: .bottom) {
            view_popover
        }
        .onTapGesture {
            if !DeviceList.isEmpty {
                self.isMenuVisible.toggle()
            }
            getDevices()
        }
        .onAppear() {
            isOnAppear = true
            getDevices()
        }
        .onChange(of: selectedDevice) { item in
            GlobalVal.currentSerialno = item.serialno
        }
        .onChange(of: [GlobalVal.isEmulatorStop, GlobalVal.isEmulatorStart]) { values in
            scheduleDelayedGetDevices(attempts: 3)
        }
        .alert("提示", isPresented: $showMsgAlert) {
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
            .contextMenu {}
    }
    
    var view_refresh_btn: some View {
        Button(action: {
            DispatchQueue.main.async {
                isRefresh.toggle()
            }
            getDevices()
        }, label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .rotationEffect(.degrees(isRefresh ? 360 : 0))
                .animation(Animation.linear(duration: 2), value: isRefresh)
                .help("Fetch")
        })
        .buttonStyle(PlainButtonStyle())
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
                        isRefresh.toggle()
                    }
                }
            } catch let error as AppError {
                if isOnAppear {
                    isOnAppear = false
                } else {
                    handlerError(error: error)
                }
            }
        }
    }
    
    // 错误处理
    private func handlerError(error: AppError) {
        let msg = parseAppError(error)
        DispatchQueue.main.async {
            message = msg
            showMsgAlert = true
        }
    }
    
    // adb devices获取数据，会有延迟，推迟3秒，执行3次
    func scheduleDelayedGetDevices(attempts: Int) {
        guard attempts > 0 else {
            return
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
            getDevices()
            scheduleDelayedGetDevices(attempts: attempts - 1)
        }
    }

}



