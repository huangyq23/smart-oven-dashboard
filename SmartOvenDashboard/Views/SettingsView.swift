//
//  SettingsView.swift
//  SmartOvenDashboard
//
//

import SwiftUI
import CodeScanner


struct DevicesView: View {
    @Environment(DevicesManager.self) var devicesManager
    
    @State private var selectedDeviceId: String? = nil
    
    @State private var isShowingScanner: Bool = false


    @MainActor
    func handleScan(result: Result<ScanResult, ScanError>) {
       isShowingScanner = false
        switch result {
        case .success(let result):
            let details = result.string
            devicesManager.pairOvenWithQRCode(data: details)
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        List(selection: $selectedDeviceId) {
            Section(header: Text("Ovens")) {
                ForEach(devicesManager.deviceInfo.keys.sorted(), id: \.self) { ovenId in
                    let oven = devicesManager.deviceInfo[ovenId]!
                    VStack(alignment: .leading) {
                        Text(oven.name)
                        Text(oven.cookerId).font(.caption)
                    }.listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
                }

                Button {
                    isShowingScanner = true
                } label: {
                    Text("Add Oven")
                }
                .sheet(isPresented: $isShowingScanner) {
                    NavigationStack{
                        CodeScannerView(codeTypes: [.qr], simulatedData: "blah", completion: handleScan)
                            .navigationTitle("Scan Pair Code")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Cancel") {
                                        isShowingScanner = false
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(DevicesManager.self) var devicesManager
    @State private var exportCompleted = false
    @State private var documentUrl: URL?
    @State private var exportingCSV = false
    @State private var showCsvPreview = false
    
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"


    var body: some View {
        NavigationStack{
            List {
                Section("Display") {
                    TemperatureUnitPickerView()
                }
                Section("Status") {
                    if WebSocketManager.shared.connected {
                        HStack{
                            Text("WebSocket")
                            Spacer()
                            Text("Connected").foregroundStyle(.secondary)
                        }
                        NavigationLink {
                            DevicesView()
                        } label: {
                            Text("Manage Devices")
                        }
                        NavigationLink {
                            List(WebSocketManager.shared.messageLog, id: \.self) { message in
                                Text(message)
                            }
                        } label: {
                            Text("WebSocket Debug Logs")
                        }

                    }
                    else {
                        HStack{
                            Text("WebSocket")
                            Spacer()
                            Text("Not Connected").foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Application") {
                    HStack{
                        Text("App Version")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    HStack{
                        Text("Build Number")
                        Spacer()
                        Text(buildNumber).foregroundStyle(.secondary)
                    }
                }
                Section("Date Export - Experimental") {
                    HStack{
                        Button {
                            self.exportingCSV = true
                            Task {
                                if let url = AppDatabase.shared.exportCSVFromTable(tableName: "ovenHistory") {
                                    DispatchQueue.main.async {
                                        self.exportingCSV = false
                                        self.documentUrl = url
                                        self.showCsvPreview = true
                                    }
                                }
                                DispatchQueue.main.async {
                                    self.exportingCSV = false
                                }
                            }
                        } label: {
                            Text("Export History Data as CSV")
                        }
                        if self.exportingCSV {
                            Spacer()
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                    Button {
                        AppDatabase.shared.backup()
                        self.exportCompleted = true
                    } label: {
                        Text("Export Backup")
                    }
                    .alert("Data Backup Saved", isPresented: $exportCompleted) {
                        
                    }
                }
                Section {
                    if !devicesManager.needsAuthentication {
                        Button {
                            TokenManager.shared.clearAuthDetails()
                            devicesManager.needsAuthentication = true
                            dismiss()
                        } label: {
                            Text("Sign Out")
                                .foregroundStyle(.red)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            DocumentInteractionController(isActive: $showCsvPreview, url: self.documentUrl)
                .frame(width: 0, height: 0)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DisplaySettingsManager(forceUnit: .celsius))
        .environment(DevicesManager.shared)
}
