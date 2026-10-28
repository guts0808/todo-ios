import Foundation
import SwiftData
import Testing
@testable import TodoApp

struct SwiftDataTodoRepositoryTests {
    private func makeRepository() throws -> SwiftDataTodoRepository {
        let container = try ModelContainer(
            for: TodoRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataTodoRepository(modelContainer: container)
    }

    @Test func roundTripPreservesAllFields() async throws {
        let repository = try makeRepository()
        let todo = Todo(
            title: "会議",
            notes: "資料を持参",
            isCompleted: true,
            dueDate: TestCalendar.date(2026, 10, 28, hour: 14),
            hasDueTime: true,
            priority: .high,
            createdAt: TestCalendar.date(2026, 10, 1),
            completedAt: TestCalendar.date(2026, 10, 28, hour: 15)
        )

        try await repository.save(todo)

        #expect(try await repository.fetchAll() == [todo])
    }

    @Test func saveUpdatesExistingTodoInsteadOfDuplicating() async throws {
        let repository = try makeRepository()
        var todo = Todo(title: "旧")
        try await repository.save(todo)

        todo.title = "新"
        todo.priority = .low
        try await repository.save(todo)

        #expect(try await repository.fetchAll() == [todo])
    }

    @Test func fetchAllReturnsNewestFirst() async throws {
        let repository = try makeRepository()
        let old = Todo(title: "old", createdAt: TestCalendar.date(2026, 10, 1))
        let new = Todo(title: "new", createdAt: TestCalendar.date(2026, 10, 2))
        try await repository.save(old)
        try await repository.save(new)

        #expect(try await repository.fetchAll().map(\.title) == ["new", "old"])
    }

    @Test func deleteAndDeleteCompleted() async throws {
        let repository = try makeRepository()
        let keep = Todo(title: "keep", createdAt: TestCalendar.date(2026, 10, 3))
        let remove = Todo(title: "remove", createdAt: TestCalendar.date(2026, 10, 2))
        let done = Todo(title: "done", isCompleted: true, createdAt: TestCalendar.date(2026, 10, 1))
        for todo in [keep, remove, done] {
            try await repository.save(todo)
        }

        try await repository.delete(id: remove.id)
        try await repository.deleteCompleted()

        #expect(try await repository.fetchAll() == [keep])
    }
}
