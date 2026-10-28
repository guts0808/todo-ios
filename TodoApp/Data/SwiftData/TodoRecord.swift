import Foundation
import SwiftData

/// SwiftData に保存する TODO のレコード。ドメインの `Todo` とは相互に変換して使う。
@Model
final class TodoRecord {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var isCompleted: Bool = false
    var dueDate: Date?
    var hasDueTime: Bool = false
    /// `Priority` の rawValue。
    var priorityRawValue: Int = Priority.none.rawValue
    var createdAt: Date = Date.now
    var completedAt: Date?

    init(todo: Todo) {
        id = todo.id
        title = todo.title
        notes = todo.notes
        isCompleted = todo.isCompleted
        dueDate = todo.dueDate
        hasDueTime = todo.hasDueTime
        priorityRawValue = todo.priority.rawValue
        createdAt = todo.createdAt
        completedAt = todo.completedAt
    }

    /// ID と作成日時以外をドメインの値で更新する。
    func update(from todo: Todo) {
        title = todo.title
        notes = todo.notes
        isCompleted = todo.isCompleted
        dueDate = todo.dueDate
        hasDueTime = todo.hasDueTime
        priorityRawValue = todo.priority.rawValue
        completedAt = todo.completedAt
    }

    func toDomain() -> Todo {
        Todo(
            id: id,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            dueDate: dueDate,
            hasDueTime: hasDueTime,
            priority: Priority(rawValue: priorityRawValue) ?? .none,
            createdAt: createdAt,
            completedAt: completedAt
        )
    }
}
