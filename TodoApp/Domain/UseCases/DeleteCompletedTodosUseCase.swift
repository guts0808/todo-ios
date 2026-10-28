import Foundation

struct DeleteCompletedTodosUseCase: Sendable {
    private let repository: any TodoRepository

    init(repository: any TodoRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.deleteCompleted()
    }
}
