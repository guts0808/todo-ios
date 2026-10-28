import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var items: [TodoItem]

    @AppStorage("todoFilter") private var filter: TodoFilter = .all
    @AppStorage("todoSortOrder") private var sortOrder: TodoSortOrder = .createdAt
    @State private var searchText = ""
    @State private var editorMode: EditorMode?
    @State private var isConfirmingClearCompleted = false

    private var visibleItems: [TodoItem] {
        TodoListArranger.arrange(items, filter: filter, sortOrder: sortOrder, searchText: searchText)
    }

    private var activeCount: Int {
        items.count { !$0.isCompleted }
    }

    private var completedCount: Int {
        items.count - activeCount
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("表示", selection: $filter) {
                        ForEach(TodoFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                let shownItems = visibleItems
                if shownItems.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(shownItems) { item in
                            row(for: item)
                        }
                    }
                }
            }
            .navigationTitle("TODO")
            .searchable(text: $searchText, prompt: "タイトルやメモを検索")
            .toolbar { toolbarContent }
            .sheet(item: $editorMode) { mode in
                switch mode {
                case .create:
                    TodoEditorView(item: nil)
                case .edit(let item):
                    TodoEditorView(item: item)
                }
            }
            .confirmationDialog(
                "完了済みの TODO を \(completedCount) 件削除しますか？",
                isPresented: $isConfirmingClearCompleted,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive, action: clearCompleted)
            }
        }
    }

    private func row(for item: TodoItem) -> some View {
        TodoRowView(
            item: item,
            onToggle: { toggle(item) },
            onSelect: { editorMode = .edit(item) }
        )
        .swipeActions(edge: .leading) {
            Button {
                toggle(item)
            } label: {
                if item.isCompleted {
                    Label("未完了に戻す", systemImage: "arrow.uturn.backward")
                } else {
                    Label("完了", systemImage: "checkmark")
                }
            }
            .tint(item.isCompleted ? .gray : .green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                delete(item)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            switch filter {
            case .all:
                ContentUnavailableView {
                    Label("TODO はありません", systemImage: "checklist")
                } description: {
                    Text("＋ボタンから新しい TODO を追加しましょう。")
                } actions: {
                    Button("TODO を追加") { editorMode = .create }
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
                Picker("並び替え", selection: $sortOrder) {
                    ForEach(TodoSortOrder.allCases) { order in
                        Label(order.label, systemImage: order.systemImage).tag(order)
                    }
                }
                Divider()
                Button("完了済みを削除", systemImage: "trash", role: .destructive) {
                    isConfirmingClearCompleted = true
                }
                .disabled(completedCount == 0)
            } label: {
                Label("その他", systemImage: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("追加", systemImage: "plus") {
                editorMode = .create
            }
        }
        ToolbarItem(placement: .status) {
            Text(activeCount == 0 ? "未完了の TODO はありません" : "未完了 \(activeCount) 件")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func toggle(_ item: TodoItem) {
        withAnimation {
            item.toggleCompletion()
        }
    }

    private func delete(_ item: TodoItem) {
        withAnimation {
            modelContext.delete(item)
        }
    }

    private func clearCompleted() {
        withAnimation {
            for item in items where item.isCompleted {
                modelContext.delete(item)
            }
        }
    }
}

private enum EditorMode: Identifiable {
    case create
    case edit(TodoItem)

    var id: AnyHashable {
        switch self {
        case .create: AnyHashable("create")
        case .edit(let item): AnyHashable(item.persistentModelID)
        }
    }
}

#Preview {
    TodoListView()
        .modelContainer(PreviewSampleData.container)
}

#Preview("空の状態") {
    TodoListView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
