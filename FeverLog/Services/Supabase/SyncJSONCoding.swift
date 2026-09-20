import Foundation

/// Shared JSON coding for every remote sync payload. `.iso8601` is required
/// explicitly — Foundation's default `JSONEncoder`/`JSONDecoder` encode
/// `Date` as a raw double timestamp, which PostgREST does not accept for
/// `timestamptz` columns.
enum SyncJSONCoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Postgres `date` columns (birthday, effective_date) store no time
    /// component; encoding the full timestamp would work but is needlessly
    /// timezone-sensitive, so these are sent as plain `yyyy-MM-dd` strings.
    static func dateOnlyString(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
