//
//  DMCDatabaseTests.swift
//  DCS ProTests
//
//  Comprehensive unit tests for DMCDatabase and DMCThread models
//

import Foundation
import Testing
@testable import DCS_Pro

// MARK: - DMC Database Loading Tests

@Suite("DMC Database Loading")
struct DMCDatabaseLoadingTests {
    
    @Test("Database loads successfully")
    func testDatabaseLoads() {
        let database = DMCDatabase.shared
        
        #expect(database.threads.count > 0, "Database should contain threads")
    }
    
    @Test("Database contains more than 400 threads")
    func testDatabaseThreadCount() {
        let database = DMCDatabase.shared
        
        #expect(database.count > 400, "DMC database should have more than 400 thread colors (typically ~489)")
    }
    
    @Test("All threads have valid IDs")
    func testAllThreadsHaveValidIDs() {
        let database = DMCDatabase.shared
        
        for thread in database.threads {
            #expect(!thread.id.isEmpty, "Thread ID should not be empty")
        }
    }
    
    @Test("All threads have valid names")
    func testAllThreadsHaveValidNames() {
        let database = DMCDatabase.shared
        
        for thread in database.threads {
            #expect(!thread.name.isEmpty, "Thread name should not be empty")
        }
    }
    
    @Test("All threads have pre-computed Lab values")
    func testAllThreadsHaveLabValues() {
        let database = DMCDatabase.shared
        
        for thread in database.threads {
            // Lab values should be within valid ranges
            // Using small tolerance for floating point precision (white can be slightly > 100)
            let tolerance = 0.001
            #expect(thread.lab.l >= -tolerance && thread.lab.l <= 100 + tolerance, 
                   "Lab L should be in range 0-100 (with floating point tolerance)")
            #expect(thread.lab.a >= -150 && thread.lab.a <= 150, 
                   "Lab a should be in reasonable range")
            #expect(thread.lab.b >= -150 && thread.lab.b <= 150, 
                   "Lab b should be in reasonable range")
        }
    }
}

// MARK: - DMC Thread Lookup Tests

@Suite("DMC Thread Lookup")
struct DMCThreadLookupTests {
    
    @Test("Black (310) lookup works")
    func testBlackLookup() {
        let database = DMCDatabase.shared
        let black = database.thread(byID: "310")
        
        #expect(black != nil, "Should find DMC 310 (Black)")
        #expect(black?.id == "310")
        #expect(black?.name.lowercased().contains("black") == true, "DMC 310 should be named Black")
    }
    
    @Test("BLANC (White) lookup works")
    func testBlancLookup() {
        let database = DMCDatabase.shared
        let blanc = database.thread(byID: "BLANC")
        
        #expect(blanc != nil, "Should find DMC BLANC (White)")
        #expect(blanc?.id == "BLANC")
    }
    
    @Test("ECRU lookup works")
    func testEcruLookup() {
        let database = DMCDatabase.shared
        let ecru = database.thread(byID: "ECRU")
        
        #expect(ecru != nil, "Should find DMC ECRU")
        #expect(ecru?.id == "ECRU")
    }
    
    @Test("Nonexistent thread returns nil")
    func testNonexistentThreadReturnsNil() {
        let database = DMCDatabase.shared
        let notFound = database.thread(byID: "NONEXISTENT999")
        
        #expect(notFound == nil, "Nonexistent thread ID should return nil")
    }
    
    @Test("Thread lookup is case-sensitive")
    func testThreadLookupCaseSensitive() {
        let database = DMCDatabase.shared
        
        let upperBlanc = database.thread(byID: "BLANC")
        let lowerBlanc = database.thread(byID: "blanc")
        
        #expect(upperBlanc != nil, "BLANC should exist")
        #expect(lowerBlanc == nil, "lowercase 'blanc' should not match (case sensitive)")
    }
    
    @Test("Numeric thread ID lookup works")
    func testNumericThreadLookup() {
        let database = DMCDatabase.shared
        
        // Test various numeric DMC codes
        let thread666 = database.thread(byID: "666")
        let thread3865 = database.thread(byID: "3865")
        
        #expect(thread666 != nil || thread3865 != nil, "At least one numeric thread should exist")
    }
}

// MARK: - DMC Thread Search Tests

@Suite("DMC Thread Search")
struct DMCThreadSearchTests {
    
    @Test("Search by name finds threads")
    func testSearchByName() {
        let database = DMCDatabase.shared
        let results = database.search(query: "Black")
        
        #expect(results.count > 0, "Should find threads containing 'Black'")
        
        let hasBlack = results.contains { $0.name.lowercased().contains("black") }
        #expect(hasBlack, "Results should include a thread with 'Black' in the name")
    }
    
    @Test("Search by ID finds threads")
    func testSearchByID() {
        let database = DMCDatabase.shared
        let results = database.search(query: "310")
        
        #expect(results.count > 0, "Should find threads matching ID '310'")
        
        let has310 = results.contains { $0.id == "310" }
        #expect(has310, "Results should include thread with ID '310'")
    }
    
    @Test("Search is case-insensitive")
    func testSearchCaseInsensitive() {
        let database = DMCDatabase.shared
        
        let upperResults = database.search(query: "BLACK")
        let lowerResults = database.search(query: "black")
        let mixedResults = database.search(query: "BlAcK")
        
        #expect(upperResults.count == lowerResults.count, "Search should be case-insensitive")
        #expect(lowerResults.count == mixedResults.count, "Search should be case-insensitive")
    }
    
    @Test("Search with no matches returns empty array")
    func testSearchNoMatches() {
        let database = DMCDatabase.shared
        let results = database.search(query: "ZZZZNONEXISTENTZZZZ")
        
        #expect(results.isEmpty, "Search with no matches should return empty array")
    }
    
    @Test("Partial name search works")
    func testPartialNameSearch() {
        let database = DMCDatabase.shared
        let results = database.search(query: "Red")
        
        #expect(results.count > 0, "Should find threads containing 'Red'")
    }
    
    @Test("Search finds skin tone colors")
    func testSearchSkinTones() {
        let database = DMCDatabase.shared
        
        // Common skin tone related terms
        let peachResults = database.search(query: "Peach")
        let tawnyResults = database.search(query: "Tawny")
        
        #expect(peachResults.count > 0 || tawnyResults.count > 0, 
               "Should find skin tone colors (Peach or Tawny)")
    }
}

// MARK: - DMC Thread Color Value Tests

@Suite("DMC Thread Color Values")
struct DMCThreadColorValueTests {
    
    @Test("Black (310) has very dark RGB values")
    func testBlackRGBValues() {
        let database = DMCDatabase.shared
        guard let black = database.thread(byID: "310") else {
            Issue.record("DMC 310 not found")
            return
        }
        
        #expect(black.rgb.r < 30, "Black red component should be very low")
        #expect(black.rgb.g < 30, "Black green component should be very low")
        #expect(black.rgb.b < 30, "Black blue component should be very low")
    }
    
    @Test("BLANC has very light RGB values")
    func testBlancRGBValues() {
        let database = DMCDatabase.shared
        guard let blanc = database.thread(byID: "BLANC") else {
            Issue.record("DMC BLANC not found")
            return
        }
        
        #expect(blanc.rgb.r > 240, "BLANC red component should be very high")
        #expect(blanc.rgb.g > 240, "BLANC green component should be very high")
        #expect(blanc.rgb.b > 240, "BLANC blue component should be very high")
    }
    
    @Test("Black has low Lab lightness")
    func testBlackLabLightness() {
        let database = DMCDatabase.shared
        guard let black = database.thread(byID: "310") else {
            Issue.record("DMC 310 not found")
            return
        }
        
        #expect(black.lab.l < 5, "Black should have Lab L close to 0")
    }
    
    @Test("BLANC has high Lab lightness")
    func testBlancLabLightness() {
        let database = DMCDatabase.shared
        guard let blanc = database.thread(byID: "BLANC") else {
            Issue.record("DMC BLANC not found")
            return
        }
        
        #expect(blanc.lab.l > 95, "BLANC should have Lab L close to 100")
    }
}

// MARK: - DMC Thread Model Tests

@Suite("DMC Thread Model")
struct DMCThreadModelTests {
    
    @Test("DMCThread is Identifiable with id property")
    func testDMCThreadIdentifiable() {
        let database = DMCDatabase.shared
        guard let thread = database.threads.first else {
            Issue.record("No threads in database")
            return
        }
        
        // id should be the DMC code string
        #expect(!thread.id.isEmpty)
    }
    
    @Test("DMCThread is Hashable")
    func testDMCThreadHashable() {
        let database = DMCDatabase.shared
        guard database.threads.count >= 2 else {
            Issue.record("Need at least 2 threads for test")
            return
        }
        
        let thread1 = database.threads[0]
        let thread2 = database.threads[1]
        
        var threadSet: Set<DMCThread> = []
        threadSet.insert(thread1)
        threadSet.insert(thread2)
        threadSet.insert(thread1) // Duplicate
        
        #expect(threadSet.count == 2, "Set should contain 2 unique threads")
    }
    
    @Test("DMCThread is Codable")
    func testDMCThreadCodable() throws {
        let database = DMCDatabase.shared
        guard let thread = database.thread(byID: "310") else {
            Issue.record("DMC 310 not found")
            return
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(thread)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DMCThread.self, from: data)
        
        #expect(decoded.id == thread.id)
        #expect(decoded.name == thread.name)
        #expect(decoded.rgb == thread.rgb)
    }
}

// MARK: - DMC Database Singleton Tests

@Suite("DMC Database Singleton")
struct DMCDatabaseSingletonTests {
    
    @Test("Shared instance is consistent")
    func testSharedInstanceConsistent() {
        let instance1 = DMCDatabase.shared
        let instance2 = DMCDatabase.shared
        
        #expect(instance1 === instance2, "Shared instance should be the same object")
    }
    
    @Test("Database count matches threads array count")
    func testCountMatchesArrayCount() {
        let database = DMCDatabase.shared
        
        #expect(database.count == database.threads.count, 
               "count property should match threads array count")
    }
}
