import Foundation

/// 編集画面から渡される入力値。
struct TodoDraft: Equatable, Sendable {
    var title: String
    var notes: String
    /// 期限日。nil なら期限なし。
    var dueDay: Date?
    /// 期限時刻（時・分のみ使用）。`dueDay` が nil のときは無視する。
    var dueTime: Date?
    var priority: Priority

    init(title: String, notes: String = "", dueDay: Date? = nil, dueTime: Date? = nil, priority: Priority = .none) {
        self.title = title
        self.notes = notes
        self.dueDay = dueDay
        self.dueTime = dueTime
        self.priority = priority
    }
}

enum TodoValidationError: Error, Equatable {
    case emptyTitle
}

/// 入力値を検証・正規化して TODO を新規作成または更新する。
struct SaveTodoUseCase: Sendable {
    private let repository: any TodoRepository
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(repository: any TodoRepository, calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { .now }) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    /// - Parameter original: 更新対象。nil なら新規作成。
    @discardableResult
    func execute(_ draft: TodoDraft, updating original: Todo? = nil) async throws -> Todo {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw TodoValidationError.emptyTitle }

        let dueDate = draft.dueDay.map { Todo.makeDueDate(day: $0, time: draft.dueTime, calendar: calendar) }

        var todo = original ?? Todo(title: title, createdAt: now())
        todo.title = title
        todo.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        todo.dueDate = dueDate
        todo.hasDueTime = dueDate != nil && draft.dueTime != nil
        todo.priority = draft.priority

        try await repository.save(todo)
        return todo
    }
}
