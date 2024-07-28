//
//  DevicesManager.swift
//  SmartOvenDashboard
//
//

import Foundation
import Combine

@Observable
@MainActor
class DevicesManager {
    var needsAuthentication: Bool = false {
        didSet {
            print("NeedsAuthentication Changed: \(needsAuthentication)")
            if needsAuthentication {
                self.activeDeviceId = nil
                self.disconnect()
            } else {
                Task {
                    if !needsAuthentication {
                        await self.connect()
                    }
                }
            }
        }
    }
    
    var connected: Bool = false
    
    var activeDeviceId: String? = nil
    var deviceInfo: [String: Device] = [:]
    var devicePayloads: [String: Payload] = [:]
    
    var firstDevice: Device? {
        deviceInfo.first?.value
    }
    
    var activeDevice: Device? {
        if let deviceId = activeDeviceId {
            deviceInfo[deviceId]
        } else {
            nil
        }
    }
    
    var activeDevicePayload: Payload? {
        if let deviceId = activeDeviceId {
            devicePayloads[deviceId]
        } else {
            nil
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = DevicesManager()

    private init() {
        recieve()
    }
    
    func expireToken() {
        
    }
    
    func airFry(_ cookerId: String) {
        self.start(cookerId: cookerId, payload: CommandPayloads.airfryPayloadPayload)
    }
    
    func steam(_ cookerId: String) {
        self.start(cookerId: cookerId, payload: CommandPayloads.steamPayloadPayload)
    }
    
    func start(cookerId: String, payload: APOStartCommand.Payload.Payload) {
        let command = APOStartCommand(
            payload: .init(
                id: cookerId,
                payload: payload
            )
        )
        
        WebSocketManager.shared.sendCommand(command)
    }
    
    func stopOven(_ cookerId: String) {
        let command = APOStopCommand(
            payload: .init(
                id: cookerId
            )
        )
        
        WebSocketManager.shared.sendCommand(command)
    }
    
    func setLampPreference(_ cookerId: String, on: Bool) {
        let command = APOSetLampPreferenceCommand(
            payload: .init(
                id: cookerId,
                payload: .init(
                    on: on
                )
            )
        )
        
        WebSocketManager.shared.sendCommand(command)
    }
    
    func setTemperatureUnit(_ cookerId: String, unit: TemperatureUnit) {
        let command = APOSetTemperatureUnitCommand(
            payload: .init(
                id: cookerId,
                payload: .init(
                    temperatureUnit: unit
                )
            )
        )
        
        WebSocketManager.shared.sendCommand(command)
    }
    
    func pairOvenWithQRCode (data: String) {
        let command = AddUserWithPairingCommand(
            payload: .init(
                payload: .init(
                    data: data
                )
            )
        )
        
        WebSocketManager.shared.sendCommand(command)
    }
    
    func disconnect() {
        WebSocketManager.shared.disconnect()
        self.connected = false
    }
    
    func connect() async {
        if let authDetails = await TokenManager.shared.getAuthDetails() {
            WebSocketManager.shared.connect(token: authDetails.idToken)
        } else {
            self.needsAuthentication = true
        }
    }
    
    func recieve() {
        WebSocketManager.shared.statePublisher.combineLatest(WebSocketManager.shared.devicesPublisher).sink { payload, devices in
            self.connected = true
            
            self.deviceInfo = Dictionary(uniqueKeysWithValues: devices.map { ($0.cookerId, $0) })
            
            // Unset active if device is gone.
            if let activeDeviceId = self.activeDeviceId {
                if !self.deviceInfo.keys.contains(activeDeviceId) {
                    self.activeDeviceId = nil
                }
            }
            
            self.devicePayloads[payload.cookerId] = payload
            
            do {
                var historyPoint = HistoryPoint(from: payload)
                try AppDatabase.shared.saveHistoryPoint(&historyPoint)
            } catch {
                print("\(error)")
            }
        }
        .store(in: &cancellables)
    }
}
