import Foundation
import Observation

/// TODO の新規作成・編集画面の状態と操作。
@MainActor
@Observable
final class TodoEditorViewModel {
    var title: String
    var notes: String
    var hasDueDate: Bool
    var dueDay: Date
    var hasDueTime: Bool
    var dueTime: Date
    var priority: Priority
    var errorMessage: String?

    @ObservationIgnored private let original: Todo?
    @ObservationIgnored private let saveTodo: SaveTodoUseCase
    @ObservationIgnored private let deleteTodo: DeleteTodoUseCase

    /// - Parameter original: 編集対象。nil なら新規作成。
    init(
        editing original: Todo?,
        saveTodo: SaveTodoUseCase,
        deleteTodo: DeleteTodoUseCase,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        self.original = original
        self.saveTodo = saveTodo
        self.deleteTodo = deleteTodo
        title = original?.title ?? ""
        notes = original?.notes ?? ""
        hasDueDate = original?.dueDate != nil
        dueDay = original?.dueDate ?? calendar.startOfDay(for: now)
        hasDueTime = original?.hasDueTime ?? false
        let existingDueTime = original?.hasDueTime == true ? original?.dueDate : nil
        dueTime = existingDueTime ?? TodoEditorViewModel.nextHour(after: now, calendar: calendar)
        priority = original?.priority ?? .none
    }

    var isEditing: Bool {
        original != nil
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    var draft: TodoDraft {
        TodoDraft(
            title: title,
            notes: notes,
            dueDay: hasDueDate ? dueDay : nil,
            dueTime: hasDueDate && hasDueTime ? dueTime : nil,
            priority: priority
        )
    }

    /// 保存に成功したら true を返す。
    func save() async -> Bool {
        do {
            try await saveTodo.execute(draft, updating: original)
            return true
        } catch TodoValidationError.emptyTitle {
            errorMessage = "タイトルを入力してください。"
        } catch {
            errorMessage = "保存に失敗しました。\n\(error.localizedDescription)"
        }
        return false
    }

    /// 削除に成功したら true を返す。
    func delete() async -> Bool {
        guard let original else { return false }
        do {
            try await deleteTodo.execute(id: original.id)
            return true
        } catch {
            errorMessage = "削除に失敗しました。\n\(error.localizedDescription)"
            return false
        }
    }

    /// 時刻の初期値として、次の正時（例: 14:20 → 15:00）を返す。
    private static func nextHour(after now: Date, calendar: Calendar) -> Date {
        let startOfHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return calendar.date(byAdding: .hour, value: 1, to: startOfHour) ?? now
    }
}
