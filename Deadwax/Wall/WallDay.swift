import Foundation

/// Role: Day edges as Int YYYYMMDD from Calendar.startOfDay. Never a Date dictionary key.
enum WallDay {
    static func key(_ date: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }
}
