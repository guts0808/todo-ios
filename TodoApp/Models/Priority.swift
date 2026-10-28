import Foundation

enum Priority: Int, CaseIterable, Identifiable, Comparable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var id: Int { rawValue }

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

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
