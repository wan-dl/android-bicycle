//
//  EmulatorView.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import SwiftUI


struct EmulatorView: View {
    // 存储 avdmanager list avds输出
    @State var avdsList: [AvdItem] = []
    
    // 存储 emulator -list-avds输出。此命令输出结果特别快
    @State var emulatorList: [AvdItem] = []
    
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    @State private var hoverItemId: String = ""
    @State private var hoverItem: String = ""
    
    @State private var activeEmulatorList: [String] = []
    
    var body: some View {
        ScrollView {
            if emulatorList.isEmpty {
                EmptyView(text: "No Emulator")
            }
            
            if (emulatorList.count != 0) {
                view_show_emulator_list
                    .padding(.horizontal, 10)
                    .offset(y: 20)
            }
        }
        .task {
            getEmulatorList()
            getAvdmanagerList()
        }
        .contextMenu {
            view_context_menu
        }
    }
    
    var view_show_emulator_list: some View {
        ForEach(emulatorList) { item in
            HStack() {
                Label("", systemImage: "circle.fill")
                    .font(.caption2)
                    .labelStyle(.iconOnly)
                    .foregroundColor(self.activeEmulatorList.contains(item.Name) ? Color.green : Color.clear)
                Image("android")
                    .resizable()
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading) {
                    Text(item.Name)
                        .font(.body)
                    HStack {
                        Text("\(item.Version) \(item.ABI)")
                            .font(.caption)
                            .padding([.top], 0.1)
                    }
                }
                Spacer()
                HStack {
                    if self.activeEmulatorList.contains(item.Name) {
                        view_boot_button(name: "stop")
                    } else {
                        view_boot_button(name: "start")
                    }
                    view_more_button(item: item)
                }
                .padding(.horizontal, 15)
            }
            .frame(height: 50)
            .background(hoverItemId == item.id ? Color.gray.opacity(0.1) : Color.clear)
            .background(selectedItem == item.Name  ? Color.cyan.opacity(0.05) : Color.clear)
            .cornerRadius(3)
            .onHover { isHovered in
                hoverItemId = isHovered ? item.id : ""
                hoverItem = isHovered ? item.Name : ""
            }
            .onTapGesture {
                selectedItem = item.Name
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    
    // 视图: 启动和停止按钮
    func view_boot_button(name: String) -> some View {
        Button(action: {
            name == "start" ? bootEmulator() : killEmulator()
        }) {
            Label("\(name)_emulator", systemImage: name == "stop" ? "stop.circle.fill": "play.fill")
                .font(.title3)
                .labelStyle(.iconOnly)
                .frame(width: 30, height: 45)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // 视图：更多按钮
    func view_more_button(item: AvdItem) -> some View {
        Menu {
            Button("open Finder", action: {
                RevealInFinder(at: item.Path)
            })
            .disabled(item.Path == "" ? true : false)
            
            Divider()
            Button("Delete", action: {
                deleteAvd(name: item.Name)
            })
        } label: {
            Label("more actions", systemImage: "ellipsis")
                .font(.title3)
                .labelStyle(.iconOnly)
                .frame(width: 30, height: 45)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
    }
    
    // 视图：右键菜单
    var view_context_menu: some View {
        Section {
            Button("Refresh Device") {
                getEmulatorList()
                getAvdmanagerList()
            }
            Divider()
        }
    }
    
    // 通过emulator命令：获取模拟器列表
    func getEmulatorList() {
        Task(priority: .medium) {
            do {
                let output = try await AndroidEmulatorManager.getEmulatorList()
                DispatchQueue.main.async {
                    self.emulatorList = []
                    if !output.isEmpty {
                        for i in output {
                            self.emulatorList.append(AvdItem(Name: i))
                        }
                    }
                }
                await getStartedEmulator(allEmulator: output)
            } catch let error {
                let msg = getErrorMessage(etype: error as! AppError)
                showAlertOnlyPrompt(title: "Error", msg: msg)
            }
        }
    }
    
    // 通过avdmanager list avd命令行获取模拟器列表
    func getAvdmanagerList() {
        Task(priority: .medium) {
            do {
                let output = try await AVDManager.getAvdList()
                if !output.isEmpty {
                    let newArray = replaceMatchingItems(in: self.emulatorList, withItemsFrom: output)
                    //print("[newArray]...\(newArray)")
                    if !newArray.isEmpty {
                        DispatchQueue.main.async {
                            self.emulatorList = newArray
                        }
                    }
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    // 通过emulator命令：获取激活的模拟器列表
    func getStartedEmulator(allEmulator: [String]) async {
        do {
            self.activeEmulatorList = try await AndroidEmulatorManager.getActiveEmulatorList(EmulatorList: allEmulator)
            //print("[activeEmulatorList] \(self.activeEmulatorList)")
        } catch let error {
            let msg = getErrorMessage(etype: error as! AppError)
            showAlertOnlyPrompt(title: "Error", msg: msg)
        }
    }
    
    // 通过emulator命令：启动模拟器
    func bootEmulator() {
        if (self.hoverItem == "") {
            return
        }
        let avdName = self.hoverItem
        AndroidEmulatorManager.startEmulator(emulatorName: avdName) { success, error in
            if success {
                activeEmulatorList.append(avdName)
            } else if let error = error {
                let msg = getErrorMessage(etype: error as! AppError)
                showAlertOnlyPrompt(title: "Error", msg: msg)
            }
        }
    }
    
    // 模拟器：停止杀死模拟器
    func killEmulator() {
        Task {
            if (self.hoverItem == "") {
                return
            }
            let avdName = self.hoverItem
            do {
                let output = try await AndroidEmulatorManager.killEmulator(emulatorName: avdName)
                if output == true {
                    activeEmulatorList.removeAll { element in
                        return element == avdName
                    }
                }
            } catch {
                let msg = getErrorMessage(etype: error as! AppError)
                showAlertOnlyPrompt(title: "Error", msg: msg)
            }
        }
    }
    
    // 模拟器：删除模拟器
    func deleteAvd(name: String) {
        Task(priority: .medium) {
            do {
                let output = try await AVDManager.delete(name: name)
                if output {
                    
                }
            } catch let error {
                let msg = getErrorMessage(etype: error as! AppError)
                showAlertOnlyPrompt(title: "Error", msg: msg)
            }
        }
    }
}


// emulator -list-avds输出结果比avdmanager list avds快，但是emulator输出内容少。
// 因此先用emulator获取，然后avdmanager有结果时再替换数据。
func replaceMatchingItems(in array1: [AvdItem], withItemsFrom array2: [AvdItem]) -> [AvdItem] {
    return array1.map { item1 in
        if let matchingItem2 = array2.first(where: { $0.Name == item1.Name }) {
            return matchingItem2
        } else {
            return item1
        }
    }
}
