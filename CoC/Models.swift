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
    
    init(type: CardType, title: String, content: String) {
        self.type = type
        self.title = title
        self.content = content
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