import Foundation
import Observation

@MainActor
@Observable
final class TodoListViewModel {
    private(set) var todos: [Todo] = []
    /// 初回の読み込みが終わったか。読み込み前に空状態を表示しないために使う。
    private(set) var hasLoaded = false
    var searchText = ""
    var errorMessage: String?

    private var storedFilter: TodoFilter
    private var storedSortOrder: TodoSortOrder

    @ObservationIgnored private let fetchTodos: FetchTodosUseCase
    @ObservationIgnored private let toggleTodoCompletion: ToggleTodoCompletionUseCase
    @ObservationIgnored private let deleteTodo: DeleteTodoUseCase
    @ObservationIgnored private let deleteCompletedTodos: DeleteCompletedTodosUseCase
    @ObservationIgnored private let preferences: UserDefaults

    private enum PreferenceKey {
        static let filter = "todoFilter"
        static let sortOrder = "todoSortOrder"
    }

    init(
        fetchTodos: FetchTodosUseCase,
        toggleTodoCompletion: ToggleTodoCompletionUseCase,
        deleteTodo: DeleteTodoUseCase,
        deleteCompletedTodos: DeleteCompletedTodosUseCase,
        preferences: UserDefaults = .standard
    ) {
        self.fetchTodos = fetchTodos
        self.toggleTodoCompletion = toggleTodoCompletion
        self.deleteTodo = deleteTodo
        self.deleteCompletedTodos = deleteCompletedTodos
        self.preferences = preferences
        storedFilter = preferences.string(forKey: PreferenceKey.filter).flatMap(TodoFilter.init(rawValue:)) ?? .all
        storedSortOrder = preferences.string(forKey: PreferenceKey.sortOrder).flatMap(TodoSortOrder.init(rawValue:)) ?? .createdAt
    }

    /// 選択中の絞り込み。変更すると次回起動時のために保存する。
    var filter: TodoFilter {
        get { storedFilter }
        set {
            storedFilter = newValue
            preferences.set(newValue.rawValue, forKey: PreferenceKey.filter)
        }
    }

    /// 選択中の並び順。変更すると次回起動時のために保存する。
    var sortOrder: TodoSortOrder {
        get { storedSortOrder }
        set {
            storedSortOrder = newValue
            preferences.set(newValue.rawValue, forKey: PreferenceKey.sortOrder)
        }
    }

    var visibleTodos: [Todo] {
        TodoListArranger.arrange(todos, filter: filter, sortOrder: sortOrder, searchText: searchText)
    }

    var activeCount: Int {
        todos.count { !$0.isCompleted }
    }

    var completedCount: Int {
        todos.count - activeCount
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    func load() async {
        do {
            todos = try await fetchTodos.execute()
        } catch {
            errorMessage = "TODO の読み込みに失敗しました。\n\(error.localizedDescription)"
        }
        hasLoaded = true
    }

    func toggleCompletion(of todo: Todo) async {
        do {
            let updated = try await toggleTodoCompletion.execute(todo)
            if let index = todos.firstIndex(where: { $0.id == updated.id }) {
                todos[index] = updated
            }
        } catch {
            errorMessage = "TODO の更新に失敗しました。\n\(error.localizedDescription)"
        }
    }

    func delete(_ todo: Todo) async {
        do {
            try await deleteTodo.execute(id: todo.id)
            todos.removeAll { $0.id == todo.id }
        } catch {
            errorMessage = "TODO の削除に失敗しました。\n\(error.localizedDescription)"
        }
    }

    func deleteCompleted() async {
        do {
            try await deleteCompletedTodos.execute()
            todos.removeAll(where: \.isCompleted)
        } catch {
            errorMessage = "TODO の削除に失敗しました。\n\(error.localizedDescription)"
        }
    }
}
