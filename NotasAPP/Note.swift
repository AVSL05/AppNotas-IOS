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
    var reminderPriority: ReminderPriority = .medium
    var category: NoteCategory = .general
    var tags: [String] = []
}

enum FontStyle: String, CaseIterable, Codable {
    case system = "System"
    case serif = "Times New Roman" 
    case monospace = "Courier"
    case rounded = "San Francisco Rounded"
    case comic = "Comic Sans MS"
    
    var displayName: String {
        return self.rawValue
    }
}

enum ReminderPriority: String, CaseIterable, Codable {
    case high = "Urgente"
    case medium = "Media prioridad"
    case low = "Baja prioridad"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "green"
        }
    }
    
    var iconName: String {
        switch self {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "minus.circle.fill"
        }
    }
}

enum NoteCategory: String, CaseIterable, Codable {
    case general = "General"
    case work = "Trabajo"
    case personal = "Personal"
    case study = "Estudio"
    case health = "Salud"
    case finance = "Finanzas"
    case travel = "Viajes"
    case ideas = "Ideas"
    case shopping = "Compras"
    case projects = "Proyectos"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .general: return "note.text"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .study: return "book.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .travel: return "airplane"
        case .ideas: return "lightbulb.fill"
        case .shopping: return "cart.fill"
        case .projects: return "folder.fill"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "gray"
        case .work: return "blue"
        case .personal: return "green"
        case .study: return "purple"
        case .health: return "red"
        case .finance: return "orange"
        case .travel: return "cyan"
        case .ideas: return "yellow"
        case .shopping: return "pink"
        case .projects: return "indigo"
        }
    }
}
