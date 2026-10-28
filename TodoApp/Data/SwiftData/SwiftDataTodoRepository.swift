import Foundation
import SwiftData

/// SwiftData を使った `TodoRepository` の実装。専用のアクター上で ModelContext を扱う。
@ModelActor
actor SwiftDataTodoRepository: TodoRepository {
    func fetchAll() throws -> [Todo] {
        let descriptor = FetchDescriptor<TodoRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ todo: Todo) throws {
        if let record = try record(id: todo.id) {
            record.update(from: todo)
        } else {
            modelContext.insert(TodoRecord(todo: todo))
        }
        try modelContext.save()
    }

    func delete(id: Todo.ID) throws {
        guard let record = try record(id: id) else { return }
        modelContext.delete(record)
        try modelContext.save()
    }

    func deleteCompleted() throws {
        let descriptor = FetchDescriptor<TodoRecord>(predicate: #Predicate { $0.isCompleted })
        for record in try modelContext.fetch(descriptor) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }

    private func record(id: Todo.ID) throws -> TodoRecord? {
        var descriptor = FetchDescriptor<TodoRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
