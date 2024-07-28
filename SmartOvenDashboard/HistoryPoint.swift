import GRDB
import Foundation

/// The Player struct.
///
/// Identifiable conformance supports SwiftUI list animations, and type-safe
/// GRDB primary key methods.
/// Equatable conformance supports tests.
struct HistoryPoint: Identifiable, Equatable {
    /// Int64 is the recommended type for auto-incremented database ids.
    /// Use nil for players that are not inserted yet in the database.
    var id: Int64?
    var cookerId: String
    var cookId: String?
    
    var updatedTimestamp: Date

    // Temperature bulbs
    var dry: Double
    var dryBottom: Double
    var dryTop: Double
    var wet: Double
    var wetDosed: Bool
    var tempMode: String
    var drySetpoint: Double?
    var wetSetpoint: Double?

    // Lamp, vent, door, water tank, fan
    var lampOn: Bool
    var lampPreference: Bool
    var ventOpen: Bool
    var doorClosed: Bool
    var waterTankEmpty: Bool
    var fanSpeed: Int

    // Heating elements
    var heatingBottomOn: Bool
    var heatingTopOn: Bool
    var heatingRearOn: Bool
    var heatingBottomWatts: Int
    var heatingTopWatts: Int
    var heatingRearWatts: Int

    // Temperature probe
    var probeConnected: Bool
    var probe: Double?
    var probeSetpoint: Double?

    // Steam generators
    var steamMode: String
    var evaporator: Double
    var boiler: Double
    var boilerDosed: Bool
    var evaporatorWatts: Int
    var boilerWatts: Int
    var relativeHumidity: Double?
    var relativeHumiditySetpoint: Double?
    var steamPercentageSetpoint: Double?

    // Timer
    var timerMode: String
    var timerInitial: Int
    
    static let probeNames = [
        \HistoryPoint.wet,
         \HistoryPoint.dry,
         \HistoryPoint.dryTop,
         \HistoryPoint.dryBottom,
         \HistoryPoint.probe
    ]
}

extension HistoryPoint {
    init(from payload: Payload) {
        // Assuming `Payload` and its nested structures provide all the necessary values.
        self.id = nil // Set to nil for new entries, assuming it's auto-incremented in the database
        self.cookerId = payload.cookerId
        self.cookId = payload.state.cook?.cookId
        self.updatedTimestamp = payload.state.updatedTimestamp
        
        // Temperature bulbs
        self.dry = payload.state.nodes.temperatureBulbs.dry.current.celsius
        self.dryBottom = payload.state.nodes.temperatureBulbs.dryBottom.current.celsius
        self.dryTop = payload.state.nodes.temperatureBulbs.dryTop.current.celsius
        self.wet = payload.state.nodes.temperatureBulbs.wet.current.celsius
        self.wetDosed = payload.state.nodes.temperatureBulbs.wet.dosed
        self.tempMode = payload.state.nodes.temperatureBulbs.mode.rawValue
        self.drySetpoint = payload.state.nodes.temperatureBulbs.mode == .dry ? payload.state.nodes.temperatureBulbs.dry.setpoint?.celsius : nil
        self.wetSetpoint = payload.state.nodes.temperatureBulbs.mode == .wet ? payload.state.nodes.temperatureBulbs.wet.setpoint?.celsius : nil

        // Lamp, vent, door, water tank, fan
        self.lampOn = payload.state.nodes.lamp.on
        self.lampPreference = payload.state.nodes.lamp.preference == .on
        self.ventOpen = payload.state.nodes.vent.open
        self.doorClosed = payload.state.nodes.door.closed
        self.waterTankEmpty = payload.state.nodes.waterTank.empty
        self.fanSpeed = payload.state.nodes.fan.speed

        // Heating elements
        self.heatingBottomOn = payload.state.nodes.heatingElements.bottom.on
        self.heatingTopOn = payload.state.nodes.heatingElements.top.on
        self.heatingRearOn = payload.state.nodes.heatingElements.rear.on
        self.heatingBottomWatts = payload.state.nodes.heatingElements.bottom.watts
        self.heatingTopWatts = payload.state.nodes.heatingElements.top.watts
        self.heatingRearWatts = payload.state.nodes.heatingElements.rear.watts

        // Temperature probe
        self.probeConnected = payload.state.nodes.temperatureProbe.connected
        if payload.state.nodes.temperatureProbe.connected {
            self.probe = payload.state.nodes.temperatureProbe.current?.celsius
            self.probeSetpoint = payload.state.nodes.temperatureProbe.setpoint?.celsius
        } else {
            self.probe = nil
            self.probeSetpoint = nil
        }

        // Steam generators
        self.steamMode = payload.state.nodes.steamGenerators.mode.rawValue
        self.evaporator = payload.state.nodes.steamGenerators.evaporator.celsius
        self.boiler = payload.state.nodes.steamGenerators.boiler.celsius
        self.boilerDosed = payload.state.nodes.steamGenerators.boiler.dosed
        self.evaporatorWatts = payload.state.nodes.steamGenerators.evaporator.watts
        self.boilerWatts = payload.state.nodes.steamGenerators.boiler.watts
        if payload.state.nodes.steamGenerators.mode == .relativeHumidity {
            self.relativeHumidity = payload.state.nodes.steamGenerators.relativeHumidity?.current
            self.relativeHumiditySetpoint = payload.state.nodes.steamGenerators.relativeHumidity?.setpoint
        } else {
            self.relativeHumidity = nil
            self.relativeHumiditySetpoint = nil
        }
        if payload.state.nodes.steamGenerators.mode == .steamPercentage {
            self.steamPercentageSetpoint = payload.state.nodes.steamGenerators.steamPercentage?.setpoint
        } else {
            self.steamPercentageSetpoint = nil
        }

        // Timer
        self.timerMode = payload.state.nodes.timer.mode.rawValue
        self.timerInitial = payload.state.nodes.timer.initial
    }
}



// MARK: - Persistence
/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension HistoryPoint: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "ovenHistory"
}
