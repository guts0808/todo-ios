import Foundation

enum Priority: Int, CaseIterable, Identifiable, Comparable, Sendable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var id: Int { rawValue }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
