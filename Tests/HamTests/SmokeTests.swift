import XCTest

@testable import Ham

final class SmokeTests: XCTestCase {

    func testHamsterAnimatorInitialization() throws {
        let animator = HamsterAnimator()
        XCTAssertNotNil(animator.currentFrame)
    }

    func testDetailedTokenUsageInitialization() throws {
        let usage = DetailedTokenUsage()
        XCTAssertEqual(usage.today, 0)
        XCTAssertEqual(usage.thisWeek, 0)
        XCTAssertEqual(usage.thisMonth, 0)
        XCTAssertTrue(usage.hourlyBreakdown.isEmpty)
    }

    func testRealTimeEstimatorInitialization() throws {
        let estimator = RealTimeUsageEstimator()
        let estimates = estimator.getEstimates()
        XCTAssertEqual(estimates.last3MinTokens, 0)
        XCTAssertEqual(estimates.last15MinTokens, 0)
        XCTAssertEqual(estimates.emaRateTokensPerMinute, 0.0)
    }

    func testPollingIntervalRecommendations() throws {
        let estimator = RealTimeUsageEstimator()
        let interval = estimator.getRecommendedPollingInterval()

        // Should be within reasonable bounds (90 seconds to 15 minutes)
        XCTAssertGreaterThanOrEqual(interval, 90.0)
        XCTAssertLessThanOrEqual(interval, 15 * 60.0)
    }
}
