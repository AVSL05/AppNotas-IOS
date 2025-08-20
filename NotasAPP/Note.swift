import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var date: Date = Date()
    var isBold: Bool = false
    var isItalic: Bool = false
    var fontStyle: FontStyle = .system
    var hasReminder: Bool = false
    var reminderDate: Date?
    var reminderEnabled: Bool = false
}

enum FontStyle: String, CaseIterable, Codable {
    case system = "System"
    case serif = "Times New Roman" 
    case monospace = "Courier"
    case rounded = "San Francisco Rounded"
    
    var displayName: String {
        return self.rawValue
    }
}
