import Foundation
import UserNotifications

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet {
            saveNotes()
        }
    }
    
    private let notesKey = "notes_key"
    
    init() {
        loadNotes()
        requestNotificationPermission()
    }
    
    func addNote(title: String, content: String, isBold: Bool = false, isItalic: Bool = false, fontStyle: FontStyle = .system, reminderDate: Date? = nil) {
        var newNote = Note(title: title, content: content, isBold: isBold, isItalic: isItalic, fontStyle: fontStyle)
        
        if let reminderDate = reminderDate {
            newNote.hasReminder = true
            newNote.reminderDate = reminderDate
            newNote.reminderEnabled = true
            scheduleNotification(for: newNote)
        }
        
        notes.append(newNote)
    }
    
    func updateNote(id: UUID, newTitle: String, newContent: String, isBold: Bool? = nil, isItalic: Bool? = nil, fontStyle: FontStyle? = nil, reminderDate: Date? = nil, reminderEnabled: Bool? = nil) {
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
