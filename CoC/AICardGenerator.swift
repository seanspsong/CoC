//
//  AICardGenerator.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import Foundation
import Combine

@MainActor
class AICardGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var generationProgress: String = ""
    @Published var errorMessage: String?
    
    // MARK: - System Prompt
    private let systemPrompt = """
    You are a cultural intelligence expert helping international business professionals understand local customs and practices. Your role is to provide practical, actionable cultural insights that help build respectful business relationships.
    
    Guidelines:
    - Provide specific, actionable advice
    - Focus on business and professional contexts
    - Include DO and DON'T examples
    - Explain the cultural reasoning behind practices
    - Keep responses concise but comprehensive (2-3 paragraphs)
    - Use respectful, professional tone
    - Avoid stereotypes or oversimplifications
    
    Categories to consider:
    - Business Etiquette & Meeting Protocols
    - Social Customs & Relationship Building
    - Communication Styles & Non-verbal Cues
    - Gift Giving & Entertainment
    - Dining Etiquette & Food Culture
    - Time Management & Scheduling
    - Hierarchy & Decision Making
    - Greeting Customs & Personal Space
    
    Format your response as JSON:
    {
        "title": "[Concise topic title]",
        "category": "[One of the categories above]",
        "insight": "[Main cultural insight paragraph]",
        "practicalTips": ["[Tip 1]", "[Tip 2]", "[Tip 3]", "[Tip 4]"]
    }
    """
    
    // MARK: - Card Generation
    func generateCulturalCard(
        destination: String,
        userQuery: String
    ) async throws -> CulturalCard {
        isGenerating = true
        generationProgress = "Analyzing your question..."
        errorMessage = nil
        
        defer {
            isGenerating = false
            generationProgress = ""
        }
        
        do {
            // Build the complete prompt
            let prompt = buildPrompt(destination: destination, query: userQuery)
            
            generationProgress = "Generating cultural insight..."
            
            // Generate content using on-device model
            let response = try await generateWithFoundationModel(prompt: prompt)
            
            generationProgress = "Processing response..."
            
            // Parse the response and create cultural card
            let card = try parseToCulturalCard(response: response, destination: destination)
            
            generationProgress = "Complete!"
            
            return card
            
        } catch {
            errorMessage = "Failed to generate cultural card: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Prompt Building
    private func buildPrompt(destination: String, query: String) -> String {
        let userPrompt = """
        Destination: \(destination)
        User Question: "\(query)"
        
        Please generate a cultural insight card that addresses the user's question in the context of doing business in \(destination). Focus on practical advice that will help them navigate this cultural aspect professionally and respectfully.
        """
        
        return systemPrompt + "\n\n" + userPrompt
    }
    
    // MARK: - Foundation Model Integration
    private func generateWithFoundationModel(prompt: String) async throws -> String {
        // NOTE: This is using a placeholder implementation since iOS 26 MLGeneration
        // is not available in current Xcode. In actual iOS 26 implementation, this would be:
        //
        // import MLGeneration
        // let response = try await MLGeneration.shared.generateText(prompt: prompt)
        // return response
        
        // Placeholder implementation for development/testing
        return try await generateMockResponse(for: prompt)
    }
    
    // MARK: - Mock Response Generator (for development)
    private func generateMockResponse(for prompt: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Analyze the prompt to generate contextual response
        let destination = extractDestination(from: prompt)
        let query = extractQuery(from: prompt)
        
        // Generate appropriate mock response based on query content
        if query.lowercased().contains("greet") || query.lowercased().contains("hello") {
            return generateGreetingResponse(for: destination)
        } else if query.lowercased().contains("meeting") || query.lowercased().contains("business") {
            return generateMeetingResponse(for: destination)
        } else if query.lowercased().contains("food") || query.lowercased().contains("eat") || query.lowercased().contains("dining") {
            return generateDiningResponse(for: destination)
        } else {
            return generateGeneralResponse(for: destination, query: query)
        }
    }
    
    // MARK: - Response Parsing
    private func parseToCulturalCard(response: String, destination: String) throws -> CulturalCard {
        // Try to parse JSON response
        if let jsonData = response.data(using: .utf8) {
            do {
                let parsed = try JSONDecoder().decode(AIResponse.self, from: jsonData)
                
                // Map category string to enum
                let category = mapStringToCategory(parsed.category)
                
                return CulturalCard(
                    title: parsed.title,
                    category: category,
                    insight: parsed.insight,
                    practicalTips: parsed.practicalTips,
                    destination: destination
                )
            } catch {
                // If JSON parsing fails, try to extract content manually
                return try parseManualResponse(response: response, destination: destination)
            }
        }
        
        throw AIGenerationError.invalidResponse
    }
    
    // MARK: - Helper Functions
    private func extractDestination(from prompt: String) -> String {
        if prompt.lowercased().contains("japan") { return "Japan" }
        if prompt.lowercased().contains("germany") { return "Germany" }
        if prompt.lowercased().contains("china") { return "China" }
        if prompt.lowercased().contains("korea") { return "Korea" }
        return "Unknown"
    }
    
    private func extractQuery(from prompt: String) -> String {
        let lines = prompt.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("User Question:") {
                return line.replacingOccurrences(of: "User Question:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }
    
    private func mapStringToCategory(_ categoryString: String) -> CulturalCategory {
        switch categoryString {
        case "Business Etiquette & Meeting Protocols":
            return .businessEtiquette
        case "Social Customs & Relationship Building":
            return .socialCustoms
        case "Communication Styles & Non-verbal Cues":
            return .communication
        case "Gift Giving & Entertainment":
            return .giftGiving
        case "Dining Etiquette & Food Culture":
            return .diningCulture
        case "Time Management & Scheduling":
            return .timeManagement
        case "Hierarchy & Decision Making":
            return .hierarchy
        case "Greeting Customs & Personal Space":
            return .greetingCustoms
        default:
            return .socialCustoms
        }
    }
    
    private func parseManualResponse(response: String, destination: String) throws -> CulturalCard {
        // Fallback manual parsing if JSON fails
        return CulturalCard(
            title: "Cultural Insight",
            category: .socialCustoms,
            insight: response,
            practicalTips: ["Follow local customs", "Be respectful", "Observe before acting", "Ask for guidance when unsure"],
            destination: destination
        )
    }
}

// MARK: - AI Response Model
private struct AIResponse: Codable {
    let title: String
    let category: String
    let insight: String
    let practicalTips: [String]
}

// MARK: - Mock Response Generators
extension AICardGenerator {
    private func generateGreetingResponse(for destination: String) -> String {
        switch destination.lowercased() {
        case "japan":
            return """
            {
                "title": "Business Greeting Etiquette",
                "category": "Greeting Customs & Personal Space",
                "insight": "In Japanese business culture, the bow (ojigi) is the traditional greeting that shows respect and hierarchy awareness. The depth and duration of your bow should reflect the status of the person you're greeting - deeper bows for senior executives, lighter bows for peers. However, many Japanese businesspeople now expect handshakes when meeting international colleagues, creating a hybrid approach.",
                "practicalTips": [
                    "DO: Offer a slight bow while extending your hand for a handshake",
                    "DO: Wait for the senior person to initiate the greeting",
                    "DON'T: Rush the greeting process - allow time for proper acknowledgment",
                    "DON'T: Use overly firm handshakes; Japanese prefer gentler grips"
                ]
            }
            """
        case "germany":
            return """
            {
                "title": "German Business Greetings",
                "category": "Greeting Customs & Personal Space",
                "insight": "German business culture values directness and efficiency in greetings. A firm handshake with direct eye contact is the standard, accompanied by formal titles and surnames until invited to use first names. Germans appreciate punctuality and prefer to keep personal and professional boundaries clear during initial meetings.",
                "practicalTips": [
                    "DO: Use a firm handshake with direct eye contact",
                    "DO: Address people by their title and surname initially",
                    "DON'T: Use first names unless explicitly invited",
                    "DON'T: Engage in extensive small talk during business greetings"
                ]
            }
            """
        default:
            return generateGeneralResponse(for: destination, query: "greeting customs")
        }
    }
    
    private func generateMeetingResponse(for destination: String) -> String {
        return """
        {
            "title": "Business Meeting Protocols",
            "category": "Business Etiquette & Meeting Protocols",
            "insight": "Business meetings in \(destination) follow specific cultural protocols that demonstrate respect and professionalism. Understanding hierarchy, timing, and communication styles is crucial for successful interactions. Preparation and attention to cultural nuances can make the difference between building strong business relationships and missing opportunities.",
            "practicalTips": [
                "DO: Arrive on time or slightly early to show respect",
                "DO: Bring business cards and exchange them properly",
                "DON'T: Interrupt senior members during presentations",
                "DON'T: Make decisions without considering hierarchy"
            ]
        }
        """
    }
    
    private func generateDiningResponse(for destination: String) -> String {
        return """
        {
            "title": "Business Dining Etiquette",
            "category": "Dining Etiquette & Food Culture",
            "insight": "Business dining in \(destination) is an important relationship-building activity with specific etiquette rules. Understanding proper table manners, gift-giving customs, and conversation topics can strengthen business partnerships. The way you handle dining situations often reflects your respect for local culture and attention to detail.",
            "practicalTips": [
                "DO: Wait for the host to begin eating or drinking",
                "DO: Try local dishes to show cultural appreciation",
                "DON'T: Discuss business immediately - build rapport first",
                "DON'T: Refuse offered food or drink without polite explanation"
            ]
        }
        """
    }
    
    private func generateGeneralResponse(for destination: String, query: String) -> String {
        return """
        {
            "title": "Cultural Business Insight",
            "category": "Social Customs & Relationship Building",
            "insight": "Understanding cultural nuances in \(destination) requires attention to both explicit customs and subtle social cues. Business relationships are built on mutual respect and cultural awareness. Taking time to learn and demonstrate appreciation for local customs shows professionalism and can lead to stronger, more successful business partnerships.",
            "practicalTips": [
                "DO: Research local customs before important interactions",
                "DO: Show genuine interest in cultural traditions",
                "DON'T: Make assumptions based on stereotypes",
                "DON'T: Ignore subtle social cues or non-verbal communication"
            ]
        }
        """
    }
}

// MARK: - AI Generation Errors
enum AIGenerationError: LocalizedError {
    case invalidResponse
    case networkError
    case modelUnavailable
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid AI response format"
        case .networkError:
            return "Network connection failed"
        case .modelUnavailable:
            return "AI model temporarily unavailable"
        case .processingFailed:
            return "Failed to process AI response"
        }
    }
} 