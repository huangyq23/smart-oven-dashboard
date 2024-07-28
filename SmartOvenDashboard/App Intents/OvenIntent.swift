//
//  StartOvenIntent.swift
//  SmartOvenDashboard
//
//

import AppIntents
import OSLog

struct StartOvenIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Oven Cooks"
    
    @Parameter(title: "Oven Name")
    var ovenName: String?
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        
        Logger.intentLogging.debug("Connecting...")
        await DevicesManager.shared.connect()
        
        while (await DevicesManager.shared.firstDevice) == nil {
            Logger.intentLogging.debug("Waiting for connect")
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        var cookerId = await DevicesManager.shared.firstDevice!.cookerId
        
        if await DevicesManager.shared.deviceInfo.values.count > 1 {
            let chosenOvenName = try await $ovenName.requestDisambiguation(among: DevicesManager.shared.deviceInfo.values.map({ $0.name }), dialog: "Which Oven?")
            
            cookerId = (await DevicesManager.shared.deviceInfo.values.first(where:{ $0.name == chosenOvenName }))!.cookerId
        }
        
        await DevicesManager.shared.airFry(cookerId)
        return .result(dialog: "Started")
    }
}

struct StopOvenIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Oven Cooks"
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        Logger.intentLogging.debug("Connecting...")
        await DevicesManager.shared.connect()
        
        while (await DevicesManager.shared.firstDevice) == nil {
            Logger.intentLogging.debug("Waiting for connect")
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        Logger.intentLogging.debug("Sending Stop...")
        await DevicesManager.shared.stopOven(DevicesManager.shared.firstDevice!.cookerId)
        
        return .result(dialog: "Stopped")
    }
}
