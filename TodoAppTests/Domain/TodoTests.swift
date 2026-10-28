import Foundation
import Testing
@testable import TodoApp

struct TodoTests {
    private let calendar = TestCalendar.tokyo
    private func date(_ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        TestCalendar.date(2026, 10, day, hour: hour, minute: minute)
    }

    @Test func toggleCompletionRecordsAndClearsCompletedAt() {
        var todo = Todo(title: "A")
        let now = date(28, hour: 9)

        todo.toggleCompletion(now: now)
        #expect(todo.isCompleted)
        #expect(todo.completedAt == now)

        todo.toggleCompletion(now: now)
        #expect(!todo.isCompleted)
        #expect(todo.completedAt == nil)
    }

    @Test func dateOnlyDueDateIsOverdueFromNextDay() {
        let now = date(28, hour: 15)
        let yesterday = Todo(title: "昨日", dueDate: date(27))
        let today = Todo(title: "今日", dueDate: date(28))

        #expect(yesterday.isOverdue(now: now, calendar: calendar))
        #expect(!today.isOverdue(now: date(28, hour: 23), calendar: calendar))
        #expect(today.isOverdue(now: date(29), calendar: calendar))
        #expect(today.isDueToday(now: now, calendar: calendar))
    }

    @Test func timedDueDateIsOverdueOnceTimePasses() {
        let todo = Todo(title: "会議", dueDate: date(28, hour: 14), hasDueTime: true)

        #expect(!todo.isOverdue(now: date(28, hour: 13), calendar: calendar))
        #expect(todo.isOverdue(now: date(28, hour: 15), calendar: calendar))
    }

    @Test func completedOrUndatedTodoIsNeverOverdue() {
        let now = date(28, hour: 15)
        let done = Todo(title: "完了", isCompleted: true, dueDate: date(27))
        let undated = Todo(title: "期限なし")

        #expect(!done.isOverdue(now: now, calendar: calendar))
        #expect(!undated.isOverdue(now: now, calendar: calendar))
    }

    @Test func hasDueTimeIsFalseWithoutDueDate() {
        #expect(!Todo(title: "A", dueDate: nil, hasDueTime: true).hasDueTime)
    }

    @Test func makeDueDateCombinesDayAndTime() {
        let time = TestCalendar.date(2000, 1, 1, hour: 18, minute: 30).addingTimeInterval(45)

        #expect(Todo.makeDueDate(day: date(28, hour: 9), time: time, calendar: calendar) == date(28, hour: 18, minute: 30))
        #expect(Todo.makeDueDate(day: date(28, hour: 9), time: nil, calendar: calendar) == date(28))
    }
}
