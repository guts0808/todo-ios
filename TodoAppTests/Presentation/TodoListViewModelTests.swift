import Foundation
import Testing
@testable import TodoApp

@MainActor
struct TodoListViewModelTests {
    private let preferences = UserDefaults(suiteName: "TodoListViewModelTests-\(UUID().uuidString)")!

    private func makeViewModel(_ repository: InMemoryTodoRepository) -> TodoListViewModel {
        TodoListViewModel(
            fetchTodos: FetchTodosUseCase(repository: repository),
            toggleTodoCompletion: ToggleTodoCompletionUseCase(repository: repository),
            deleteTodo: DeleteTodoUseCase(repository: repository),
            deleteCompletedTodos: DeleteCompletedTodosUseCase(repository: repository),
            preferences: preferences
        )
    }

    @Test func loadAndFilter() async {
        let repository = InMemoryTodoRepository(todos: [Todo(title: "A"), Todo(title: "B", isCompleted: true)])
        let viewModel = makeViewModel(repository)
        #expect(!viewModel.hasLoaded)

        await viewModel.load()
        #expect(viewModel.hasLoaded)
        #expect(viewModel.todos.count == 2)
        #expect(viewModel.activeCount == 1)
        #expect(viewModel.completedCount == 1)

        viewModel.filter = .active
        #expect(viewModel.visibleTodos.map(\.title) == ["A"])

        viewModel.filter = .all
        viewModel.searchText = "b"
        #expect(viewModel.isSearching)
        #expect(viewModel.visibleTodos.map(\.title) == ["B"])
    }

    @Test func toggleCompletionUpdatesStateAndRepository() async throws {
        let todo = Todo(title: "A")
        let repository = InMemoryTodoRepository(todos: [todo])
        let viewModel = makeViewModel(repository)
        await viewModel.load()

        await viewModel.toggleCompletion(of: todo)

        #expect(viewModel.todos.first?.isCompleted == true)
        #expect(try await repository.fetchAll().first?.isCompleted == true)
    }

    @Test func deleteAndDeleteCompleted() async throws {
        let keep = Todo(title: "keep")
        let remove = Todo(title: "remove")
        let done = Todo(title: "done", isCompleted: true)
        let repository = InMemoryTodoRepository(todos: [keep, remove, done])
        let viewModel = makeViewModel(repository)
        await viewModel.load()

        await viewModel.delete(remove)
        await viewModel.deleteCompleted()

        #expect(viewModel.todos == [keep])
        #expect(try await repository.fetchAll() == [keep])
    }

    @Test func filterAndSortOrderArePersisted() {
        let viewModel = makeViewModel(InMemoryTodoRepository())
        viewModel.filter = .completed
        viewModel.sortOrder = .priority

        let restored = makeViewModel(InMemoryTodoRepository())
        #expect(restored.filter == .completed)
        #expect(restored.sortOrder == .priority)
    }
}
