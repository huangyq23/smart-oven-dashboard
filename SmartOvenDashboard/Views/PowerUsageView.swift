//
//  PowerUsageView.swift
//  SmartOvenDashboard
//
//

import SwiftUI
import Charts

struct PowerChip: View {
    var label: String
    var power: Int
    var color: Color
    
    var body: some View {
        HStack{
            Text(label)
                .fontWeight(.bold)
                .font(.callout.smallCaps())
                .padding(3)
                .frame(width: 110, alignment: .leading)
                .foregroundStyle(color)
            Text("\(power, format: .number.grouping(.never))W")
                .monospacedDigit()
        }
    }
}

#Preview("PowerChip") {
    VStack(alignment: .leading, spacing: 0){
        PowerChip(label: "Boiler", power: 100, color: .blue)
        PowerChip(label: "Evaporator", power: 2100, color: .orange)
    }
}

struct PowerUsageView: View {
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
                PowerChip(label: "Boiler", power: selectedPoint.boilerWatts, color: .blue)
                PowerChip(label: "Evaporator", power: selectedPoint.evaporatorWatts, color: .orange)
                PowerChip(label: "Top", power: selectedPoint.heatingTopWatts, color: .green)
                PowerChip(label: "Bottom", power: selectedPoint.heatingBottomWatts, color: .red)
                PowerChip(label: "Rear", power: selectedPoint.heatingRearWatts, color: .purple)
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
        Chart {
            ForEach(historyPoints) { element in
                LineMark(
                    x: .value("Time", element.updatedTimestamp),
                    y: .value("W", element.boilerWatts)
                )
                .interpolationMethod(.stepStart)
                .foregroundStyle(by: .value("Power", "Boiler"))
                
                LineMark(
                    x: .value("Time", element.updatedTimestamp),
                    y: .value("W", element.evaporatorWatts)
                )
                .interpolationMethod(.stepStart)
                .foregroundStyle(by: .value("Power", "Evaporator"))
//                
                LineMark(
                    x: .value("Time", element.updatedTimestamp),
                    y: .value("W", element.heatingTopWatts)
                )
                .interpolationMethod(.stepStart)
                .foregroundStyle(by: .value("Power", "Top"))
//                
                LineMark(
                    x: .value("Time", element.updatedTimestamp),
                    y: .value("W", element.heatingBottomWatts)
                )
                .interpolationMethod(.stepStart)
                .foregroundStyle(by: .value("Power", "Bottom"))
//                
                LineMark(
                    x: .value("Time", element.updatedTimestamp),
                    y: .value("W", element.heatingRearWatts)
                )
                .interpolationMethod(.stepStart)
                .foregroundStyle(by: .value("Power", "Rear"))
                
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
                    valueSelectionPopover
                }
            }

        }
        .chartForegroundStyleScale(
            domain: ["Boiler", "Evaporator", "Top", "Bottom", "Rear"],
            range: [.blue, .orange, .green, .red, .purple]
        )
        .chartXVisibleDomain(length: interval.rawValue)
        .chartXScale(domain: (Date() - interval.timeInterval()) ... Date())
//        .chartYScale(domain: 0 ... 1000)
        .chartXAxis(.automatic)
        .chartYAxis(.visible)
        .chartLegend(.automatic)
        .frame(minHeight: 300)
        .background(Color(UIColor.systemBackground))
        .chartXSelection(value: $rawSelectedDate)
    }
}

#Preview {
    PowerUsageView(historyPoints: [])
}


