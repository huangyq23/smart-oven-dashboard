//
//  StoredTemperatureHistoryView.swift
//  SmartOvenDashboard
//
//

import SwiftUI
import Charts

struct TemperatureChip: View {
    @EnvironmentObject var displaySetingsManager: DisplaySettingsManager
    
    var label: String
    var temperature: Double
    var color: Color
    
    var body: some View {
        HStack{
            Text(label)
                .fontWeight(.bold)
                .font(.callout.smallCaps())
                .padding(3)
                .frame(width: 56, alignment: .leading)
                .foregroundStyle(color)
            Text(displaySetingsManager.displayTemperature(temperature))
                .monospacedDigit()
        }
    }
}

#Preview("TemperatureChip") {
    VStack(spacing: 0){
        TemperatureChip(label: "Wet", temperature: 100.0, color: .blue)
        TemperatureChip(label: "Dry", temperature: 100.0, color: .orange)
        TemperatureChip(label: "Probe", temperature: 100.0, color: .green)
    }.environmentObject(DisplaySettingsManager(forceUnit: .fahrenheit))

}

struct StoredTemperatureHistoryView: View {
    @EnvironmentObject var displaySetingsManager: DisplaySettingsManager
    var historyPoints: [HistoryPoint]
    var interval: TimeIntervalSelection = .thirtyMinutes
    
    @State var rawSelectedDate: Date? = nil
    
    var selectedPoint: HistoryPoint? {
        if let rawSelectedDate {
            return findClosestHistoryPoint(in: historyPoints, to: rawSelectedDate)
        }
        
        return nil
    }
    
    @ViewBuilder
    var valueSelectionPopover: some View {
        if let selectedPoint {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(selectedPoint.updatedTimestamp, format: .dateTime)")
                    .font(.caption)
                    .monospacedDigit()
                TemperatureChip(label: "Wet", temperature: selectedPoint.wet, color: .blue)
                TemperatureChip(label: "Dry", temperature: selectedPoint.dry, color: .orange)
                
                if selectedPoint.probe != nil {
                    TemperatureChip(label: "Probe", temperature: selectedPoint.probe!, color: .green)
                }
                
            }
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(.background.opacity(0.70))
            }
        } else {
            EmptyView()
        }
    }
    
    var body: some View {
        let displayTemperatureUnit = displaySetingsManager.temperatureUnit.rawValue
        
        Chart {
            ForEach(historyPoints) { element in
                LineMark(
                    x: .value("Time", element.updatedTimestamp),
                    y: .value(displayTemperatureUnit, displaySetingsManager.rawDisplayTemperature(element.wet))
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(by: .value("Probe", "Wet"))
                
                LineMark(
                    x: .value("Time", element.updatedTimestamp),
                    y: .value(displayTemperatureUnit, displaySetingsManager.rawDisplayTemperature(element.dry))
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(by: .value("Probe", "Dry"))
                
                if (element.probe != nil) {
                    LineMark(
                        x: .value("Time", element.updatedTimestamp),
                        y: .value(displayTemperatureUnit, displaySetingsManager.rawDisplayTemperature(element.probe!))
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(by: .value("Probe", "Probe"))
                }
                
                if (element.drySetpoint != nil) {
                    LineMark(
                        x: .value("Time", element.updatedTimestamp),
                        y: .value(displayTemperatureUnit, displaySetingsManager.rawDisplayTemperature(element.drySetpoint!))
                    )
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(by: .value("Probe", "Dry Setpoint"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
                }
                if (element.wetSetpoint != nil) {
                    LineMark(
                        x: .value("Time", element.updatedTimestamp),
                        y: .value("displayTemperatureUnit", displaySetingsManager.rawDisplayTemperature(element.wetSetpoint!))
                    )
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(by: .value("Probe", "Wet Setpoint"))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 5]))
                }
                if (element.probeSetpoint != nil) {
                    LineMark(
                        x: .value("Time", element.updatedTimestamp),
                        y: .value(displayTemperatureUnit, displaySetingsManager.rawDisplayTemperature(element.probeSetpoint!))
                    )
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(by: .value("Probe", "Probe Setpoint"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
                }
            }
            if let selectedPoint {
                RuleMark(
                    x: .value("Selected", selectedPoint.updatedTimestamp)
                )
                .foregroundStyle(Color.gray.opacity(0.3))
                .offset(yStart: -10)
                .zIndex(-1)
                .annotation(
                    position: .top, spacing: 0,
                    overflowResolution: .init(
                        x: .fit(to: .chart),
                        y: .disabled
                    )
                ) {
                    valueSelectionPopover.environmentObject(displaySetingsManager)
                }
            }

        }
        .chartForegroundStyleScale(
            domain: ["Wet", "Dry", "Probe", "Wet Setpoint", "Dry Setpoint", "Probe Setpoint"],
            range: [.blue, .orange, .green, .blue.opacity(0.5), .orange.opacity(0.5), .green.opacity(0.5)]
        )
        .chartXVisibleDomain(length: interval.rawValue)
        .chartXScale(domain: (Date() - interval.timeInterval()) ... Date())
        .chartXAxis(.automatic)
        .chartYAxis(.automatic)
        .chartLegend(.automatic)
        .frame(minHeight: 300)
        .background(Color(UIColor.systemBackground))
        .chartXSelection(value: $rawSelectedDate)
    }
}

#Preview {
    StoredTemperatureHistoryView(historyPoints: [])
            .environmentObject(DisplaySettingsManager(forceUnit: .fahrenheit))
}

