import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let onToggle: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? Color.accentColor : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(todo.isCompleted ? "未完了に戻す" : "完了にする")

            Button(action: onSelect) {
                HStack(alignment: .firstTextBaseline) {
                    details
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if todo.priority != .none {
                    Text(todo.priority.marks)
                        .fontWeight(.bold)
                        .foregroundStyle(todo.isCompleted ? Color.secondary : todo.priority.color)
                        .accessibilityLabel("優先度 \(todo.priority.label)")
                }
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
            }

            if !todo.notes.isEmpty {
                Text(todo.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let dueDate = todo.dueDate {
                // 期限切れ・「今日」の表示が時間の経過で切り替わるよう毎分更新する
                TimelineView(.everyMinute) { context in
                    Label {
                        Text(dueDateText(dueDate, now: context.date))
                    } icon: {
                        Image(systemName: todo.hasDueTime ? "clock" : "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(dueDateColor(now: context.date))
                }
            }
        }
    }

    private func dueDateText(_ dueDate: Date, now: Date) -> String {
        var text = todo.isDueToday(now: now)
            ? "今日"
            : dueDate.formatted(.dateTime.month().day().weekday())
        if todo.hasDueTime {
            text += " " + dueDate.formatted(date: .omitted, time: .shortened)
        }
        if todo.isOverdue(now: now) {
            text += " · 期限切れ"
        }
        return text
    }

    private func dueDateColor(now: Date) -> Color {
        if todo.isCompleted { return .secondary }
        if todo.isOverdue(now: now) { return .red }
        if todo.isDueToday(now: now) { return .orange }
        return .secondary
    }
}
