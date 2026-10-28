import SwiftUI

// ドメインの値を画面表示用の文言・色に変換する。

extension Priority {
    var label: String {
        switch self {
        case .none: "なし"
        case .low: "低"
        case .medium: "中"
        case .high: "高"
        }
    }

    /// リマインダー風の「!」マーク。優先度なしは空文字。
    var marks: String {
        String(repeating: "!", count: rawValue)
    }

    var color: Color {
        switch self {
        case .none: .secondary
        case .low: .blue
        case .medium: .orange
        case .high: .red
        }
    }
}

extension TodoFilter {
    var label: String {
        switch self {
        case .all: "すべて"
        case .active: "未完了"
        case .completed: "完了"
        }
    }
}

extension TodoSortOrder {
    var label: String {
        switch self {
        case .createdAt: "作成日順"
        case .dueDate: "期限順"
        case .priority: "優先度順"
        }
    }

    var systemImage: String {
        switch self {
        case .createdAt: "clock"
        case .dueDate: "calendar"
        case .priority: "exclamationmark.circle"
        }
    }
}
