# Cup of Culture (CoC) 🌍☕

A cultural learning iOS app designed for international business professionals and travelers to quickly understand destination cultures.

## Overview

Cup of Culture helps users navigate cultural differences by providing essential cultural insights, business etiquette, and local customs for destinations worldwide. Perfect for busy professionals who need quick, actionable cultural knowledge before traveling or conducting international business.

## UI/UX Design

### Main Interface Structure

**Primary Screen Layout:**
```
┌─────────────────────────────────┐
│ [🧭] Destinations    Settings [⚙️] │  ← Top Navigation Bar
├─────────────────────────────────┤
│                                 │
│                                 │
│        Main Content Area        │  ← Cultural Cards Display
│     (Destination Cards View)    │
│                                 │
│                                 │
├─────────────────────────────────┤
│                         [+] ←── │  ← Floating Action Button
└─────────────────────────────────┘
```

### Navigation Components

**🧭 Top Left - Destinations Context Menu**
- **Trigger**: Tap destinations button (🧭)
- **Function**: Shows list of all user-added destinations
- **UI**: Slide-over or modal list view
- **Actions**: 
  - Select destination to view its cultural cards
  - Quick switch between destinations

**⚙️ Top Right - Settings**
- **Trigger**: Tap settings button (⚙️)
- **Function**: App configuration and preferences
- **UI**: Standard settings modal/navigation
- **Options**: 
  - Notifications preferences
  - Offline data management
  - Export/backup destinations

**➕ Bottom Floating Action Button**
- **Position**: Bottom right corner (floating)
- **Behavior**: Context-aware functionality
- **States**:
  - **First-time user**: "Add Your First Destination"
  - **In main view**: "Add New Destination" 
  - **Within destination**: "Add Cultural Card"

### User Journey Flow

**1. First-Time User Experience**
```
Launch App → Empty State → Tap [+] → Add First Destination → View Destination → Tap [+] → Add First Cultural Card
```

**2. Regular User Flow**
```
Main View → Select Destination (🧭) → View Cultural Cards → Tap [+] → Add New Card
     ↳ OR → Tap [+] → Add New Destination
```

**3. Cultural Card Creation**
```
Destination View → Tap [+] → Choose Card Type → Fill Content → Save → View in Destination
```

### Content Structure

**🗺️ Destination**
- Name & flag/image
- Collection of cultural knowledge cards
- Progress indicator (cards added)
- Last updated timestamp

**🎴 Cultural Knowledge Card Types**
- **Business Etiquette**: Meeting protocols, dress codes, punctuality
- **Social Customs**: Greetings, conversation topics, personal space
- **Dining Culture**: Table manners, tipping, dining customs
- **Communication**: Direct vs. indirect, gestures, eye contact
- **Gift Giving**: Appropriate gifts, presentation, occasions
- **Quick Facts**: Key phrases, important numbers, cultural notes

## Features (Planned)

- **Destination Selector**: Choose countries and cities to explore
- **Cultural Essentials**: Key cultural norms, greetings, and social customs  
- **Business Etiquette**: Meeting protocols, negotiation styles, and professional practices
- **Quick Reference**: Do's and don'ts, key phrases, and cultural tips
- **Offline Access**: Essential information available without internet connection

## Technology Stack

- **Platform**: iOS (Swift/SwiftUI)
- **Minimum iOS Version**: iOS 17.0+
- **Architecture**: MVVM with SwiftUI

## Development Setup

1. Clone the repository
```bash
git clone https://github.com/seanspsong/CoC.git
cd CoC
```

2. Open `CoC.xcodeproj` in Xcode
3. Build and run on simulator or device

## Contributing

This project is currently in early development. Contributions, ideas, and feedback are welcome!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### MIT License Summary
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use
- ❌ Liability
- ❌ Warranty

---

*Bridging cultures, one cup at a time* ☕🌏 
