import Foundation

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
    }
    
    func addNote(title: String, content: String, isBold: Bool = false, isItalic: Bool = false, fontStyle: FontStyle = .system) {
        let newNote = Note(title: title, content: content, isBold: isBold, isItalic: isItalic, fontStyle: fontStyle)
        notes.append(newNote)
    }
    
    func updateNote(id: UUID, newTitle: String, newContent: String, isBold: Bool? = nil, isItalic: Bool? = nil, fontStyle: FontStyle? = nil) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].title = newTitle
            notes[index].content = newContent
            if let isBold = isBold { notes[index].isBold = isBold }
            if let isItalic = isItalic { notes[index].isItalic = isItalic }
            if let fontStyle = fontStyle { notes[index].fontStyle = fontStyle }
        }
    }
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
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
