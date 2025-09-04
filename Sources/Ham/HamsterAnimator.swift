import Cocoa
import Foundation

@MainActor
class HamsterAnimator {
    private var animationTimer: Timer?
    private var currentFrameIndex: Int = 0
    private var animationSpeed: Double = 1.0  // frames per second
    private let hamsterFrames: [NSImage]

    var currentFrame: NSImage {
        return hamsterFrames[currentFrameIndex]
    }

    init() {
        // Create simple hamster frames (we'll use text-based for now, replace with actual images later)
        hamsterFrames = HamsterAnimator.createHamsterFrames()
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
        // Create simple text-based hamster animation frames
        let frames = ["🐹", "🐹", "🐹", "🐹"]  // We'll replace with actual sprite images

        return frames.map { emoji in
            let image = NSImage(size: NSSize(width: 18, height: 18))
            image.lockFocus()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16),
                .foregroundColor: NSColor.controlTextColor,
            ]

            let rect = NSRect(x: 1, y: 1, width: 16, height: 16)
            emoji.draw(in: rect, withAttributes: attributes)

            image.unlockFocus()
            return image
        }
    }
}
