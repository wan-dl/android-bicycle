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
    
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    
    @State private var currentSerialno: String = ""
    @State private var currentDeviceAllPackageRawData: [AppPackageInfo] = []
    
    @State private var showMsgAlert = false
    @State private var message: String = ""
    
    var filteredPackageData: [AppPackageInfo] {
        if searchText.isEmpty {
            return currentDeviceAllPackageRawData
        } else {
            return currentDeviceAllPackageRawData.filter { $0.name.contains(searchText) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            SearchTextField(text: $searchText)
                .padding(10)
            
            if !filteredPackageData.isEmpty {
                ScrollView() {
                    view_app_package_list
                }
            }
        }
        .onTapGesture {
            getDeviceAllPackage()
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
    }
    
    // 视图：App应用包
    var view_app_package_list: some View {
        VStack {
            ForEach(filteredPackageData, id: \.id) { item in
                VStack(alignment: .leading) {
                    Text(item.name)
                }
                .padding(.horizontal, 10)
                .frame(height: 30)
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
        .padding(.bottom, 20)
        .contextMenu {
            view_context_menu
        }
    }
    
    // 视图：右键菜单
    var view_context_menu: some View {
        Section {
            Button("App Uninstall ") {
                AppUninstall()
            }
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
                    let output = try await ADB.packageList(serialno: currentSerialno)
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
            } catch let error as AppError {
                handlerError(error: error)
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
