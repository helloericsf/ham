import Foundation

/// Real-time usage estimator that tracks token usage in 3-minute bins
/// and provides smooth EMA-based animation rates
@MainActor
class RealTimeUsageEstimator {

    // MARK: - Configuration
    private let binWidthMinutes: Double = 3.0
    private let totalBins: Int = 20  // 60 minutes / 3 minutes = 20 bins
    private let smoothingTauSeconds: Double = 180.0  // 3 minutes
    private let decayTauSeconds: Double = 480.0  // 8 minutes
    private let maxInstantaneousRate: Double = 500.0  // tokens/min cap for spike protection

    // MARK: - State
    private var lastSnapshot: UsageSnapshot?
    private var emaRate: Double = 0.0
    private var ringBuffer: [Int] = Array(repeating: 0, count: 20)
    private var currentBinIndex: Int = 0
    private var binStartTime: Date = Date()

    // MARK: - Data Structures

    private struct UsageSnapshot {
        let timestamp: Date
        let latestHourlyBucketStart: TimeInterval
        let latestHourlyValue: Int

        init(timestamp: Date, hourlyBreakdown: [Int], hourlyBucketStarts: [TimeInterval]) {
            self.timestamp = timestamp

            // Find the latest hourly bucket
            if let maxIndex = hourlyBucketStarts.indices.max(by: {
                hourlyBucketStarts[$0] < hourlyBucketStarts[$1]
            }) {
                self.latestHourlyBucketStart = hourlyBucketStarts[maxIndex]
                self.latestHourlyValue = hourlyBreakdown[maxIndex]
            } else {
                self.latestHourlyBucketStart = 0
                self.latestHourlyValue = 0
            }
        }
    }

    struct RealTimeEstimates {
        let last3MinTokens: Int
        let last15MinTokens: Int
        let emaRateTokensPerMinute: Double
        let timestamp: Date
    }

    // MARK: - Public Interface

    init() {
        binStartTime = alignToBinBoundary(Date())
        print("🕐 RealTimeUsageEstimator initialized with 3-minute bins")
    }

    /// Ingest new usage data and update estimates
    func ingest(_ usage: DetailedTokenUsage, hourlyBucketStarts: [TimeInterval]) {
        let now = Date()

        // Create new snapshot
        let newSnapshot = UsageSnapshot(
            timestamp: now,
            hourlyBreakdown: usage.hourlyBreakdown,
            hourlyBucketStarts: hourlyBucketStarts
        )

        // Decay EMA for time elapsed since last update
        if let lastSnapshot = lastSnapshot {
            let dtSeconds = now.timeIntervalSince(lastSnapshot.timestamp)
            if dtSeconds > 0 {
                let decayFactor = exp(-dtSeconds / decayTauSeconds)
                emaRate *= decayFactor
            }
        }

        // Calculate delta and update EMA
        if let lastSnapshot = lastSnapshot {
            let delta = calculateTokenDelta(from: lastSnapshot, to: newSnapshot)
            updateEMA(with: delta, timeDelta: now.timeIntervalSince(lastSnapshot.timestamp))
            updateRingBuffer(with: delta, at: now)

            print("🕐 Token delta: \(delta), EMA rate: \(String(format: "%.2f", emaRate)) tpm")
        } else {
            // First snapshot - initialize ring buffer
            updateRingBuffer(with: 0, at: now)
        }

        self.lastSnapshot = newSnapshot
    }

    /// Get current real-time estimates
    func getEstimates() -> RealTimeEstimates {
        let now = Date()

        // Decay EMA for elapsed time since last ingest
        if let lastSnapshot = lastSnapshot {
            let dtSeconds = now.timeIntervalSince(lastSnapshot.timestamp)
            if dtSeconds > 0 {
                let decayFactor = exp(-dtSeconds / decayTauSeconds)
                let currentEMA = emaRate * decayFactor

                return RealTimeEstimates(
                    last3MinTokens: getCurrentBinTokens(),
                    last15MinTokens: getLast15MinTokens(),
                    emaRateTokensPerMinute: currentEMA,
                    timestamp: now
                )
            }
        }

        return RealTimeEstimates(
            last3MinTokens: getCurrentBinTokens(),
            last15MinTokens: getLast15MinTokens(),
            emaRateTokensPerMinute: emaRate,
            timestamp: now
        )
    }

    /// Get polling interval recommendation based on current activity
    func getRecommendedPollingInterval() -> TimeInterval {
        let estimates = getEstimates()
        let rate = estimates.emaRateTokensPerMinute

        let baseInterval: TimeInterval
        switch rate {
        case 0..<0.1:
            baseInterval = 15 * 60  // 15 minutes
        case 0.1..<1.0:
            baseInterval = 7 * 60  // 7 minutes
        case 1.0..<10.0:
            baseInterval = 3 * 60  // 3 minutes
        case 10.0..<50.0:
            baseInterval = 2 * 60  // 2 minutes
        default:
            baseInterval = 90  // 90 seconds (minimum)
        }

        // Add ±10% jitter
        let jitter = Double.random(in: 0.9...1.1)
        let interval = max(90.0, baseInterval * jitter)  // Never below 90 seconds

        return interval
    }

    // MARK: - Private Implementation

    private func calculateTokenDelta(from oldSnapshot: UsageSnapshot, to newSnapshot: UsageSnapshot)
        -> Int
    {
        // Same hour bucket
        if oldSnapshot.latestHourlyBucketStart == newSnapshot.latestHourlyBucketStart {
            return max(0, newSnapshot.latestHourlyValue - oldSnapshot.latestHourlyValue)
        }

        // Hour boundary crossed - need to be more careful
        // This is a simplified approach; in production we'd want to handle
        // the case where multiple hours have passed more robustly
        let delta = max(0, newSnapshot.latestHourlyValue)
        return min(delta, Int(maxInstantaneousRate * 5))  // Cap to 5 minutes of max rate
    }

    private func updateEMA(with tokenDelta: Int, timeDelta: TimeInterval) {
        guard timeDelta > 0 else { return }

        let dtMinutes = max(0.1, timeDelta / 60.0)
        let instantaneousRate = min(maxInstantaneousRate, Double(tokenDelta) / dtMinutes)

        let alpha = 1.0 - exp(-timeDelta / smoothingTauSeconds)
        emaRate = alpha * instantaneousRate + (1.0 - alpha) * emaRate
    }

    private func updateRingBuffer(with tokenDelta: Int, at timestamp: Date) {
        let alignedTime = alignToBinBoundary(timestamp)

        // Advance bins if we've crossed boundaries
        let binsPassed = Int(alignedTime.timeIntervalSince(binStartTime) / (binWidthMinutes * 60))

        if binsPassed > 0 {
            // Clear any bins we've skipped
            for _ in 0..<min(binsPassed, totalBins) {
                currentBinIndex = (currentBinIndex + 1) % totalBins
                ringBuffer[currentBinIndex] = 0
            }
            binStartTime = alignedTime
        }

        // Add tokens to current bin
        ringBuffer[currentBinIndex] += tokenDelta
    }

    private func alignToBinBoundary(_ date: Date) -> Date {
        let timeInterval = date.timeIntervalSince1970
        let binWidthSeconds = binWidthMinutes * 60
        let alignedInterval = floor(timeInterval / binWidthSeconds) * binWidthSeconds
        return Date(timeIntervalSince1970: alignedInterval)
    }

    private func getCurrentBinTokens() -> Int {
        return ringBuffer[currentBinIndex]
    }

    private func getLast15MinTokens() -> Int {
        // Sum last 5 bins (5 * 3 minutes = 15 minutes)
        var total = 0
        for i in 0..<5 {
            let index = (currentBinIndex - i + totalBins) % totalBins
            total += ringBuffer[index]
        }
        return total
    }
}

// MARK: - Extensions

extension RealTimeUsageEstimator.RealTimeEstimates: CustomStringConvertible {
    var description: String {
        return
            "RealTimeEstimates(last3min: \(last3MinTokens), last15min: \(last15MinTokens), emaRate: \(String(format: "%.2f", emaRateTokensPerMinute)) tpm)"
    }
}
