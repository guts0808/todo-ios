import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? Color.accentColor : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(item.isCompleted ? "未完了に戻す" : "完了にする")

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
                if item.priority != .none {
                    Text(item.priority.marks)
                        .fontWeight(.bold)
                        .foregroundStyle(item.isCompleted ? Color.secondary : item.priority.color)
                        .accessibilityLabel("優先度 \(item.priority.label)")
                }
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
            }

            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let dueDate = item.dueDate {
                // 期限切れ・「今日」の表示が時間の経過で切り替わるよう毎分更新する
                TimelineView(.everyMinute) { context in
                    Label {
                        Text(dueDateText(dueDate, now: context.date))
                    } icon: {
                        Image(systemName: item.hasDueTime ? "clock" : "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(dueDateColor(now: context.date))
                }
            }
        }
    }

    private func dueDateText(_ dueDate: Date, now: Date) -> String {
        var text = item.isDueToday(now: now)
            ? "今日"
            : dueDate.formatted(.dateTime.month().day().weekday())
        if item.hasDueTime {
            text += " " + dueDate.formatted(date: .omitted, time: .shortened)
        }
        if item.isOverdue(now: now) {
            text += " · 期限切れ"
        }
        return text
    }

    private func dueDateColor(now: Date) -> Color {
        if item.isCompleted { return .secondary }
        if item.isOverdue(now: now) { return .red }
        if item.isDueToday(now: now) { return .orange }
        return .secondary
    }
}

extension Priority {
    var color: Color {
        switch self {
        case .none: .secondary
        case .low: .blue
        case .medium: .orange
        case .high: .red
        }
    }
}
