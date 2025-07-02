//
//  DataManager.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Data Manager
@MainActor
class DataManager: ObservableObject {
    @Published var destinations: [Destination] = []
    
    private let fileName = "destinations.json"
    
    init() {
        loadDestinations()
    }
    
    // MARK: - File URLs
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var destinationsURL: URL {
        documentsDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Load Data
    func loadDestinations() {
        print("📂 [DataManager] Loading destinations from persistent storage...")
        
        do {
            // Check if file exists
            guard FileManager.default.fileExists(atPath: destinationsURL.path) else {
                print("📝 [DataManager] No saved data found, loading sample data...")
                loadSampleData()
                return
            }
            
            // Load and decode data
            let data = try Data(contentsOf: destinationsURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            destinations = try decoder.decode([Destination].self, from: data)
            print("✅ [DataManager] Successfully loaded \(destinations.count) destinations")
            
            // Log loaded destinations
            for destination in destinations {
                print("   - \(destination.name): \(destination.culturalCards.count) cards")
            }
            
        } catch {
            print("❌ [DataManager] Failed to load destinations: \(error)")
            print("🔄 [DataManager] Falling back to sample data...")
            loadSampleData()
        }
    }
    
    // MARK: - Save Data
    func saveDestinations() {
        print("💾 [DataManager] Saving destinations to persistent storage...")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(destinations)
            try data.write(to: destinationsURL)
            
            print("✅ [DataManager] Successfully saved \(destinations.count) destinations")
            print("📍 [DataManager] Saved to: \(destinationsURL.path)")
            
            // Log saved destinations
            for destination in destinations {
                print("   - \(destination.name): \(destination.culturalCards.count) cards")
            }
            
        } catch {
            print("❌ [DataManager] Failed to save destinations: \(error)")
        }
    }
    
    // MARK: - Data Operations
    func addDestination(_ destination: Destination) {
        destinations.append(destination)
        saveDestinations()
        print("➕ [DataManager] Added destination: \(destination.name)")
    }
    
    func removeDestination(at index: Int) {
        guard index < destinations.count else { return }
        let destinationName = destinations[index].name
        destinations.remove(at: index)
        saveDestinations()
        print("➖ [DataManager] Removed destination: \(destinationName)")
    }
    
    func addCard(_ card: CulturalCard, to destination: Destination) {
        print("🔍 [DataManager] Adding card to destination...")
        print("📋 [DataManager] Card details:")
        print("   - Title: '\(card.title)'")
        print("   - Is AI Generated: \(card.isAIGenerated)")
        print("   - Name Card: '\(card.nameCard ?? "nil")'")
        print("   - Key Knowledge: \(card.keyKnowledge?.count ?? 0) items")
        print("   - Cultural Insights: \(card.culturalInsights?.count ?? 0) characters")
        print("   - Question: '\(card.question ?? "nil")'")
        print("   - Content: '\(card.content.prefix(100))...'")
        
        if let index = destinations.firstIndex(where: { $0.id == destination.id }) {
            destinations[index].addCard(card)
            saveDestinations()
            print("➕ [DataManager] Added card '\(card.title)' to \(destination.name)")
            
            // Verify the card was actually added with the correct data
            if let addedCard = destinations[index].culturalCards.last {
                print("🔍 [DataManager] Verification - Added card:")
                print("   - Title: '\(addedCard.title)'")
                print("   - Is AI Generated: \(addedCard.isAIGenerated)")
                print("   - Name Card: '\(addedCard.nameCard ?? "nil")'")
                print("   - Key Knowledge: \(addedCard.keyKnowledge?.count ?? 0) items")
                print("   - Cultural Insights: \(addedCard.culturalInsights?.count ?? 0) characters")
                print("   - Question: '\(addedCard.question ?? "nil")'")
            }
        }
    }
    
    func removeCard(at cardIndex: Int, from destination: Destination) {
        if let destIndex = destinations.firstIndex(where: { $0.id == destination.id }) {
            guard cardIndex < destinations[destIndex].culturalCards.count else { return }
            let cardTitle = destinations[destIndex].culturalCards[cardIndex].title
            destinations[destIndex].removeCard(at: cardIndex)
            saveDestinations()
            print("➖ [DataManager] Removed card '\(cardTitle)' from \(destination.name)")
        }
    }
    
    func removeCard(_ card: CulturalCard, from destination: Destination) {
        if let destIndex = destinations.firstIndex(where: { $0.id == destination.id }),
           let cardIndex = destinations[destIndex].culturalCards.firstIndex(where: { $0.id == card.id }) {
            destinations[destIndex].removeCard(at: cardIndex)
            saveDestinations()
            print("➖ [DataManager] Removed card '\(card.title)' from \(destination.name)")
        }
    }
    
    func updateDestination(_ destination: Destination) {
        if let index = destinations.firstIndex(where: { $0.id == destination.id }) {
            destinations[index] = destination
            saveDestinations()
            print("🔄 [DataManager] Updated destination: \(destination.name)")
        }
    }
    
    // MARK: - Sample Data
    private func loadSampleData() {
        print("🎭 [DataManager] Loading sample data for first-time setup...")
        destinations = Destination.sampleData
        saveDestinations() // Save sample data to persistent storage
        print("✅ [DataManager] Sample data loaded and saved")
    }
    
    // MARK: - Utility Methods
    func printStorageInfo() {
        print("📊 [DataManager] Storage Information:")
        print("   - Documents Directory: \(documentsDirectory.path)")
        print("   - Destinations File: \(destinationsURL.path)")
        print("   - File Exists: \(FileManager.default.fileExists(atPath: destinationsURL.path))")
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: destinationsURL.path),
           let fileSize = attributes[.size] as? Int64 {
            print("   - File Size: \(fileSize) bytes")
        }
    }
    
    // MARK: - Data Validation
    func validateData() -> Bool {
        // Check for duplicate destination IDs
        let destinationIds = destinations.map { $0.id }
        let uniqueIds = Set(destinationIds)
        
        if destinationIds.count != uniqueIds.count {
            print("⚠️ [DataManager] Warning: Duplicate destination IDs found!")
            return false
        }
        
        // Check for duplicate card IDs within destinations
        for destination in destinations {
            let cardIds = destination.culturalCards.map { $0.id }
            let uniqueCardIds = Set(cardIds)
            
            if cardIds.count != uniqueCardIds.count {
                print("⚠️ [DataManager] Warning: Duplicate card IDs found in \(destination.name)!")
                return false
            }
        }
        
        print("✅ [DataManager] Data validation passed")
        return true
    }
} 