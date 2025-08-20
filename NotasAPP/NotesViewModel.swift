import Foundation
import UserNotifications

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet {
            saveNotes()
        }
    }
    @Published var selectedCategory: NoteCategory? = nil
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    
    private let notesKey = "notes_key"
    
    init() {
        loadNotes()
        requestNotificationPermission()
    }
    
    // MARK: - Computed Properties for Filtering
    
    var filteredNotes: [Note] {
        var filtered = notes
        
        // Filtrar por categoría
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filtrar por texto de búsqueda
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filtrar por tags seleccionados
        if !selectedTags.isEmpty {
            filtered = filtered.filter { note in
                !Set(note.tags).isDisjoint(with: selectedTags)
            }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    var availableTags: [String] {
        let allTags = notes.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    var notesCountByCategory: [NoteCategory: Int] {
        var counts: [NoteCategory: Int] = [:]
        for category in NoteCategory.allCases {
            counts[category] = notes.filter { $0.category == category }.count
        }
        return counts
    }
    
    // MARK: - Category and Tags Management
    
    func setSelectedCategory(_ category: NoteCategory?) {
        selectedCategory = category
    }
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func clearFilters() {
        selectedCategory = nil
        searchText = ""
        selectedTags.removeAll()
    }
    
    func addNote(title: String, content: String, isBold: Bool = false, isItalic: Bool = false, fontStyle: FontStyle = .system, reminderDate: Date? = nil, category: NoteCategory = .general, tags: [String] = []) {
        var newNote = Note(title: title, content: content, isBold: isBold, isItalic: isItalic, fontStyle: fontStyle, category: category, tags: tags)
        
        if let reminderDate = reminderDate {
            newNote.hasReminder = true
            newNote.reminderDate = reminderDate
            newNote.reminderEnabled = true
            scheduleNotification(for: newNote)
        }
        
        notes.append(newNote)
    }
    
    func updateNote(id: UUID, newTitle: String, newContent: String, isBold: Bool? = nil, isItalic: Bool? = nil, fontStyle: FontStyle? = nil, reminderDate: Date? = nil, reminderEnabled: Bool? = nil, category: NoteCategory? = nil, tags: [String]? = nil) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            // Cancelar notificación anterior si existe
            if notes[index].hasReminder {
                cancelNotification(for: notes[index])
            }
            
            notes[index].title = newTitle
            notes[index].content = newContent
            if let isBold = isBold { notes[index].isBold = isBold }
            if let isItalic = isItalic { notes[index].isItalic = isItalic }
            if let fontStyle = fontStyle { notes[index].fontStyle = fontStyle }
            if let category = category { notes[index].category = category }
            if let tags = tags { notes[index].tags = tags }
            
            // Actualizar recordatorio
            if let reminderDate = reminderDate {
                notes[index].hasReminder = true
                notes[index].reminderDate = reminderDate
                notes[index].reminderEnabled = reminderEnabled ?? true
                
                if notes[index].reminderEnabled {
                    scheduleNotification(for: notes[index])
                }
            } else if let reminderEnabled = reminderEnabled {
                notes[index].reminderEnabled = reminderEnabled
                
                if reminderEnabled && notes[index].hasReminder {
                    scheduleNotification(for: notes[index])
                }
            }
        }
    }
    
    func toggleReminder(for noteId: UUID) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].reminderEnabled.toggle()
            
            if notes[index].reminderEnabled && notes[index].hasReminder {
                scheduleNotification(for: notes[index])
            } else {
                cancelNotification(for: notes[index])
            }
        }
    }
    
    func deleteNote(at offsets: IndexSet) {
        // Cancelar notificaciones antes de eliminar
        for index in offsets {
            if notes[index].hasReminder {
                cancelNotification(for: notes[index])
            }
        }
        notes.remove(atOffsets: offsets)
    }
    
    // MARK: - Notification Methods
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func scheduleNotification(for note: Note) {
        guard let reminderDate = note.reminderDate, reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📝 Recordatorio de Nota"
        content.body = "\(note.title)\n\(note.content.prefix(100))"
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: note.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func cancelNotification(for note: Note) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [note.id.uuidString])
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    private func loadNotes() {
        if let savedNotes = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: savedNotes) {
            notes = decoded
        }
    }
}
