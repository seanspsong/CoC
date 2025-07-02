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
                        // Floating Add Button (Top Left)
                        FloatingActionButton(
                            isEmpty: destinations.isEmpty,
                            isInDestination: selectedDestination != nil
                        ) {
                            handleFloatingActionTap()
                        }
                        .padding(.leading, 20)
                        .padding(.top, 8)
                        
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
                ForEach(destinations) { destination in
                    Button(action: {
                        onDestinationTap(destination)
                    }) {
                        DestinationCardView(destination: destination)
                    }
                    .buttonStyle(CardButtonStyle())
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
                    
                    // Cultural Cards
                    LazyVStack(spacing: 24) {
                        ForEach(destination.culturalCards) { card in
                            CulturalCardView(card: card)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            
            // Floating Back Button (Bottom Left)
            VStack {
                Spacer()
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
                    .padding(.bottom, 30)
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let isEmpty: Bool
    let isInDestination: Bool
    let action: () -> Void
    
    var buttonText: String {
        if isEmpty {
            return "Add Your First Destination"
        } else if isInDestination {
            return "Add Cultural Card"
        } else {
            return "Add Destination"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("+")
                    .font(.title2)
                    .fontWeight(.semibold)
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
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views
struct DestinationCardView: View {
    let destination: Destination
    
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
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: destination.culturalCards.count)
    }
}

struct CulturalCardView: View {
    let card: CulturalCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            HStack(spacing: 12) {
                // Icon background with accent color
                Text(card.type.emoji)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cocPurple.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.cocPurple.opacity(0.2), lineWidth: 1)
                            )
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.type.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(card.type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 18)
            
            // Enhanced Divider
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
                .padding(.horizontal, 24)
            
            // Card Content
            Text(card.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(6)
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
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
