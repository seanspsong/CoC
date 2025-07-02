//
//  AICardGenerator.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import Foundation
import Combine
import FoundationModels

// MARK: - AI Response Structure
@Generable
struct CulturalInsightResponse {
    @Guide(description: "A concise, descriptive title for the cultural insight")
    let title: String
    
    @Guide(description: "One of: Business Etiquette, Social Customs, Communication Styles, Gift Giving, Dining Etiquette, Time Management, Hierarchy, Greeting Customs")
    let category: String
    
    @Guide(description: "One word/concept or full person name that captures the essence (e.g., 'Respect', 'Hierarchy', 'Tanaka Hiroshi', 'Protocol')")
    let nameCard: String
    
    @Guide(description: "Exactly 4 key knowledge points starting with relevant emojis", .count(4))
    let keyKnowledge: [String]
    
    @Guide(description: "A comprehensive cultural insight paragraph explaining the practice and cultural reasoning")
    let culturalInsights: String
}

@MainActor
class AICardGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var generationProgress: String = ""
    @Published var errorMessage: String?
    
    // MARK: - Language Model Session
    private let languageSession: LanguageModelSession
    
    init() {
        // Initialize the language model session with cultural intelligence instructions
        let instructions = """
        You are a cultural expert helping people understand local customs and practices. Provide helpful cultural insights that are accurate and respectful.
        """
        
        languageSession = LanguageModelSession(instructions: instructions)
        print("🧠 [AICardGenerator] Initialized LanguageModelSession with simplified cultural instructions")
    }
    

    
    // MARK: - Card Generation
    func generateCulturalCard(
        destination: String,
        userQuery: String
    ) async throws -> CulturalCard {
        print("🤖 [AICardGenerator] ===== STARTING CULTURE CONTENT GENERATION =====")
        print("🎯 [AICardGenerator] Destination: '\(destination)'")
        print("🎤 [AICardGenerator] Voice Transcript: '\(userQuery)'")
        print("📏 [AICardGenerator] Transcript Length: \(userQuery.count) characters")
        
        isGenerating = true
        generationProgress = "Analyzing your question..."
        errorMessage = nil
        
        defer {
            isGenerating = false
            generationProgress = ""
            print("🏁 [AICardGenerator] ===== GENERATION PROCESS COMPLETED =====")
        }
        
        do {
            // Build the complete prompt
            print("🔨 [AICardGenerator] Building AI prompt...")
            let prompt = buildPrompt(destination: destination, query: userQuery)
            
            generationProgress = "Generating cultural insight..."
            print("⚡ [AICardGenerator] Sending prompt to AI model...")
            
            // Generate content using on-device model with structured response
            let response = try await generateWithFoundationModel(prompt: prompt)
            
            generationProgress = "Processing response..."
            print("🔍 [AICardGenerator] Converting structured response to CulturalCard...")
            
            // Convert structured response to cultural card
            let card = convertToCulturalCard(response: response, destination: destination, question: userQuery)
            
            generationProgress = "Complete!"
            print("✅ [AICardGenerator] Cultural card generated successfully!")
            print("📋 [AICardGenerator] Card Title: '\(card.title)'")
            print("🏷️ [AICardGenerator] Card Category: \(card.category?.title ?? "None")")
            
            return card
            
        } catch {
            let errorMsg = "Failed to generate cultural card: \(error.localizedDescription)"
            print("❌ [AICardGenerator] ERROR: \(errorMsg)")
            print("❌ [AICardGenerator] Error Details: \(error)")
            errorMessage = errorMsg
            throw error
        }
    }
    
    // MARK: - Prompt Building
    private func buildPrompt(destination: String, query: String) -> String {
        print("📝 [AICardGenerator] Constructing prompt for LanguageModelSession...")
        
        let prompt = """
        Destination: \(destination)
        User Question: "\(query)"
        
        Please provide a cultural insight about \(destination) that addresses the user's question. Structure your response with:
        1. A name card: use a full person name (given name + family name) if about specific people/roles, otherwise use one concept word
        2. Four key knowledge points starting with relevant emojis
        3. Comprehensive cultural insights paragraph
        """
        
        print("📋 [AICardGenerator] PROMPT FOR FOUNDATION MODEL:")
        print("--- PROMPT START ---")
        print(prompt)
        print("--- PROMPT END ---")
        print("📏 [AICardGenerator] Prompt Length: \(prompt.count) characters")
        
        return prompt
    }
    
    // MARK: - Foundation Model Integration
    private func generateWithFoundationModel(prompt: String) async throws -> CulturalInsightResponse {
        print("🧠 [AICardGenerator] Calling Apple Foundation Model via LanguageModelSession...")
        
        // Check if the model is available
        guard SystemLanguageModel.default.availability == .available else {
            print("❌ [AICardGenerator] Foundation Model not available")
            throw NSError(domain: "AICardGenerator", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Apple Intelligence Foundation Model is not available on this device"
            ])
        }
        
        print("✅ [AICardGenerator] Foundation Model is available")
        print("📤 [AICardGenerator] Sending structured prompt to Foundation Model...")
        
        do {
            // Use guided generation to get structured response
            let response = try await languageSession.respond(
                to: prompt,
                generating: CulturalInsightResponse.self
            )
            
            print("📤 [AICardGenerator] STRUCTURED AI RESPONSE RECEIVED:")
            print("--- AI RESPONSE START ---")
            print("Title: \(response.content.title)")
            print("Category: \(response.content.category)")
            print("Name Card: \(response.content.nameCard)")
            print("Key Knowledge: \(response.content.keyKnowledge)")
            print("Cultural Insights: \(response.content.culturalInsights)")
            print("--- AI RESPONSE END ---")
            
            return response.content
            
        } catch {
            print("❌ [AICardGenerator] Foundation Model error: \(error)")
            print("🔄 [AICardGenerator] Falling back to mock response...")
            
            // Fallback to mock response if Foundation Model fails
            let mockResponse = try await generateMockResponse(for: prompt)
            return try parseMockResponseToStructured(mockResponse)
        }
    }
    
    // MARK: - Mock Response Generator (for development)
    private func generateMockResponse(for prompt: String) async throws -> String {
        print("🎭 [AICardGenerator] Generating mock AI response...")
        
        // Simulate network delay
        print("⏱️ [AICardGenerator] Simulating AI processing delay (2 seconds)...")
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Analyze the prompt to generate contextual response
        let destination = extractDestination(from: prompt)
        let query = extractQuery(from: prompt)
        
        print("🔍 [AICardGenerator] Extracted from prompt:")
        print("   - Destination: '\(destination)'")
        print("   - Query: '\(query)'")
        
        // Generate appropriate mock response based on query content
        let responseType: String
        let response: String
        
        if query.lowercased().contains("greet") || query.lowercased().contains("hello") {
            responseType = "Greeting Response"
            response = generateGreetingResponse(for: destination)
        } else if query.lowercased().contains("meeting") || query.lowercased().contains("business") {
            responseType = "Meeting Response"
            response = generateMeetingResponse(for: destination)
        } else if query.lowercased().contains("food") || query.lowercased().contains("eat") || query.lowercased().contains("dining") {
            responseType = "Dining Response"
            response = generateDiningResponse(for: destination)
        } else {
            responseType = "General Response"
            response = generateGeneralResponse(for: destination, query: query)
        }
        
        print("🎯 [AICardGenerator] Selected response type: \(responseType)")
        return response
    }
    
    // MARK: - Response Conversion
    private func convertToCulturalCard(response: CulturalInsightResponse, destination: String, question: String) -> CulturalCard {
        print("🔄 [AICardGenerator] Converting structured response to CulturalCard...")
        
        // Map category string to enum
        let category = mapStringToCategory(response.category)
        
        let card = CulturalCard(
            title: response.title,
            category: category,
            nameCard: response.nameCard,
            keyKnowledge: response.keyKnowledge,
            culturalInsights: response.culturalInsights,
            destination: destination,
            question: question
        )
        
        print("✅ [AICardGenerator] Successfully converted to CulturalCard")
        print("🔍 [AICardGenerator] Final card details:")
        print("   - Title: '\(card.title)'")
        print("   - Is AI Generated: \(card.isAIGenerated)")
        print("   - Name Card: '\(card.nameCard ?? "nil")'")
        print("   - Key Knowledge: \(card.keyKnowledge?.count ?? 0) items: \(card.keyKnowledge ?? [])")
        print("   - Cultural Insights: '\(card.culturalInsights ?? "nil")'")
        print("   - Question: '\(card.question ?? "nil")'")
        print("   - Content (legacy): '\(card.content.prefix(100))...'")
        print("   - Category: \(card.category?.title ?? "nil")")
        print("📋 [AICardGenerator] Card Structure:")
        print("   - Name Card: '\(response.nameCard)'")
        print("   - Key Knowledge: \(response.keyKnowledge.count) points")
        print("   - Cultural Insights: \(response.culturalInsights.count) characters")
        return card
    }
    
    // MARK: - Mock Response Fallback
    private func parseMockResponseToStructured(_ mockResponse: String) throws -> CulturalInsightResponse {
        print("🔧 [AICardGenerator] Parsing mock response to structured format...")
        print("📝 [AICardGenerator] Mock response content:")
        print("--- MOCK RESPONSE START ---")
        print(mockResponse)
        print("--- MOCK RESPONSE END ---")
        
        // Try to parse JSON response from mock
        if let jsonData = mockResponse.data(using: .utf8) {
            do {
                let parsed = try JSONDecoder().decode(AIResponse.self, from: jsonData)
                
                print("✅ [AICardGenerator] Successfully parsed mock JSON response!")
                print("📋 [AICardGenerator] Parsed data:")
                print("   - Title: '\(parsed.title)'")
                print("   - Category: '\(parsed.category)'")
                print("   - Name Card: '\(parsed.nameCard ?? "nil")'")
                print("   - Key Knowledge: \(parsed.keyKnowledge?.count ?? 0) items")
                print("   - Cultural Insights: \(parsed.culturalInsights?.count ?? 0) chars")
                
                return CulturalInsightResponse(
                    title: parsed.title,
                    category: parsed.category,
                    nameCard: parsed.nameCard ?? extractNameCard(from: parsed.title),
                    keyKnowledge: parsed.keyKnowledge ?? parsed.practicalTips,
                    culturalInsights: parsed.culturalInsights ?? parsed.insight
                )
            } catch {
                print("❌ [AICardGenerator] JSON parsing failed with error: \(error)")
                print("🔍 [AICardGenerator] JSON Data Length: \(jsonData.count) bytes")
                print("🔄 [AICardGenerator] Attempting manual content extraction...")
                
                // Manual parsing fallback - extract content from JSON string
                return extractContentFromJSONString(mockResponse)
            }
        }
        
        print("❌ [AICardGenerator] Could not convert mock response to JSON data")
        print("🔄 [AICardGenerator] Using raw content as cultural insights")
        
        // Final fallback - use the raw response as cultural insights
        return CulturalInsightResponse(
            title: "Cultural Business Insight",
            category: "Social Customs & Relationship Building",
            nameCard: "Culture",
            keyKnowledge: [
                "📚 Research local customs before important interactions",
                "❤️ Show genuine interest in cultural traditions",
                "🚫 Avoid assumptions based on stereotypes",
                "👀 Pay attention to subtle social cues"
            ],
            culturalInsights: mockResponse
        )
    }
    
    // MARK: - Legacy Response Parsing (for compatibility)
    private func parseToCulturalCard(response: String, destination: String, question: String) throws -> CulturalCard {
        print("🔧 [AICardGenerator] Parsing AI response to CulturalCard...")
        
        // Try to parse JSON response
        if let jsonData = response.data(using: .utf8) {
            print("✅ [AICardGenerator] AI response converted to JSON data successfully")
            
            do {
                print("🔍 [AICardGenerator] Attempting JSON parsing...")
                let parsed = try JSONDecoder().decode(AIResponse.self, from: jsonData)
                
                print("✅ [AICardGenerator] JSON parsed successfully!")
                print("📋 [AICardGenerator] Parsed content:")
                print("   - Title: '\(parsed.title)'")
                print("   - Category: '\(parsed.category)'")
                print("   - Insight Length: \(parsed.insight.count) characters")
                print("   - Practical Tips Count: \(parsed.practicalTips.count)")
                
                // Map category string to enum
                let category = mapStringToCategory(parsed.category)
                print("🏷️ [AICardGenerator] Mapped category '\(parsed.category)' to: \(category)")
                
                let card = CulturalCard(
                    title: parsed.title,
                    category: category,
                    nameCard: parsed.nameCard ?? extractNameCard(from: parsed.title),
                    keyKnowledge: parsed.keyKnowledge ?? parsed.practicalTips,
                    culturalInsights: parsed.culturalInsights ?? parsed.insight,
                    destination: destination,
                    question: question
                )
                
                print("✅ [AICardGenerator] CulturalCard created successfully!")
                return card
                
            } catch {
                print("❌ [AICardGenerator] JSON parsing failed: \(error)")
                print("🔄 [AICardGenerator] Falling back to manual parsing...")
                // If JSON parsing fails, try to extract content manually
                return try parseManualResponse(response: response, destination: destination, question: question)
            }
        }
        
        print("❌ [AICardGenerator] Could not convert response to JSON data")
        throw AIGenerationError.invalidResponse
    }
    
    // MARK: - Manual Content Extraction
    private func extractContentFromJSONString(_ jsonString: String) -> CulturalInsightResponse {
        print("🔧 [AICardGenerator] Extracting content manually from JSON string...")
        
        // Extract title
        let title = extractValue(from: jsonString, key: "title") ?? "Cultural Business Insight"
        
        // Extract category
        let category = extractValue(from: jsonString, key: "category") ?? "Social Customs & Relationship Building"
        
        // Extract name card
        let nameCard = extractValue(from: jsonString, key: "nameCard") ?? "Culture"
        
        // Extract cultural insights
        let culturalInsights = extractValue(from: jsonString, key: "culturalInsights") ?? 
                              extractValue(from: jsonString, key: "insight") ?? 
                              "Understanding cultural nuances requires attention to both explicit customs and subtle social cues. Building relationships based on mutual respect and cultural awareness shows professionalism and leads to successful partnerships."
        
        // Extract key knowledge array
        let keyKnowledge = extractArrayValues(from: jsonString, key: "keyKnowledge") ?? 
                          extractArrayValues(from: jsonString, key: "practicalTips") ?? [
            "📚 Research local customs before important interactions",
            "❤️ Show genuine interest in cultural traditions",
            "🚫 Avoid assumptions based on stereotypes",
            "👀 Pay attention to subtle social cues"
        ]
        
        print("✅ [AICardGenerator] Manual extraction completed!")
        print("📋 [AICardGenerator] Extracted content:")
        print("   - Title: '\(title)'")
        print("   - Category: '\(category)'")
        print("   - Name Card: '\(nameCard)'")
        print("   - Key Knowledge: \(keyKnowledge.count) items")
        print("   - Cultural Insights: \(culturalInsights.count) characters")
        
        return CulturalInsightResponse(
            title: title,
            category: category,
            nameCard: nameCard,
            keyKnowledge: keyKnowledge,
            culturalInsights: culturalInsights
        )
    }
    
    private func extractValue(from jsonString: String, key: String) -> String? {
        // Extract string value from JSON using regex
        let pattern = "\"" + key + "\"\\s*:\\s*\"([^\"]*)\""
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: jsonString, options: [], range: NSRange(location: 0, length: jsonString.count)),
           let range = Range(match.range(at: 1), in: jsonString) {
            return String(jsonString[range])
        }
        return nil
    }
    
    private func extractArrayValues(from jsonString: String, key: String) -> [String]? {
        // Extract array of strings from JSON - handle multiline arrays properly
        let pattern = "\"" + key + "\"\\s*:\\s*\\[([^\\]]+)\\]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: jsonString, options: [], range: NSRange(location: 0, length: jsonString.count)),
           let range = Range(match.range(at: 1), in: jsonString) {
            
            let arrayContent = String(jsonString[range])
            print("🔍 [AICardGenerator] Raw array content: '\(arrayContent)'")
            
            // More robust parsing - split by quotes and commas
            var items: [String] = []
            let scanner = Scanner(string: arrayContent)
            
            while !scanner.isAtEnd {
                scanner.scanUpToString("\"")
                if scanner.scanString("\"") != nil {
                    if let item = scanner.scanUpToString("\"") {
                        let cleanedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !cleanedItem.isEmpty {
                            items.append(cleanedItem)
                        }
                    }
                    scanner.scanString("\"")
                }
                scanner.scanUpToString("\"")
            }
            
            print("🔍 [AICardGenerator] Extracted array items: \(items)")
            return items.isEmpty ? nil : items
        }
        return nil
    }
    
    // MARK: - Helper Functions
    private func extractDestination(from prompt: String) -> String {
        if prompt.lowercased().contains("japan") { return "Japan" }
        if prompt.lowercased().contains("germany") { return "Germany" }
        if prompt.lowercased().contains("china") { return "China" }
        if prompt.lowercased().contains("korea") { return "Korea" }
        return "Unknown"
    }
    
    private func extractNameCard(from title: String) -> String {
        // Extract key word or name from title for name card
        let lowercaseTitle = title.lowercased()
        
        // Check for person-related contexts that might warrant full names
        if lowercaseTitle.contains("ceo") || lowercaseTitle.contains("executive") || lowercaseTitle.contains("manager") {
            return "Executive Name"
        } else if lowercaseTitle.contains("host") || lowercaseTitle.contains("hostess") {
            return "Host Name"
        } else if lowercaseTitle.contains("colleague") || lowercaseTitle.contains("coworker") {
            return "Colleague Name"
        }
        // Concept-based name cards
        else if lowercaseTitle.contains("greeting") || lowercaseTitle.contains("hello") {
            return "Greeting"
        } else if lowercaseTitle.contains("meeting") || lowercaseTitle.contains("business") {
            return "Protocol"
        } else if lowercaseTitle.contains("dining") || lowercaseTitle.contains("food") {
            return "Dining"
        } else if lowercaseTitle.contains("time") || lowercaseTitle.contains("punctuality") {
            return "Timing"
        } else if lowercaseTitle.contains("hierarchy") || lowercaseTitle.contains("respect") {
            return "Respect"
        } else if lowercaseTitle.contains("gift") {
            return "Gifting"
        } else if lowercaseTitle.contains("communication") || lowercaseTitle.contains("speak") {
            return "Communication"
        } else {
            // Extract first meaningful word from title
            let words = title.components(separatedBy: " ")
            return words.first { !["the", "a", "an", "of", "in", "for", "with", "and"].contains($0.lowercased()) } ?? "Culture"
        }
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
    
    private func parseManualResponse(response: String, destination: String, question: String) throws -> CulturalCard {
        print("🛠️ [AICardGenerator] Using manual parsing fallback...")
        print("📝 [AICardGenerator] Creating basic CulturalCard from raw response")
        
        // Fallback manual parsing if JSON fails
        let card = CulturalCard(
            title: "Cultural Insight",
            category: .socialCustoms,
            nameCard: "Culture",
            keyKnowledge: ["👀 Follow local customs", "🙏 Be respectful", "📝 Observe before acting", "❓ Ask for guidance when unsure"],
            culturalInsights: response,
            destination: destination,
            question: question
        )
        
        print("✅ [AICardGenerator] Manual parsing completed!")
        print("📋 [AICardGenerator] Manual card details:")
        print("   - Title: '\(card.title)'")
        print("   - Category: \(card.category?.title ?? "None")")
        print("   - Insight: Using full AI response as insight")
        print("   - Tips: Using default tips")
        
        return card
    }
}

// MARK: - AI Response Model
private struct AIResponse: Codable {
    let title: String
    let category: String
    let nameCard: String?
    let keyKnowledge: [String]?
    let culturalInsights: String?
    
    // Legacy fields for backward compatibility
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
                "nameCard": "Respect",
                "keyKnowledge": [
                    "🙇 Bowing depth reflects hierarchy and respect levels",
                    "🤝 Handshakes are becoming common with international colleagues",
                    "👴 Senior person should initiate the greeting interaction",
                    "🤏 Gentle grip preferred over firm Western-style handshakes"
                ],
                "culturalInsights": "In Japanese business culture, the bow (ojigi) is the traditional greeting that shows respect and hierarchy awareness. The depth and duration of your bow should reflect the status of the person you're greeting - deeper bows for senior executives, lighter bows for peers. However, many Japanese businesspeople now expect handshakes when meeting international colleagues, creating a hybrid approach that honors both traditions.",
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
                "nameCard": "Directness",
                "keyKnowledge": [
                    "🤝 Firm handshake with direct eye contact is standard",
                    "🎩 Use formal titles and surnames until invited otherwise",
                    "⏰ Punctuality shows respect and professionalism",
                    "🚧 Keep personal and professional boundaries clear"
                ],
                "culturalInsights": "German business culture values directness and efficiency in greetings. A firm handshake with direct eye contact is the standard, accompanied by formal titles and surnames until invited to use first names. Germans appreciate punctuality and prefer to keep personal and professional boundaries clear during initial meetings, focusing on business rather than extensive personal conversation.",
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
            "nameCard": "Protocol",
            "keyKnowledge": [
                "⏰ Punctuality demonstrates respect and professionalism",
                "💳 Business card exchange follows specific cultural rules",
                "📊 Hierarchy determines speaking order and decision-making",
                "📚 Cultural preparation shows commitment to relationships"
            ],
            "culturalInsights": "Business meetings in \(destination) follow specific cultural protocols that demonstrate respect and professionalism. Understanding hierarchy, timing, and communication styles is crucial for successful interactions. Preparation and attention to cultural nuances can make the difference between building strong business relationships and missing opportunities.",
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
            "nameCard": "Dining",
            "keyKnowledge": [
                "🍽️ Host always initiates eating and drinking",
                "👍 Trying local dishes shows cultural appreciation",
                "💬 Build rapport before discussing business matters",
                "🙏 Politely explain if you cannot eat something offered"
            ],
            "culturalInsights": "Business dining in \(destination) is an important relationship-building activity with specific etiquette rules. Understanding proper table manners, gift-giving customs, and conversation topics can strengthen business partnerships. The way you handle dining situations often reflects your respect for local culture and attention to detail.",
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
        // Check if query is about specific people/roles to determine name card type
        let lowercaseQuery = query.lowercased()
        let nameCard: String
        
        if lowercaseQuery.contains("ceo") || lowercaseQuery.contains("executive") || lowercaseQuery.contains("manager") {
            // Use appropriate full name based on destination
            switch destination.lowercased() {
            case "japan":
                nameCard = "Tanaka Hiroshi"
            case "germany":
                nameCard = "Müller Hans"
            case "china":
                nameCard = "Wang Li Ming"
            case "korea":
                nameCard = "Kim Min Jun"
            default:
                nameCard = "Executive Name"
            }
        } else if lowercaseQuery.contains("colleague") || lowercaseQuery.contains("coworker") {
            switch destination.lowercased() {
            case "japan":
                nameCard = "Sato Yuki"
            case "germany":
                nameCard = "Schmidt Anna"
            case "china":
                nameCard = "Liu Wei"
            case "korea":
                nameCard = "Park Ji Hye"
            default:
                nameCard = "Colleague Name"
            }
        } else {
            nameCard = "Culture"
        }
        
        return """
        {
            "title": "Cultural Business Insight",
            "category": "Social Customs & Relationship Building",
            "nameCard": "\(nameCard)",
            "keyKnowledge": [
                "📚 Research local customs before important interactions",
                "❤️ Show genuine interest in cultural traditions",
                "🚫 Avoid assumptions based on stereotypes",
                "👀 Pay attention to subtle social cues and non-verbal communication"
            ],
            "culturalInsights": "Understanding cultural nuances in \(destination) requires attention to both explicit customs and subtle social cues. Business relationships are built on mutual respect and cultural awareness. Taking time to learn and demonstrate appreciation for local customs shows professionalism and can lead to stronger, more successful business partnerships.",
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