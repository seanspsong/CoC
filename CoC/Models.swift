//
//  Models.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import Foundation

// MARK: - Destination Model
struct Destination: Identifiable, Codable {
    let id = UUID()
    var name: String
    var flag: String
    var culturalCards: [CulturalCard]
    var dateAdded: Date
    var lastUpdated: Date
    
    // Custom CodingKeys to exclude id from encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case name, flag, culturalCards, dateAdded, lastUpdated
    }
    
    // Custom decoder to handle id initialization
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.flag = try container.decode(String.self, forKey: .flag)
        self.culturalCards = try container.decode([CulturalCard].self, forKey: .culturalCards)
        self.dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    }
    
    init(name: String, flag: String) {
        self.name = name
        self.flag = flag
        self.culturalCards = []
        self.dateAdded = Date()
        self.lastUpdated = Date()
    }
    
    mutating func addCard(_ card: CulturalCard) {
        culturalCards.append(card)
        lastUpdated = Date()
    }
    
    mutating func removeCard(at index: Int) {
        guard index < culturalCards.count else { return }
        culturalCards.remove(at: index)
        lastUpdated = Date()
    }
}

// MARK: - Cultural Card Model
struct CulturalCard: Identifiable, Codable {
    let id = UUID()
    var type: CardType
    var title: String
    var content: String
    var dateAdded: Date
    
    // AI-Generated Card Properties
    var category: CulturalCategory?
    var nameCard: String?           // Section 1: One word/name (big bold)
    var keyKnowledge: [String]?     // Section 2: Key Knowledge (bullet points)
    var culturalInsights: String?   // Section 3: Cultural Insights (text paragraph)
    var isAIGenerated: Bool
    var destination: String?
    
    // Legacy properties for backward compatibility (computed properties - not encoded)
    var insight: String? { culturalInsights }
    var practicalTips: [String]? { keyKnowledge }
    
    // Custom CodingKeys to exclude id and computed properties from encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case type, title, content, dateAdded
        case category, nameCard, keyKnowledge, culturalInsights, isAIGenerated, destination
    }
    
    // Custom decoder to handle id initialization
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.type = try container.decode(CardType.self, forKey: .type)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        self.category = try container.decodeIfPresent(CulturalCategory.self, forKey: .category)
        self.nameCard = try container.decodeIfPresent(String.self, forKey: .nameCard)
        self.keyKnowledge = try container.decodeIfPresent([String].self, forKey: .keyKnowledge)
        self.culturalInsights = try container.decodeIfPresent(String.self, forKey: .culturalInsights)
        self.isAIGenerated = try container.decode(Bool.self, forKey: .isAIGenerated)
        self.destination = try container.decodeIfPresent(String.self, forKey: .destination)
    }
    
    // Traditional card initializer
    init(type: CardType, title: String, content: String) {
        self.type = type
        self.title = title
        self.content = content
        self.dateAdded = Date()
        self.isAIGenerated = false
        self.category = nil
        self.nameCard = nil
        self.keyKnowledge = nil
        self.culturalInsights = nil
        self.destination = nil
    }
    
    // AI-Generated card initializer
    init(
        title: String,
        category: CulturalCategory,
        nameCard: String,
        keyKnowledge: [String],
        culturalInsights: String,
        destination: String
    ) {
        self.type = category.cardType
        self.title = title
        self.content = culturalInsights // Use cultural insights as primary content for legacy compatibility
        self.category = category
        self.nameCard = nameCard
        self.keyKnowledge = keyKnowledge
        self.culturalInsights = culturalInsights
        self.isAIGenerated = true
        self.destination = destination
        self.dateAdded = Date()
    }
}

// MARK: - Card Type Enum
enum CardType: String, CaseIterable, Codable {
    case businessEtiquette = "business_etiquette"
    case socialCustoms = "social_customs"
    case diningCulture = "dining_culture"
    case communication = "communication"
    case giftGiving = "gift_giving"
    case quickFacts = "quick_facts"
    
    var title: String {
        switch self {
        case .businessEtiquette:
            return "Business Etiquette"
        case .socialCustoms:
            return "Social Customs"
        case .diningCulture:
            return "Dining Culture"
        case .communication:
            return "Communication"
        case .giftGiving:
            return "Gift Giving"
        case .quickFacts:
            return "Quick Facts"
        }
    }
    
    var emoji: String {
        switch self {
        case .businessEtiquette:
            return "💼"
        case .socialCustoms:
            return "🤝"
        case .diningCulture:
            return "🍽️"
        case .communication:
            return "💬"
        case .giftGiving:
            return "🎁"
        case .quickFacts:
            return "⚡"
        }
    }
    
    var description: String {
        switch self {
        case .businessEtiquette:
            return "Meeting protocols, dress codes, punctuality"
        case .socialCustoms:
            return "Greetings, conversation topics, personal space"
        case .diningCulture:
            return "Table manners, tipping, dining customs"
        case .communication:
            return "Direct vs. indirect, gestures, eye contact"
        case .giftGiving:
            return "Appropriate gifts, presentation, occasions"
        case .quickFacts:
            return "Key phrases, important numbers, cultural notes"
        }
    }
}

// MARK: - Cultural Category Enum (for AI-Generated Cards)
enum CulturalCategory: String, CaseIterable, Codable {
    case businessEtiquette = "Business Etiquette & Meeting Protocols"
    case socialCustoms = "Social Customs & Relationship Building"
    case communication = "Communication Styles & Non-verbal Cues"
    case giftGiving = "Gift Giving & Entertainment"
    case diningCulture = "Dining Etiquette & Food Culture"
    case timeManagement = "Time Management & Scheduling"
    case hierarchy = "Hierarchy & Decision Making"
    case greetingCustoms = "Greeting Customs & Personal Space"
    
    var title: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .businessEtiquette:
            return "💼"
        case .socialCustoms:
            return "🤝"
        case .communication:
            return "💬"
        case .giftGiving:
            return "🎁"
        case .diningCulture:
            return "🍽️"
        case .timeManagement:
            return "⏰"
        case .hierarchy:
            return "👔"
        case .greetingCustoms:
            return "👋"
        }
    }
    
    var cardType: CardType {
        switch self {
        case .businessEtiquette, .hierarchy:
            return .businessEtiquette
        case .socialCustoms, .greetingCustoms:
            return .socialCustoms
        case .communication:
            return .communication
        case .giftGiving:
            return .giftGiving
        case .diningCulture:
            return .diningCulture
        case .timeManagement:
            return .quickFacts
        }
    }
}

// MARK: - Sample Data
extension Destination {
    static let sampleData: [Destination] = [
        {
            var japan = Destination(name: "Japan", flag: "🇯🇵")
            japan.addCard(CulturalCard(
                type: .businessEtiquette,
                title: "Business Card Exchange",
                content: "Present and receive business cards with both hands. Take time to read the card before putting it away. Never write on someone's business card in their presence."
            ))
            japan.addCard(CulturalCard(
                type: .socialCustoms,
                title: "Bowing Etiquette",
                content: "Bowing is still common in formal situations. A slight bow of the head is appropriate for foreigners. The deeper the bow, the more respect shown."
            ))
            return japan
        }(),
        
        {
            var germany = Destination(name: "Germany", flag: "🇩🇪")
            germany.addCard(CulturalCard(
                type: .businessEtiquette,
                title: "Punctuality",
                content: "Germans value punctuality highly. Arrive exactly on time or slightly early. Being late is considered disrespectful and unprofessional."
            ))
            germany.addCard(CulturalCard(
                type: .diningCulture,
                title: "Table Manners",
                content: "Keep your hands visible on the table. Wait for the host to say 'Guten Appetit' before eating. Don't cut potatoes with a knife - use your fork."
            ))
            return germany
        }()
    ]
} 