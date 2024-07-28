import Foundation
import GRDB
import OSLog

extension AppDatabase {
    /// The database for the application
    static let shared = makeShared()
    
    private static func makeShared() -> AppDatabase {
        do {
            // Apply recommendations from
            // <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseconnections>
            //
            // Create the "Application Support/Database" directory if needed
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)
            
            // Support for tests: delete the database if requested
            if CommandLine.arguments.contains("-reset") {
                try? fileManager.removeItem(at: directoryURL)
            }
            
            // Create the database folder if needed
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // Open or create the database
            let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
            Logger.appLogging.info("Database stored at \(databaseURL.path)")
            let dbPool = try DatabasePool(
                path: databaseURL.path,
                // Use default AppDatabase configuration
                configuration: AppDatabase.makeConfiguration())
            
            // Create the AppDatabase
            let appDatabase = try AppDatabase(dbPool)
            
            return appDatabase
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            //
            // Typical reasons for an error here include:
            // * The parent directory cannot be created, or disallows writing.
            // * The database is not accessible, due to permissions or data protection when the device is locked.
            // * The device is out of space.
            // * The database could not be migrated to its latest schema version.
            // Check the error message to determine what the actual problem was.
            fatalError("Unresolved error \(error)")
        }
    }
    
    func exportCSVFromTable(tableName: String) -> URL? {
        do {
            // Fetch rows from the table
            let rows = try self.reader.read { db in
                try Row.fetchAll(db, sql: "SELECT * FROM \(tableName)")
            }

            // Convert rows to CSV format
            let csvString = convertRowsToCSV(rows: rows)

            // Save CSV string to file
            return try saveCSVFile(csvString: csvString, for: tableName)
        } catch {
            print("Database error: \(error)")
            return nil
        }
    }

    private func convertRowsToCSV(rows: [Row]) -> String {
        var csvString = ""

        // Assuming the first row contains the column names
        if let firstRow = rows.first {
            csvString += firstRow.columnNames.joined(separator: ",") + "\n"
        }

        for row in rows {
            csvString += row.databaseValues.map { "\(String(describing: $0))" }.joined(separator: ",") + "\n"
        }

        return csvString
    }

    private func saveCSVFile(csvString: String, for tableName: String) throws -> URL {
        let fileManager = FileManager.default
        let docDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = docDirectory.appendingPathComponent("\(tableName).csv")

        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    func backup() -> Void  {
        do {
            let fileManager = FileManager.default
            
            let documentURL = try fileManager.url(
                for: .documentDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            
            let directoryURL = documentURL.appendingPathComponent("OvenDatabase", isDirectory: true)
            
            // Create the database folder if needed
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // Open or create the database
            let databaseURL = directoryURL.appendingPathComponent("backup.sqlite")
            Logger.appLogging.info("Backup Database stored at \(databaseURL.path)")
            let dbPool = try DatabasePool(
                path: databaseURL.path,
                // Use default AppDatabase configuration
                configuration: AppDatabase.makeConfiguration())
            
            
            try self.reader.backup(to: dbPool)
            
            try dbPool.close()

        } catch {
            Logger.appLogging.error("\(error)")
        }
    }
    
    /// Creates an empty database for SwiftUI previews
    static func empty() -> AppDatabase {
        // Connect to an in-memory database
        // See https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseconnections
        let dbQueue = try! DatabaseQueue(configuration: AppDatabase.makeConfiguration())
        return try! AppDatabase(dbQueue)
    }
    
    /// Creates a database full of random players for SwiftUI previews
    static func random() -> AppDatabase {
        let appDatabase = empty()
        try! appDatabase.createFixtureIfEmpty()
        return appDatabase
    }
}
