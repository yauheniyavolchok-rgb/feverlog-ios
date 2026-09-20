import Foundation
import Testing
@testable import FeverLog

@Suite("SyncRetryPolicy")
struct SyncRetryPolicyTests {
    @Test("delay doubles with each attempt, exponential backoff starting at 2s")
    func delayDoublesEachAttempt() {
        #expect(SyncRetryPolicy.delay(forAttempt: 0) == 2)
        #expect(SyncRetryPolicy.delay(forAttempt: 1) == 4)
        #expect(SyncRetryPolicy.delay(forAttempt: 2) == 8)
        #expect(SyncRetryPolicy.delay(forAttempt: 3) == 16)
    }

    @Test("delay is bounded and never exceeds the cap")
    func delayIsCapped() {
        #expect(SyncRetryPolicy.delay(forAttempt: 20) == 300)
        #expect(SyncRetryPolicy.delay(forAttempt: 1000) == 300)
    }

    @Test("shouldRetry is true below the attempt ceiling and false at/above it")
    func shouldRetryRespectsMaxAttempts() {
        #expect(SyncRetryPolicy.shouldRetry(retryCount: 0))
        #expect(SyncRetryPolicy.shouldRetry(retryCount: SyncRetryPolicy.maxAttempts - 1))
        #expect(!SyncRetryPolicy.shouldRetry(retryCount: SyncRetryPolicy.maxAttempts))
        #expect(!SyncRetryPolicy.shouldRetry(retryCount: SyncRetryPolicy.maxAttempts + 5))
    }

    @Test("nextRetryDate adds the computed delay to the reference date")
    func nextRetryDateAddsDelay() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let next = SyncRetryPolicy.nextRetryDate(forAttempt: 1, from: reference)
        #expect(next == reference.addingTimeInterval(SyncRetryPolicy.delay(forAttempt: 1)))
    }
}
