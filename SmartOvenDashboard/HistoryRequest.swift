import Combine
import GRDB
import GRDBQuery
import Foundation

struct HistoryPointRequest: Queryable {
    
    // MARK: - Queryable Implementation
    
    var cookerId: String
    var selectedInterval: TimeIntervalSelection
    
    static var defaultValue: [HistoryPoint] { [] }
    
    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[HistoryPoint], Error> {
        // Build the publisher from the general-purpose read-only access
        // granted by `appDatabase.reader`.
        // Some apps will prefer to call a dedicated method of `appDatabase`.
        ValueObservation
            .tracking(fetchValue(_:))
            .publisher(
                in: appDatabase.reader,
                // The `.immediate` scheduling feeds the view right on
                // subscription, and avoids an undesired animation when the
                // application starts.
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    // This method is not required by Queryable, but it makes it easier
    // to test PlayerRequest.
    
    func fetchValue(_ db: Database) throws -> [HistoryPoint] {
        return try HistoryPoint
            .filter(Column("cookerId") == cookerId)
            .filter(Column("updatedTimestamp") > Date() - selectedInterval.timeInterval())
            .order(Column("updatedTimestamp").asc)
            .fetchAll(db)
    }
}
