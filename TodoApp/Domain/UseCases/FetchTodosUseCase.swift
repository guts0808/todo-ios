import Foundation

struct FetchTodosUseCase: Sendable {
    private let repository: any TodoRepository

    init(repository: any TodoRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Todo] {
        try await repository.fetchAll()
    }
}
