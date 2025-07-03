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
    
    @Guide(description: "One word/concept or full person name with local translation (e.g., 'Respect\\n尊敬', 'Hierarchy\\n階層', 'Tanaka Hiroshi\\n田中宏', 'Protocol\\n礼儀')")
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
        1. A name card: use a full person name (given name + family name) if about specific people/roles, otherwise use one concept word. ALWAYS provide both English and local language versions separated by newline (e.g., "Respect\\n尊敬" for concepts, "Tanaka Hiroshi\\n田中宏" for names).
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
            let destination = extractDestination(from: prompt)
            return try parseMockResponseToStructured(mockResponse, destination: destination)
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
        
        // Parse the nameCard if it contains both app and local language
        var nameCardApp: String? = nil
        var nameCardLocal: String? = nil
        
        let nameCard = response.nameCard
        let lines = nameCard.components(separatedBy: "\n")
        if lines.count >= 2 {
            nameCardApp = lines[0]
            nameCardLocal = lines[1]
        } else {
            // If we only got one line, try to get localized version for concepts
            nameCardApp = nameCard
            // Try to get localized version if it's a concept
            let localizedVersion = getLocalizedNameCard(concept: nameCard, destination: destination)
            let localizedLines = localizedVersion.components(separatedBy: "\n")
            if localizedLines.count >= 2 {
                nameCardApp = localizedLines[0]
                nameCardLocal = localizedLines[1]
            } else {
                nameCardLocal = nil
            }
        }
        
        let card = CulturalCard(
            title: response.title,
            category: category,
            nameCardApp: nameCardApp,
            nameCardLocal: nameCardLocal,
            keyKnowledge: response.keyKnowledge,
            culturalInsights: response.culturalInsights,
            destination: destination,
            question: question
        )
        
        print("✅ [AICardGenerator] Successfully converted to CulturalCard")
        print("🔍 [AICardGenerator] Final card details:")
        print("   - Title: '\(card.title)'")
        print("   - Is AI Generated: \(card.isAIGenerated)")
        print("   - Name Card App: '\(card.nameCardApp ?? "nil")'")
        print("   - Name Card Local: '\(card.nameCardLocal ?? "nil")'")
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
    private func parseMockResponseToStructured(_ mockResponse: String, destination: String) throws -> CulturalInsightResponse {
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
                    nameCard: parsed.nameCard ?? extractNameCard(from: parsed.title, destination: destination),
                    keyKnowledge: parsed.keyKnowledge ?? parsed.practicalTips,
                    culturalInsights: parsed.culturalInsights ?? parsed.insight
                )
            } catch {
                print("❌ [AICardGenerator] JSON parsing failed with error: \(error)")
                print("🔍 [AICardGenerator] JSON Data Length: \(jsonData.count) bytes")
                print("🔄 [AICardGenerator] Attempting manual content extraction...")
                
                // Manual parsing fallback - extract content from JSON string
                return extractContentFromJSONString(mockResponse, destination: destination)
            }
        }
        
        print("❌ [AICardGenerator] Could not convert mock response to JSON data")
        print("🔄 [AICardGenerator] Using raw content as cultural insights")
        
        // Final fallback - use the raw response as cultural insights
        return CulturalInsightResponse(
            title: "Cultural Business Insight",
            category: "Social Customs & Relationship Building",
            nameCard: getLocalizedNameCard(concept: "culture", destination: destination),
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
                
                // Parse the nameCard if it contains both app and local language
                let nameCardString = parsed.nameCard ?? extractNameCard(from: parsed.title, destination: destination)
                let lines = nameCardString.components(separatedBy: "\n")
                let nameCardApp = lines.count >= 2 ? lines[0] : nameCardString
                let nameCardLocal = lines.count >= 2 ? lines[1] : nil
                
                let card = CulturalCard(
                    title: parsed.title,
                    category: category,
                    nameCardApp: nameCardApp,
                    nameCardLocal: nameCardLocal,
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
    private func extractContentFromJSONString(_ jsonString: String, destination: String) -> CulturalInsightResponse {
        print("🔧 [AICardGenerator] Extracting content manually from JSON string...")
        
        // Extract title
        let title = extractValue(from: jsonString, key: "title") ?? "Cultural Business Insight"
        
        // Extract category
        let category = extractValue(from: jsonString, key: "category") ?? "Social Customs & Relationship Building"
        
        // Extract name card
        let nameCard = extractValue(from: jsonString, key: "nameCard") ?? getLocalizedNameCard(concept: "culture", destination: destination)
        
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
    
    private func extractNameCard(from title: String, destination: String = "Unknown") -> String {
        // Extract key word or name from title for name card
        let lowercaseTitle = title.lowercased()
        
        // Check for person-related contexts that might warrant full names
        if lowercaseTitle.contains("ceo") || lowercaseTitle.contains("executive") || lowercaseTitle.contains("manager") {
            switch destination.lowercased() {
            case "japan":
                return "Tanaka Hiroshi\n田中宏"
            case "germany":
                return "Hans Müller\nハンス・ミュラー"
            case "china":
                return "Wang Li Ming\n王立明"
            case "korea":
                return "Kim Min Jun\n김민준"
            default:
                return "Executive Name"
            }
        } else if lowercaseTitle.contains("host") || lowercaseTitle.contains("hostess") {
            switch destination.lowercased() {
            case "japan":
                return "Yamamoto Kenji\n山本健二"
            case "germany":
                return "Maria Weber\nマリア・ウェーバー"
            case "china":
                return "Chen Mei Li\n陈美丽"
            case "korea":
                return "Lee Sung Ho\n이성호"
            default:
                return "Host Name"
            }
        } else if lowercaseTitle.contains("colleague") || lowercaseTitle.contains("coworker") {
            switch destination.lowercased() {
            case "japan":
                return "Sato Yuki\n佐藤由紀"
            case "germany":
                return "Anna Schmidt\nアンナ・シュミット"
            case "china":
                return "Liu Wei\n刘伟"
            case "korea":
                return "Park Ji Hye\n박지혜"
            default:
                return "Colleague Name"
            }
        }
        // Concept-based name cards (now localized)
        else if lowercaseTitle.contains("greeting") || lowercaseTitle.contains("hello") {
            return getLocalizedNameCard(concept: "greeting", destination: destination)
        } else if lowercaseTitle.contains("meeting") || lowercaseTitle.contains("business") {
            return getLocalizedNameCard(concept: "protocol", destination: destination)
        } else if lowercaseTitle.contains("dining") || lowercaseTitle.contains("food") {
            return getLocalizedNameCard(concept: "dining", destination: destination)
        } else if lowercaseTitle.contains("time") || lowercaseTitle.contains("punctuality") {
            return getLocalizedNameCard(concept: "time", destination: destination)
        } else if lowercaseTitle.contains("hierarchy") || lowercaseTitle.contains("respect") {
            return getLocalizedNameCard(concept: "respect", destination: destination)
        } else if lowercaseTitle.contains("gift") {
            return getLocalizedNameCard(concept: "gift", destination: destination)
        } else if lowercaseTitle.contains("communication") || lowercaseTitle.contains("speak") {
            return getLocalizedNameCard(concept: "communication", destination: destination)
        } else {
            // Extract first meaningful word from title and check if it's a place name
            let words = title.components(separatedBy: " ")
            let firstWord = words.first { !["the", "a", "an", "of", "in", "for", "with", "and"].contains($0.lowercased()) }
            
            // Check if it's a place name that should be localized
            if let word = firstWord {
                return getLocalizedPlaceName(place: word, destination: destination) ?? 
                       getLocalizedNameCard(concept: word, destination: destination)
            }
            
            return getLocalizedNameCard(concept: "culture", destination: destination)
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
        let nameCardString = getLocalizedNameCard(concept: "culture", destination: destination)
        let lines = nameCardString.components(separatedBy: "\n")
        let nameCardApp = lines.count >= 2 ? lines[0] : nameCardString
        let nameCardLocal = lines.count >= 2 ? lines[1] : nil
        
        let card = CulturalCard(
            title: "Cultural Insight",
            category: .socialCustoms,
            nameCardApp: nameCardApp,
            nameCardLocal: nameCardLocal,
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
                "nameCard": "\(getLocalizedNameCard(concept: "respect", destination: destination))",
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
                "nameCard": "\(getLocalizedNameCard(concept: "directness", destination: destination))",
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
            "nameCard": "\(getLocalizedNameCard(concept: "protocol", destination: destination))",
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
            "nameCard": "\(getLocalizedNameCard(concept: "dining", destination: destination))",
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
                nameCard = "Tanaka Hiroshi\n田中宏"
            case "germany":
                nameCard = "Hans Müller\nハンス・ミュラー"
            case "china":
                nameCard = "Wang Li Ming\n王立明"
            case "korea":
                nameCard = "Kim Min Jun\n김민준"
            default:
                nameCard = "Executive Name"
            }
        } else if lowercaseQuery.contains("colleague") || lowercaseQuery.contains("coworker") {
            switch destination.lowercased() {
            case "japan":
                nameCard = "Sato Yuki\n佐藤由紀"
            case "germany":
                nameCard = "Anna Schmidt\nアンナ・シュミット"
            case "china":
                nameCard = "Liu Wei\n刘伟"
            case "korea":
                nameCard = "Park Ji Hye\n박지혜"
            default:
                nameCard = "Colleague Name"
            }
        } else {
            // Use localized concept name for "Culture"
            nameCard = getLocalizedNameCard(concept: "culture", destination: destination)
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

// MARK: - Local Language Mapping
extension AICardGenerator {
    private func getLocalizedNameCard(concept: String, destination: String) -> String {
        let lowercaseDestination = destination.lowercased()
        let lowercaseConcept = concept.lowercased()
        
        switch lowercaseDestination {
        case "japan":
            return getJapaneseNameCard(for: lowercaseConcept)
        case "germany":
            return getGermanNameCard(for: lowercaseConcept)
        case "china":
            return getChineseNameCard(for: lowercaseConcept)
        case "korea":
            return getKoreanNameCard(for: lowercaseConcept)
        default:
            return concept // Fallback to English
        }
    }
    
    private func getJapaneseNameCard(for concept: String) -> String {
        switch concept {
        case "respect":
            return "Respect\n尊敬" // Sonkei - Respect
        case "directness":
            return "Directness\n直接性" // Chokusetu-sei - Directness
        case "protocol":
            return "Protocol\n礼儀" // Reigi - Protocol/Etiquette
        case "dining":
            return "Dining\n食事" // Shokuji - Dining
        case "culture":
            return "Culture\n文化" // Bunka - Culture
        case "hierarchy":
            return "Hierarchy\n階層" // Kaisō - Hierarchy
        case "communication":
            return "Communication\nコミュニケーション" // Komyunikēshon - Communication
        case "time":
            return "Time\n時間" // Jikan - Time
        case "gift":
            return "Gift\n贈り物" // Okurimono - Gift
        case "greeting":
            return "Greeting\n挨拶" // Aisatsu - Greeting
        case "business":
            return "Business\nビジネス" // Bijinesu - Business
        case "meeting":
            return "Meeting\n会議" // Kaigi - Meeting
        case "founder":
            return "Founder\n創設者" // Sōsetsushya - Founder
        case "pioneer":
            return "Pioneer\n先駆者" // Senkusha - Pioneer
        case "automotive":
            return "Automotive\n自動車" // Jidōsha - Automotive
        case "visionary":
            return "Visionary\n先見の明" // Senken no mei - Visionary
        case "innovator":
            return "Innovator\n革新者" // Kakushinsya - Innovator
        case "leader":
            return "Leader\nリーダー" // Rīdā - Leader
        case "strategic":
            return "Strategic\n戦略的" // Senryaku-teki - Strategic
        case "collaborative":
            return "Collaborative\n協力的" // Kyōryoku-teki - Collaborative
        default:
            return concept
        }
    }
    
    private func getGermanNameCard(for concept: String) -> String {
        switch concept {
        case "respect":
            return "Respect\nRespekt"
        case "directness":
            return "Directness\nDirektheit"
        case "protocol":
            return "Protocol\nProtokoll"
        case "dining":
            return "Dining\nSpeisen"
        case "culture":
            return "Culture\nKultur"
        case "hierarchy":
            return "Hierarchy\nHierarchie"
        case "communication":
            return "Communication\nKommunikation"
        case "time":
            return "Time\nZeit"
        case "gift":
            return "Gift\nGeschenk"
        case "greeting":
            return "Greeting\nBegrüßung"
        case "business":
            return "Business\nGeschäft"
        case "meeting":
            return "Meeting\nBesprechung"
        default:
            return concept
        }
    }
    
    private func getChineseNameCard(for concept: String) -> String {
        switch concept {
        case "respect":
            return "Respect\n尊重" // Zūnzhòng - Respect
        case "directness":
            return "Directness\n直接" // Zhíjiē - Directness
        case "protocol":
            return "Protocol\n礼仪" // Lǐyí - Protocol/Etiquette
        case "dining":
            return "Dining\n用餐" // Yòngcān - Dining
        case "culture":
            return "Culture\n文化" // Wénhuà - Culture
        case "hierarchy":
            return "Hierarchy\n等级" // Děngjí - Hierarchy
        case "communication":
            return "Communication\n沟通" // Gōutōng - Communication
        case "time":
            return "Time\n时间" // Shíjiān - Time
        case "gift":
            return "Gift\n礼物" // Lǐwù - Gift
        case "greeting":
            return "Greeting\n问候" // Wènhòu - Greeting
        case "business":
            return "Business\n商务" // Shāngwù - Business
        case "meeting":
            return "Meeting\n会议" // Huìyì - Meeting
        default:
            return concept
        }
    }
    
    private func getKoreanNameCard(for concept: String) -> String {
        switch concept {
        case "respect":
            return "Respect\n존경" // Jongyeong - Respect
        case "directness":
            return "Directness\n직접성" // Jikjeopseong - Directness
        case "protocol":
            return "Protocol\n예의" // Ye-ui - Protocol/Etiquette
        case "dining":
            return "Dining\n식사" // Siksa - Dining
        case "culture":
            return "Culture\n문화" // Munhwa - Culture
        case "hierarchy":
            return "Hierarchy\n계층" // Gyecheung - Hierarchy
        case "communication":
            return "Communication\n의사소통" // Uisasotong - Communication
        case "time":
            return "Time\n시간" // Sigan - Time
        case "gift":
            return "Gift\n선물" // Seonmul - Gift
        case "greeting":
            return "Greeting\n인사" // Insa - Greeting
        case "business":
            return "Business\n비즈니스" // Bijeuneseu - Business
        case "meeting":
            return "Meeting\n회의" // Hoe-ui - Meeting
        default:
            return concept
        }
    }
    
    private func getLocalizedPlaceName(place: String, destination: String) -> String? {
        let lowercasePlace = place.lowercased()
        let lowercaseDestination = destination.lowercased()
        
        switch lowercaseDestination {
        case "japan":
            return getJapanesePlaceName(for: lowercasePlace)
        case "germany":
            return getGermanPlaceName(for: lowercasePlace)
        case "china":
            return getChinesePlaceName(for: lowercasePlace)
        case "korea":
            return getKoreanPlaceName(for: lowercasePlace)
        default:
            return nil
        }
    }
    
    private func getJapanesePlaceName(for place: String) -> String? {
        switch place {
        case "tokyo":
            return "Tokyo\n東京"
        case "osaka":
            return "Osaka\n大阪"
        case "kyoto":
            return "Kyoto\n京都"
        case "yokohama":
            return "Yokohama\n横浜"
        case "kobe":
            return "Kobe\n神戸"
        case "nagoya":
            return "Nagoya\n名古屋"
        case "sapporo":
            return "Sapporo\n札幌"
        case "fukuoka":
            return "Fukuoka\n福岡"
        case "sendai":
            return "Sendai\n仙台"
        case "hiroshima":
            return "Hiroshima\n広島"
        default:
            return nil
        }
    }
    
    private func getGermanPlaceName(for place: String) -> String? {
        switch place {
        case "berlin":
            return "Berlin\nBerlin"
        case "munich", "münchen":
            return "München\nMunich"
        case "hamburg":
            return "Hamburg\nHamburg"
        case "cologne", "köln":
            return "Köln\nCologne"
        case "frankfurt":
            return "Frankfurt\nFrankfurt"
        case "stuttgart":
            return "Stuttgart\nStuttgart"
        case "düsseldorf":
            return "Düsseldorf\nDüsseldorf"
        case "dortmund":
            return "Dortmund\nDortmund"
        case "essen":
            return "Essen\nEssen"
        case "dresden":
            return "Dresden\nDresden"
        default:
            return nil
        }
    }
    
    private func getChinesePlaceName(for place: String) -> String? {
        switch place {
        case "beijing":
            return "Beijing\n北京"
        case "shanghai":
            return "Shanghai\n上海"
        case "guangzhou":
            return "Guangzhou\n广州"
        case "shenzhen":
            return "Shenzhen\n深圳"
        case "chengdu":
            return "Chengdu\n成都"
        case "hangzhou":
            return "Hangzhou\n杭州"
        case "wuhan":
            return "Wuhan\n武汉"
        case "xi'an", "xian":
            return "Xi'an\n西安"
        case "nanjing":
            return "Nanjing\n南京"
        case "tianjin":
            return "Tianjin\n天津"
        default:
            return nil
        }
    }
    
    private func getKoreanPlaceName(for place: String) -> String? {
        switch place {
        case "seoul":
            return "Seoul\n서울"
        case "busan":
            return "Busan\n부산"
        case "incheon":
            return "Incheon\n인천"
        case "daegu":
            return "Daegu\n대구"
        case "daejeon":
            return "Daejeon\n대전"
        case "gwangju":
            return "Gwangju\n광주"
        case "suwon":
            return "Suwon\n수원"
        case "ulsan":
            return "Ulsan\n울산"
        case "changwon":
            return "Changwon\n창원"
        case "goyang":
            return "Goyang\n고양"
        default:
            return nil
        }
    }
} 