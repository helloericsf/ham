# 🎨 Sprite Animation Implementation Plan

This document provides a detailed technical plan for replacing Ham's emoji-based animations with real pixel-art hamster sprites.

## 🎯 Objectives

1. **Replace emoji animations** with proper pixel-art hamster sprites
2. **Improve visual quality** with smooth, professional animations
3. **Optimize performance** for menu bar constraints
4. **Support Retina displays** with @2x and @3x assets
5. **Maintain animation state system** while enhancing visual fidelity

## 🎨 Asset Requirements

### Sprite Specifications
- **Base size**: 16x16 pixels (menu bar optimized)
- **Retina support**: @2x (32x32), @3x (48x48)
- **Format**: PNG with transparency
- **Color palette**: Limited palette for consistent style
- **Animation frames**: 4-8 frames per animation cycle

### Animation States & Frame Counts

| State | Description | Frame Count | FPS | Duration |
|-------|------------|-------------|-----|----------|
| `sleeping` | Still hamster, closed eyes | 1-2 | 0.5 | Static/Breathing |
| `idle` | Occasional ear twitch, blink | 4 | 1.0 | 4 seconds |
| `walking` | Steady walking pace | 4 | 2.0 | 2 seconds |
| `running` | Fast running cycle | 6 | 4.0 | 1.5 seconds |
| `sprinting` | Maximum speed with blur | 8 | 6.0 | 1.3 seconds |

### Sprite Sheet Organization
```
Resources/Sprites/
├── hamster_sleeping.png     # 1-2 frames horizontal
├── hamster_idle.png         # 4 frames horizontal  
├── hamster_walking.png      # 4 frames horizontal
├── hamster_running.png      # 6 frames horizontal
├── hamster_sprinting.png    # 8 frames horizontal
└── @2x/ and @3x/           # Retina variants
```

## 💾 Technical Implementation

### 1. Sprite Sheet Data Structure

```swift
struct SpriteSheet {
    let image: NSImage
    let frameSize: NSSize
    let frameCount: Int
    let frameRate: Double
    
    func getFrame(at index: Int) -> NSImage {
        let frameWidth = frameSize.width
        let frameHeight = frameSize.height
        let x = CGFloat(index) * frameWidth
        
        let rect = NSRect(x: x, y: 0, width: frameWidth, height: frameHeight)
        
        let frameImage = NSImage(size: frameSize)
        frameImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: frameSize), 
                   from: rect, 
                   operation: .copy, 
                   fraction: 1.0)
        frameImage.unlockFocus()
        
        return frameImage
    }
}
```

### 2. Enhanced HamsterAnimator

```swift
@MainActor
class HamsterAnimator {
    // MARK: - Properties
    private var animationTimer: Timer?
    private var currentFrameIndex: Int = 0
    private var currentState: HamsterState = .sleeping
    private var targetState: HamsterState = .sleeping
    private var transitionProgress: Double = 0.0
    private var isTransitioning: Bool = false
    
    // Sprite management
    private let spriteSheets: [HamsterState: SpriteSheet]
    private var currentSpriteSheet: SpriteSheet
    private var preloadedFrames: [HamsterState: [NSImage]] = [:]
    
    // Animation settings
    private var animationSpeed: Double = 1.0
    private let baseFrameRate: Double = 2.0 // Base FPS for walking
    
    // MARK: - Initialization
    init() {
        self.spriteSheets = Self.loadSpriteSheets()
        self.currentSpriteSheet = spriteSheets[.sleeping]!
        preloadAllFrames()
        print("🎨 HamsterAnimator initialized with sprite sheets")
    }
    
    // MARK: - Sprite Loading
    private static func loadSpriteSheets() -> [HamsterState: SpriteSheet] {
        var sheets: [HamsterState: SpriteSheet] = [:]
        
        let spriteConfigs: [(HamsterState, String, Int, Double)] = [
            (.sleeping, "hamster_sleeping", 2, 0.5),
            (.idle, "hamster_idle", 4, 1.0),
            (.walking, "hamster_walking", 4, 2.0),
            (.running, "hamster_running", 6, 4.0),
            (.sprinting, "hamster_sprinting", 8, 6.0)
        ]
        
        for (state, filename, frameCount, frameRate) in spriteConfigs {
            if let image = loadSpriteImage(named: filename) {
                sheets[state] = SpriteSheet(
                    image: image,
                    frameSize: NSSize(width: 16, height: 16),
                    frameCount: frameCount,
                    frameRate: frameRate
                )
            }
        }
        
        return sheets
    }
    
    private static func loadSpriteImage(named filename: String) -> NSImage? {
        // Try to load from app bundle first
        if let bundleImage = NSImage(named: filename) {
            return bundleImage
        }
        
        // Try to load from Resources directory
        if let resourcePath = Bundle.main.path(forResource: filename, ofType: "png"),
           let image = NSImage(contentsOfFile: resourcePath) {
            return image
        }
        
        print("⚠️ Could not load sprite: \(filename)")
        return nil
    }
    
    private func preloadAllFrames() {
        for (state, spriteSheet) in spriteSheets {
            var frames: [NSImage] = []
            for i in 0..<spriteSheet.frameCount {
                frames.append(spriteSheet.getFrame(at: i))
            }
            preloadedFrames[state] = frames
        }
        print("🎨 Preloaded \(preloadedFrames.count) animation sets")
    }
}
```

### 3. Animation State Management

```swift
extension HamsterAnimator {
    func updateForTokenUsage(_ tokensPerMinute: Double) {
        let newState = calculateStateFromUsage(tokensPerMinute)
        
        if newState != targetState {
            print("🎨 Transitioning from \(currentState) to \(newState)")
            startTransition(to: newState)
        }
    }
    
    private func calculateStateFromUsage(_ tokensPerMinute: Double) -> HamsterState {
        switch tokensPerMinute {
        case 0:
            return .sleeping
        case 0.1...0.9:
            return .idle
        case 1...10:
            return .walking
        case 11...50:
            return .running
        default:
            return .sprinting
        }
    }
    
    private func startTransition(to newState: HamsterState) {
        guard let newSpriteSheet = spriteSheets[newState] else { return }
        
        targetState = newState
        isTransitioning = true
        transitionProgress = 0.0
        
        // Special case: instant transition to/from sleeping
        if currentState == .sleeping || newState == .sleeping {
            completeTransition()
        } else {
            // Smooth transition for other states
            animateTransition()
        }
    }
    
    private func animateTransition() {
        // Use a brief transition period to ease between states
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isTransitioning else {
                timer.invalidate()
                return
            }
            
            self.transitionProgress += 0.1
            
            if self.transitionProgress >= 0.5 { // 500ms transition
                self.completeTransition()
                timer.invalidate()
            }
        }
    }
    
    private func completeTransition() {
        currentState = targetState
        currentSpriteSheet = spriteSheets[currentState]!
        currentFrameIndex = 0
        isTransitioning = false
        transitionProgress = 0.0
        
        updateAnimationTimer()
    }
}
```

### 4. Frame Rendering & Updates

```swift
extension HamsterAnimator {
    var currentFrame: NSImage {
        guard let frames = preloadedFrames[currentState],
              !frames.isEmpty else {
            // Fallback to generating frame on-demand
            return currentSpriteSheet.getFrame(at: currentFrameIndex)
        }
        
        let safeIndex = min(currentFrameIndex, frames.count - 1)
        return frames[safeIndex]
    }
    
    private func updateAnimationTimer() {
        animationTimer?.invalidate()
        
        // Don't animate if sleeping or no frames
        guard currentState != .sleeping,
              currentSpriteSheet.frameCount > 1 else {
            currentFrameIndex = 0
            return
        }
        
        let frameRate = currentSpriteSheet.frameRate * animationSpeed
        let interval = 1.0 / frameRate
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.nextFrame()
            }
        }
    }
    
    private func nextFrame() {
        guard !isTransitioning else { return }
        
        let frameCount = currentSpriteSheet.frameCount
        currentFrameIndex = (currentFrameIndex + 1) % frameCount
    }
    
    func startAnimation() {
        updateAnimationTimer()
        print("🎨 Started sprite animation for state: \(currentState)")
    }
    
    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        currentFrameIndex = 0
    }
}
```

## 📁 File Structure Changes

### New Files to Create
```
Sources/Ham/Animation/
├── SpriteSheet.swift           # Sprite sheet management
├── HamsterAnimator+Sprites.swift  # Sprite-specific extensions
└── AnimationTransition.swift      # Smooth state transitions

Resources/Sprites/
├── hamster_sleeping.png        # Static/breathing hamster
├── hamster_sleeping@2x.png
├── hamster_sleeping@3x.png
├── hamster_idle.png           # Occasional movement
├── hamster_idle@2x.png
├── hamster_idle@3x.png
├── hamster_walking.png        # Steady walk cycle
├── hamster_walking@2x.png
├── hamster_walking@3x.png
├── hamster_running.png        # Fast run cycle
├── hamster_running@2x.png
├── hamster_running@3x.png
├── hamster_sprinting.png      # Max speed with effects
├── hamster_sprinting@2x.png
└── hamster_sprinting@3x.png
```

### Files to Modify
- `Sources/Ham/HamsterAnimator.swift`: Complete rewrite using sprites
- `Package.swift`: Add resource bundle support if needed
- `Ham.app/Contents/Info.plist`: Update if adding resource bundles

## 🎨 Asset Creation Guidelines

### Design Principles
1. **Consistent style**: Pixel-art aesthetic with limited color palette
2. **Clear silhouette**: Recognizable at 16x16 pixels
3. **Smooth animation**: Proper frame spacing for natural movement
4. **Menu bar friendly**: High contrast, readable on both light/dark menu bars

### Color Palette Suggestions
```
Primary Hamster Colors:
- Body: #D4A574 (light brown)
- Highlights: #F5E6B3 (cream)
- Shadows: #8B4513 (dark brown)
- Eyes: #000000 (black)
- Nose: #FF69B4 (pink)

Background:
- Transparent PNG
- Optional: Subtle shadow for depth
```

### Animation Timing
- **Walking**: Natural pace, foot placement every 0.25s
- **Running**: Faster leg movement, slight body bounce
- **Sprinting**: Motion blur, speed lines, exaggerated poses

## ⚡ Performance Optimizations

### Memory Management
```swift
// Lazy loading for better memory usage
private lazy var spriteCache: NSCache<NSString, NSImage> = {
    let cache = NSCache<NSString, NSImage>()
    cache.countLimit = 50 // Max cached frames
    return cache
}()

// Preload only current and adjacent states
private func preloadAdjacentStates() {
    let statesToPreload = getAdjacentStates(for: currentState)
    for state in statesToPreload {
        if preloadedFrames[state] == nil {
            loadFramesForState(state)
        }
    }
}
```

### Rendering Optimizations
- Cache rendered frames to avoid repeated sprite sheet operations
- Use `NSImage.cacheMode` for better performance
- Implement frame skipping during high CPU usage
- Use background queues for sprite loading

## 🧪 Testing Strategy

### Visual Testing
1. **Frame accuracy**: Verify all frames load correctly
2. **Animation smoothness**: Test transitions between states
3. **Retina rendering**: Ensure crisp display on all screen types
4. **Performance**: Monitor CPU/memory usage during animation

### Automated Tests
```swift
class SpriteAnimationTests: XCTestCase {
    func testSpriteSheetLoading() {
        let animator = HamsterAnimator()
        XCTAssertNotNil(animator.currentFrame)
    }
    
    func testStateTransitions() {
        let animator = HamsterAnimator()
        animator.updateForTokenUsage(50.0)
        // Verify state change to sprinting
    }
    
    func testFrameProgression() {
        // Test that frames advance correctly over time
    }
}
```

## 📋 Implementation Checklist

### Phase 1: Foundation
- [ ] Create sprite sheet data structures
- [ ] Implement basic sprite loading system
- [ ] Test with simple placeholder sprites
- [ ] Verify menu bar rendering

### Phase 2: Animation System
- [ ] Rewrite HamsterAnimator for sprites
- [ ] Implement frame progression logic
- [ ] Add state transition system
- [ ] Test animation smoothness

### Phase 3: Asset Integration
- [ ] Create/source hamster sprite assets
- [ ] Generate @2x and @3x variants
- [ ] Add sprites to app bundle
- [ ] Test on different display types

### Phase 4: Optimization
- [ ] Implement frame caching
- [ ] Add performance monitoring
- [ ] Optimize memory usage
- [ ] Test on older hardware

### Phase 5: Polish
- [ ] Fine-tune animation timing
- [ ] Add transition effects
- [ ] Implement fallback system
- [ ] Comprehensive testing

## 📊 Success Metrics

- **Visual Quality**: Professional appearance in menu bar
- **Performance**: <5MB memory usage, <2% CPU
- **Compatibility**: Works on macOS 13+ Intel and Apple Silicon
- **Reliability**: No animation glitches or crashes
- **User Experience**: Smooth, delightful animations that enhance the app

---

This implementation plan provides a comprehensive roadmap for transforming Ham's animation system from emoji-based to professional pixel-art sprites while maintaining performance and reliability.