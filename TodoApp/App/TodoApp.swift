import SwiftUI

@main
struct TodoApp: App {
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            TodoListView(
                viewModel: container.makeTodoListViewModel(),
                makeEditorViewModel: container.makeTodoEditorViewModel(editing:)
            )
        }
    }
}
