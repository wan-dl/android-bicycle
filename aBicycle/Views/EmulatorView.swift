//
//  EmulatorView.swift
//  aBicycle
//
//  Created by 1 on 8/3/23.
//

import SwiftUI


struct EmulatorView: View {
    @EnvironmentObject var GlobalVal: GlobalObservable
    
    @StateObject private var viewModel = AvdViewModel()
    
    @State private var selectedItemId: String = ""
    @State private var selectedItem: String = ""
    @State private var hoverItemId: String = ""
    @State private var hoverItem: String = ""
    
    @State private var isHoverBootButton: String = ""
    @State private var isHoverMoreButton: String = ""
    
    @State private var showDeleteAlert = false
    @State private var deleteAvdName: String = ""
    
    
    var body: some View {
        ScrollView {
            if viewModel.emulatorList.isEmpty {
                EmptyView(text: "No Emulator")
            }
            
            if (viewModel.emulatorList.count != 0) {
                VStack {
                    view_show_emulator_list
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 20)
                .alert("是否确认删除？", isPresented: $showDeleteAlert) {
                    Button("确认", role: .cancel ) {
                        viewModel.deleteAvd(name: deleteAvdName)
                    }
                    Button("取消", role: .cancel) { }
                }
                .alert("提示", isPresented: $viewModel.showMsgAlert) {
                    Button("关闭", role: .cancel) { }
                } message: {
                    Text(viewModel.message)
                }
            }
        }
        .task {
            viewModel.getEmulatorList()
            viewModel.getAvdmanagerList()
        }
        .contextMenu {
            view_context_menu
        }
    }
    
    // 视图：展示模拟器列表数据
    var view_show_emulator_list: some View {
        ForEach(viewModel.emulatorList) { item in
            HStack() {
                Label("", systemImage: "circle.fill")
                    .font(.caption2)
                    .labelStyle(.iconOnly)
                    .foregroundColor(viewModel.activeEmulatorList.contains(item.Name) ? Color.green : Color.clear)
                Image("android")
                    .resizable()
                    .frame(width: 24, height: 24)
                view_show_avd_info(item: item)
                Spacer()
                HStack {
                    if viewModel.activeEmulatorList.contains(item.Name) {
                        view_boot_button(action_name: "stop", avd_name: item.Name)
                    } else {
                        view_boot_button(action_name: "start", avd_name: item.Name)
                            
                    }
                    view_more_button(item: item)
                }
            }
            .padding(.trailing, 10)
            .frame(height: 55)
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
    }
    
    // 视图：展示模拟器信息，比如名称、操作系统版本号等
    func view_show_avd_info(item: AvdItem) -> some View {
        VStack(alignment: .leading) {
            Text(item.Name)
                .font(.body)
            HStack {
                if item.Version != "" {
                    Text("\(item.Version) \(item.ABI) \(item.Skin)")
                        .font(.caption)
                        .padding([.top], 0.1)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.05))
                        .frame(width: 300, height: 10)
                }
            }
        }
    }
    
    // 视图: 启动和停止按钮
    func view_boot_button(action_name: String, avd_name: String) -> some View {
        Button(action: {
            if action_name == "start" {
                viewModel.bootEmulator(avdName: avd_name)
                GlobalVal.isEmulatorStart += 1
            } else {
                viewModel.killEmulator(avd_name: avd_name)
                GlobalVal.isEmulatorStop += 1
            }
            
        }) {
            Label("\(action_name)_emulator", systemImage: action_name == "stop" ? "stop.circle.fill": "play.fill")
                .font(.title3)
                .labelStyle(.iconOnly)
                .frame(width: 30, height: 45)
                .contentShape(Rectangle())
        }
        .buttonStyle(avdBootButtonStyle(avd_name: avd_name ,isHover: $isHoverBootButton))
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
                deleteAvdName = item.Name
                showDeleteAlert = true
            })
        } label: {
            Label("more actions", systemImage: "ellipsis")
                .font(.title3)
                .labelStyle(.iconOnly)
                .frame(width: 30, height: 45)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 35, height: 25)
        .background(isHoverMoreButton == item.Name ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { isHovered in
            isHoverMoreButton = isHovered ? item.Name  : ""
        }
    }
    
    // 视图：右键菜单
    var view_context_menu: some View {
        Section {
            Button("Refresh Device") {
                viewModel.getEmulatorList()
                viewModel.getAvdmanagerList()
            }
            Divider()
        }
    }
}

fileprivate final class AvdViewModel: ObservableObject {
    // 存储 emulator -list-avds输出。此命令输出结果特别快
    @Published var emulatorList: [AvdItem] = []
    
    @Published var activeEmulatorList: [String] = []
    
    @Published var showMsgAlert = false
    @Published var message: String = ""
    
    
    func handlerError(error: AppError) {
        if case .ExecutionFailed(let output) = error {
            self.message = output
        } else {
            self.message = getErrorMessage(etype: error)
        }
        DispatchQueue.main.async {
            self.showMsgAlert = true
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
            } catch let error as AppError {
                handlerError(error: error)
            }
        }
    }
    
    // 通过avdmanager list avd命令行获取模拟器列表
    func getAvdmanagerList() {
        Task(priority: .high) {
            do {
                let output = try await AVDManager.getAvdList()
                if !output.isEmpty {
                    let newArray = replaceMatchingItems(in: emulatorList, withItemsFrom: output)
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
            let output = try await AndroidEmulatorManager.getActiveEmulatorList(EmulatorList: allEmulator)
            DispatchQueue.main.async {
                self.activeEmulatorList = output
            }
        } catch {
            if let appError = error as? AppError {
                handlerError(error: appError)
            } else {
                print("[error] getStartedEmulator(): \(error)")
            }
        }
    }
    
    // 模拟器：删除模拟器
    func deleteAvd(name: String) {
        Task(priority: .medium) {
            do {
                let output = try await AVDManager.delete(name: name)
                if output {
                    let tmp: [AvdItem] = self.emulatorList
                    DispatchQueue.main.async {
                        self.emulatorList = tmp.filter { item in
                            return item.Name != name
                        }
                    }
                }
            } catch let error as AppError {
                handlerError(error: error)
            }
        }
    }
    
    // 模拟器: 通过emulator命令启动
    func bootEmulator(avdName: String) {
        AndroidEmulatorManager.startEmulator(emulatorName: avdName) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.activeEmulatorList.append(avdName)
                }
            } else {
                DispatchQueue.main.async {
                    self.message = String(describing: error)
                    self.showMsgAlert = true
                }
            }
        }
    }
    
    // 模拟器：停止杀死模拟器
    func killEmulator(avd_name: String) {
        Task {
            do {
                let output = try await AndroidEmulatorManager.killEmulator(emulatorName: avd_name)
                if output == true {
                    DispatchQueue.main.async {
                        self.activeEmulatorList.removeAll { element in
                            return element == avd_name
                        }
                    }
                }
            } catch let error as AppError {
                handlerError(error: error)
            }
        }
    }
    
    // emulator -list-avds输出结果比avdmanager list avds快，但是emulator输出内容少。
    // 因此先用emulator获取，然后avdmanager有结果时再替换数据。
    private func replaceMatchingItems(in array1: [AvdItem], withItemsFrom array2: [AvdItem]) -> [AvdItem] {
        return array1.map { item1 in
            if let matchingItem2 = array2.first(where: { $0.Name == item1.Name }) {
                return matchingItem2
            } else {
                return item1
            }
        }
    }
}
