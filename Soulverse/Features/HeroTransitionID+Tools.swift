import Foundation

// MARK: - Tools View Transitions
extension HeroTransitionID {
    /// Generates a unique ID for a tool cell
    static func toolsCell(section: Int, item: Int) -> String {
        return "tools_cell_\(section)_\(item)"
    }
}
