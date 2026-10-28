import Foundation
import Testing
@testable import TodoApp

@MainActor
struct TodoEditorViewModelTests {
    private let now = TestCalendar.date(2026, 10, 28, hour: 14, minute: 20)

    private func makeViewModel(editing todo: Todo?, repository: InMemoryTodoRepository) -> TodoEditorViewModel {
        TodoEditorViewModel(
            editing: todo,
            saveTodo: SaveTodoUseCase(repository: repository, calendar: TestCalendar.tokyo),
            deleteTodo: DeleteTodoUseCase(repository: repository),
            now: now,
            calendar: TestCalendar.tokyo
        )
    }

    @Test func newTodoStartsEmptyWithSensibleDefaults() {
        let viewModel = makeViewModel(editing: nil, repository: InMemoryTodoRepository())

        #expect(!viewModel.isEditing)
        #expect(!viewModel.canSave)
        #expect(!viewModel.hasDueDate)
        #expect(viewModel.dueDay == TestCalendar.date(2026, 10, 28))
        #expect(viewModel.dueTime == TestCalendar.date(2026, 10, 28, hour: 15))
    }

    @Test func editingPrefillsFromTodo() {
        let todo = Todo(
            title: "会議",
            notes: "メモ",
            dueDate: TestCalendar.date(2026, 10, 30, hour: 18, minute: 30),
            hasDueTime: true,
            priority: .high
        )
        let viewModel = makeViewModel(editing: todo, repository: InMemoryTodoRepository(todos: [todo]))

        #expect(viewModel.isEditing)
        #expect(viewModel.title == "会議")
        #expect(viewModel.hasDueDate)
        #expect(viewModel.hasDueTime)
        #expect(viewModel.dueTime == todo.dueDate)
        #expect(viewModel.priority == .high)
    }

    @Test func draftIgnoresTimeWhenDueDateIsOff() {
        let viewModel = makeViewModel(editing: nil, repository: InMemoryTodoRepository())
        viewModel.title = "A"
        viewModel.hasDueTime = true

        #expect(viewModel.draft.dueDay == nil)
        #expect(viewModel.draft.dueTime == nil)
    }

    @Test func saveCreatesTodo() async throws {
        let repository = InMemoryTodoRepository()
        let viewModel = makeViewModel(editing: nil, repository: repository)
        viewModel.title = "牛乳を買う"
        viewModel.hasDueDate = true
        viewModel.hasDueTime = true

        #expect(await viewModel.save())

        let saved = try await repository.fetchAll()
        #expect(saved.map(\.title) == ["牛乳を買う"])
        #expect(saved.first?.dueDate == TestCalendar.date(2026, 10, 28, hour: 15))
        #expect(saved.first?.hasDueTime == true)
    }

    @Test func saveWithBlankTitleShowsError() async throws {
        let repository = InMemoryTodoRepository()
        let viewModel = makeViewModel(editing: nil, repository: repository)
        viewModel.title = "   "

        #expect(await viewModel.save() == false)
        #expect(viewModel.isShowingError)
        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test func deleteRemovesEditingTodo() async throws {
        let todo = Todo(title: "A")
        let repository = InMemoryTodoRepository(todos: [todo])
        let viewModel = makeViewModel(editing: todo, repository: repository)

        #expect(await viewModel.delete())
        #expect(try await repository.fetchAll().isEmpty)
    }
}
