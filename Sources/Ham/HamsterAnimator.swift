import Cocoa
import Foundation

enum HamsterState {
    case sleeping  // 0 tokens/min - completely still
    case idle  // Very low usage - occasional movement
    case walking  // 1-10 tokens/min
    case running  // 11-50 tokens/min
    case sprinting  // 50+ tokens/min
}

@MainActor
class HamsterAnimator {
    private var animationTimer: Timer?
    private var currentFrameIndex: Int = 0
    private var animationSpeed: Double = 1.0  // frames per second
    private var currentState: HamsterState = .sleeping
    private let hamsterFrames: [NSImage]

    var currentFrame: NSImage {
        return hamsterFrames[currentFrameIndex]
    }

    init() {
        hamsterFrames = HamsterAnimator.createHamsterFrames()
        print("🐹 HamsterAnimator initialized with \(hamsterFrames.count) frames")
    }

    func startAnimation() {
        stopAnimation()
        updateAnimationTimer()
    }

    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func setAnimationSpeed(_ speed: Double) {
        animationSpeed = max(0.1, min(speed, 5.0))  // Clamp between 0.1 and 5.0
        updateAnimationTimer()
    }

    func updateForTokenUsage(_ tokensPerMinute: Double) {
        let newState: HamsterState
        let newSpeed: Double

        switch tokensPerMinute {
        case 0:
            newState = .sleeping
            newSpeed = 0.0  // Completely still when no usage
        case 0.1...0.9:
            newState = .idle
            newSpeed = 0.3  // Very slow occasional movement
        case 1...10:
            newState = .walking
            newSpeed = 1.5  // Moderate speed
        case 11...50:
            newState = .running
            newSpeed = 3.0  // Fast animation
        default:
            newState = .sprinting
            newSpeed = 5.0  // Maximum speed
        }

        if newState != currentState {
            currentState = newState
            print("🐹 Hamster state changed to: \(newState), speed: \(newSpeed)")
        }

        if newState == .sleeping {
            stopAnimation()
            currentFrameIndex = 0  // Show first frame (sleeping hamster)
        } else {
            setAnimationSpeed(newSpeed)
        }
    }

    private func updateAnimationTimer() {
        stopAnimation()

        let interval = 1.0 / animationSpeed
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.nextFrame()
            }
        }
    }

    private func nextFrame() {
        currentFrameIndex = (currentFrameIndex + 1) % hamsterFrames.count
    }

    private static func createHamsterFrames() -> [NSImage] {
        // Create animated hamster frames from sleeping to sprinting
        let frameData: [(String, NSColor)] = [
            ("😴", .systemGray),  // Frame 0: Sleeping (for zero token usage)
            ("🐹", .systemOrange),  // Frame 1: Awake/Standing
            ("🚶‍♂️", .systemOrange),  // Frame 2: Walking step 1
            ("🐹", .systemOrange),  // Frame 3: Standing
            ("🚶‍♀️", .systemOrange),  // Frame 4: Walking step 2
            ("🏃‍♂️", .systemOrange),  // Frame 5: Running
            ("💨", .systemBlue),  // Frame 6: Speed burst
            ("🏃‍♀️", .systemRed),  // Frame 7: Sprinting
            ("⚡", .systemYellow),  // Frame 8: Lightning speed
        ]

        return frameData.map { (emoji, color) in
            let image = NSImage(size: NSSize(width: 20, height: 18))
            image.lockFocus()

            // Clear background
            NSColor.clear.set()
            NSRect(origin: .zero, size: image.size).fill()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: color,
            ]

            let rect = NSRect(x: 2, y: 2, width: 16, height: 14)
            emoji.draw(in: rect, withAttributes: attributes)

            image.unlockFocus()
            image.isTemplate = false  // Don't use template mode
            return image
        }
    }
}
