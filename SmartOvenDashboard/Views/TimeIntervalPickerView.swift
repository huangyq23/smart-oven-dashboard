//
//  TimeIntervalPickerView.swift
//  SmartOvenDashboard
//
//

import SwiftUI


enum TimeIntervalSelection: Int, CaseIterable, Identifiable {
    case tenMinutes = 600
    case thirtyMinutes = 1800
    case oneHour = 3600
    case threeHour = 10800
    case sixHours = 21600
    case twelveHours = 43200
    case twentyFourHours = 86400

    var id: Int { self.rawValue }

    var label: String {
        switch self {
        case .tenMinutes: return "10m"
        case .thirtyMinutes: return "30m"
        case .oneHour: return "1h"
        case .threeHour: return "3h"
        case .sixHours: return "6h"
        case .twelveHours: return "12h"
        case .twentyFourHours: return "24h"
        }
    }

    func timeInterval() -> TimeInterval {
        return TimeInterval(self.rawValue)
    }
}

struct TimeIntervalPickerView: View {
    @Binding var selectedInterval: TimeIntervalSelection

    var body: some View {
        Picker("Select Time Interval", selection: $selectedInterval) {
            ForEach(TimeIntervalSelection.allCases, id: \.self) { interval in
                Text(interval.label).tag(interval)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    TimeIntervalPickerView(selectedInterval: .constant(.tenMinutes))
        .previewLayout(.sizeThatFits)
        .padding()
}
