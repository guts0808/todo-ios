import SwiftUI

struct TodoListView: View {
    @State private var viewModel: TodoListViewModel
    @State private var editorTarget: EditorTarget?
    @State private var isConfirmingClearCompleted = false
    private let makeEditorViewModel: @MainActor (Todo?) -> TodoEditorViewModel

    init(
        viewModel: TodoListViewModel,
        makeEditorViewModel: @escaping @MainActor (Todo?) -> TodoEditorViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeEditorViewModel = makeEditorViewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("表示", selection: $viewModel.filter) {
                        ForEach(TodoFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                let shownTodos = viewModel.visibleTodos
                if shownTodos.isEmpty {
                    if viewModel.hasLoaded {
                        emptyState
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(shownTodos) { todo in
                            row(for: todo)
                        }
                    }
                }
            }
            .animation(.default, value: viewModel.visibleTodos)
            .navigationTitle("TODO")
            .searchable(text: $viewModel.searchText, prompt: "タイトルやメモを検索")
            .toolbar { toolbarContent }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(item: $editorTarget, onDismiss: reload) { target in
                TodoEditorView(viewModel: makeEditorViewModel(target.todo))
            }
            .confirmationDialog(
                "完了済みの TODO を \(viewModel.completedCount) 件削除しますか？",
                isPresented: $isConfirmingClearCompleted,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    Task { await viewModel.deleteCompleted() }
                }
            }
            .alert("エラー", isPresented: $viewModel.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func row(for todo: Todo) -> some View {
        TodoRowView(
            todo: todo,
            onToggle: { toggle(todo) },
            onSelect: { editorTarget = .edit(todo) }
        )
        .swipeActions(edge: .leading) {
            Button {
                toggle(todo)
            } label: {
                if todo.isCompleted {
                    Label("未完了に戻す", systemImage: "arrow.uturn.backward")
                } else {
                    Label("完了", systemImage: "checkmark")
                }
            }
            .tint(todo.isCompleted ? .gray : .green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.delete(todo) }
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.isSearching {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            switch viewModel.filter {
            case .all:
                ContentUnavailableView {
                    Label("TODO はありません", systemImage: "checklist")
                } description: {
                    Text("＋ボタンから新しい TODO を追加しましょう。")
                } actions: {
                    Button("TODO を追加") { editorTarget = .create }
                        .buttonStyle(.borderedProminent)
                }
            case .active:
                ContentUnavailableView(
                    "未完了の TODO はありません",
                    systemImage: "checkmark.circle",
                    description: Text("すべて完了しました！")
                )
            case .completed:
                ContentUnavailableView(
                    "完了した TODO はありません",
                    systemImage: "circle.dashed"
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("並び替え", selection: $viewModel.sortOrder) {
                    ForEach(TodoSortOrder.allCases) { order in
                        Label(order.label, systemImage: order.systemImage).tag(order)
                    }
                }
                Divider()
                Button("完了済みを削除", systemImage: "trash", role: .destructive) {
                    isConfirmingClearCompleted = true
                }
                .disabled(viewModel.completedCount == 0)
            } label: {
                Label("その他", systemImage: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("追加", systemImage: "plus") {
                editorTarget = .create
            }
        }
        ToolbarItem(placement: .status) {
            Text(viewModel.activeCount == 0 ? "未完了の TODO はありません" : "未完了 \(viewModel.activeCount) 件")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func toggle(_ todo: Todo) {
        Task { await viewModel.toggleCompletion(of: todo) }
    }

    private func reload() {
        Task { await viewModel.load() }
    }
}

private enum EditorTarget: Identifiable {
    case create
    case edit(Todo)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let todo): todo.id.uuidString
        }
    }

    var todo: Todo? {
        switch self {
        case .create: nil
        case .edit(let todo): todo
        }
    }
}

#Preview {
    let container = AppContainer.preview()
    TodoListView(
        viewModel: container.makeTodoListViewModel(),
        makeEditorViewModel: container.makeTodoEditorViewModel(editing:)
    )
}

#Preview("空の状態") {
    let container = AppContainer.preview(todos: [])
    TodoListView(
        viewModel: container.makeTodoListViewModel(),
        makeEditorViewModel: container.makeTodoEditorViewModel(editing:)
    )
}
