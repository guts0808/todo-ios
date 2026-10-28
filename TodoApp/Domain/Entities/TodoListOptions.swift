import Foundation

enum TodoFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case active
    case completed

    var id: Self { self }

    func includes(_ todo: Todo) -> Bool {
        switch self {
        case .all: true
        case .active: !todo.isCompleted
        case .completed: todo.isCompleted
        }
    }
}

enum TodoSortOrder: String, CaseIterable, Identifiable, Sendable {
    case createdAt
    case dueDate
    case priority

    var id: Self { self }
}
