import Foundation

/// タイムゾーンを固定した、テスト用のカレンダーと日付生成。
enum TestCalendar {
    static let tokyo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        tokyo.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
