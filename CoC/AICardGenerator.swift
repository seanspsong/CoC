//
//  AICardGenerator.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import Foundation
import Combine
import UIKit

// MARK: - GPT-5 Responses API Integration
struct GPT5Request: Codable {
    let model: String
    let input: String
    let reasoning: ReasoningConfig?
    let text: TextConfig?
    
    struct ReasoningConfig: Codable {
        let effort: String // "minimal", "low", "medium", "high"
    }
    
    struct TextConfig: Codable {
        let verbosity: String // "low", "medium", "high"
    }
}
    


struct GPT5Response: Codable {
    let id: String?
    let object: String?
    let createdAt: Int?
    let model: String?
    let output: [OutputItem]?
    let outputText: String?
    
    enum CodingKeys: String, CodingKey {
        case id, object, model, output
        case createdAt = "created_at"
        case outputText = "output_text"
    }
    
    struct OutputItem: Codable {
        let id: String?
        let type: String?
        let status: String?
        let content: [ContentItem]?
        let role: String?
        let text: String?
        
        enum CodingKeys: String, CodingKey {
            case id, type, status, content, role, text
        }
    }
    
    struct ContentItem: Codable {
        let type: String?
        let text: String?
        let annotations: [String]?
        let logprobs: [String]?
    }
    
    // Computed property to get the actual output text
    var text: String {
        // First try the direct output_text field
        if let outputText = outputText {
            return outputText
        }
        
        // Then try to find text in output items
        if let output = output {
            for item in output {
                // Try direct text field
                if let text = item.text {
                    return text
                }
                
                // Try content array
                if let content = item.content {
                    for contentItem in content {
                        if contentItem.type == "output_text", let text = contentItem.text {
                            return text
                        }
                    }
                }
            }
        }
        
        return ""
    }
}

// MARK: - AI Generation Errors
enum AIGenerationError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case emptyResponse
    case httpError(Int)
    case networkError(String)
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "OpenAI API key not configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid GPT-5 API URL"
        case .invalidResponse:
            return "Invalid response from GPT-5 API"
        case .emptyResponse:
            return "Empty response from GPT-5 API"
        case .httpError(let statusCode):
            return "HTTP Error \(statusCode) from GPT-5 API"
        case .networkError(let message):
            return "Network error: \(message)"
        case .processingFailed:
            return "Failed to process ChatGPT response"
        }
    }
}

// MARK: - AI Response Structure
struct CulturalInsightResponse: Codable {
    let title: String
    let category: String
    let nameCard: String
    let keyKnowledge: [String]
    let culturalInsights: String
}

@MainActor
class AICardGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var generationProgress: String = ""
    @Published var errorMessage: String?
    
    // MARK: - GPT-5 Configuration
    private let gpt5Endpoint = "https://api.openai.com/v1/responses"
    private let model = "gpt-5" // Latest ChatGPT 5 model
    
    private var apiKey: String {
        return UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    init() {
        print("🧠 [AICardGenerator] Initialized with ChatGPT 5 integration")
        print("🔑 [AICardGenerator] API key configured: \(apiKey.isEmpty ? "❌ No" : "✅ Yes")")
    }
    
    // MARK: - Card Generation
    func generateCulturalCard(
        destination: Destination,
        userQuery: String
    ) async throws -> CulturalCard {
        print("🤖 [AICardGenerator] ===== STARTING GPT-5 GENERATION =====")
        print("🎯 [AICardGenerator] Destination: '\(destination.name)' (Country: \(destination.country))")
        print("🎤 [AICardGenerator] Voice Transcript: '\(userQuery)'")
        print("📏 [AICardGenerator] Transcript Length: \(userQuery.count) characters")
        
        isGenerating = true
        generationProgress = "Connecting to ChatGPT..."
        errorMessage = nil
        
        defer {
            isGenerating = false
            generationProgress = ""
            print("🏁 [AICardGenerator] ===== GENERATION PROCESS COMPLETED =====")
        }
        
        do {
            // Build the system prompt with country context
            print("🔨 [AICardGenerator] Building country-specific system prompt...")
            let systemPrompt = buildSystemPrompt(country: destination.country)
            let userPrompt = buildUserPrompt(destination: destination, query: userQuery)
            
            generationProgress = "Generating cultural insight..."
            print("⚡ [AICardGenerator] Sending request to GPT-5 API...")
            
            // Generate content using GPT-5
            let response = try await generateWithGPT5(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )
            
            generationProgress = "Processing response..."
            print("🔍 [AICardGenerator] Converting GPT-5 response to CulturalCard...")
            
            // Convert response to cultural card
            let card = convertToCulturalCard(
                response: response,
                destination: destination,
                question: userQuery
            )
            
            generationProgress = "Complete!"
            print("✅ [AICardGenerator] Cultural card generated successfully with GPT-5!")
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
    
    // MARK: - System Prompt Building
    private func buildSystemPrompt(country: String) -> String {
        return """
        You are a cultural intelligence expert specializing in \(country)'s business and social customs. Your role is to provide accurate, nuanced cultural insights that help international business professionals navigate \(country)'s cultural landscape successfully.

        COUNTRY FOCUS: \(country)
        - Provide insights specifically relevant to \(country)'s cultural context
        - Include country-specific examples, practices, and social norms
        - Consider \(country)'s unique business culture, hierarchy, and communication styles
        - Reference \(country)'s historical and cultural background when relevant

        RESPONSE FORMAT: Respond with a JSON object like this:
        {
            "title": "Cultural insight title",
            "category": "Business Etiquette",
            "nameCard": "Respect\\n尊敬",
            "keyKnowledge": ["🔸 Point 1", "🔸 Point 2", "🔸 Point 3", "🔸 Point 4"],
            "culturalInsights": "Detailed explanation"
        }

        CULTURAL ACCURACY: 
        - Provide authentic, researched information about \(country)
        - Avoid stereotypes or generalizations
        - Include practical business applications
        - Explain the cultural reasoning behind practices
        - Use appropriate local language translations when applicable
        """
    }
    
    // MARK: - User Prompt Building
    private func buildUserPrompt(destination: Destination, query: String) -> String {
        return """
        Country: \(destination.country)
        User Question: "\(query)"
        
        Please provide a cultural insight about \(destination.country) that directly addresses the user's question. Focus on practical business applications and cultural understanding specific to \(destination.country).
        """
    }
    
    // MARK: - GPT-5 Responses API Integration
    private func generateWithGPT5(
        systemPrompt: String,
        userPrompt: String
    ) async throws -> CulturalInsightResponse {
        print("🧠 [AICardGenerator] Calling GPT-5 Responses API...")
        
        guard !apiKey.isEmpty else {
            print("❌ [AICardGenerator] OpenAI API key not configured")
            throw AIGenerationError.apiKeyNotConfigured
        }
        
        // Combine system and user prompts
        let combinedPrompt = """
        \(systemPrompt)
        
        \(userPrompt)
        """
        
        let request = GPT5Request(
            model: model,
            input: combinedPrompt,
            reasoning: GPT5Request.ReasoningConfig(effort: "medium"),
            text: GPT5Request.TextConfig(verbosity: "medium")
        )
        
        // Send request
        guard let url = URL(string: gpt5Endpoint) else {
            throw AIGenerationError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
            
            print("📤 [AICardGenerator] Sending request to GPT-5 Responses API...")
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIGenerationError.invalidResponse
            }
            
            print("📥 [AICardGenerator] Received GPT-5 response: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [AICardGenerator] HTTP Error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("❌ [AICardGenerator] Error details: \(errorData)")
                }
                throw AIGenerationError.httpError(httpResponse.statusCode)
            }
            
            // Debug: Print raw response data
            print("🔍 [AICardGenerator] Raw API response data length: \(data.count)")
            if let rawResponseString = String(data: data, encoding: .utf8) {
                print("🔍 [AICardGenerator] Raw API response: \(rawResponseString)")
            }
            
            // Parse response
            let gpt5Response = try JSONDecoder().decode(GPT5Response.self, from: data)
            
            print("📤 [AICardGenerator] GPT-5 RESPONSE:")
            print("--- RESPONSE START ---")
            print("Output text length: \(gpt5Response.text.count)")
            print("Output text: '\(gpt5Response.text)'")
            print("--- RESPONSE END ---")
            
            // Parse the JSON content
            let responseData = gpt5Response.text.data(using: .utf8) ?? Data()
            let culturalResponse = try JSONDecoder().decode(CulturalInsightResponse.self, from: responseData)
            
            print("✅ [AICardGenerator] Successfully parsed structured response")
            print("📋 [AICardGenerator] Response details:")
            print("   - Title: '\(culturalResponse.title)'")
            print("   - Category: '\(culturalResponse.category)'")
            print("   - Name Card: '\(culturalResponse.nameCard)'")
            print("   - Key Knowledge: \(culturalResponse.keyKnowledge.count) items")
            print("   - Cultural Insights: \(culturalResponse.culturalInsights.count) characters")
            
            return culturalResponse
            
        } catch {
            print("❌ [AICardGenerator] GPT-5 API error: \(error)")
            throw AIGenerationError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Response Conversion
    private func convertToCulturalCard(
        response: CulturalInsightResponse,
        destination: Destination,
        question: String
    ) -> CulturalCard {
        print("🔄 [AICardGenerator] Converting ChatGPT response to CulturalCard...")
        
        // Map category string to enum
        let category = mapStringToCategory(response.category)
        
        // Parse the nameCard for bilingual display
        var nameCardApp: String? = nil
        var nameCardLocal: String? = nil
        
        let nameCard = response.nameCard
        print("🔍 [AICardGenerator] Raw nameCard from response: '\(nameCard)'")
        
        let lines = nameCard.components(separatedBy: "\n")
        print("🔍 [AICardGenerator] Split into \(lines.count) lines: \(lines)")
        
        if lines.count >= 2 {
            nameCardApp = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
            nameCardLocal = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)
            print("🔍 [AICardGenerator] Set nameCardApp: '\(nameCardApp!)'")
            print("🔍 [AICardGenerator] Set nameCardLocal: '\(nameCardLocal!)'")
        } else {
            nameCardApp = nameCard.trimmingCharacters(in: .whitespacesAndNewlines)
            nameCardLocal = nil
            print("🔍 [AICardGenerator] Single line nameCard: '\(nameCardApp!)'")
        }
        
        let card = CulturalCard(
            title: response.title,
            category: category,
            nameCardApp: nameCardApp,
            nameCardLocal: nameCardLocal,
            keyKnowledge: response.keyKnowledge,
            culturalInsights: response.culturalInsights,
            destination: destination.country, // Use country instead of name
            question: question
        )
        
        print("✅ [AICardGenerator] Successfully converted to CulturalCard")
        print("🔍 [AICardGenerator] Final card details:")
        print("   - Title: '\(card.title)'")
        print("   - Country: '\(card.destination ?? "nil")'")
        print("   - Name Card App: '\(card.nameCardApp ?? "nil")'")
        print("   - Name Card Local: '\(card.nameCardLocal ?? "nil")'")
        print("   - Key Knowledge: \(card.keyKnowledge?.count ?? 0) items")
        print("   - Cultural Insights: \(card.culturalInsights?.count ?? 0) characters")
        
        return card
    }
    
    // MARK: - Helper Functions
    private func mapStringToCategory(_ categoryString: String) -> CulturalCategory {
        switch categoryString {
        case "Business Etiquette":
            return .businessEtiquette
        case "Social Customs":
            return .socialCustoms
        case "Communication Styles":
            return .communication
        case "Gift Giving":
            return .giftGiving
        case "Dining Etiquette":
            return .diningCulture
        case "Time Management":
            return .timeManagement
        case "Hierarchy":
            return .hierarchy
        case "Greeting Customs":
            return .greetingCustoms
        default:
            return .socialCustoms
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
    
    // MARK: - Image-based Card Generation
    func generateCulturalCardFromImage(
        image: UIImage,
        destination: Destination
    ) async throws -> CulturalCard {
        print("📸 [AICardGenerator] ===== STARTING IMAGE-BASED GENERATION =====")
        print("🎯 [AICardGenerator] Destination: '\(destination.name)' (Country: \(destination.country))")
        
        isGenerating = true
        generationProgress = "Analyzing image..."
        errorMessage = nil
        
        defer {
            isGenerating = false
            generationProgress = ""
            print("🏁 [AICardGenerator] ===== IMAGE GENERATION COMPLETED =====")
        }
        
        do {
            // Convert image to base64
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw AIGenerationError.processingFailed
            }
            let base64Image = imageData.base64EncodedString()
            
            generationProgress = "Understanding cultural context..."
            
            // Build prompts for image analysis
            let systemPrompt = buildImageSystemPrompt(country: destination.country)
            let userPrompt = "Analyze this image and provide cultural insights relevant to \(destination.country). What cultural elements, practices, or learning opportunities do you see?"
            
            // Generate content using GPT-5 Vision
            let response = try await generateWithChatGPTVision(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                base64Image: base64Image
            )
            
            generationProgress = "Creating cultural card..."
            
            // Convert response to cultural card
            let card = convertToCulturalCard(
                response: response,
                destination: destination,
                question: "Image analysis: Cultural insights from photo"
            )
            
            print("✅ [AICardGenerator] Image-based cultural card generated successfully!")
            print("📋 [AICardGenerator] Card Title: '\(card.title)'")
            
            return card
            
        } catch {
            let errorMsg = "Failed to generate cultural card from image: \(error.localizedDescription)"
            print("❌ [AICardGenerator] ERROR: \(errorMsg)")
            errorMessage = errorMsg
            throw error
        }
    }
    
    // MARK: - Image System Prompt
    private func buildImageSystemPrompt(country: String) -> String {
        return """
        You are a cultural intelligence expert specializing in \(country)'s culture, traditions, and social customs. You will analyze images and provide educational cultural insights.

        COUNTRY FOCUS: \(country)
        - Analyze visual elements that relate to \(country)'s culture
        - Identify cultural practices, traditions, or social customs visible in the image
        - Provide educational insights about \(country)'s cultural context
        - Explain the significance of what you observe in relation to \(country)'s culture

        IMAGE ANALYSIS GUIDELINES:
        - Look for cultural elements: architecture, clothing, food, activities, social interactions
        - Consider seasonal or regional aspects specific to \(country)
        - Identify business or social customs that might be relevant
        - Note any traditional or modern cultural elements

        RESPONSE FORMAT: Respond with a JSON object like this:
        {
            "title": "Cultural insight from image",
            "category": "Business Etiquette",
            "nameCard": "Respect\\n尊敬",
            "keyKnowledge": ["🔸 Point 1", "🔸 Point 2", "🔸 Point 3", "🔸 Point 4"],
            "culturalInsights": "Detailed explanation"
        }

        ACCURACY: 
        - Only describe what you can clearly observe in the image
        - Relate observations to authentic \(country) cultural practices
        - Provide practical, actionable cultural insights
        - Avoid assumptions not supported by visual evidence
        """
    }
    
    // MARK: - ChatGPT Vision API Integration
    private func generateWithChatGPTVision(
        systemPrompt: String,
        userPrompt: String,
        base64Image: String
    ) async throws -> CulturalInsightResponse {
        print("🧠 [AICardGenerator] Calling GPT-5 Vision API...")
        
        guard !apiKey.isEmpty else {
            print("❌ [AICardGenerator] OpenAI API key not configured")
            throw AIGenerationError.apiKeyNotConfigured
        }
        
        // Combine system and user prompts with image reference
        let combinedPrompt = """
        \(systemPrompt)
        
        \(userPrompt)
        
        [Image data: \(base64Image)]
        """
        
        // Create GPT-5 vision request
        let request = GPT5Request(
            model: "gpt-5", // GPT-5 with vision capabilities
            input: combinedPrompt,
            reasoning: GPT5Request.ReasoningConfig(effort: "medium"),
            text: GPT5Request.TextConfig(verbosity: "medium")
        )
        
        // Send request
        guard let url = URL(string: gpt5Endpoint) else {
            throw AIGenerationError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
            
            print("📤 [AICardGenerator] Sending vision request to GPT-5...")
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIGenerationError.invalidResponse
            }
            
            print("📥 [AICardGenerator] Received GPT-5 vision response: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [AICardGenerator] HTTP Error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("❌ [AICardGenerator] Error details: \(errorData)")
                }
                throw AIGenerationError.httpError(httpResponse.statusCode)
            }
            
            // Parse response
            let gpt5Response = try JSONDecoder().decode(GPT5Response.self, from: data)
            
            print("📤 [AICardGenerator] GPT-5 VISION RESPONSE:")
            print("--- RESPONSE START ---")
            print("Output text length: \(gpt5Response.text.count)")
            print("Output text: '\(gpt5Response.text)'")
            print("--- RESPONSE END ---")
            
            // Parse the JSON content
            let responseData = gpt5Response.text.data(using: .utf8) ?? Data()
            let culturalResponse = try JSONDecoder().decode(CulturalInsightResponse.self, from: responseData)
            
            print("✅ [AICardGenerator] Successfully parsed vision response")
            
            return culturalResponse
            
        } catch {
            print("❌ [AICardGenerator] GPT-5 Vision API error: \(error)")
            throw AIGenerationError.networkError(error.localizedDescription)
        }
    }
}

