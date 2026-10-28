import Foundation

/// メモリ上だけで保持する `TodoRepository` の実装。プレビューやテストで使う。
actor InMemoryTodoRepository: TodoRepository {
    private var todos: [Todo.ID: Todo]

    init(todos: [Todo] = []) {
        self.todos = Dictionary(uniqueKeysWithValues: todos.map { ($0.id, $0) })
    }

    func fetchAll() throws -> [Todo] {
        todos.values.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ todo: Todo) throws {
        todos[todo.id] = todo
    }

    func delete(id: Todo.ID) throws {
        todos[id] = nil
    }

    func deleteCompleted() throws {
        todos = todos.filter { !$0.value.isCompleted }
    }
}
