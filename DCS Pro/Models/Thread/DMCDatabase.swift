import Foundation

/// Singleton database of all DMC thread colors
class DMCDatabase {
    static let shared = DMCDatabase()
    
    private(set) var threads: [DMCThread] = []
    private var threadsByID: [String: DMCThread] = [:]
    
    private init() {
        loadDatabase()
    }
    
    private func loadDatabase() {
        guard let url = Bundle.main.url(forResource: "dmc_colors", withExtension: "json") else {
            print("Warning: DMC database file not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let database = try decoder.decode(DMCDatabaseFile.self, from: data)
            
            // Convert to DMCThread with pre-computed Lab values
            threads = database.threads.map { entry in
                let rgb = RGBColor(r: entry.rgb.r, g: entry.rgb.g, b: entry.rgb.b)
                return DMCThread(id: entry.id, name: entry.name, rgb: rgb, lab: rgb.toLab())
            }
            
            // Build lookup dictionary
            for thread in threads {
                threadsByID[thread.id] = thread
            }
            
            print("Loaded \(threads.count) DMC thread colors")
        } catch {
            print("Error loading DMC database: \(error)")
        }
    }
    
    /// Get thread by DMC code
    func thread(byID id: String) -> DMCThread? {
        threadsByID[id]
    }
    
    /// Search threads by name or ID
    func search(query: String) -> [DMCThread] {
        let lowercased = query.lowercased()
        return threads.filter {
            $0.id.lowercased().contains(lowercased) ||
            $0.name.lowercased().contains(lowercased)
        }
    }
    
    /// Get thread count
    var count: Int {
        threads.count
    }
}

// MARK: - Database File Structure

private struct DMCDatabaseFile: Codable {
    let version: String
    let lastUpdated: String
    let threads: [ThreadEntry]
    
    struct ThreadEntry: Codable {
        let id: String
        let name: String
        let rgb: RGBEntry
    }
    
    struct RGBEntry: Codable {
        let r: UInt8
        let g: UInt8
        let b: UInt8
    }
}
