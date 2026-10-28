import Foundation
import SwiftData

/// 依存関係を組み立てる Composition Root。各層の具体的な実装はここでだけ結びつける。
@MainActor
final class AppContainer {
    private let repository: any TodoRepository

    init(repository: any TodoRepository) {
        self.repository = repository
    }

    /// 端末内の SwiftData ストアを使う本番用の構成。
    static func live() -> AppContainer {
        do {
            let modelContainer = try ModelContainer(for: TodoRecord.self)
            return AppContainer(repository: SwiftDataTodoRepository(modelContainer: modelContainer))
        } catch {
            fatalError("データストアの初期化に失敗しました: \(error)")
        }
    }

    func makeTodoListViewModel() -> TodoListViewModel {
        TodoListViewModel(
            fetchTodos: FetchTodosUseCase(repository: repository),
            toggleTodoCompletion: ToggleTodoCompletionUseCase(repository: repository),
            deleteTodo: DeleteTodoUseCase(repository: repository),
            deleteCompletedTodos: DeleteCompletedTodosUseCase(repository: repository)
        )
    }

    func makeTodoEditorViewModel(editing todo: Todo?) -> TodoEditorViewModel {
        TodoEditorViewModel(
            editing: todo,
            saveTodo: SaveTodoUseCase(repository: repository),
            deleteTodo: DeleteTodoUseCase(repository: repository)
        )
    }
}
