# 🐹 Ham Enhancement Roadmap

This document outlines planned enhancements for Ham - LLM Token Usage Menu Bar Monitor, organized by priority and implementation complexity.

## 🎯 Phase 1: Core Visual & Animation Improvements (v1.1)

### 1.1 Real Hamster Sprite Animations

**Current State**: Using emoji characters (😴, 🐹, 🚶‍♂️, etc.) for animation frames
**Target State**: Pixel-perfect hamster sprite animations with smooth running cycles

**Technical Approach**:
- Create/source hamster sprite sheets (16x16 or 32x32 pixels)
- Implement proper sprite frame management
- Add smooth transitions between animation states

**Implementation Steps**:
1. **Asset Creation**
   - Design or source hamster sprites for each state (sleeping, idle, walking, running, sprinting)
   - Create running cycle animations (4-8 frames per cycle)
   - Export as PNG sprites with transparency
   - Add @2x and @3x versions for Retina displays

2. **Code Changes**
   ```swift
   // New sprite management system
   struct SpriteSheet {
       let image: NSImage
       let frameSize: NSSize
       let frameCount: Int
   }
   
   // Enhanced HamsterAnimator
   private let spriteSheets: [HamsterState: SpriteSheet]
   private var currentStateFrames: [NSImage] = []
   ```

3. **Animation Improvements**
   - Implement state transition animations
   - Add easing between speed changes
   - Optimize frame rendering for menu bar constraints

**Files to Modify**:
- `Sources/Ham/HamsterAnimator.swift`: Complete sprite system rewrite
- `Ham.app/Contents/Resources/`: Add sprite assets
- `Package.swift`: Add resource bundle if needed

**Timeline**: 1-2 weeks
**Priority**: High (major visual improvement)

### 1.2 Enhanced Animation States & Transitions

**Current State**: 5 basic states with instant transitions
**Target State**: Smooth state transitions with intermediate animations

**Implementation**:
- Add transition states (e.g., `walkingToRunning`, `runningToSprinting`)
- Implement easing curves for speed changes
- Add particle effects for high usage states (dust clouds, speed lines)

**Files to Modify**:
- `Sources/Ham/HamsterAnimator.swift`
- Add new `AnimationTransition.swift` file

**Timeline**: 1 week
**Priority**: Medium

## 🔌 Phase 2: Real API Integration (v1.2)

### 2.1 Complete OpenAI Usage API Integration

**Current State**: Mock implementation returning random data
**Target State**: Real-time OpenAI usage tracking via official API

**Technical Research**:
- OpenAI doesn't provide real-time usage API
- Usage data available via billing API with ~24h delay
- Alternative: Track usage locally during API calls

**Implementation Strategy**:
```swift
// Option 1: Billing API Integration (delayed data)
class OpenAIBillingMonitor {
    func getDailyUsage(date: Date) async throws -> OpenAIUsage {
        // Call https://api.openai.com/v1/usage?date=YYYY-MM-DD
    }
}

// Option 2: Local Usage Tracking (real-time)
class OpenAIUsageTracker {
    func recordAPICall(model: String, promptTokens: Int, completionTokens: Int) {
        // Store locally with timestamp
    }
}
```

**Files to Create/Modify**:
- `Sources/Ham/OpenAIBillingAPI.swift`: New billing API integration
- `Sources/Ham/APIMonitor.swift`: Update OpenAIMonitor implementation
- `Sources/Ham/UsageTracker.swift`: New local usage tracking system

**Timeline**: 1 week
**Priority**: High (core functionality)

### 2.2 Enhanced Google AI Usage Tracking

**Current State**: API key validation only, manual usage recording
**Target State**: Automatic usage detection and recording

**Implementation**:
- Intercept Google AI API calls (if possible)
- Enhance manual recording with better UX
- Add usage estimation based on content analysis

**Files to Modify**:
- `Sources/Ham/APIMonitor.swift`: GoogleAIMonitor enhancements

**Timeline**: 3-5 days
**Priority**: Medium

## 📊 Phase 3: Historical Tracking & Analytics (v1.3)

### 3.1 Usage History Database

**Current State**: Only current day tracking in UserDefaults
**Target State**: Complete historical usage database with trends

**Technical Approach**:
```swift
// Core Data model for usage history
@objc(UsageRecord)
class UsageRecord: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var provider: String
    @NSManaged var tokens: Int32
    @NSManaged var cost: Double
    @NSManaged var model: String?
}

// Usage analytics engine
class UsageAnalytics {
    func getDailyUsage(days: Int) -> [DailyUsage]
    func getWeeklyTrends() -> WeeklyTrend
    func getUsageByProvider() -> [ProviderUsage]
    func predictMonthlyUsage() -> UsagePrediction
}
```

**Implementation Steps**:
1. Add Core Data stack to project
2. Create usage data models
3. Migrate existing UserDefaults data
4. Implement analytics calculations
5. Add data export functionality

**Files to Create**:
- `Sources/Ham/CoreDataStack.swift`
- `Sources/Ham/UsageRecord+CoreDataClass.swift`
- `Sources/Ham/UsageAnalytics.swift`
- `Sources/Ham/DataMigration.swift`
- `Ham.xcdatamodeld` (Core Data model)

**Files to Modify**:
- `Sources/Ham/APIMonitor.swift`: Store to Core Data
- `Package.swift`: Add Core Data dependency

**Timeline**: 2 weeks
**Priority**: Medium-High

### 3.2 Advanced Menu Bar Statistics

**Current State**: Simple "Tokens Today" display
**Target State**: Rich statistics in menu dropdown

**Implementation**:
```swift
// Enhanced menu with sub-menus
├── Tokens Today: 1,247
├── This Week: 8,923
├── This Month: 24,567
├── ▶ By Provider
│   ├── Anthropic: 45%
│   ├── OpenAI: 35%
│   └── Google AI: 20%
├── ▶ Usage Trends
│   ├── Today vs Yesterday: +12%
│   ├── This Week vs Last: -3%
│   └── Predicted Monthly: ~28K
└── View Detailed Stats...
```

**Files to Modify**:
- `Sources/Ham/MenuBarManager.swift`: Enhanced menu creation

**Timeline**: 1 week
**Priority**: Medium

## 💰 Phase 4: Cost Tracking & Budget Management (v1.4)

### 4.1 Token Cost Calculations

**Implementation**:
```swift
// Pricing data structure
struct APIpricing {
    let provider: APIProvider
    let model: String
    let inputTokenCost: Decimal  // per 1K tokens
    let outputTokenCost: Decimal
    let lastUpdated: Date
}

// Cost calculator
class CostCalculator {
    func calculateDailyCost(usage: [UsageRecord]) -> Decimal
    func getMonthlyProjection() -> CostProjection
    func getCostByProvider() -> [ProviderCost]
}
```

**Files to Create**:
- `Sources/Ham/CostCalculator.swift`
- `Sources/Ham/PricingData.swift`
- `Resources/api_pricing.json`

**Timeline**: 1 week
**Priority**: High

### 4.2 Budget Alerts & Notifications

**Implementation**:
- Daily/weekly/monthly budget thresholds
- Native macOS notifications for budget warnings
- Visual indicators in menu bar when approaching limits

**Files to Create**:
- `Sources/Ham/BudgetManager.swift`
- `Sources/Ham/NotificationManager.swift`

**Timeline**: 1 week
**Priority**: Medium

## 📱 Phase 5: Advanced UI & User Experience (v2.0)

### 5.1 Detailed Statistics Window

**Current State**: Basic settings window only
**Target State**: Rich statistics dashboard with charts

**Technical Approach**:
- SwiftUI-based statistics window
- Charts framework for visualizations
- Export functionality (CSV, JSON)

**Features**:
- Usage over time line charts
- Provider breakdown pie charts
- Cost analysis bar charts
- Model usage distribution
- Peak usage time analysis

**Implementation**:
```swift
// New statistics window
struct StatisticsWindow: View {
    @StateObject private var analytics = UsageAnalytics()
    
    var body: some View {
        TabView {
            UsageChartsView()
                .tabItem { Label("Usage", systemImage: "chart.line.uptrend.xyaxis") }
            
            CostAnalysisView()
                .tabItem { Label("Costs", systemImage: "dollarsign.circle") }
            
            TrendsView()
                .tabItem { Label("Trends", systemImage: "calendar") }
        }
    }
}
```

**Files to Create**:
- `Sources/Ham/StatisticsWindow/`
  - `StatisticsWindow.swift`
  - `UsageChartsView.swift`
  - `CostAnalysisView.swift`
  - `TrendsView.swift`
  - `ExportManager.swift`

**Dependencies**:
- Swift Charts framework (iOS 16+/macOS 13+)

**Timeline**: 2-3 weeks
**Priority**: Medium

### 5.2 Customization & Themes

**Features**:
- Custom hamster themes (different animals, colors)
- Animation speed sensitivity adjustment
- Notification preferences
- Menu bar appearance options

**Files to Create**:
- `Sources/Ham/ThemeManager.swift`
- `Sources/Ham/CustomizationView.swift`
- `Resources/Themes/`

**Timeline**: 1-2 weeks
**Priority**: Low

## 🔧 Phase 6: Performance & Polish (v2.1)

### 6.1 Performance Optimizations

**Improvements**:
- Reduce memory footprint of animation system
- Optimize Core Data queries with proper indexing
- Background queue for API calls
- Intelligent polling (faster when usage is high)

**Files to Modify**:
- All core components for performance profiling
- Add performance monitoring utilities

**Timeline**: 1 week
**Priority**: Medium

### 6.2 Error Handling & Reliability

**Improvements**:
- Comprehensive error recovery
- Network connectivity handling
- API rate limiting respect
- Corrupted data recovery

**Files to Create**:
- `Sources/Ham/ErrorRecovery.swift`
- `Sources/Ham/NetworkMonitor.swift`

**Timeline**: 1 week
**Priority**: High

## 📦 Implementation Timeline

### Immediate (Next 2-4 weeks)
1. Real hamster sprites (1.1.1)
2. OpenAI API integration (2.1)
3. Cost calculations (4.1)

### Short-term (1-2 months)
1. Historical tracking database (3.1)
2. Enhanced menu statistics (3.2)
3. Budget alerts (4.2)

### Medium-term (2-4 months)
1. Advanced statistics window (5.1)
2. Performance optimizations (6.1)
3. Enhanced error handling (6.2)

### Long-term (4+ months)
1. Customization & themes (5.2)
2. Advanced animation transitions (1.2)

## 🎯 Success Metrics

- **User Engagement**: Menu bar click-through rates
- **Accuracy**: API usage tracking precision vs actual billing
- **Performance**: Memory usage < 50MB, CPU usage < 1%
- **Reliability**: Uptime > 99.9%, error recovery success rate
- **User Satisfaction**: GitHub stars, issue resolution time

## 📋 Technical Considerations

### Dependencies
- **Core Data**: For historical tracking
- **Charts**: For visualization (macOS 13+ requirement)
- **Network**: Enhanced URLSession with retry logic
- **Security**: Keychain access for API keys

### Compatibility
- **macOS**: Maintain 13.0+ requirement
- **Architecture**: Support Intel and Apple Silicon
- **Performance**: Optimize for low-power usage

### Distribution
- **Code Signing**: Prepare for App Store or notarization
- **Updates**: Implement auto-update mechanism
- **Licensing**: Maintain open-source Apache 2.0

---

This roadmap provides a clear path for evolving Ham from a basic token monitor to a comprehensive LLM usage analytics platform while maintaining its core simplicity and performance characteristics.