import Foundation
import SwiftData
import Testing
@testable import TodoApp

@MainActor
struct TodoListArrangerTests {
    private let container: ModelContainer
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        container = try ModelContainer(
            for: TodoItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func make(
        _ title: String,
        notes: String = "",
        dueInDays: Int? = nil,
        priority: Priority = .none,
        createdMinutesAgo: Double = 0,
        completed: Bool = false
    ) -> TodoItem {
        let item = TodoItem(
            title: title,
            notes: notes,
            dueDate: dueInDays.map { base.addingTimeInterval(Double($0) * 86_400) },
            priority: priority,
            createdAt: base.addingTimeInterval(-createdMinutesAgo * 60)
        )
        if completed {
            item.toggleCompletion(now: base)
        }
        container.mainContext.insert(item)
        return item
    }

    private func titles(_ items: [TodoItem]) -> [String] {
        items.map(\.title)
    }

    @Test func filterSeparatesActiveAndCompleted() {
        let items = [make("A"), make("B", completed: true), make("C")]

        let active = TodoListArranger.arrange(items, filter: .active, sortOrder: .createdAt, searchText: "")
        let completed = TodoListArranger.arrange(items, filter: .completed, sortOrder: .createdAt, searchText: "")
        let all = TodoListArranger.arrange(items, filter: .all, sortOrder: .createdAt, searchText: "")

        #expect(Set(titles(active)) == ["A", "C"])
        #expect(titles(completed) == ["B"])
        #expect(all.count == 3)
    }

    @Test func searchMatchesTitleAndNotesIgnoringCase() {
        let items = [
            make("Buy Milk"),
            make("買い物", notes: "milk と卵"),
            make("ジム"),
        ]

        let result = TodoListArranger.arrange(items, filter: .all, sortOrder: .createdAt, searchText: "  MILK ")
        #expect(Set(titles(result)) == ["Buy Milk", "買い物"])

        let blank = TodoListArranger.arrange(items, filter: .all, sortOrder: .createdAt, searchText: "   ")
        #expect(blank.count == 3)
    }

    @Test func incompleteItemsComeFirstThenNewest() {
        let items = [
            make("old", createdMinutesAgo: 30),
            make("done-new", createdMinutesAgo: 0, completed: true),
            make("new", createdMinutesAgo: 10),
        ]

        let result = TodoListArranger.arrange(items, filter: .all, sortOrder: .createdAt, searchText: "")
        #expect(titles(result) == ["new", "old", "done-new"])
    }

    @Test func dueDateSortPutsEarlierFirstAndUndatedLast() {
        let items = [
            make("none", createdMinutesAgo: 0),
            make("later", dueInDays: 5),
            make("sooner", dueInDays: 1),
        ]

        let result = TodoListArranger.arrange(items, filter: .all, sortOrder: .dueDate, searchText: "")
        #expect(titles(result) == ["sooner", "later", "none"])
    }

    @Test func prioritySortPutsHighFirstAndBreaksTiesByNewest() {
        let items = [
            make("low", priority: .low),
            make("high-old", priority: .high, createdMinutesAgo: 20),
            make("high-new", priority: .high, createdMinutesAgo: 5),
            make("none"),
        ]

        let result = TodoListArranger.arrange(items, filter: .all, sortOrder: .priority, searchText: "")
        #expect(titles(result) == ["high-new", "high-old", "low", "none"])
    }
}

@MainActor
struct TodoItemTests {
    private let container: ModelContainer
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    init() throws {
        container = try ModelContainer(
            for: TodoItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func toggleCompletionRecordsAndClearsCompletedAt() {
        let item = TodoItem(title: "A")
        container.mainContext.insert(item)
        let now = date(2026, 10, 28, hour: 9)

        item.toggleCompletion(now: now)
        #expect(item.isCompleted)
        #expect(item.completedAt == now)

        item.toggleCompletion(now: now)
        #expect(!item.isCompleted)
        #expect(item.completedAt == nil)
    }

    @Test func overdueOnlyWhenIncompleteAndBeforeToday() {
        let now = date(2026, 10, 28, hour: 15)
        let yesterday = TodoItem(title: "昨日", dueDate: date(2026, 10, 27))
        let today = TodoItem(title: "今日", dueDate: date(2026, 10, 28))
        let noDate = TodoItem(title: "期限なし")
        let doneYesterday = TodoItem(title: "完了済み", dueDate: date(2026, 10, 27))
        [yesterday, today, noDate, doneYesterday].forEach { container.mainContext.insert($0) }
        doneYesterday.toggleCompletion(now: now)

        #expect(yesterday.isOverdue(now: now, calendar: calendar))
        #expect(!today.isOverdue(now: now, calendar: calendar))
        #expect(today.isDueToday(now: now, calendar: calendar))
        #expect(!noDate.isOverdue(now: now, calendar: calendar))
        #expect(!doneYesterday.isOverdue(now: now, calendar: calendar))
    }

    @Test func timedDueDateIsOverdueOnceTimePasses() {
        let item = TodoItem(title: "会議", dueDate: date(2026, 10, 28, hour: 14), hasDueTime: true)
        container.mainContext.insert(item)

        #expect(!item.isOverdue(now: date(2026, 10, 28, hour: 13), calendar: calendar))
        #expect(item.isOverdue(now: date(2026, 10, 28, hour: 15), calendar: calendar))
        #expect(item.isDueToday(now: date(2026, 10, 28, hour: 15), calendar: calendar))
    }

    @Test func dateOnlyDueDateIsNotOverdueDuringTheDay() {
        let item = TodoItem(title: "買い物", dueDate: date(2026, 10, 28))
        container.mainContext.insert(item)

        #expect(!item.isOverdue(now: date(2026, 10, 28, hour: 23), calendar: calendar))
        #expect(item.isOverdue(now: date(2026, 10, 29, hour: 0), calendar: calendar))
    }

    @Test func makeDueDateCombinesDayAndTime() {
        let day = date(2026, 10, 28, hour: 9)
        let time = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: 18, minute: 30, second: 45))!

        #expect(TodoItem.makeDueDate(day: day, time: time, calendar: calendar)
            == calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 18, minute: 30)))
        #expect(TodoItem.makeDueDate(day: day, time: nil, calendar: calendar) == date(2026, 10, 28))
    }

    @Test func hasDueTimeIsFalseWithoutDueDate() {
        let item = TodoItem(title: "A", dueDate: nil, hasDueTime: true)
        container.mainContext.insert(item)
        #expect(!item.hasDueTime)
    }

    @Test func priorityFallsBackToNoneForUnknownRawValue() {
        let item = TodoItem(title: "A", priority: .high)
        container.mainContext.insert(item)
        #expect(item.priority == .high)

        item.priorityRawValue = 99
        #expect(item.priority == .none)
    }
}
