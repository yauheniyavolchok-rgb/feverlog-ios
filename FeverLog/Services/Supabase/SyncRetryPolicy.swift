import Foundation

/// Deterministic, pure bounded-backoff calculation for sync queue retries.
/// No jitter is added deliberately, so behavior is exactly reproducible in
/// tests; a production tune-up could add jitter without changing the
/// public shape of this type.
enum SyncRetryPolicy {
    static let maxAttempts = 6

    /// Whether a queue item that has already failed `retryCount` times
    /// should still be retried at all.
    static func shouldRetry(retryCount: Int) -> Bool {
        retryCount < maxAttempts
    }

    /// Exponential backoff starting at 2s, doubling each attempt, capped
    /// at 5 minutes: 2s, 4s, 8s, 16s, 32s, capped thereafter.
    static func delay(forAttempt retryCount: Int) -> TimeInterval {
        let cap: TimeInterval = 300
        let raw = pow(2.0, Double(retryCount + 1))
        return min(raw, cap)
    }

    static func nextRetryDate(forAttempt retryCount: Int, from referenceDate: Date = .now) -> Date {
        referenceDate.addingTimeInterval(delay(forAttempt: retryCount))
    }
}
