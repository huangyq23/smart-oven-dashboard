//
//  BooleanHistoryView.swift
//  SmartOvenDashboard
//
//

import SwiftUI
import Charts

struct BooleanInterval: Identifiable {
    var id: String
    var interval: DateInterval
}

func getIntervalsForProperties(from historyPoints: [HistoryPoint], for keyPathNamePairs: [(KeyPath<HistoryPoint, Bool>, String, Bool)]) -> [BooleanInterval] {
    var allIntervals: [BooleanInterval] = []
    var currentIntervalsStart: [String: Date] = [:]

    // Initialize currentIntervalsStart for each keyPathNamePair
    for (_, name, _) in keyPathNamePairs {
        currentIntervalsStart[name] = nil
    }

    for item in historyPoints {
        for (keyPath, name, reverse) in keyPathNamePairs {
            let isTrue = item[keyPath: keyPath] != reverse

            if isTrue && currentIntervalsStart[name] == nil {
                // Start of a new interval
                currentIntervalsStart[name] = item.updatedTimestamp
            } else if !isTrue && currentIntervalsStart[name] != nil {
                // End of the current interval
                if let start = currentIntervalsStart[name] {
                    allIntervals.append(BooleanInterval(id: name, interval: DateInterval(start: start, end: item.updatedTimestamp)))
                    currentIntervalsStart[name] = nil
                }
            }
        }
    }

    // Check for any unclosed intervals
    for (_, name, _) in keyPathNamePairs {
        if let last = currentIntervalsStart[name] {
            allIntervals.append(BooleanInterval(id: name, interval: DateInterval(start: last, end: Date()))) // Assuming current time as end
        }
    }

    return allIntervals
}

struct BooleanItemHistoryView: View {
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
        
        let intervals = getIntervalsForProperties(from: historyPoints, for: [
            (\HistoryPoint.lampOn, "Lamp On", false),
            (\HistoryPoint.doorClosed, "Door Opened", true),
            (\HistoryPoint.ventOpen, "Vent Open", false),
        ])

        Chart(intervals) {
            BarMark(
                xStart: .value("Start Time", $0.interval.start),
                xEnd: .value("End Time", $0.interval.end),
                y: .value("Type", $0.id)
            )
        }
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
