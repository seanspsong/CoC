//
//  ContentView.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingDestinations = false
    @State private var showingSettings = false
    @State private var destinations: [Destination] = []
    @State private var selectedDestination: Destination?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main Content Area
                VStack {
                    // Top Navigation Bar
                    HStack {
                        // Destinations Button (Compass)
                        Button(action: {
                            showingDestinations.toggle()
                        }) {
                            HStack(spacing: 8) {
                                Text("🧭")
                                    .font(.title2)
                                Text("Destinations")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        // Settings Button
                        Button(action: {
                            showingSettings.toggle()
                        }) {
                            Text("⚙️")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // Main Content
                    if destinations.isEmpty {
                        // Empty State
                        EmptyStateView(onLoadSampleData: loadSampleData)
                    } else if let selectedDestination = selectedDestination {
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
                    
                    Spacer()
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(
                            isEmpty: destinations.isEmpty,
                            isInDestination: selectedDestination != nil
                        ) {
                            handleFloatingActionTap()
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDestinations) {
            DestinationsListView(
                destinations: destinations,
                selectedDestination: $selectedDestination
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func handleFloatingActionTap() {
        if destinations.isEmpty {
            // Add first destination
            addNewDestination()
        } else if selectedDestination != nil {
            // Add new cultural card to current destination
            addNewCard()
        } else {
            // Add new destination
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
        destinations = Destination.sampleData
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let onLoadSampleData: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🌍")
                .font(.system(size: 80))
            
            Text("Welcome to Cup of Culture")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Start building your cultural knowledge by adding your first destination")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                HStack {
                    Text("1.")
                        .fontWeight(.semibold)
                    Text("Tap the")
                    Text("+")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("button below")
                }
                
                HStack {
                    Text("2.")
                        .fontWeight(.semibold)
                    Text("Add your destination")
                }
                
                HStack {
                    Text("3.")
                        .fontWeight(.semibold)
                    Text("Create cultural knowledge cards")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.top, 20)
            
            // Sample Data Button for Demo
            Button(action: onLoadSampleData) {
                HStack {
                    Text("🎯")
                    Text("Load Sample Data")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .padding(.top, 30)
        }
        .padding()
    }
}

// MARK: - Destinations Overview View
struct DestinationsOverviewView: View {
    let destinations: [Destination]
    let onDestinationTap: (Destination) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160))
            ], spacing: 16) {
                ForEach(destinations) { destination in
                    DestinationCardView(destination: destination)
                        .onTapGesture {
                            onDestinationTap(destination)
                        }
                }
            }
            .padding()
        }
    }
}

// MARK: - Destination Detail View
struct DestinationDetailView: View {
    let destination: Destination
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Text("←")
                            .font(.title2)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(destination.flag)
                    .font(.largeTitle)
            }
            .padding(.horizontal)
            
            Text("Cultural Cards for \(destination.name)")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            if destination.culturalCards.isEmpty {
                VStack(spacing: 16) {
                    Text("🎴")
                        .font(.system(size: 60))
                    
                    Text("No cultural cards yet")
                        .font(.headline)
                    
                    Text("Tap the + button to add your first cultural knowledge card")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(destination.culturalCards) { card in
                            CulturalCardView(card: card)
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
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
            .background(Color.blue)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views
struct DestinationCardView: View {
    let destination: Destination
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(destination.flag)
                .font(.system(size: 40))
            
            Text(destination.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("\(destination.culturalCards.count) cards")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CulturalCardView: View {
    let card: CulturalCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.type.emoji)
                    .font(.title2)
                Text(card.type.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(card.content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Modal Views
struct DestinationsListView: View {
    let destinations: [Destination]
    @Binding var selectedDestination: Destination?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(destinations) { destination in
                Button(action: {
                    selectedDestination = destination
                    dismiss()
                }) {
                    HStack {
                        Text(destination.flag)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(destination.name)
                                .font(.headline)
                            Text("\(destination.culturalCards.count) cards")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("🧭 Destinations")
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

#Preview {
    ContentView()
}
