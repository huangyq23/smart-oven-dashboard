

import Foundation
import OSLog

extension Logger {
    static let appLogging = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Main")
    static let intentLogging = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "App Intent")
}

extension Logger {
    static func retrieveLogs(since timeInterval: TimeInterval) throws -> [String] {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let date = Date.now.addingTimeInterval(-24 * 3600)
        let position = store.position(date: date)
        
        return try store
            .getEntries(at: position)
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == Bundle.main.bundleIdentifier! }
            .map { "[\($0.date.formatted())] [\($0.category)] \($0.composedMessage)" }
    }
}
