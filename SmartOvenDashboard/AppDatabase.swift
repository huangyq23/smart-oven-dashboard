import Foundation
import GRDB
import os.log

struct AppDatabase {
    /// Creates an `AppDatabase`, and makes sure the database schema
    /// is ready.
    ///
    /// - important: Create the `DatabaseWriter` with a configuration
    ///   returned by ``makeConfiguration(_:)``.
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    /// Provides access to the database.
    ///
    /// Application can use a `DatabasePool`, while SwiftUI previews and tests
    /// can use a fast in-memory `DatabaseQueue`.
    ///
    /// See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseconnections>
    private let dbWriter: any DatabaseWriter
}

// MARK: - Database Configuration

extension AppDatabase {
    private static let sqlLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SQL")
    
    /// SQL statements are logged if the `SQL_TRACE` environment variable
    /// is set.
    ///
    /// - parameter base: A base configuration.
    public static func makeConfiguration(_ base: Configuration = Configuration()) -> Configuration {
        var config = base
        
        // An opportunity to add required custom SQL functions or
        // collations, if needed:
        // config.prepareDatabase { db in
        //     db.add(function: ...)
        // }
        
        // Log SQL statements if the `SQL_TRACE` environment variable is set.
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/database/trace(options:_:)>
        if ProcessInfo.processInfo.environment["SQL_TRACE"] != nil {
            config.prepareDatabase { db in
                db.trace {
                    // It's ok to log statements publicly. Sensitive
                    // information (statement arguments) are not logged
                    // unless config.publicStatementArguments is set
                    // (see below).
                    os_log("%{public}@", log: sqlLogger, type: .debug, String(describing: $0))
                }
            }
        }
        
#if DEBUG
        // Protect sensitive information by enabling verbose debugging in
        // DEBUG builds only.
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/configuration/publicstatementarguments>
        config.publicStatementArguments = true
#endif
        
        return config
    }
}

// MARK: - Database Migrations

extension AppDatabase {
    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations>
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
#if DEBUG
        // Speed up development by nuking the database when migrations change
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations>
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        
        migrator.registerMigration("ovenHistory") { db in
            // Create a table
            // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseschema>
            try db.create(table: "ovenHistory") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("cookerId", .text).notNull()
                t.column("cookId", .text)
                t.column("updatedTimestamp", .datetime).notNull()

                // Temperature bulbs
                t.column("dry", .double).notNull()
                t.column("dryBottom", .double).notNull()
                t.column("dryTop", .double).notNull()
                t.column("wet", .double).notNull()
                t.column("wetDosed", .boolean).notNull()
                t.column("tempMode", .text).notNull()
                t.column("drySetpoint", .double)
                t.column("wetSetpoint", .double)

                // Lamp, vent, door, water tank, fan
                t.column("lampOn", .boolean).notNull()
                t.column("lampPreference", .boolean).notNull()
                t.column("ventOpen", .boolean).notNull()
                t.column("doorClosed", .boolean).notNull()
                t.column("waterTankEmpty", .boolean).notNull()
                t.column("fanSpeed", .integer).notNull()

                // Heating elements
                t.column("heatingBottomOn", .boolean).notNull()
                t.column("heatingTopOn", .boolean).notNull()
                t.column("heatingRearOn", .boolean).notNull()
                t.column("heatingBottomWatts", .integer).notNull()
                t.column("heatingTopWatts", .integer).notNull()
                t.column("heatingRearWatts", .integer).notNull()

                // Temperature probe
                t.column("probeConnected", .boolean).notNull()
                t.column("probe", .double)
                t.column("probeSetpoint", .double)

                // Steam generators
                t.column("steamMode", .text).notNull()
                t.column("evaporator", .double).notNull()
                t.column("boiler", .double).notNull()
                t.column("boilerDosed", .boolean).notNull()
                t.column("evaporatorWatts", .integer).notNull()
                t.column("boilerWatts", .integer).notNull()
                t.column("relativeHumidity", .double)
                t.column("relativeHumiditySetpoint", .double)
                t.column("steamPercentageSetpoint", .double)

                // Timer
                t.column("timerMode", .text).notNull()
                t.column("timerInitial", .integer).notNull()
            }
            
            try db.create(indexOn: "ovenHistory", columns: ["updatedTimestamp"])
        }
        
        migrator.registerMigration("addCookerIndex") { db in
            try db.create(indexOn: "ovenHistory", columns: ["cookerId", "cookId"])
        }
        
        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }
        
        return migrator
    }
}


// MARK: - Database Access: Writes
// The write methods execute invariant-preserving database transactions.

extension AppDatabase {
    /// A validation error that prevents some players from being saved into
    /// the database.
//    enum ValidationError: LocalizedError {
//        case missingName
//        
//        var errorDescription: String? {
//            switch self {
//            case .missingName:
//                return "Please provide a name"
//            }
//        }
//    }
    
    /// Saves (inserts or updates) a player. When the method returns, the
    /// player is present in the database, and its id is not nil.
    func saveHistoryPoint(_ historyPoint: inout HistoryPoint) throws {
        try dbWriter.write { db in
            try historyPoint.save(db)
        }
    }

    func createFixtureIfEmpty() throws {
        try dbWriter.write { db in
            if try HistoryPoint.all().isEmpty(db) {
                try createHistoryFixtures(db)
            }
        }
    }

//    /// Support for `createRandomPlayersIfEmpty()` and `refreshPlayers()`.
    private func createHistoryFixtures(_ db: Database) throws {
        try db.execute(sql: Fixtures.historyPoints)
    }
}

// MARK: - Database Access: Reads

// This demo app does not provide any specific reading method, and instead
// gives an unrestricted read-only access to the rest of the application.
// In your app, you are free to choose another path, and define focused
// reading methods.
extension AppDatabase {
    /// Provides a read-only access to the database
    var reader: DatabaseReader {
        dbWriter
    }
}
