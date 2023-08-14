//
//  AppPackages.swift
//  aBicycle
//
//  Created by 1 on 8/10/23.
//

import SwiftUI

struct AppPackages: View {
    @EnvironmentObject var GlobalVal: GlobalObservable
    
    @State private var searchText: String = ""
    
    @State private var hoverItem: String = ""
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    
    @State private var isOnlyShowThirdPackage: Bool = false
    
    @State private var currentSerialno: String = ""
    @State private var currentDeviceAllPackageRawData: [AppPackageInfo] = []
    
    @State private var showMsgAlert = false
    @State private var message: String = ""
    
    @State private var multiSelection = Set<UUID>()
    
    // 用于确认弹窗
    @State private var showConfirmDeleteAlert = false
    
    
    var filteredPackageData: [AppPackageInfo] {
        if searchText.isEmpty {
            return currentDeviceAllPackageRawData
        } else {
            return currentDeviceAllPackageRawData.filter { $0.name.contains(searchText) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Section {
                SearchTextField(text: $searchText)
                view_checkbox_for_third_package
            }
            .padding(.horizontal, 15)
            
            if !filteredPackageData.isEmpty {
                view_app_package_list
            } else {
                view_empty
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if currentDeviceAllPackageRawData.isEmpty {
                    self.currentSerialno = GlobalVal.currentSerialno
                    getDeviceAllPackage()
                }
            }
        }
        .onChange(of: GlobalVal.currentSerialno) { value in
            self.currentSerialno = value
            getDeviceAllPackage()
        }
        .alert("提示", isPresented: $showMsgAlert) {
            Button("关闭", role: .cancel) { }
        } message: {
            Text(message)
        }
        .alert("确认", isPresented: $showConfirmDeleteAlert) {
            Button("取消", role: .cancel) {
                self.showConfirmDeleteAlert.toggle()
            }
            Button("删除", role: .destructive) {
                AppUninstall()
            }
        } message: {
            Text("是否要删除\(selectedItem)？删除后无法还原。")
        }
    }
    
    var view_empty: some View {
        Section {
            if filteredPackageData.isEmpty && !currentSerialno.isEmpty {
                EmptyView(
                    text: "No App Packages",
                    rightMenu: "Refresh Package",
                    action: { getDeviceAllPackage() }
                )
            }
            
            if currentSerialno.isEmpty {
                EmptyView(text: "currently no connected devices")
            }
        }
    }
    
    var view_checkbox_for_third_package: some View {
        Toggle(isOn: $isOnlyShowThirdPackage) {
            Label("only show third party packages", systemImage: "flag.fill")
                .labelStyle(.titleOnly)
        }
        .toggleStyle(.checkbox)
        .padding([.top], 15)
        .onChange(of: isOnlyShowThirdPackage) { val in
            getDeviceAllPackage()
        }
    }
    
    // 视图：App应用包
    var view_app_package_list: some View {
        List(filteredPackageData, selection: $multiSelection) { item in
            HStack {
                Text(item.name)
                    .frame(maxHeight: .infinity)
                Spacer()
            }
            .contentShape(Rectangle())
            .frame(height: 30)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hoverItem == item.name ? Color.primary.opacity(0.05) : Color.clear)
            .cornerRadius(3)
            .onHover { isHovered in
                hoverItem = isHovered ? item.name  : ""
                selectedItem = isHovered ? item.name  : ""
            }
        }
        .onChange(of: multiSelection) { val in
            if let selectID = val.first {
                selectedItem = filteredPackageData.first { $0.id == selectID }?.name ?? ""
            }
        }
        .onDeleteCommand {
            self.showConfirmDeleteAlert = true
        }
        .contextMenu {
            view_context_menu
        }
    }
    
    // 视图：右键菜单
    var view_context_menu: some View {
        Group {
            Button("App Uninstall") {
                self.showConfirmDeleteAlert = true
            }
            .disabled(selectedItem == "" ? true : false)
            Divider()
            Button("Refresh Package List") {
                getDeviceAllPackage()
            }
        }
    }
    
    // 获取当前设备包名
    fileprivate func getDeviceAllPackage() {
        if !self.currentSerialno.isEmpty {
            Task(priority: .medium) {
                do {
                    let cmdOption: String = isOnlyShowThirdPackage ? "-3" : "-a"
                    let output = try await ADB.packageList(serialno: currentSerialno, cmdOption: cmdOption)
                    DispatchQueue.main.async {
                        currentDeviceAllPackageRawData = []
                        if !output.isEmpty {
                            currentDeviceAllPackageRawData = output.map { AppPackageInfo(name: $0) }
                        }
                    }
                } catch let error as AppError {
                    handlerError(error: error)
                }
            }
        }
    }

    
    private func AppUninstall() {
        Task(priority: .medium) {
            do {
                let output = try await ADB.uninstallApp(serialno: currentSerialno, packageName: selectedItem)
                if output {
                    getDeviceAllPackage()
                }
                selectedItem = ""
            } catch let error as AppError {
                handlerError(error: error)
            }
        }
    }
    
    private func handlerError(error: AppError) {
        let msg = parseAppError(error)
        DispatchQueue.main.async {
            message = msg
            showMsgAlert = true
        }
    }
}
