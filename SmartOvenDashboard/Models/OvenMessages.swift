//
//  OvenMessages.swift
//  SmartOvenDashboard
//
//

import Foundation

struct ApplianceCommandType: Codable {
    let command: String
}

struct APOWifiListCommand: Codable {
    let command: String
    let payload: [Device]
}

struct Device: Codable {
    let cookerId, name, pairedAt, type: String
}

protocol APOCommand: Codable {
    associatedtype PayloadType: Codable
    var command: String { get }
    var payload: PayloadType { get }
    var requestId: UUID { get }
}

struct APOStartCommand: Codable, APOCommand {
    var command: String = "CMD_APO_START"
    let payload: Payload
    var requestId: UUID = UUID()
  
    struct Payload: Codable {
        let id: String
        let payload: Payload
        var type: String = "CMD_APO_START"
        
        struct Payload: Codable {
            let cookId: String
            let stages: [StartPayloadStage]
        }
    }
}

struct StartPayloadStage: Codable {
    let stepType, id, title, description: String
    let type: String
    let userActionRequired: Bool
    let temperatureBulbs: StageTemperatureBulbs
    let heatingElements: StageHeatingElements
    let fan: StageFan
    let vent: Vent
    let rackPosition: Int
    let timerAdded: Bool?
    let probeAdded: Bool
    let steamGenerators: StageSteamGenerators?
}

struct APOStopCommand: Codable, APOCommand {
    var requestId: UUID = UUID()
    var command: String = "CMD_APO_STOP"
    let payload: Payload
    
    struct Payload: Codable {
        let id: String
        var type: String = "CMD_APO_STOP"
    }
}

struct AddUserWithPairingCommand: Codable, APOCommand {
    var requestId: UUID = UUID()
    var command: String = "CMD_ADD_USER_WITH_PAIRING"
    let payload: Payload
    
    struct Payload: Codable {
        var id: String = ""
        var type: String = "CMD_ADD_USER_WITH_PAIRING"
        let payload: Payload
        
        struct Payload: Codable {
            let data: String
        }
    }
}

struct APOSetLampPreferenceCommand: Codable, APOCommand {
    var requestId: UUID = UUID()
    var command: String = "CMD_APO_SET_LAMP_PREFERENCE"
    let payload: Payload
    
    struct Payload: Codable {
        let id: String
        let payload: Payload
        var type: String = "CMD_APO_SET_LAMP_PREFERENCE"
        
        struct Payload: Codable {
            let on: Bool
        }
    }
}

struct APOSetTemperatureUnitCommand: Codable, APOCommand {
    var requestId: UUID = UUID()
    var command: String = "CMD_APO_SET_TEMPERATURE_UNIT"
    let payload: Payload
    
    struct Payload: Codable {
        let id: String
        let payload: Payload
        var type: String = "CMD_APO_SET_TEMPERATURE_UNIT"
        
        struct Payload: Codable {
            let temperatureUnit: TemperatureUnit
        }
    }
}

// Define the top-level structure
struct ApplianceCommand: Codable {
    let command: String
    let payload: Payload
}

// Define the payload structure
struct Payload: Codable {
    let cookerId: String
    let type: String
    let state: OvenState
}

// Define the state structure
struct OvenState: Codable {
    let version: Int
    let updatedTimestamp: Date
    let systemInfo: SystemInfo
    let state: CookerState
    let nodes: Nodes
    let cook: Cook?
}

struct Cook: Codable {
    let activeStageId: String
    let stages: [Stage]
    let activeStageSecondsElapsed, secondsElapsed: Int
    let cookId: String
    let activeStageIndex: Int
    let stageTransitionPendingUserAction: Bool
    
    var activeStage: Stage {
        stages[activeStageIndex]
    }
}

// MARK: - Stage
struct Stage: Codable {
    let fan: StageFan
    let heatingElements: StageHeatingElements
    let temperatureBulbs: StageTemperatureBulbs
    let userActionRequired: Bool
    let id: String
    let type: StageType
    let vent: Vent
    let title: Int
    let steamGenerators: StageSteamGenerators?
}

enum StageType: String, Codable {
    case idle = "cook"
    case cook = "preheat"
    case descale = "stop"
}

// MARK: - StageFan
struct StageFan: Codable {
    let speed: Int
}

// MARK: - StageHeatingElements
struct StageHeatingElements: Codable {
    let rear, top, bottom: HeatingElementStatus
}

// MARK: - PurpleBottom
struct HeatingElementStatus: Codable {
    let on: Bool
}

// MARK: - StageTemperatureBulbs
struct StageTemperatureBulbs: Codable {
    let mode: String
    let dry: StageDry?
    let wet: StageWet?
}

struct StageDry: Codable {
    let setpoint: Temperature
}

struct StageWet: Codable {
    let setpoint: Temperature
}

struct StageSteamGenerators: Codable {
    let mode: String
    let relativeHumidity: StageRelativeHumidity?
    let steamPercentage: StageSteamPercentage?
}

struct StageRelativeHumidity: Codable {
    let setpoint: Double
}

struct StageSteamPercentage: Codable {
    let setpoint: Double
}

// Define the system info structure
struct SystemInfo: Codable {
    let online: Bool
    let hardwareVersion: String
    let powerMains: Int
    let powerHertz: Int
    let firmwareVersion: String
    let uiHardwareVersion: String
    let uiFirmwareVersion: String
//    let firmwareUpdatedTimestamp: String
    let lastConnectedTimestamp, lastDisconnectedTimestamp: Date
    let triacsFailed: Bool
}


enum CookerStateMode: String, Codable {
    case idle = "idle"
    case cook = "cook"
    case descale = "descale"
    // Add other cases as needed
}

enum TemperatureUnit: String, Codable {
    case c = "C"
    case f = "F"
}

// Define the cooker state structure
struct CookerState: Codable {
    let mode: CookerStateMode
    let temperatureUnit: TemperatureUnit
    let processedCommandIds: [UUID]
}

// Define the nodes structure
struct Nodes: Codable {
    let temperatureBulbs: TemperatureBulbs
    let timer: Timer
    let temperatureProbe: TemperatureProbe
    let steamGenerators: SteamGenerators
    let heatingElements: HeatingElements
    let fan: Fan
    let vent: Vent
    let waterTank: WaterTank
    let door: Door
    let lamp: Lamp
    let userInterfaceCircuit: UserInterfaceCircuit
}

enum TemperatureBulbsMode: String, Codable {
    case dry = "dry"
    case wet = "wet"
    // Add other cases as needed
}

// Define other nested structures
struct TemperatureBulbs: Codable {
    let mode: TemperatureBulbsMode
    let wet: Wet
    let dry: Dry
    let dryTop: DryTop
    let dryBottom: DryBottom
}

protocol TemperaturePoint: Codable {
    var current: Temperature { get }
}

protocol TemperatureSetpoint: Codable {
    var setpoint: Temperature? { get }
}

struct Wet: Codable, TemperaturePoint, TemperatureSetpoint {
    let current: Temperature
    let setpoint: Temperature?
    let dosed: Bool
    let doseFailed: Bool
}

struct Dry: Codable, TemperaturePoint, TemperatureSetpoint {
    let current: Temperature
    let setpoint: Temperature?
}

struct DryTop: Codable, TemperaturePoint {
    let current: Temperature
    let overheated: Bool
}

struct DryBottom: Codable, TemperaturePoint {
    let current: Temperature
    let overheated: Bool
}

struct Temperature: Codable {
    let celsius: Double
    let fahrenheit: Double
}

enum TimerMode: String, Codable {
    case complete = "complete"
    case idle = "idle"
    case paused = "paused"
    case running = "running"
}

struct Timer: Codable {
    let mode: TimerMode
    let initial: Int
    let current: Int
}

struct TemperatureProbe: Codable {
    let connected: Bool
    let current: Temperature?
    let setpoint: Temperature?
}

enum SteamGeneratorMode: String, Codable {
    case relativeHumidity = "relative-humidity"
    case steamPercentage = "steam-percentage"
    case idle = "idle"
}

struct SteamGenerators: Codable {
    let mode: SteamGeneratorMode
    let relativeHumidity: RelativeHumidity?
    let evaporator: Evaporator
    let boiler: Boiler
    let steamPercentage: SteamPercentage?
}

struct RelativeHumidity: Codable {
    let setpoint: Double?
    let current: Double?
}

struct SteamPercentage: Codable {
    let setpoint: Double
}

struct Evaporator: Codable {
    let failed: Bool
    let overheated: Bool
    let celsius: Double
    let watts: Int
}

struct Boiler: Codable {
    let celsius: Double
    let descaleRequired: Bool
    let dosed: Bool
    let failed: Bool
    let overheated: Bool
    let watts: Int
}

struct HeatingElements: Codable {
    let top: HeatingElement
    let bottom: HeatingElement
    let rear: HeatingElement
}

struct HeatingElement: Codable {
    let on: Bool
    let failed: Bool
    let watts: Int
}

struct Fan: Codable {
    let speed: Int
    let failed: Bool
}

struct Vent: Codable {
    let open: Bool
}

struct WaterTank: Codable {
    let empty: Bool
}

struct Door: Codable {
    let closed: Bool
}

enum LampPreference: String, Codable {
    case on = "on"
    case off = "off"
}

struct Lamp: Codable {
    let on: Bool
    let failed: Bool
    let preference: LampPreference
}

struct UserInterfaceCircuit: Codable {
    let communicationFailed: Bool
}
