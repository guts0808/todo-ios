import Foundation

enum TodoFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case completed

    var id: Self { self }

    var label: String {
        switch self {
        case .all: "すべて"
        case .active: "未完了"
        case .completed: "完了"
        }
    }

    func includes(_ item: TodoItem) -> Bool {
        switch self {
        case .all: true
        case .active: !item.isCompleted
        case .completed: item.isCompleted
        }
    }
}

enum TodoSortOrder: String, CaseIterable, Identifiable {
    case createdAt
    case dueDate
    case priority

    var id: Self { self }

    var label: String {
        switch self {
        case .createdAt: "作成日順"
        case .dueDate: "期限順"
        case .priority: "優先度順"
        }
    }

    var systemImage: String {
        switch self {
        case .createdAt: "clock"
        case .dueDate: "calendar"
        case .priority: "exclamationmark.circle"
        }
    }
}

/// 一覧に表示する TODO の絞り込み・検索・並び替えを行う。
enum TodoListArranger {
    static func arrange(
        _ items: [TodoItem],
        filter: TodoFilter,
        sortOrder: TodoSortOrder,
        searchText: String
    ) -> [TodoItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return items
            .filter { filter.includes($0) }
            .filter { query.isEmpty || $0.title.localizedStandardContains(query) || $0.notes.localizedStandardContains(query) }
            .sorted { areInIncreasingOrder($0, $1, by: sortOrder) }
    }

    /// 未完了を先に並べ、その中で指定の順序、最後に新しい順で比較する。
    static func areInIncreasingOrder(_ lhs: TodoItem, _ rhs: TodoItem, by sortOrder: TodoSortOrder) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }

        switch sortOrder {
        case .createdAt:
            break
        case .dueDate:
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?) where l != r:
                return l < r
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            default:
                break
            }
        case .priority:
            if lhs.priority != rhs.priority {
                return lhs.priority > rhs.priority
            }
        }

        return lhs.createdAt > rhs.createdAt
    }
}
