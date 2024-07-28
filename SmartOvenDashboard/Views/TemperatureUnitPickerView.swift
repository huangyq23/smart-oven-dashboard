//
//  TemperatureUnitPickerView.swift
//  SmartOvenDashboard
//
//

import SwiftUI

struct TemperatureUnitPickerView: View {
    @EnvironmentObject var displaySettingManager: DisplaySettingsManager
    
    var body: some View {
        HStack {
            Text("Temperature Unit")
            Spacer()
            Picker("Select Unit", selection: $displaySettingManager.temperatureUnit) {
                ForEach(DisplayTemperatureUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
    }
}

#Preview {
    TemperatureUnitPickerView()
        .environmentObject(DisplaySettingsManager(forceUnit: .celsius))
}
