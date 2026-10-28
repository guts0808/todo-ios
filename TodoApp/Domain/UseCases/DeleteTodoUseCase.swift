import Foundation

struct DeleteTodoUseCase: Sendable {
    private let repository: any TodoRepository

    init(repository: any TodoRepository) {
        self.repository = repository
    }

    func execute(id: Todo.ID) async throws {
        try await repository.delete(id: id)
    }
}
