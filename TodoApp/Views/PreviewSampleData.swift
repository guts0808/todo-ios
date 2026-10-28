import Foundation
import SwiftData

/// SwiftUI プレビュー用のサンプルデータ入りコンテナ。
@MainActor
enum PreviewSampleData {
    static let container: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: TodoItem.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let samples = [
                TodoItem(title: "牛乳を買う", notes: "低脂肪のもの", dueDate: today, priority: .medium),
                TodoItem(
                    title: "会議の資料を共有",
                    dueDate: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today),
                    hasDueTime: true
                ),
                TodoItem(title: "企画書を提出", dueDate: calendar.date(byAdding: .day, value: -1, to: today), priority: .high),
                TodoItem(title: "ジムに行く", dueDate: calendar.date(byAdding: .day, value: 2, to: today)),
                TodoItem(title: "本を返却する", priority: .low),
            ]
            samples.forEach { container.mainContext.insert($0) }

            let done = TodoItem(title: "歯医者を予約")
            done.toggleCompletion()
            container.mainContext.insert(done)
            return container
        } catch {
            fatalError("プレビュー用コンテナの作成に失敗しました: \(error)")
        }
    }()
}
