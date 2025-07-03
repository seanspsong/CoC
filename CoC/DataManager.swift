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
            
            // Migrate old format cards to new format
            migrateCardsToNewFormat()
            
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
        print("   - Name Card App: '\(card.nameCardApp ?? "nil")'")
        print("   - Name Card Local: '\(card.nameCardLocal ?? "nil")'")
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
                print("   - Name Card App: '\(addedCard.nameCardApp ?? "nil")'")
                print("   - Name Card Local: '\(addedCard.nameCardLocal ?? "nil")'")
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
    
    // MARK: - Migration
    private func migrateCardsToNewFormat() {
        print("🔄 [DataManager] Checking for cards that need migration to new format...")
        
        var migrationCount = 0
        
        for destinationIndex in destinations.indices {
            let destination = destinations[destinationIndex]
            
            for cardIndex in destinations[destinationIndex].culturalCards.indices {
                var card = destinations[destinationIndex].culturalCards[cardIndex]
                
                // Check if card needs migration (old format with no nameCardApp/nameCardLocal)
                if card.nameCardApp == nil && card.nameCardLocal == nil && !card.isAIGenerated {
                    print("🔧 [DataManager] Migrating card: '\(card.title)' in \(destination.name)")
                    
                    // Create appropriate bilingual name cards based on title
                    let (nameCardApp, nameCardLocal) = generateNameCardForMigration(
                        title: card.title, 
                        destination: destination.name
                    )
                    
                    // Create key knowledge from content
                    let keyKnowledge = generateKeyKnowledgeFromContent(card.content)
                    
                    // Determine appropriate category
                    let category = determineCategoryFromType(card.type)
                    
                    // Create migrated card
                    let migratedCard = CulturalCard(
                        title: card.title,
                        category: category,
                        nameCardApp: nameCardApp,
                        nameCardLocal: nameCardLocal,
                        keyKnowledge: keyKnowledge,
                        culturalInsights: card.content,
                        destination: destination.name
                    )
                    
                    // Replace the old card with migrated version
                    destinations[destinationIndex].culturalCards[cardIndex] = migratedCard
                    migrationCount += 1
                    
                    print("✅ [DataManager] Migrated: '\(card.title)' -> App: '\(nameCardApp)', Local: '\(nameCardLocal ?? "nil")'")
                }
            }
        }
        
        if migrationCount > 0 {
            print("✅ [DataManager] Migration completed: \(migrationCount) cards migrated to new format")
            saveDestinations() // Save the migrated data
        } else {
            print("ℹ️ [DataManager] No cards needed migration")
        }
    }
    
    private func generateNameCardForMigration(title: String, destination: String) -> (String, String?) {
        let lowercaseTitle = title.lowercased()
        
        // Map titles to appropriate concepts
        if lowercaseTitle.contains("business card") || lowercaseTitle.contains("protocol") {
            return ("Protocol", getLocalizedConcept("protocol", for: destination))
        } else if lowercaseTitle.contains("bow") || lowercaseTitle.contains("respect") || lowercaseTitle.contains("greeting") {
            return ("Respect", getLocalizedConcept("respect", for: destination))
        } else if lowercaseTitle.contains("punctuality") || lowercaseTitle.contains("time") {
            return ("Time", getLocalizedConcept("time", for: destination))
        } else if lowercaseTitle.contains("dining") || lowercaseTitle.contains("table") || lowercaseTitle.contains("manners") {
            return ("Dining", getLocalizedConcept("dining", for: destination))
        } else if lowercaseTitle.contains("communication") {
            return ("Communication", getLocalizedConcept("communication", for: destination))
        } else if lowercaseTitle.contains("gift") {
            return ("Gift", getLocalizedConcept("gift", for: destination))
        } else if lowercaseTitle.contains("hierarchy") {
            return ("Hierarchy", getLocalizedConcept("hierarchy", for: destination))
        } else {
            return ("Culture", getLocalizedConcept("culture", for: destination))
        }
    }
    
    private func getLocalizedConcept(_ concept: String, for destination: String) -> String? {
        switch destination.lowercased() {
        case "japan":
            switch concept {
            case "protocol": return "礼儀"
            case "respect": return "尊敬"
            case "time": return "時間"
            case "dining": return "食事"
            case "communication": return "コミュニケーション"
            case "gift": return "贈り物"
            case "hierarchy": return "階層"
            case "culture": return "文化"
            default: return nil
            }
        case "germany":
            switch concept {
            case "protocol": return "Protokoll"
            case "respect": return "Respekt"
            case "time": return "Zeit"
            case "dining": return "Speisen"
            case "communication": return "Kommunikation"
            case "gift": return "Geschenk"
            case "hierarchy": return "Hierarchie"
            case "culture": return "Kultur"
            default: return nil
            }
        default:
            return nil
        }
    }
    
    private func generateKeyKnowledgeFromContent(_ content: String) -> [String] {
        // Split content into sentences and create key knowledge points
        let sentences = content.components(separatedBy: ". ").filter { !$0.isEmpty }
        
        return sentences.enumerated().map { index, sentence in
            let emoji = ["📚", "👀", "🙏", "⚡"][index % 4]
            let cleanSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ".", with: "")
            return "\(emoji) \(cleanSentence)"
        }
    }
    
    private func determineCategoryFromType(_ type: CardType) -> CulturalCategory {
        switch type {
        case .businessEtiquette:
            return .businessEtiquette
        case .socialCustoms:
            return .socialCustoms
        case .communication:
            return .communication
        case .giftGiving:
            return .giftGiving
        case .diningCulture:
            return .diningCulture
        case .quickFacts:
            return .timeManagement
        }
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