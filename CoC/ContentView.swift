//
//  ContentView.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import SwiftUI

// MARK: - Color Theme
extension Color {
    static let cocPurple = Color(red: 0x8A/255, green: 0x2B/255, blue: 0xE2/255)
}

struct ContentView: View {
    @State private var showingSettings = false
    @State private var destinations: [Destination] = []
    @State private var selectedDestination: Destination?
    @State private var selectedCard: CulturalCard?
    @State private var showingVoiceRecording = false
    @StateObject private var voiceRecorder = VoiceRecorder()
    @StateObject private var aiGenerator = AICardGenerator()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main Content (Full Screen)
                if let selectedCard = selectedCard, let selectedDestination = selectedDestination {
                    // Cultural Card Detail View
                    CulturalCardDetailView(
                        card: selectedCard,
                        destination: selectedDestination
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            self.selectedCard = nil
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity),
                        removal: .scale(scale: 0.1).combined(with: .opacity)
                    ))
                    .zIndex(2)
                } else if showingVoiceRecording, let selectedDestination = selectedDestination {
                    // Voice Recording Interface
                    VoiceRecordingCardView(
                        destination: selectedDestination,
                        voiceRecorder: voiceRecorder,
                        aiGenerator: aiGenerator
                    ) { generatedCard in
                        // Handle successful card generation
                        addGeneratedCard(generatedCard, to: selectedDestination)
                        showingVoiceRecording = false
                    } onCancel: {
                        // Handle cancellation
                        showingVoiceRecording = false
                    }
                    .zIndex(1)
                } else if let selectedDestination = selectedDestination {
                    // Destination Detail View
                    DestinationDetailView(
                        destination: selectedDestination,
                        onCardTap: { card in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                self.selectedCard = card
                            }
                        },
                        onAddCard: {
                            addNewCard()
                        }
                    ) {
                        self.selectedDestination = nil
                    }
                } else {
                    // Destinations Overview
                    DestinationsOverviewView(destinations: destinations) { destination in
                        selectedDestination = destination
                    }
                }
                
                // Floating Buttons Overlay
                VStack {
                    HStack {
                        // Floating Add Button (Top Left) - Only show in destinations overview
                        if selectedDestination == nil {
                            AddDestinationButton {
                                addNewDestination()
                            }
                            .padding(.leading, 20)
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                        
                        // Floating Settings Button (Top Right)
                        Button(action: {
                            showingSettings.toggle()
                        }) {
                            Text("⚙️")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            loadSampleData()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func handleFloatingActionTap() {
        if selectedDestination != nil {
            // Add new cultural card to current destination
            addNewCard()
        } else {
            // Add new destination to the overview
            addNewDestination()
        }
    }
    
    private func addNewDestination() {
        // TODO: Show destination creation sheet
        print("Adding new destination")
    }
    
    private func addNewCard() {
        // Show voice recording interface for AI card generation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingVoiceRecording = true
        }
    }
    
    private func addGeneratedCard(_ card: CulturalCard, to destination: Destination) {
        // Find the destination index and add the card
        if let index = destinations.firstIndex(where: { $0.id == destination.id }) {
            destinations[index].addCard(card)
        }
    }
    
    private func loadSampleData() {
        // Only load sample data if destinations are empty to avoid duplicates
        if destinations.isEmpty {
            destinations = Destination.sampleData
        }
    }
}

// MARK: - Destinations Overview View
struct DestinationsOverviewView: View {
    let destinations: [Destination]
    let onDestinationTap: (Destination) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 180))
            ], spacing: 20) {
                                        ForEach(Array(destinations.enumerated()), id: \.element.id) { index, destination in
                            DestinationCardView(destination: destination, onTap: {
                                onDestinationTap(destination)
                            })
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                            .animation(.spring(response: 1.2, dampingFraction: 0.9).delay(Double(index) * 0.1), value: destinations.count)
                        }
            }
            .padding(.horizontal, 20)
            .padding(.top, 80) // Top padding to avoid floating buttons
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Destination Detail View
struct DestinationDetailView: View {
    let destination: Destination
    let onCardTap: (CulturalCard) -> Void
    let onAddCard: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGray6).opacity(0.3)
                .ignoresSafeArea()
            
            if destination.culturalCards.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Text(destination.flag)
                        .font(.system(size: 80))
                    
                    Text("No cultural cards yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Tap the + button to add your first cultural knowledge card for \(destination.name)")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 80)
            } else {
                // Cultural Cards List
                ScrollView {
                    // Header Section
                    VStack(spacing: 12) {
                        Text(destination.flag)
                            .font(.system(size: 60))
                        
                        Text("Cultural Cards for \(destination.name)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(destination.culturalCards.count) cultural \(destination.culturalCards.count == 1 ? "card" : "cards")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 100) // Extra top padding for floating buttons
                    .padding(.bottom, 20)
                    
                    // Staggered Cultural Cards Layout (PPnotes style)
                    StaggeredCulturalCardsGrid(cards: destination.culturalCards, onCardTap: onCardTap)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            
            // Floating Back Button (Top Left)
            VStack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Text("←")
                                .font(.title2)
                                .fontWeight(.medium)
                            Text("Back")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.cocPurple)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                Spacer()
            }
            
            // Floating Add Card Button (Bottom Center)
        VStack {
                Spacer()
                HStack {
                    Spacer()
                    AddCulturalCardButton {
                        onAddCard()
                    }
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let isEmpty: Bool
    let isInDestination: Bool
    let action: () -> Void
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    var buttonText: String {
        if isEmpty {
            return "Add Your First Destination"
        } else if isInDestination {
            return "Add Cultural Card"
        } else {
            return "Add Destination"
        }
    }
    
    private var pulseEffect: CGFloat {
        pulseAnimation ? 1.05 : 1.0
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("+")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                if isEmpty {
                    Text(buttonText)
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, isEmpty ? 20 : 16)
            .padding(.vertical, 16)
            .background(Color.cocPurple)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isPressed ? 0.3 : 0.2), radius: isPressed ? 6 : 4, x: 0, y: isPressed ? 3 : 2)
            .scaleEffect(pulseEffect)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            // Press animation feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            action()
        }
        .onAppear {
            // Start pulse animation
            if !isInDestination {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    pulseAnimation = true
                }
            }
        }
    }
}

// MARK: - Add Destination Button
struct AddDestinationButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    private var pulseEffect: CGFloat {
        pulseAnimation ? 1.05 : 1.0
    }
    
    var body: some View {
        Button(action: {
            // Press animation feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            Text("+")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .frame(width: 44, height: 44)
                .background(Color.cocPurple)
                .clipShape(Circle())
                .shadow(color: .black.opacity(isPressed ? 0.3 : 0.2), radius: isPressed ? 6 : 4, x: 0, y: isPressed ? 3 : 2)
                .scaleEffect(pulseEffect)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Start subtle pulse animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Add Cultural Card Button
struct AddCulturalCardButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    private var pulseEffect: CGFloat {
        pulseAnimation ? 1.08 : 1.0
    }
    
    var body: some View {
        Button(action: {
            // Press animation feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            Text("+")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .frame(width: 60, height: 60)
                .background(Color.cocPurple)
                .clipShape(Circle())
                .shadow(color: .black.opacity(isPressed ? 0.4 : 0.25), radius: isPressed ? 8 : 12, x: 0, y: isPressed ? 4 : 6)
                .scaleEffect(pulseEffect)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulseAnimation)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Start subtle pulse animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Voice Recording Card View
struct VoiceRecordingCardView: View {
    let destination: Destination
    @ObservedObject var voiceRecorder: VoiceRecorder
    @ObservedObject var aiGenerator: AICardGenerator
    let onCardGenerated: (CulturalCard) -> Void
    let onCancel: () -> Void
    
    @State private var showingGeneratedCard = false
    @State private var generatedCard: CulturalCard?
    @State private var recordingState: RecordingState = .ready
    @State private var waveformTrigger = false
    
    enum RecordingState {
        case ready
        case recording
        case processing
        case generated
        case error
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    if recordingState == .ready {
                        onCancel()
                    }
                }
            
            // Main Card Content
            VStack(spacing: 0) {
                if showingGeneratedCard, let card = generatedCard {
                    // Show generated card
                    GeneratedCardContentView(card: card, destination: destination)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                } else {
                    // Voice recording interface
                    EmptyCardWithMicrophoneView(
                        destination: destination,
                        voiceRecorder: voiceRecorder,
                        aiGenerator: aiGenerator,
                        recordingState: $recordingState,
                        waveformTrigger: $waveformTrigger
                    )
                }
                
                // Action buttons
                if showingGeneratedCard {
                    HStack(spacing: 20) {
                        Button("Regenerate") {
                            regenerateCard()
                        }
                        .foregroundColor(.cocPurple)
                        
                        Button("Save Card") {
                            if let card = generatedCard {
                                onCardGenerated(card)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.cocPurple)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .scaleEffect(showingGeneratedCard ? 1.0 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingGeneratedCard)
        }
        .onChange(of: recordingState) { oldValue, newValue in
            handleStateChange(from: oldValue, to: newValue)
        }
    }
    
    private func handleStateChange(from oldState: RecordingState, to newState: RecordingState) {
        switch newState {
        case .processing:
            processVoiceInput()
        case .generated:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingGeneratedCard = true
            }
        default:
            break
        }
    }
    
    private func processVoiceInput() {
        guard !voiceRecorder.transcribedText.isEmpty else {
            recordingState = .error
            return
        }
        
        Task {
            do {
                let card = try await aiGenerator.generateCulturalCard(
                    destination: destination.name,
                    userQuery: voiceRecorder.transcribedText
                )
                
                await MainActor.run {
                    generatedCard = card
                    recordingState = .generated
                }
            } catch {
                await MainActor.run {
                    recordingState = .error
                }
            }
        }
    }
    
    private func regenerateCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingGeneratedCard = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            recordingState = .processing
        }
    }
}

// MARK: - Empty Card with Microphone View
struct EmptyCardWithMicrophoneView: View {
    let destination: Destination
    @ObservedObject var voiceRecorder: VoiceRecorder
    @ObservedObject var aiGenerator: AICardGenerator
    @Binding var recordingState: VoiceRecordingCardView.RecordingState
    @Binding var waveformTrigger: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Cultural Insight")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                HStack {
                    HStack(spacing: 8) {
                        Text("Ask about \(destination.name)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(destination.flag)
                            .font(.system(size: 24))
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            Spacer()
            
            // Recording Interface Content
            VStack(spacing: 20) {
                if recordingState == .recording {
                    // Live transcribed text display
                    VStack(spacing: 16) {
                        // Waveform visualization during recording
                        WaveformVisualizationView(
                            audioLevels: voiceRecorder.audioLevels,
                            isAnimating: voiceRecorder.isRecording
                        )
                        .frame(height: 40)
                        .padding(.horizontal, 24)
                        
                        // Live transcribed text
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("What you're saying:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                            .tracking(0.5)
                                        
                                        Spacer()
                                        
                                        // Real-time indicator
                                        if !voiceRecorder.transcribedText.isEmpty {
                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(Color.cocPurple)
                                                    .frame(width: 6, height: 6)
                                                    .opacity(0.6)
                                                    .scaleEffect(1.2)
                                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: voiceRecorder.isRecording)
                                                Text("LIVE")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.cocPurple)
                                            }
                                        }
                                    }
                                    
                                    Text(voiceRecorder.transcribedText.isEmpty ? "Start speaking..." : voiceRecorder.transcribedText)
                                        .font(.body)
                                        .foregroundColor(voiceRecorder.transcribedText.isEmpty ? .secondary : .primary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .animation(.easeInOut(duration: 0.2), value: voiceRecorder.transcribedText)
                                        .id("transcribedText")
                                }
                            }
                            .frame(maxHeight: 120)
                            .padding(.horizontal, 24)
                            .onChange(of: voiceRecorder.transcribedText) { _, _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo("transcribedText", anchor: .bottom)
                                }
                            }
                        }
                        
                        Text("Listening...")
                            .font(.caption)
                            .foregroundColor(.cocPurple)
                            .fontWeight(.medium)
                    }
                } else if recordingState == .processing {
                    // AI generation progress
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text(aiGenerator.generationProgress.isEmpty ? "Processing..." : aiGenerator.generationProgress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if recordingState == .error {
                    // Error state
                    VStack(spacing: 12) {
                        Text("❌")
                            .font(.system(size: 40))
                        
                        Text(voiceRecorder.errorMessage ?? aiGenerator.errorMessage ?? "Something went wrong")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    // Ready state instruction
                    Text(recordingState == .recording ? "Tap mic to stop recording" : "Tap to ask about \(destination.name) culture")
                        .font(.subheadline)
                        .foregroundColor(recordingState == .recording ? .cocPurple : .secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(minHeight: recordingState == .recording ? 180 : 60)
            
            Spacer()
            
            // Bottom Action Button
            VStack(spacing: 16) {
                if recordingState == .ready || recordingState == .recording {
                    // Microphone Button (handles both start and stop)
                    MicrophoneButton(
                        isRecording: voiceRecorder.isRecording,
                        hasPermission: voiceRecorder.hasPermission
                    ) {
                        if voiceRecorder.isRecording {
                            voiceRecorder.stopRecording()
                            recordingState = .processing
                        } else {
                            voiceRecorder.startRecording()
                            recordingState = .recording
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .frame(minHeight: 400)
    }
}

// MARK: - Generated Card Content View
struct GeneratedCardContentView: View {
    let card: CulturalCard
    let destination: Destination
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Content - New 3-Section Structure
                VStack(alignment: .leading, spacing: 24) {
                    // Section 1: Name Card (Big Bold Font)
                    if let nameCard = card.nameCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name Card")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                            
                            Text(nameCard)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Section 2: Key Knowledge (Bullet Points)
                    if let keyKnowledge = card.keyKnowledge, !keyKnowledge.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Knowledge")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.cocPurple)
                            
                            ForEach(keyKnowledge, id: \.self) { knowledge in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(knowledge)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Section 3: Cultural Insights (Text)
                    if let culturalInsights = card.culturalInsights {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cultural Insights")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.cocPurple)
                            
                            Text(culturalInsights)
                                .font(.body)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Legacy fallback: Show old format if new format not available
                    if card.nameCard == nil && card.keyKnowledge == nil && card.culturalInsights == nil {
                        VStack(alignment: .leading, spacing: 16) {
                            if let insight = card.insight {
                                Text(insight)
                                    .font(.body)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            if let tips = card.practicalTips, !tips.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Practical Tips:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.cocPurple)
                                    
                                    ForEach(tips, id: \.self) { tip in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text(tip)
                                                .font(.caption)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40) // Increased bottom padding for better scroll experience
            }
        }
        .scrollIndicators(.hidden) // Hide scroll indicators for cleaner look
    }
}

// MARK: - Microphone Button
struct MicrophoneButton: View {
    let isRecording: Bool
    let hasPermission: Bool
    let action: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.cocPurple)
                    .frame(width: 80, height: 80)
                    .scaleEffect(isRecording ? (pulseAnimation ? 1.1 : 1.0) : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                
                // Recording rings
                if isRecording {
                    Circle()
                        .stroke(Color.cocPurple.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)
                }
                
                // Icon based on recording state
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: isRecording ? 24 : 28, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .disabled(!hasPermission)
        .opacity(hasPermission ? 1.0 : 0.5)
        .onAppear {
            if isRecording {
                pulseAnimation = true
            }
        }
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
        }
    }
}

// MARK: - Waveform Visualization
struct WaveformVisualizationView: View {
    let audioLevels: [Float]
    let isAnimating: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(audioLevels.enumerated()), id: \.offset) { index, level in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.cocPurple)
                    .frame(width: 3, height: max(4, CGFloat(level) * 60))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
}

// MARK: - Supporting Views
struct DestinationCardView: View {
    let destination: Destination
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header with Flag
            HStack {
                Text(destination.flag)
                    .font(.system(size: 50))
                Spacer()
                
                // Card count badge
                Text("\(destination.culturalCards.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color.cocPurple)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Card Content
            VStack(alignment: .leading, spacing: 6) {
                Text(destination.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(destination.culturalCards.count == 1 ? "1 cultural card" : "\(destination.culturalCards.count) cultural cards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Cultural categories preview
                if !destination.culturalCards.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(Set(destination.culturalCards.prefix(3).map(\.type))), id: \.self) { cardType in
                            Text(cardType.emoji)
                                .font(.caption)
                        }
                        if destination.culturalCards.count > 3 {
                            Text("•••")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(isPressed ? 0.15 : 0.08), radius: isPressed ? 12 : 8, x: 0, y: isPressed ? 6 : 4)
                .shadow(color: .black.opacity(isPressed ? 0.08 : 0.04), radius: isPressed ? 4 : 2, x: 0, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPressed ? Color.cocPurple.opacity(0.2) : Color(.systemGray5), lineWidth: isPressed ? 1.0 : 0.5)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: destination.culturalCards.count)
        .onTapGesture {
            // Press animation feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            onTap()
        }
    }
}

struct CulturalCardView: View {
    let card: CulturalCard
    let index: Int
    let onTap: () -> Void
    @State private var isPressed = false
    
    // Random card height for staggered effect (PPnotes style)
    private var cardHeight: CGFloat {
        let heights: [CGFloat] = [140, 150, 145, 160, 155, 145, 165, 135, 150]
        return heights[index % heights.count]
    }
    
    // Random slight rotation for organic feel (PPnotes style)
    private var rotation: Double {
        let rotations: [Double] = [-4, -2, -1, 0, 1, 2, 4, -3, 3, -1.5, 1.5]
        return rotations[index % rotations.count]
    }
    
    // Slight position offset for natural look
    private var positionOffset: CGSize {
        let xOffsets: [CGFloat] = [-3, 2, -2, 4, 0, -4, 3, -1, 1]
        let yOffsets: [CGFloat] = [-2, 1, -3, 2, 0, -1, 3, -2, 1]
        return CGSize(
            width: xOffsets[index % xOffsets.count],
            height: yOffsets[index % yOffsets.count]
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with timestamp-style date (PPnotes uniform style)
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Cultural")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    
                    Text("Insight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Title section (PPnotes uniform style)
            HStack {
                Text(card.type.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Category emoji
                Text(card.type.emoji)
                    .font(.system(size: 18))
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            
            // Content preview (PPnotes transcription style)
            Text(card.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            Spacer()
            
            // Bottom section (simplified)
            HStack {
                Text(card.type.description)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text("Tap to learn")
                    .font(.caption2)
                    .foregroundColor(.cocPurple)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(height: cardHeight) // Variable height for staggered effect
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray6), lineWidth: 0.5)
        }
        .rotationEffect(.degrees(rotation)) // Random tilt for organic feel
        .offset(positionOffset) // Slight position variation for organic feel
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            // Press animation feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            // Call the tap action
            onTap()
        }
    }
}

// MARK: - Staggered Grid Layout
struct StaggeredCulturalCardsGrid: View {
    let cards: [CulturalCard]
    let onCardTap: (CulturalCard) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let columnWidth = (width - 16) / 2 // Account for spacing
            
            HStack(alignment: .top, spacing: 16) {
                // Left column
                LazyVStack(spacing: 16) {
                    ForEach(Array(leftColumnCards.enumerated()), id: \.element.id) { index, card in
                        CulturalCardView(card: card, index: leftColumnIndex(for: index), onTap: {
                            onCardTap(card)
                        })
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(index) * 0.1), value: cards.count)
                    }
                }
                .frame(width: columnWidth)
                
                // Right column
                LazyVStack(spacing: 16) {
                    ForEach(Array(rightColumnCards.enumerated()), id: \.element.id) { index, card in
                        CulturalCardView(card: card, index: rightColumnIndex(for: index), onTap: {
                            onCardTap(card)
                        })
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(index) * 0.1), value: cards.count)
                    }
                }
                .frame(width: columnWidth)
            }
        }
        .frame(height: maxColumnHeight + 50) // Dynamic height based on content
    }
    
    // Split cards into two columns for staggered layout
    private var leftColumnCards: [CulturalCard] {
        cards.enumerated().compactMap { index, card in
            index % 2 == 0 ? card : nil
        }
    }
    
    private var rightColumnCards: [CulturalCard] {
        cards.enumerated().compactMap { index, card in
            index % 2 == 1 ? card : nil
        }
    }
    
    // Calculate original index for left column items
    private func leftColumnIndex(for columnIndex: Int) -> Int {
        return columnIndex * 2
    }
    
    // Calculate original index for right column items
    private func rightColumnIndex(for columnIndex: Int) -> Int {
        return columnIndex * 2 + 1
    }
    
    // Calculate the maximum height needed
    private var maxColumnHeight: CGFloat {
        let leftHeight = calculateColumnHeight(for: leftColumnCards, startingIndex: 0)
        let rightHeight = calculateColumnHeight(for: rightColumnCards, startingIndex: 1)
        return max(leftHeight, rightHeight)
    }
    
    private func calculateColumnHeight(for cards: [CulturalCard], startingIndex: Int) -> CGFloat {
        var totalHeight: CGFloat = 0
        for (index, _) in cards.enumerated() {
            let originalIndex = startingIndex + index * 2
            let cardHeight = getCardHeight(for: originalIndex)
            totalHeight += cardHeight + 16 // Add spacing
        }
        return totalHeight
    }
    
    private func getCardHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [140, 150, 145, 160, 155, 145, 165, 135, 150]
        return heights[index % heights.count]
    }
}

// MARK: - Cultural Card Detail View
struct CulturalCardDetailView: View {
    let card: CulturalCard
    let destination: Destination
    let onBack: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onBack()
                }
            
            // Card Detail Content (PPnotes style)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header section (PPnotes style)
                    VStack(alignment: .leading, spacing: 16) {

                        
                        // Cultural card header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cultural Insight")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                                
                                Text(destination.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Category emoji
                            Text(card.type.emoji)
                                .font(.system(size: 32))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Card content (PPnotes note style)
                    VStack(alignment: .leading, spacing: 24) {
                        // Title section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.type.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(card.type.description)
                                .font(.subheadline)
                                .foregroundColor(.cocPurple)
                                .fontWeight(.medium)
                        }
                        
                        // Main content
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Cultural Knowledge")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(card.content)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                                .multilineTextAlignment(.leading)
                        }
                        
                        // Additional insights section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Insights")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                InsightRow(icon: "💡", text: "Understanding this cultural practice helps build rapport with local colleagues")
                                InsightRow(icon: "🤝", text: "Shows respect for traditional business customs")
                                InsightRow(icon: "📈", text: "Can improve business relationship outcomes")
                            }
                        }
                        
                        // Context section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cultural Context")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("This practice is deeply rooted in \(destination.name)'s cultural values and has been maintained across generations of business professionals.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
            .scaleEffect(isVisible ? 1.0 : 0.1)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Insight Row Component
struct InsightRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.body)
            
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Modal Views
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Preferences") {
                    HStack {
                        Text("🔔")
                        Text("Notifications")
                    }
                    
                    HStack {
                        Text("💾")
                        Text("Offline Data")
                    }
                    
                    HStack {
                        Text("📤")
                        Text("Export/Backup")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("ℹ️")
                        Text("Version 1.0")
                    }
                    
                    HStack {
                        Text("⚖️")
                        Text("MIT License")
                    }
                }
            }
            .navigationTitle("⚙️ Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Button Styles
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
