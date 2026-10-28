import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String = ""
    var notes: String = ""
    var isCompleted: Bool = false
    /// 期限。時刻を指定しない場合はその日の 0:00 を保存する。
    var dueDate: Date?
    /// `dueDate` の時刻部分が有効かどうか。
    var hasDueTime: Bool = false
    /// `Priority` の rawValue。SwiftData で扱いやすいよう Int で保存する。
    var priorityRawValue: Int = Priority.none.rawValue
    var createdAt: Date = Date.now
    var completedAt: Date?

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        hasDueTime: Bool = false,
        priority: Priority = .none,
        createdAt: Date = .now
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasDueTime = dueDate != nil && hasDueTime
        self.priorityRawValue = priority.rawValue
        self.createdAt = createdAt
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRawValue) ?? .none }
        set { priorityRawValue = newValue.rawValue }
    }

    func toggleCompletion(now: Date = .now) {
        isCompleted.toggle()
        completedAt = isCompleted ? now : nil
    }

    /// 未完了で、時刻指定ありなら期限時刻を過ぎたとき、日付のみなら期限日が今日より前のときに期限切れ。
    func isOverdue(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard !isCompleted, let dueDate else { return false }
        return hasDueTime ? dueDate <= now : dueDate < calendar.startOfDay(for: now)
    }

    /// `day` の日付と `time` の時・分を組み合わせた期限を作る。`time` が nil ならその日の 0:00。
    static func makeDueDate(day: Date, time: Date?, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        guard let time else { return startOfDay }
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: startOfDay
        ) ?? startOfDay
    }

    func isDueToday(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let dueDate else { return false }
        return calendar.isDate(dueDate, inSameDayAs: now)
    }
}
