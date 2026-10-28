import Foundation
import Testing
@testable import TodoApp

struct TodoListArrangerTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func make(
        _ title: String,
        notes: String = "",
        dueInDays: Int? = nil,
        priority: Priority = .none,
        createdMinutesAgo: Double = 0,
        completed: Bool = false
    ) -> Todo {
        Todo(
            title: title,
            notes: notes,
            isCompleted: completed,
            dueDate: dueInDays.map { base.addingTimeInterval(Double($0) * 86_400) },
            priority: priority,
            createdAt: base.addingTimeInterval(-createdMinutesAgo * 60)
        )
    }

    private func titles(_ todos: [Todo]) -> [String] {
        todos.map(\.title)
    }

    @Test func filterSeparatesActiveAndCompleted() {
        let todos = [make("A"), make("B", completed: true), make("C")]

        let active = TodoListArranger.arrange(todos, filter: .active, sortOrder: .createdAt, searchText: "")
        let completed = TodoListArranger.arrange(todos, filter: .completed, sortOrder: .createdAt, searchText: "")
        let all = TodoListArranger.arrange(todos, filter: .all, sortOrder: .createdAt, searchText: "")

        #expect(Set(titles(active)) == ["A", "C"])
        #expect(titles(completed) == ["B"])
        #expect(all.count == 3)
    }

    @Test func searchMatchesTitleAndNotesIgnoringCase() {
        let todos = [make("Buy Milk"), make("買い物", notes: "milk と卵"), make("ジム")]

        let result = TodoListArranger.arrange(todos, filter: .all, sortOrder: .createdAt, searchText: "  MILK ")
        #expect(Set(titles(result)) == ["Buy Milk", "買い物"])

        let blank = TodoListArranger.arrange(todos, filter: .all, sortOrder: .createdAt, searchText: "   ")
        #expect(blank.count == 3)
    }

    @Test func incompleteTodosComeFirstThenNewest() {
        let todos = [
            make("old", createdMinutesAgo: 30),
            make("done-new", createdMinutesAgo: 0, completed: true),
            make("new", createdMinutesAgo: 10),
        ]

        let result = TodoListArranger.arrange(todos, filter: .all, sortOrder: .createdAt, searchText: "")
        #expect(titles(result) == ["new", "old", "done-new"])
    }

    @Test func dueDateSortPutsEarlierFirstAndUndatedLast() {
        let todos = [make("none"), make("later", dueInDays: 5), make("sooner", dueInDays: 1)]

        let result = TodoListArranger.arrange(todos, filter: .all, sortOrder: .dueDate, searchText: "")
        #expect(titles(result) == ["sooner", "later", "none"])
    }

    @Test func prioritySortPutsHighFirstAndBreaksTiesByNewest() {
        let todos = [
            make("low", priority: .low),
            make("high-old", priority: .high, createdMinutesAgo: 20),
            make("high-new", priority: .high, createdMinutesAgo: 5),
            make("none"),
        ]

        let result = TodoListArranger.arrange(todos, filter: .all, sortOrder: .priority, searchText: "")
        #expect(titles(result) == ["high-new", "high-old", "low", "none"])
    }
}
