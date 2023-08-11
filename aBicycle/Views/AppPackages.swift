//
//  AppPackages.swift
//  aBicycle
//
//  Created by 1 on 8/10/23.
//

import SwiftUI

struct AppPackages: View {
    
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    
    @State private var currentSerialno: String = ""
    @State private var currentDeviceAllPackageList: [AppPackageInfo] = []
    
    var body: some View {
        ScrollView {
            SelectAndroidDevice(currentSerialno: $currentSerialno)
                .onChange(of: currentSerialno) { value in
                    getDeviceAllPackage()
                }
            
            if !currentDeviceAllPackageList.isEmpty {
                view_app_package_list
            }
        }
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
            Button("Refresh Package List") {
                getDeviceAllPackage()
            }
        }
    }
    
    private func getDeviceAllPackage() {
        getCurrentDevicePackageList(Serialno: $currentSerialno, AllPackageList: $currentDeviceAllPackageList)
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
