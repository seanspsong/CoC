# Cup of Culture (CoC) 🌍

An iOS application designed to help international travelers quickly learn destination cultures through an intuitive, card-based interface.

## Features ✨

### 🎨 **Modern Purple Design Theme**
- Beautiful purple color scheme (#8A2BE2) throughout the app
- Professional card-based UI with sophisticated shadows and animations
- Responsive design optimized for all iOS devices

### 🌍 **Cultural Knowledge System**
- **Destination Cards**: Elegant card views showcasing countries with flags and cultural information
- **Cultural Cards**: Six distinct categories of cultural knowledge:
  - 🤝 Business Etiquette
  - 🎭 Social Customs  
  - 🍽️ Dining Culture
  - 💬 Communication
  - 🎁 Gift Giving
  - ⚡ Quick Facts

### 🎯 **Intuitive Navigation**
- Full-screen destination overview with responsive grid layout
- Floating action buttons (+ for adding content, ⚙️ for settings)
- Smooth navigation between destinations and cultural details
- One-tap access to cultural cards with detailed information

### 📱 **Sample Content**
- Pre-loaded with comprehensive cultural data for Japan and Germany
- Real-world cultural insights and practical business tips
- Expandable content system for adding more destinations

## Technical Specifications 🛠️

- **Platform**: iOS 17.0+
- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Language**: Swift 5
- **Design Pattern**: Card-based UI with floating elements
- **Color Theme**: Purple (#8A2BE2) with modern gradients and shadows

## Project Structure 📁

```
CoC/
├── CoCApp.swift           # App entry point
├── ContentView.swift      # Main UI implementation
├── Models.swift          # Data models (Destination, CulturalCard)
├── Assets.xcassets/      # App icons and assets
├── VibeLog.md           # Development documentation
└── README.md            # This file
```

## Installation & Setup 🚀

1. **Clone the repository:**
   ```bash
   git clone https://github.com/seanspsong/CoC.git
   cd CoC
   ```

2. **Open in Xcode:**
   ```bash
   open CoC.xcodeproj
   ```

3. **Build and Run:**
   - Select your target device (iPhone/iPad simulator or physical device)
   - Press `Cmd + R` to build and run
   - App will automatically load with sample cultural data

## Usage Guide 👆

### Main Interface
- **Browse Destinations**: Scroll through the card-based destination overview
- **Tap Destinations**: Tap any destination card to view cultural details
- **Add Content**: Use the purple + button to add new destinations or cultural cards
- **Settings**: Access app preferences via the ⚙️ settings button

### Cultural Learning
- Each destination contains multiple cultural cards
- Cards are organized by category with visual icons
- Tap any cultural card to expand and read detailed information
- Navigate back using the purple "Back" button

## Color Theme 🎨

The app uses a consistent purple color theme (#8A2BE2) across all interactive elements:
- Action buttons and CTAs
- Card accents and highlights  
- Navigation elements
- Icon backgrounds and borders

## Future Enhancements 🚀

- [ ] Add more destination countries
- [ ] Implement user-generated content
- [ ] Cultural quiz functionality
- [ ] Offline content synchronization
- [ ] Multi-language support
- [ ] Business networking features

## Contributing 🤝

This project follows standard iOS development practices. To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact 📧

**Sean Song** - Project Developer
- GitHub: [@seanspsong](https://github.com/seanspsong)
- Repository: [CoC](https://github.com/seanspsong/CoC)

---

Made with 💜 for cultural learning and global business success.

# Cup of Culture - AI-Powered Cultural Cards

## 🎯 Project Overview
Cup of Culture is an iOS app that helps international travelers learn destination cultures through AI-generated cultural insight cards. The app uses iOS 26's on-device Foundation model to create personalized cultural knowledge based on voice queries.

## ✨ Core Features

### 🤖 AI-Powered Card Generation
- **On-Device LLM**: Uses iOS 26 Foundation model for privacy-first AI generation
- **Voice-to-Card**: Speak your cultural questions, get instant insights
- **Context-Aware**: Generates content specific to destination and business context
- **Offline Capable**: All AI processing happens on-device

### 🎙️ Voice Interaction Flow
1. **Card Creation**: User taps + button to start new cultural card
2. **Empty Card State**: Shows placeholder card with microphone button
3. **Voice Recording**: User taps mic, speaks their cultural question
4. **Speech-to-Text**: Transcribes voice using iOS Speech framework
5. **AI Generation**: On-device LLM generates cultural insight
6. **Card Population**: Displays generated content with beautiful animations

## 🏗️ System Architecture

### AI Generation Pipeline
```
Voice Input → Speech Recognition → Text Processing → LLM Prompt → Generated Content → Card Display
```

### Core Components
- **VoiceRecordingView**: Handles microphone input and speech recognition
- **AICardGenerator**: Manages LLM prompts and content generation
- **EmptyCardState**: Shows recording interface before content generation
- **GeneratedCardView**: Displays AI-created cultural insights

## 🎨 User Experience Design

### Card Generation Flow
1. **Trigger**: User taps floating + button in cultural cards view
2. **Empty State**: Presents empty card with:
   - Destination context (e.g., "Cultural Insight for Japan")
   - Large microphone button with pulse animation
   - Instruction text: "Tap to ask about Japanese culture"
3. **Recording State**: 
   - Microphone turns red with recording animation
   - Waveform visualization shows audio levels
   - "Listening..." text with stop button
4. **Processing State**:
   - "Generating your cultural insight..." with loading animation
   - AI thinking indicator
5. **Generated State**:
   - Smooth transition to populated card
   - Content appears with fade-in animation
   - Save/regenerate buttons

### Voice Interface
- **Visual Feedback**: Animated waveforms during recording
- **Audio Cues**: System sounds for start/stop recording
- **Error Handling**: Clear messages for recording/generation failures
- **Accessibility**: VoiceOver support for all states

## 📝 Prompts

This section documents the simplified AI prompts used in the Cup of Culture system for generating cultural insights.

### 🤖 System Instructions (LanguageModelSession)

The following simplified instructions are set when initializing the `LanguageModelSession`:

```
You are a cultural expert helping people understand local customs and practices. Provide helpful cultural insights that are accurate and respectful.
```

### 🎯 Structured Response Schema

The AI uses guided generation with a **3-section cultural card structure**:

```swift
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
```

### 💬 User Prompt Template

For each voice query, the system constructs a simplified prompt using this template:

```
Destination: [DESTINATION_NAME]
User Question: "[TRANSCRIBED_VOICE_INPUT]"

Please provide a cultural insight about [DESTINATION_NAME] that addresses the user's question. Structure your response with:
1. A name card: use a full person name (given name + family name) if about specific people/roles, otherwise use one concept word
2. Four key knowledge points starting with relevant emojis
3. Comprehensive cultural insights paragraph
```

**Example Prompt:**
```
Destination: Japan
User Question: "How should I greet people in business meetings?"

Please provide a cultural insight about Japan that addresses the user's question. Structure your response with:
1. A name card: use a full person name (given name + family name) if about specific people/roles, otherwise use one concept word
2. Four key knowledge points starting with relevant emojis
3. Comprehensive cultural insights paragraph
```

### 🎭 Mock Response Templates (Development Fallbacks)

For development and testing, the system includes contextual mock responses:

#### Greeting Response Template
```json
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
    "culturalInsights": "In Japanese business culture, the bow (ojigi) is the traditional greeting that shows respect and hierarchy awareness. The depth and duration of your bow should reflect the status of the person you're greeting - deeper bows for senior executives, lighter bows for peers. However, many Japanese businesspeople now expect handshakes when meeting international colleagues, creating a hybrid approach that honors both traditions."
}
```

#### Meeting Response Template
```json
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
    "culturalInsights": "Business meetings in [DESTINATION] follow specific cultural protocols that demonstrate respect and professionalism. Understanding hierarchy, timing, and communication styles is crucial for successful interactions. Preparation and attention to cultural nuances can make the difference between building strong business relationships and missing opportunities."
}
```

#### Dining Response Template
```json
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
    "culturalInsights": "Business dining in [DESTINATION] is an important relationship-building activity with specific etiquette rules. Understanding proper table manners, gift-giving customs, and conversation topics can strengthen business partnerships. The way you handle dining situations often reflects your respect for local culture and attention to detail."
}
```

#### General Response Template
```json
{
    "title": "Cultural Business Insight",
    "category": "Social Customs & Relationship Building",
    "nameCard": "Culture",
    "keyKnowledge": [
        "📚 Research local customs before important interactions",
        "❤️ Show genuine interest in cultural traditions",
        "🚫 Avoid assumptions based on stereotypes",
        "👀 Pay attention to subtle social cues and non-verbal communication"
    ],
    "culturalInsights": "Understanding cultural nuances in [DESTINATION] requires attention to both explicit customs and subtle social cues. Business relationships are built on mutual respect and cultural awareness. Taking time to learn and demonstrate appreciation for local customs shows professionalism and can lead to stronger, more successful business partnerships."
}
```

#### Executive Meeting Response Template (with Person Name)
```json
{
    "title": "Meeting with Senior Executive",
    "category": "Business Etiquette & Meeting Protocols",
    "nameCard": "Tanaka Hiroshi",
    "keyKnowledge": [
        "🎩 Address executives using full title and surname initially",
        "📋 Prepare detailed agenda and supporting materials in advance",
        "⏳ Wait for senior person to initiate business discussion",
        "📝 Follow up meetings with formal written summary"
    ],
    "culturalInsights": "When meeting with senior executives in Japan, the cultural emphasis on hierarchy and respect becomes paramount. Executive meetings follow strict protocols that demonstrate your understanding of Japanese business culture and your respect for organizational structure."
}
```

### 🏷️ Cultural Categories

The system maps responses to these predefined cultural categories:

- **Business Etiquette & Meeting Protocols** → `.businessEtiquette`
- **Social Customs & Relationship Building** → `.socialCustoms`
- **Communication Styles & Non-verbal Cues** → `.communication`
- **Gift Giving & Entertainment** → `.giftGiving`
- **Dining Etiquette & Food Culture** → `.diningCulture`
- **Time Management & Scheduling** → `.timeManagement`
- **Hierarchy & Decision Making** → `.hierarchy`
- **Greeting Customs & Personal Space** → `.greetingCustoms`

### 🧪 Prompt Testing Strategy

#### Context Detection
The system analyzes user queries to select appropriate response templates:
- **Greeting queries**: Contains "greet", "hello" → Greeting Response
- **Meeting queries**: Contains "meeting", "business" → Meeting Response  
- **Dining queries**: Contains "food", "eat", "dining" → Dining Response
- **General queries**: All other inputs → General Response

#### Quality Assurance
- **Cultural Accuracy**: Responses are reviewed for cultural sensitivity
- **Practical Focus**: Provides helpful, actionable advice for users
- **Respectful Tone**: Avoids stereotypes and maintains respectful language
- **Structured Format**: Consistent JSON schema for reliable parsing

### 📋 Example Usage

**Voice Input**: "How should I greet people in business meetings in Japan?"

**System Processing**: 
1. Speech-to-text converts voice to: `"How should I greet people in business meetings in Japan?"`
2. Simplified template constructs prompt with destination context
3. LanguageModelSession generates structured response using cultural expertise
4. Response is converted to CulturalCard with proper categorization

**Generated Card**:
- **Title**: "Business Greeting Etiquette" 
- **Category**: Greeting Customs & Personal Space
- **Name Card**: "Respect" (displayed in large, bold font)
- **Key Knowledge**: 4 emoji-prefixed bullet points about greeting protocols  
- **Cultural Insights**: Comprehensive explanation of Japanese greeting traditions

## 🔧 Technical Implementation

### iOS 26 Foundation Model Integration
```swift
import FoundationModels

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

class AICardGenerator {
    private let languageSession: LanguageModelSession
    
    init() {
        let instructions = """
        You are a cultural expert helping people understand local customs and practices. Provide helpful cultural insights that are accurate and respectful.
        """
        
        languageSession = LanguageModelSession(instructions: instructions)
    }
    
    func generateCulturalCard(
        destination: String,
        userQuery: String
    ) async throws -> CulturalCard {
        let prompt = buildPrompt(destination: destination, query: userQuery)
        
        // Use guided generation with structured response
        let response = try await languageSession.respond(
            to: prompt,
            generating: CulturalInsightResponse.self
        )
        
        return convertToCulturalCard(response: response.content, destination: destination)
    }
}
```

### Speech Recognition
```swift
import Speech

class VoiceRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    
    func startRecording() async throws {
        // Request permissions and start speech recognition
    }
}
```

### Data Models
```swift
struct CulturalCard {
    let id: UUID
    let title: String
    let category: CulturalCategory
    let insight: String
    let practicalTips: [String]
    let destination: String
    let isAIGenerated: Bool
    let createdAt: Date
}

enum CulturalCategory: String, CaseIterable {
    case businessEtiquette = "Business Etiquette & Meeting Protocols"
    case socialCustoms = "Social Customs & Relationship Building"
    case communication = "Communication Styles & Non-verbal Cues"
    // ... other categories
}
```

## 🎭 Animation & Visual Design

### Recording Interface
- **Microphone Button**: Large, prominent button with purple theme
- **Recording Animation**: Pulsing red circle with expanding rings
- **Waveform Visualization**: Real-time audio levels with smooth bars
- **State Transitions**: Smooth morphing between recording states

### Content Generation
- **Loading States**: Elegant spinner with "AI thinking" messaging  
- **Content Reveal**: Fade-in animation for generated text
- **Card Transformation**: Smooth transition from empty to populated state

### Error Handling
- **Permission Denied**: Clear explanation with settings redirect
- **Network Issues**: Graceful offline messaging (shouldn't occur with on-device model)
- **Generation Failures**: Retry options with helpful error messages

## 🔒 Privacy & Security

### On-Device Processing
- **No Network Calls**: All AI processing happens locally on device
- **Voice Data**: Audio is processed locally and not stored
- **Content Privacy**: Generated insights remain on user's device
- **Permission Management**: Proper microphone access handling

### Data Storage
- **Local Core Data**: Cards stored locally with sync options
- **User Control**: Easy deletion and regeneration of AI content
- **Export Options**: Share generated insights while maintaining privacy

## 🚀 Development Phases

### Phase 1: Core Voice Recording ✅ **[COMPLETED]**
- ✅ Design approved and documented
- ✅ Implement voice recording interface with waveform visualization
- ✅ Add speech-to-text transcription using SFSpeechRecognizer
- ✅ Create empty card state with microphone and animations
- ✅ Full voice-to-card workflow implementation

### Phase 2: AI Integration ✅ **[COMPLETED - FOUNDATION]**
- ✅ Integrate iOS 26 Foundation model (mock implementation ready)
- ✅ Implement sophisticated prompt engineering system
- ✅ Add content generation pipeline with cultural expertise
- ✅ Mock AI responses for testing and development

### Phase 3: Enhanced UX 🎯 **[PLANNED]**
- Polish animations and transitions
- Add regeneration and editing features
- Implement accessibility improvements

### Phase 4: Advanced Features 🚀 **[FUTURE]**
- Context-aware prompting based on user history
- Batch generation for common scenarios
- Export and sharing functionality

## 🧪 Testing Strategy

### AI Quality Assurance
- **Prompt Testing**: Validate responses across cultural contexts
- **Content Review**: Ensure respectful, accurate cultural insights
- **Edge Cases**: Handle unusual or inappropriate voice inputs

### User Experience Testing
- **Voice Recognition**: Test across accents and languages
- **Error Scenarios**: Microphone permissions, processing failures
- **Performance**: Ensure smooth on-device generation

## 📊 Success Metrics

### User Engagement
- **Card Generation Rate**: How often users create AI cards vs manual
- **Voice Usage**: Percentage of cards created via voice vs text
- **Content Quality**: User ratings of AI-generated insights

### Technical Performance
- **Generation Speed**: Time from voice input to displayed card
- **Recognition Accuracy**: Speech-to-text quality metrics
- **Battery Impact**: Monitor on-device LLM power consumption

---

## 💡 Future Enhancements

- **Multi-language Support**: Generate cards in user's preferred language
- **Conversation Mode**: Follow-up questions for deeper cultural insights
- **Visual Enrichment**: AI-generated illustrations for cultural concepts
- **Smart Suggestions**: Proactive cultural tips based on calendar/location

This design leverages iOS 26's cutting-edge on-device AI capabilities while maintaining user privacy and delivering a magical, voice-first cultural learning experience.
