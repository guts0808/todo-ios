import Foundation

struct ToggleTodoCompletionUseCase: Sendable {
    private let repository: any TodoRepository
    private let now: @Sendable () -> Date

    init(repository: any TodoRepository, now: @escaping @Sendable () -> Date = { .now }) {
        self.repository = repository
        self.now = now
    }

    /// 完了状態を反転して保存し、更新後の TODO を返す。
    func execute(_ todo: Todo) async throws -> Todo {
        var updated = todo
        updated.toggleCompletion(now: now())
        try await repository.save(updated)
        return updated
    }
}
