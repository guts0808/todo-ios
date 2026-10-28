import SwiftUI

/// TODO の新規作成・編集画面。
struct TodoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TodoEditorViewModel
    @State private var isConfirmingDelete = false
    @FocusState private var isTitleFocused: Bool

    init(viewModel: TodoEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タイトル", text: $viewModel.title)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                    TextField("メモ", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    Toggle(isOn: $viewModel.hasDueDate.animation()) {
                        Label("期限", systemImage: "calendar")
                    }
                    if viewModel.hasDueDate {
                        DatePicker("日付", selection: $viewModel.dueDay, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                        Toggle(isOn: $viewModel.hasDueTime.animation()) {
                            Label("時刻", systemImage: "clock")
                        }
                        if viewModel.hasDueTime {
                            DatePicker("時刻", selection: $viewModel.dueTime, displayedComponents: .hourAndMinute)
                        }
                    }
                    Picker(selection: $viewModel.priority) {
                        ForEach(Priority.allCases) { priority in
                            Text(priority.label).tag(priority)
                        }
                    } label: {
                        Label("優先度", systemImage: "exclamationmark.circle")
                    }
                }

                if viewModel.isEditing {
                    Section {
                        Button("この TODO を削除", role: .destructive) {
                            isConfirmingDelete = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "TODO を編集" : "新規 TODO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditing ? "保存" : "追加") {
                        Task {
                            if await viewModel.save() { dismiss() }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .confirmationDialog("この TODO を削除しますか？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    Task {
                        if await viewModel.delete() { dismiss() }
                    }
                }
            }
            .alert("エラー", isPresented: $viewModel.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                if !viewModel.isEditing {
                    isTitleFocused = true
                }
            }
        }
    }
}

#Preview("新規") {
    TodoEditorView(viewModel: AppContainer.preview().makeTodoEditorViewModel(editing: nil))
}

#Preview("編集") {
    TodoEditorView(viewModel: AppContainer.preview().makeTodoEditorViewModel(editing: Todo.previewSamples[1]))
}
