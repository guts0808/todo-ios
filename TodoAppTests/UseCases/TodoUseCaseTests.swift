import Foundation
import Testing
@testable import TodoApp

struct SaveTodoUseCaseTests {
    private let now = TestCalendar.date(2026, 10, 28, hour: 9)

    private func makeUseCase(_ repository: InMemoryTodoRepository) -> SaveTodoUseCase {
        let now = now
        return SaveTodoUseCase(repository: repository, calendar: TestCalendar.tokyo, now: { now })
    }

    @Test func createsTrimmedTodoWithDueDateAndTime() async throws {
        let repository = InMemoryTodoRepository()
        let draft = TodoDraft(
            title: "  牛乳を買う  ",
            notes: " 低脂肪 \n",
            dueDay: TestCalendar.date(2026, 10, 30, hour: 15),
            dueTime: TestCalendar.date(2000, 1, 1, hour: 18, minute: 30),
            priority: .high
        )

        let saved = try await makeUseCase(repository).execute(draft)

        #expect(saved.title == "牛乳を買う")
        #expect(saved.notes == "低脂肪")
        #expect(saved.dueDate == TestCalendar.date(2026, 10, 30, hour: 18, minute: 30))
        #expect(saved.hasDueTime)
        #expect(saved.priority == .high)
        #expect(saved.createdAt == now)
        #expect(try await repository.fetchAll() == [saved])
    }

    @Test func dateOnlyDraftStoresStartOfDay() async throws {
        let draft = TodoDraft(title: "A", dueDay: TestCalendar.date(2026, 10, 30, hour: 15))

        let saved = try await makeUseCase(InMemoryTodoRepository()).execute(draft)

        #expect(saved.dueDate == TestCalendar.date(2026, 10, 30))
        #expect(!saved.hasDueTime)
    }

    @Test func timeWithoutDayIsIgnored() async throws {
        let draft = TodoDraft(title: "A", dueDay: nil, dueTime: TestCalendar.date(2000, 1, 1, hour: 9))

        let saved = try await makeUseCase(InMemoryTodoRepository()).execute(draft)

        #expect(saved.dueDate == nil)
        #expect(!saved.hasDueTime)
    }

    @Test func blankTitleIsRejected() async throws {
        let repository = InMemoryTodoRepository()

        await #expect(throws: TodoValidationError.emptyTitle) {
            try await makeUseCase(repository).execute(TodoDraft(title: "  \n "))
        }
        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test func updateKeepsIdentityAndCompletionState() async throws {
        let original = Todo(title: "旧", isCompleted: true, createdAt: TestCalendar.date(2026, 1, 1), completedAt: now)
        let repository = InMemoryTodoRepository(todos: [original])

        let updated = try await makeUseCase(repository).execute(TodoDraft(title: "新", priority: .low), updating: original)

        #expect(updated.id == original.id)
        #expect(updated.createdAt == original.createdAt)
        #expect(updated.isCompleted)
        #expect(updated.completedAt == now)
        #expect(updated.title == "新")
        #expect(try await repository.fetchAll() == [updated])
    }
}

struct TodoMutationUseCaseTests {
    @Test func toggleCompletionPersistsChange() async throws {
        let now = TestCalendar.date(2026, 10, 28, hour: 9)
        let todo = Todo(title: "A")
        let repository = InMemoryTodoRepository(todos: [todo])

        let toggled = try await ToggleTodoCompletionUseCase(repository: repository, now: { now }).execute(todo)

        #expect(toggled.isCompleted)
        #expect(toggled.completedAt == now)
        #expect(try await repository.fetchAll() == [toggled])
    }

    @Test func deleteRemovesOnlyTarget() async throws {
        let keep = Todo(title: "keep")
        let remove = Todo(title: "remove")
        let repository = InMemoryTodoRepository(todos: [keep, remove])

        try await DeleteTodoUseCase(repository: repository).execute(id: remove.id)

        #expect(try await repository.fetchAll() == [keep])
    }

    @Test func deleteCompletedKeepsActiveTodos() async throws {
        let active = Todo(title: "active")
        let repository = InMemoryTodoRepository(todos: [active, Todo(title: "done", isCompleted: true)])

        try await DeleteCompletedTodosUseCase(repository: repository).execute()

        #expect(try await repository.fetchAll() == [active])
    }

    @Test func fetchReturnsNewestFirst() async throws {
        let old = Todo(title: "old", createdAt: TestCalendar.date(2026, 10, 1))
        let new = Todo(title: "new", createdAt: TestCalendar.date(2026, 10, 2))
        let repository = InMemoryTodoRepository(todos: [old, new])

        #expect(try await FetchTodosUseCase(repository: repository).execute() == [new, old])
    }
}
