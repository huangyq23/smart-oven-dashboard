//
//  ContentView.swift
//  SmartOvenDashboard
//
//

import SwiftUI
import GRDBQuery

struct Setting: Identifiable, Hashable {
    let id: String
}

struct OvenIdentity: Identifiable, Hashable {
    let id: String
}

struct ContentView: View {
    @State private var deviceManager = DevicesManager.shared
    @State private var showSettings = false
    @State private var preferredColumn = NavigationSplitViewColumn.content
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    @Environment(\.scenePhase) var scenePhase
    
    
    var body: some View {
        NavigationSplitView{
            VStack{
                if !deviceManager.needsAuthentication {
                    List(selection: $deviceManager.activeDeviceId) {
                        Section(header: Text("Ovens")) {
                            ForEach(deviceManager.deviceInfo.keys.sorted(), id: \.self) { ovenId in
                                NavigationLink(deviceManager.deviceInfo[ovenId]?.name ?? "Unknown", value: OvenIdentity(id: ovenId))
                            }
                        }
                    }
                }
                LoginStatusView()
            }
            .navigationTitle("Dashboard")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }.sheet(isPresented: $showSettings) {
                        SettingsView()
                    }
                }
            }
            
            
        } detail: {
            if let activeDeviceId = deviceManager.activeDeviceId {
                OvenDetailsView(
                    initialRequest: .init(cookerId: activeDeviceId, selectedInterval: .thirtyMinutes),
                    device: deviceManager.deviceInfo[activeDeviceId]!,
                    payload: deviceManager.devicePayloads[activeDeviceId]
                )
            }
        }
        .environment(deviceManager)
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active, .inactive:
                UIApplication.shared.isIdleTimerDisabled = true
                Task {
                    await deviceManager.connect()
                }
            case .background:
                UIApplication.shared.isIdleTimerDisabled = false
                //                deviceManager.disconnect()
                break
            @unknown default:
                break
            }
        }
    }
}

struct OvenDetailsView: View {
    var device: Device
    var payload: Payload?

//    @Query(HistoryPointRequest(cookerId: device.cookerId, selectedInterval: .thirtyMinutes)) private var historyPoints: [HistoryPoint]
    
    @Query<HistoryPointRequest>
    private var historyPoints: [HistoryPoint]
    
    @State private var selectedInterval : TimeIntervalSelection = .thirtyMinutes
    
    init(initialRequest: HistoryPointRequest, device: Device, payload: Payload? = nil) {
        _historyPoints = Query(initialRequest)
        self.device = device
        self.payload = payload
    }
    
    var body: some View {
        let combinedIntervalBinding = Binding(
            get: { self.selectedInterval },
            set: { newValue in
                self.selectedInterval = newValue
                self.$historyPoints.selectedInterval.wrappedValue = newValue
            }
        )
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Quick Control")
                    .font(.title3)
                
                QuickControlsView(
                    cooking: payload?.state.state.mode == .cook,
                    lightOn: payload?.state.nodes.lamp.preference == .on,
                    setLight: { on in
                        DevicesManager.shared.setLampPreference(device.cookerId, on: on)
                    },
                    stop: {
                        DevicesManager.shared.stopOven(device.cookerId)
                    },
                    steam: {
                        DevicesManager.shared.steam(device.cookerId)
                    },
                    airFry: {
                        DevicesManager.shared.airFry(device.cookerId)
                    }
                )
                
                if let ovenState = payload?.state {
                    Text("Temperature")
                        .font(.title3)
                    
                    LiveStatusView(ovenState: ovenState)
                }
                
                Text("Temperature History")
                    .font(.title3)
                
                VStack(spacing: 10) {
                    TimeIntervalPickerView(selectedInterval: combinedIntervalBinding)
                    
                    StoredTemperatureHistoryView(historyPoints: historyPoints, interval: selectedInterval)
                    PowerUsageView(historyPoints: historyPoints, interval: selectedInterval)
                    
                    BooleanItemHistoryView(historyPoints: historyPoints, interval: selectedInterval)
                }
            }
            .padding(20)
            .navigationTitle(device.name)
        }
        
    }
}


struct MetricCardView: View {
    @EnvironmentObject var displaySettingsManager: DisplaySettingsManager

    var title: String
    var value: Double
    var maximum: Double
    
    let gradient = Gradient(colors: [.blue, .pink])

    
    var body: some View {
        VStack {
            Gauge(value: value, in: 0...maximum) {
                Text(displaySettingsManager.temperatureUnit.rawValue)
            } currentValueLabel: {
                Text(displaySettingsManager.displayTemperatureWithoutUnit(value))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(gradient)
            Text(title)
                .font(.caption)
        }
        .padding(0)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
    }
}

struct OvenDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        OvenDetailsView(
            initialRequest: .init(cookerId: Fixtures.exampleDevice.cookerId, selectedInterval: .thirtyMinutes),
            device: Fixtures.exampleDevice,
            payload: Fixtures.examplePayload)
        .environmentObject(DisplaySettingsManager(forceUnit: .fahrenheit))
        .environment(\.appDatabase, .random())
    }
}

#Preview {
    ContentView()
        .environmentObject(DisplaySettingsManager(forceUnit: .fahrenheit))
}

struct LiveStatusView: View {
    var ovenState: OvenState
    
    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: 80))
        ]
        
        let temperatureBulbs = ovenState.nodes.temperatureBulbs
        let steamGenerators = ovenState.nodes.steamGenerators
        let temperatureProbe = ovenState.nodes.temperatureProbe
        
        LazyVGrid(columns: columns, spacing: 10) {
            MetricCardView(title: "Wet", value: temperatureBulbs.wet.current.celsius, maximum: 100)
            MetricCardView(title: "Dry", value: temperatureBulbs.dry.current.celsius, maximum: 200)
            MetricCardView(title: "Dry Top", value: temperatureBulbs.dryTop.current.celsius, maximum: 200)
            MetricCardView(title: "Dry Bottom", value: temperatureBulbs.dryBottom.current.celsius, maximum: 200)
            MetricCardView(title: "Evaporator", value: steamGenerators.evaporator.celsius, maximum: 100)
            MetricCardView(title: "Boiler", value: steamGenerators.boiler.celsius, maximum: 100)
            if temperatureProbe.connected {
                MetricCardView(title: "Probe", value: temperatureProbe.current?.celsius ?? -1, maximum: 100)
            }
            
        }
    }
}
