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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main Content (Full Screen)
                if let selectedDestination = selectedDestination {
                    // Destination Detail View
                    DestinationDetailView(destination: selectedDestination) {
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
        // TODO: Show card creation sheet
        print("Adding new cultural card")
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
                    StaggeredCulturalCardsGrid(cards: destination.culturalCards)
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
            
            // TODO: Handle card tap action
        }
    }
}

// MARK: - Staggered Grid Layout
struct StaggeredCulturalCardsGrid: View {
    let cards: [CulturalCard]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let columnWidth = (width - 16) / 2 // Account for spacing
            
            HStack(alignment: .top, spacing: 16) {
                // Left column
                LazyVStack(spacing: 16) {
                    ForEach(Array(leftColumnCards.enumerated()), id: \.element.id) { index, card in
                        CulturalCardView(card: card, index: leftColumnIndex(for: index))
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
                        CulturalCardView(card: card, index: rightColumnIndex(for: index))
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
