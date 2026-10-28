import SwiftData
import SwiftUI

/// TODO の新規作成・編集画面。`item` が nil なら新規作成。
struct TodoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: TodoItem?

    @State private var title: String
    @State private var notes: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var hasDueTime: Bool
    @State private var dueTime: Date
    @State private var priority: Priority
    @State private var isConfirmingDelete = false
    @FocusState private var isTitleFocused: Bool

    init(item: TodoItem?) {
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _notes = State(initialValue: item?.notes ?? "")
        _hasDueDate = State(initialValue: item?.dueDate != nil)
        _dueDate = State(initialValue: item?.dueDate ?? Calendar.current.startOfDay(for: .now))
        _hasDueTime = State(initialValue: item?.hasDueTime ?? false)
        let existingDueTime = item?.hasDueTime == true ? item?.dueDate : nil
        _dueTime = State(initialValue: existingDueTime ?? Self.nextHour())
        _priority = State(initialValue: item?.priority ?? .none)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タイトル", text: $title)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                    TextField("メモ", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    Toggle(isOn: $hasDueDate.animation()) {
                        Label("期限", systemImage: "calendar")
                    }
                    if hasDueDate {
                        DatePicker("日付", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                        Toggle(isOn: $hasDueTime.animation()) {
                            Label("時刻", systemImage: "clock")
                        }
                        if hasDueTime {
                            DatePicker("時刻", selection: $dueTime, displayedComponents: .hourAndMinute)
                        }
                    }
                    Picker(selection: $priority) {
                        ForEach(Priority.allCases) { priority in
                            Text(priority.label).tag(priority)
                        }
                    } label: {
                        Label("優先度", systemImage: "exclamationmark.circle")
                    }
                }

                if item != nil {
                    Section {
                        Button("この TODO を削除", role: .destructive) {
                            isConfirmingDelete = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(item == nil ? "新規 TODO" : "TODO を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(item == nil ? "追加" : "保存", action: save)
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .confirmationDialog("この TODO を削除しますか？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive, action: deleteItem)
            }
            .onAppear {
                if item == nil {
                    isTitleFocused = true
                }
            }
        }
    }

    private func save() {
        let includesTime = hasDueDate && hasDueTime
        let normalizedDueDate = hasDueDate
            ? TodoItem.makeDueDate(day: dueDate, time: includesTime ? dueTime : nil)
            : nil
        let notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let item {
            item.title = trimmedTitle
            item.notes = notes
            item.dueDate = normalizedDueDate
            item.hasDueTime = includesTime
            item.priority = priority
        } else {
            let newItem = TodoItem(
                title: trimmedTitle,
                notes: notes,
                dueDate: normalizedDueDate,
                hasDueTime: includesTime,
                priority: priority
            )
            modelContext.insert(newItem)
        }
        dismiss()
    }

    /// 時刻の初期値として、現在時刻の次の正時（例: 14:20 → 15:00）を返す。
    private static func nextHour(from now: Date = .now, calendar: Calendar = .current) -> Date {
        let startOfHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return calendar.date(byAdding: .hour, value: 1, to: startOfHour) ?? now
    }

    private func deleteItem() {
        if let item {
            modelContext.delete(item)
        }
        dismiss()
    }
}

#Preview("新規") {
    TodoEditorView(item: nil)
        .modelContainer(PreviewSampleData.container)
}
