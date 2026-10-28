import SwiftData
import SwiftUI

@main
struct TodoApp: App {
    var body: some Scene {
        WindowGroup {
            TodoListView()
        }
        .modelContainer(for: TodoItem.self)
    }
}
