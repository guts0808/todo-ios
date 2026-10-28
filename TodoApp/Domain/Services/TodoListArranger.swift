import Foundation

/// 一覧に表示する TODO の絞り込み・検索・並び替えを行う。
enum TodoListArranger {
    static func arrange(
        _ todos: [Todo],
        filter: TodoFilter,
        sortOrder: TodoSortOrder,
        searchText: String
    ) -> [Todo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return todos
            .filter { filter.includes($0) }
            .filter { query.isEmpty || $0.title.localizedStandardContains(query) || $0.notes.localizedStandardContains(query) }
            .sorted { areInIncreasingOrder($0, $1, by: sortOrder) }
    }

    /// 未完了を先に並べ、その中で指定の順序、最後に新しい順で比較する。
    static func areInIncreasingOrder(_ lhs: Todo, _ rhs: Todo, by sortOrder: TodoSortOrder) -> Bool {
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
