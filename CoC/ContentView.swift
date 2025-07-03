//
//  ContentView.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import SwiftUI
import PhotosUI

// MARK: - Color Theme
extension Color {
    static let cocPurple = Color(red: 0x8A/255, green: 0x2B/255, blue: 0xE2/255)
}

// MARK: - Country Model
struct Country: Identifiable {
    let id = UUID()
    let name: String
    let flag: String
}

extension Country {
    static let availableCountries: [Country] = [
        Country(name: "Japan", flag: "🇯🇵"),
        Country(name: "Germany", flag: "🇩🇪"),
        Country(name: "United Kingdom", flag: "🇬🇧"),
        Country(name: "France", flag: "🇫🇷"),
        Country(name: "Italy", flag: "🇮🇹"),
        Country(name: "Spain", flag: "🇪🇸"),
        Country(name: "China", flag: "🇨🇳"),
        Country(name: "South Korea", flag: "🇰🇷"),
        Country(name: "India", flag: "🇮🇳"),
        Country(name: "Brazil", flag: "🇧🇷"),
        Country(name: "Mexico", flag: "🇲🇽"),
        Country(name: "Netherlands", flag: "🇳🇱"),
        Country(name: "Sweden", flag: "🇸🇪"),
        Country(name: "Switzerland", flag: "🇨🇭"),
        Country(name: "Australia", flag: "🇦🇺"),
        Country(name: "Canada", flag: "🇨🇦")
    ]
}

// MARK: - Country Selection View
struct CountrySelectionView: View {
    let onCountrySelected: (Country) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150))
                ], spacing: 16) {
                    ForEach(Country.availableCountries) { country in
                        CountryCardView(country: country) {
                            onCountrySelected(country)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.cocPurple)
                }
            }
        }
    }
}

// MARK: - Country Card View
struct CountryCardView: View {
    let country: Country
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text(country.flag)
                .font(.system(size: 50))
            
            Text(country.name)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(isPressed ? 0.15 : 0.08), radius: isPressed ? 12 : 8, x: 0, y: isPressed ? 6 : 4)
                .shadow(color: .black.opacity(isPressed ? 0.08 : 0.04), radius: isPressed ? 4 : 2, x: 0, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPressed ? Color.cocPurple.opacity(0.3) : Color(.systemGray5), lineWidth: isPressed ? 2.0 : 0.5)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
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
            
            onTap()
        }
    }
}

struct ContentView: View {
    @State private var showingSettings = false
    @StateObject private var dataManager = DataManager()
    @State private var selectedDestination: Destination?
    @State private var selectedCard: CulturalCard?
    @State private var showingVoiceRecording = false

    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingCountrySelection = false
    @State private var showingAPIKeyAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @StateObject private var voiceRecorder = VoiceRecorder()
    @StateObject private var aiGenerator = AICardGenerator()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main Content (Full Screen)
                if let selectedCard = selectedCard, let selectedDestination = selectedDestination {
                    // Show appropriate view based on card type
                    ZStack {
                        // Background overlay
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    self.selectedCard = nil
                                }
                            }
                        
                        // Choose view based on whether card is AI-generated
                        if selectedCard.isAIGenerated {
                            // Use AI-generated card view for structured content
                            GeneratedCardContentView(card: selectedCard, destination: selectedDestination, onClose: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    self.selectedCard = nil
                                }
                            })
                                .background {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 60)
                        } else {
                            // Use traditional card view for legacy content
                            CulturalCardDetailView(
                                card: selectedCard,
                                destination: selectedDestination
                            ) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    self.selectedCard = nil
                                }
                            }
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
                        aiGenerator: aiGenerator,
                        onCardGenerated: { generatedCard in
                            // Handle successful card generation
                            addGeneratedCard(generatedCard, to: selectedDestination)
                            showingVoiceRecording = false
                        },
                        onCancel: {
                            // Handle cancellation
                            showingVoiceRecording = false
                        },
                        onAPIKeyError: {
                            // Handle API key error
                            showingAPIKeyAlert = true
                            showingVoiceRecording = false
                        },
                        onCameraSelected: {
                            // Handle camera selection
                            showingVoiceRecording = false
                            showingCamera = true
                        },
                        onPhotoSelected: {
                            // Handle photo selection
                            showingVoiceRecording = false
                            showingImagePicker = true
                        }
                    )
                    .zIndex(1)
                } else if let selectedDestination = selectedDestination,
                          let currentDestination = dataManager.destinations.first(where: { $0.id == selectedDestination.id }) {
                    // Destination Detail View (always use current data from DataManager)
                    DestinationDetailView(
                        destination: currentDestination,
                        onCardTap: { card in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                self.selectedCard = card
                            }
                        },
                        onCardDelete: { card in
                            deleteCard(card, from: currentDestination)
                        },
                        onAddCard: {
                            addNewCard()
                        }
                    ) {
                        self.selectedDestination = nil
                    }
                } else {
                    // Destinations Overview
                    DestinationsOverviewView(
                        destinations: dataManager.destinations,
                        onDestinationTap: { destination in
                            selectedDestination = destination
                        },
                        onDestinationDelete: { destination in
                            deleteDestination(destination)
                        }
                    )
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
                        
                        // Title in center - Only show in destinations overview
                        if selectedDestination == nil {
                            Text("CoC: Cup of Culture")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.top, 16)
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
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }

        .sheet(isPresented: $showingImagePicker) {
            NavigationView {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Text("Select Photo")
                        .foregroundColor(.cocPurple)
                }
                .navigationTitle("Choose Photo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showingImagePicker = false
                        }
                        .foregroundColor(.cocPurple)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(selectedImage: $selectedImage, isPresented: $showingCamera)
        }
        .sheet(isPresented: $showingCountrySelection) {
            CountrySelectionView { selectedCountry in
                createDestination(for: selectedCountry)
                showingCountrySelection = false
            } onCancel: {
                showingCountrySelection = false
            }
        }
        .alert("API Key Required", isPresented: $showingAPIKeyAlert) {
            Button("Settings") {
                showingSettings = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please add your OpenAI API key in Settings to use AI-powered cultural insights.")
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            await processSelectedImage(uiImage)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedImage) { newImage in
            Task {
                if let newImage = newImage {
                    await processSelectedImage(newImage)
                }
            }
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
        showingCountrySelection = true
    }
    
    private func createDestination(for country: Country) {
        let newDestination = Destination(name: country.name, flag: country.flag, country: country.name)
        dataManager.addDestination(newDestination)
        print("Added new destination: \(newDestination.name) (Country: \(newDestination.country))")
    }
    
    private func addNewCard() {
        // Show voice recording interface with all input options
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingVoiceRecording = true
        }
    }
    
    private func addGeneratedCard(_ card: CulturalCard, to destination: Destination) {
        // Use DataManager to add the card and automatically save
        dataManager.addCard(card, to: destination)
        // No need to update selectedDestination since the view now gets current data from DataManager
    }
    
    private func deleteCard(_ card: CulturalCard, from destination: Destination) {
        // Use DataManager to remove the card and automatically save
        dataManager.removeCard(card, from: destination)
        print("🗑️ Deleted card: \(card.title)")
    }
    
    private func deleteDestination(_ destination: Destination) {
        // Use DataManager to remove the destination and automatically save
        if let index = dataManager.destinations.firstIndex(where: { $0.id == destination.id }) {
            dataManager.removeDestination(at: index)
            print("🗑️ Deleted destination: \(destination.name)")
        }
    }
    
    private func processSelectedImage(_ image: UIImage) async {
        guard let selectedDestination = selectedDestination else { return }
        
        print("📸 [ContentView] Processing selected image...")
        
        do {
            // Generate cultural card from image using AI
            let generatedCard = try await aiGenerator.generateCulturalCardFromImage(
                image: image,
                destination: selectedDestination
            )
            
            // Add the generated card to the destination
            await MainActor.run {
                addGeneratedCard(generatedCard, to: selectedDestination)
                // Reset selected image
                selectedImage = nil
                selectedPhotoItem = nil
            }
            
            print("✅ [ContentView] Successfully generated card from image")
            
        } catch {
            print("❌ [ContentView] Failed to generate card from image: \(error)")
            await MainActor.run {
                if error.localizedDescription.contains("API key") {
                    showingAPIKeyAlert = true
                }
                // Reset selected image
                selectedImage = nil
                selectedPhotoItem = nil
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Destinations Overview View
struct DestinationsOverviewView: View {
    let destinations: [Destination]
    let onDestinationTap: (Destination) -> Void
    let onDestinationDelete: (Destination) -> Void
    
    var body: some View {
        // Destinations List
        List {
            ForEach(Array(destinations.enumerated()), id: \.element.id) { index, destination in
                DestinationCardView(destination: destination, onTap: {
                    onDestinationTap(destination)
                })
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .animation(.spring(response: 1.2, dampingFraction: 0.9).delay(Double(index) * 0.1), value: destinations.count)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    onDestinationDelete(destinations[index])
                }
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .padding(.top, 60) // Add top padding for the floating buttons
    }
}

// MARK: - Destination Detail View
struct DestinationDetailView: View {
    let destination: Destination
    let onCardTap: (CulturalCard) -> Void
    let onCardDelete: (CulturalCard) -> Void
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
                    .padding(.top, 60) // Reduced top padding to move view up
                    .padding(.bottom, 20)
                    
                    // Staggered Cultural Cards Layout (PPnotes style)
                    StaggeredCulturalCardsGrid(
                        cards: destination.culturalCards, 
                        onCardTap: onCardTap,
                        onCardDelete: onCardDelete
                    )
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
    let onAPIKeyError: () -> Void
    let onCameraSelected: () -> Void
    let onPhotoSelected: () -> Void
    
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
                        waveformTrigger: $waveformTrigger,
                        onCameraSelected: onCameraSelected,
                        onPhotoSelected: onPhotoSelected
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
            
            // Close button positioned at top right corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onCancel()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 40)
                    .padding(.top, 20)
                }
                Spacer()
            }
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
                    destination: destination,
                    userQuery: voiceRecorder.transcribedText
                )
                
                await MainActor.run {
                    generatedCard = card
                    recordingState = .generated
                }
            } catch {
                await MainActor.run {
                    recordingState = .error
                    // Check if it's an API key error and show alert
                    if let aiError = error as? AIGenerationError,
                       case .apiKeyNotConfigured = aiError {
                        print("❌ [VoiceRecording] API key not configured error")
                        onAPIKeyError()
                    }
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
    let onCameraSelected: () -> Void
    let onPhotoSelected: () -> Void
    
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
            
            // Bottom Action Buttons
            VStack(spacing: 16) {
                if recordingState == .ready {
                    // Three input buttons: Camera, Microphone, Photo
                    HStack(spacing: 32) {
                        // Camera Button
                        InputActionButton(
                            icon: "📷",
                            title: "Camera",
                            color: .blue,
                            action: onCameraSelected
                        )
                        
                        // Microphone Button (larger, in center)
                        MicrophoneButton(
                            isRecording: voiceRecorder.isRecording,
                            hasPermission: voiceRecorder.hasPermission
                        ) {
                            voiceRecorder.startRecording()
                            recordingState = .recording
                        }
                        
                        // Photo Button
                        InputActionButton(
                            icon: "🖼️",
                            title: "Photo",
                            color: .green,
                            action: onPhotoSelected
                        )
                    }
                } else if recordingState == .recording {
                    // Only show microphone button when recording
                    MicrophoneButton(
                        isRecording: voiceRecorder.isRecording,
                        hasPermission: voiceRecorder.hasPermission
                    ) {
                        voiceRecorder.stopRecording()
                        recordingState = .processing
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .frame(minHeight: 400)
    }
}

// MARK: - Input Action Button
struct InputActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                    action()
                }
            }) {
                Text(icon)
                    .font(.system(size: 28))
                    .frame(width: 56, height: 56)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Generated Card Content View
struct GeneratedCardContentView: View {
    let card: CulturalCard
    let destination: Destination
    let onClose: (() -> Void)?
    @State private var isExpanded = false
    @StateObject private var ttsManager = TextToSpeechManager()
    
    init(card: CulturalCard, destination: Destination, onClose: (() -> Void)? = nil) {
        self.card = card
        self.destination = destination
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                // YOUR QUESTION Section
                if let question = card.question, !question.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR QUESTION")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        
                        Text(question)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                
                // NAME CARD Section
                if let nameCardApp = card.nameCardApp {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAME CARD")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(nameCardApp)
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                if let nameCardLocal = card.nameCardLocal {
                                    Text(nameCardLocal)
                                        .font(.system(size: 32, weight: .bold, design: .default))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            
                            // Speaker button for pronunciation (only show if local language is available)
                            if let nameCardLocal = card.nameCardLocal {
                                Button(action: {
                                    let languageCode = ttsManager.getLanguageCode(for: destination.name)
                                    print("🔊 [UI] Speaking - Destination: '\(destination.name)', Local Name: '\(nameCardLocal)'")
                                    print("🔊 [UI] Language code: '\(languageCode)'")
                                    ttsManager.speak(text: nameCardLocal, language: languageCode)
                                }) {
                                    Image(systemName: ttsManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.2.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.cocPurple)
                                        .frame(width: 32, height: 32)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                        .opacity(ttsManager.isSpeaking ? 0.7 : 1.0)
                                        .scaleEffect(ttsManager.isSpeaking ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: ttsManager.isSpeaking)
                                }
                                .disabled(ttsManager.isSpeaking)
                                .padding(.top, 4) // Align with text baseline
                            }
                        }
                    }
                }
                
                // Key Knowledge Section
                if let keyKnowledge = card.keyKnowledge, !keyKnowledge.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Knowledge")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cocPurple)
                        
                        ForEach(keyKnowledge, id: \.self) { knowledge in
                            HStack(alignment: .top, spacing: 12) {
                                Text("-")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.cocPurple)
                                
                                Text(knowledge)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                        
                        // Expand/Collapse Button at bottom, centered
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isExpanded.toggle()
                                }
                            }) {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.cocPurple)
                                    .frame(width: 24, height: 24)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                    }
                }
                
                // Cultural Insights Section (Expandable)
                if let culturalInsights = card.culturalInsights, isExpanded {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cultural Insights")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cocPurple)
                        
                        Text(culturalInsights)
                            .font(.body)
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
                
                // Legacy fallback: Show old format if new format not available
                if card.nameCardApp == nil && card.nameCardLocal == nil && card.keyKnowledge == nil && card.culturalInsights == nil {
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
            .padding(.vertical, 24)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.9)
            .fixedSize(horizontal: false, vertical: true)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Close button positioned at top right corner (only show if onClose is provided)
            if let onClose = onClose {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            onClose()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            }
        }
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
    let onDelete: () -> Void
    @Binding var isDeleteMode: Bool
    @State private var isPressed = false
    @State private var shakeOffset: CGFloat = 0
    
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
    
    // Display title: Use Name Card for AI-generated cards, category title for others
    private var cardDisplayTitle: String {
        if card.isAIGenerated, let nameCardApp = card.nameCardApp, !nameCardApp.isEmpty {
            return nameCardApp
        } else if card.isAIGenerated, let nameCard = card.nameCard, !nameCard.isEmpty {
            return nameCard
        } else {
            return card.type.title
        }
    }
    
    // Contextual emoji based on card content
    private var contextualEmoji: String {
        // For AI-generated cards, determine emoji based on nameCard or title content
        if card.isAIGenerated {
            let searchText = (card.nameCardApp ?? card.title).lowercased()
            
            // Company/Brand emojis
            if searchText.contains("sony") {
                return "📱"
            } else if searchText.contains("nintendo") {
                return "🎮"
            } else if searchText.contains("toyota") {
                return "🚗"
            } else if searchText.contains("yamaha") {
                return "🎵"
            } else if searchText.contains("honda") {
                return "🏍️"
            } else if searchText.contains("panasonic") {
                return "🔌"
            } else if searchText.contains("canon") {
                return "📷"
            } else if searchText.contains("mitsubishi") {
                return "🏢"
            } else if searchText.contains("ferrari") {
                return "🏎️"
            } else if searchText.contains("lamborghini") {
                return "🏎️"
            } else if searchText.contains("maserati") {
                return "🏎️"
            } else if searchText.contains("porsche") {
                return "🏎️"
            } else if searchText.contains("bmw") {
                return "🚗"
            } else if searchText.contains("mercedes") {
                return "🚗"
            } else if searchText.contains("audi") {
                return "🚗"
            } else if searchText.contains("volkswagen") {
                return "🚗"
            }
            
            // People/Names emojis
            else if searchText.contains("hiroshi") || searchText.contains("tanaka") {
                return "👨‍💼"
            } else if searchText.contains("fusajiro") || searchText.contains("yamauchi") {
                return "🎯"
            } else if searchText.contains("masuda") {
                return "🎼"
            } else if searchText.contains("ibuka") || searchText.contains("morita") {
                return "💡"
            } else if searchText.contains("enzo") && searchText.contains("ferrari") {
                return "🏎️"
            }
            
            // Places/Landmarks emojis
            else if searchText.contains("fuji") || searchText.contains("mount") {
                return "🗻"
            } else if searchText.contains("tokyo") {
                return "🏙️"
            } else if searchText.contains("kyoto") {
                return "⛩️"
            } else if searchText.contains("osaka") {
                return "🍜"
            } else if searchText.contains("temple") {
                return "🏛️"
            } else if searchText.contains("shrine") {
                return "⛩️"
            }
            
            // Business/Cultural concept emojis
            else if searchText.contains("founder") || searchText.contains("ceo") {
                return "👔"
            } else if searchText.contains("innovation") || searchText.contains("technology") {
                return "💡"
            } else if searchText.contains("culture") || searchText.contains("tradition") {
                return "🎌"
            } else if searchText.contains("business") || searchText.contains("meeting") {
                return "💼"
            } else if searchText.contains("dining") || searchText.contains("food") {
                return "🍽️"
            } else if searchText.contains("greeting") || searchText.contains("bow") {
                return "🙇‍♂️"
            }
            
            // Default for AI-generated cards
            else {
                return "🎌"
            }
        } else {
            // For manual cards, use category emoji
            return card.type.emoji
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Empty spacer for consistent layout
            Spacer()
                .frame(height: 12)
            
            // Title section (PPnotes uniform style)
            HStack {
                // Use Name Card for AI-generated cards, otherwise use category title
                Text(cardDisplayTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Contextual emoji based on card content
                Text(contextualEmoji)
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
        .offset(x: positionOffset.width + shakeOffset, y: positionOffset.height) // Slight position variation + shake
        .scaleEffect(isPressed ? 0.96 : (isDeleteMode ? 0.95 : 1.0))
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isDeleteMode)
        .overlay {
            // Delete button overlay
            if isDeleteMode {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Haptic feedback for deletion
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                            
                            // Call delete action with animation
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                onDelete()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.red)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        .offset(x: 6, y: -6) // Position slightly outside top-right corner
                    }
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: isDeleteMode)
            }
        }
        .onTapGesture {
            // Normal tap behavior (delete mode handled in parent)
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
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press detected - enter delete mode
            withAnimation(.easeInOut(duration: 0.3)) {
                isDeleteMode = true
            }
        } onPressingChanged: { pressing in
            // Haptic feedback on press start
            if pressing && !isDeleteMode {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
        .onChange(of: isDeleteMode) { oldValue, newValue in
            if newValue {
                startShaking()
            } else {
                stopShaking()
            }
        }
    }
    
    // MARK: - Shake Animation Methods
    private func startShaking() {
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            shakeOffset = 2
        }
    }
    
    private func stopShaking() {
        withAnimation(.easeInOut(duration: 0.1)) {
            shakeOffset = 0
        }
    }
}

// MARK: - Staggered Grid Layout
struct StaggeredCulturalCardsGrid: View {
    let cards: [CulturalCard]
    let onCardTap: (CulturalCard) -> Void
    let onCardDelete: (CulturalCard) -> Void
    @State private var isDeleteMode = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let columnWidth = (width - 16) / 2 // Account for spacing
            
            HStack(alignment: .top, spacing: 16) {
                // Left column
                LazyVStack(spacing: 16) {
                    ForEach(Array(leftColumnCards.enumerated()), id: \.element.id) { index, card in
                        CulturalCardView(
                            card: card, 
                            index: leftColumnIndex(for: index), 
                            onTap: {
                                if !isDeleteMode {
                                    onCardTap(card)
                                }
                            },
                            onDelete: {
                                onCardDelete(card)
                                // Exit delete mode after deletion
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isDeleteMode = false
                                }
                            },
                            isDeleteMode: $isDeleteMode
                        )
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
                        CulturalCardView(
                            card: card, 
                            index: rightColumnIndex(for: index), 
                            onTap: {
                                if !isDeleteMode {
                                    onCardTap(card)
                                }
                            },
                            onDelete: {
                                onCardDelete(card)
                                // Exit delete mode after deletion
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isDeleteMode = false
                                }
                            },
                            isDeleteMode: $isDeleteMode
                        )
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
        .onTapGesture {
            if isDeleteMode {
                // Exit delete mode when tapping outside cards
                withAnimation(.easeInOut(duration: 0.3)) {
                    isDeleteMode = false
                }
            }
        }
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
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @State private var showingAPIKeyInput = false
    @State private var tempAPIKey = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("AI Configuration") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("OpenAI API Key")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button(apiKey.isEmpty ? "Add Key" : "Update") {
                                tempAPIKey = apiKey
                                showingAPIKeyInput = true
                            }
                            .font(.caption)
                            .foregroundColor(.cocPurple)
                        }
                        
                        Text(apiKey.isEmpty ? "Required for AI-powered cultural insights" : "API key configured ✓")
                            .font(.caption)
                            .foregroundColor(apiKey.isEmpty ? .red : .green)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("AI Model")
                        Spacer()
                        Text("ChatGPT 4.1")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    Text("Cup of Culture helps international business travelers understand destination cultures through AI-powered insights.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .sheet(isPresented: $showingAPIKeyInput) {
            APIKeyInputView(
                apiKey: $tempAPIKey,
                onSave: { newKey in
                    apiKey = newKey
                    showingAPIKeyInput = false
                },
                onCancel: {
                    showingAPIKeyInput = false
                }
            )
        }
    }
}

// MARK: - API Key Input View
struct APIKeyInputView: View {
    @Binding var apiKey: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @State private var showingKey = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("OpenAI API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your API key is stored securely on your device and never shared.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if showingKey {
                                TextField("sk-proj-...", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("sk-proj-...", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            
                            Button(action: { showingKey.toggle() }) {
                                Image(systemName: showingKey ? "eye.slash" : "eye")
                                    .foregroundColor(.cocPurple)
                            }
                        }
                        
                        Text("Example: sk-proj-abcd1234efgh5678...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Link("Get your API key from OpenAI", 
                             destination: URL(string: "https://platform.openai.com/api-keys")!)
                            .font(.caption)
                            .foregroundColor(.cocPurple)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("API Key")
            .navigationBarItems(
                leading: Button("Cancel") { 
                    onCancel()
                },
                trailing: Button("Save") {
                    onSave(apiKey)
                }
                .disabled(apiKey.isEmpty || !apiKey.hasPrefix("sk-"))
                .foregroundColor(apiKey.isEmpty || !apiKey.hasPrefix("sk-") ? .gray : .cocPurple)
            )
        }
    }
    
    init(apiKey: Binding<String>, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self._apiKey = apiKey
        self.onSave = onSave
        self.onCancel = onCancel
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
