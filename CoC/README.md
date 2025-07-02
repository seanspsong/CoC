# Cup of Culture (CoC) 🌍

An iOS application designed to help international business professionals and travelers quickly learn destination cultures through an intuitive, card-based interface.

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
Cup of Culture is an iOS app that helps international business professionals learn destination cultures through AI-generated cultural insight cards. The app uses iOS 26's on-device Foundation model to create personalized cultural knowledge based on voice queries.

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

## 🧠 AI Prompt Engineering

### System Prompt
```
You are a cultural intelligence expert helping international business professionals understand local customs and practices. Your role is to provide practical, actionable cultural insights that help build respectful business relationships.

Context: User is traveling to [DESTINATION] for business purposes.

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

Format your response as:
Title: [Concise topic title]
Category: [One of the categories above]
Insight: [Main cultural insight paragraph]
Practical Tips: [Specific do's and don'ts]
```

### User Prompt Template
```
Destination: [DESTINATION_NAME]
User Question: "[TRANSCRIBED_VOICE_INPUT]"

Please generate a cultural insight card that addresses the user's question in the context of doing business in [DESTINATION_NAME]. Focus on practical advice that will help them navigate this cultural aspect professionally and respectfully.
```

### Example Prompts & Responses

**User Input**: "How should I greet people in business meetings in Japan?"

**Generated Response**:
```
Title: Business Greeting Etiquette
Category: Business Etiquette & Meeting Protocols
Insight: In Japanese business culture, the bow (ojigi) is the traditional greeting that shows respect and hierarchy awareness. The depth and duration of your bow should reflect the status of the person you're greeting - deeper bows for senior executives, lighter bows for peers. However, many Japanese businesspeople now expect handshakes when meeting international colleagues, creating a hybrid approach.
Practical Tips: 
• DO: Offer a slight bow while extending your hand for a handshake
• DO: Wait for the senior person to initiate the greeting
• DON'T: Rush the greeting process - allow time for proper acknowledgment
• DON'T: Use overly firm handshakes; Japanese prefer gentler grips
```

## 🔧 Technical Implementation

### iOS 26 Foundation Model Integration
```swift
import MLGeneration

class AICardGenerator {
    private let model = MLGeneration.shared
    
    func generateCulturalCard(
        destination: String,
        userQuery: String
    ) async throws -> CulturalCard {
        let prompt = buildPrompt(destination: destination, query: userQuery)
        let response = try await model.generateText(prompt: prompt)
        return parseToCulturalCard(response)
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

### Phase 1: Core Voice Recording 🔄 **[IN PROGRESS]**
- ✅ Design approved and documented
- 🔄 Implement voice recording interface
- 🔄 Add speech-to-text transcription
- 🔄 Create empty card state with microphone

### Phase 2: AI Integration 📋 **[NEXT]**
- Integrate iOS 26 Foundation model
- Implement prompt engineering system
- Add content generation pipeline

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
