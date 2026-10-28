import Foundation

// SwiftUI プレビュー用。SwiftData を使わずメモリ上のサンプルデータで動かす。

extension AppContainer {
    static func preview(todos: [Todo] = Todo.previewSamples) -> AppContainer {
        AppContainer(repository: InMemoryTodoRepository(todos: todos))
    }
}

extension Todo {
    static var previewSamples: [Todo] {
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        return [
            Todo(title: "牛乳を買う", notes: "低脂肪のもの", dueDate: today, priority: .medium, createdAt: now),
            Todo(
                title: "会議の資料を共有",
                dueDate: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today),
                hasDueTime: true,
                createdAt: now.addingTimeInterval(-60)
            ),
            Todo(
                title: "企画書を提出",
                dueDate: calendar.date(byAdding: .day, value: -1, to: today),
                priority: .high,
                createdAt: now.addingTimeInterval(-120)
            ),
            Todo(
                title: "ジムに行く",
                dueDate: calendar.date(byAdding: .day, value: 2, to: today),
                createdAt: now.addingTimeInterval(-180)
            ),
            Todo(title: "本を返却する", priority: .low, createdAt: now.addingTimeInterval(-240)),
            Todo(title: "歯医者を予約", isCompleted: true, createdAt: now.addingTimeInterval(-300), completedAt: now),
        ]
    }
}
