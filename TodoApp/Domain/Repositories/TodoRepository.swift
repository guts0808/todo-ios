import Foundation

/// TODO の永続化を抽象化するリポジトリ。実装は Data 層が提供する。
protocol TodoRepository: Sendable {
    /// すべての TODO を作成日の新しい順で返す。
    func fetchAll() async throws -> [Todo]
    /// 同じ ID があれば更新し、なければ追加する。
    func save(_ todo: Todo) async throws
    func delete(id: Todo.ID) async throws
    func deleteCompleted() async throws
}
