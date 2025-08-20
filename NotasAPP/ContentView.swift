import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingAddNote = false
    @State private var showingSettings = false
    @State private var selectedNote: Note?
    @State private var settingsToggle = false
    @State private var isDarkMode = false
    @State private var useSystemTheme = true
    @Environment(\.colorScheme) private var currentColorScheme
    
    var body: some View {
        TabView {
            // Pestaña de Lista de Notas
            NotesListView(viewModel: viewModel, showingSettings: $showingSettings, showingAddNote: $showingAddNote)
                .tabItem {
                    Image(systemName: "note.text")
                    Text("Notas")
                }
            
            // Pestaña de Calendario
            CalendarView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendario")
                }
        }
        .accentColor(.purple)
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(viewModel: viewModel)
        }
        .sheet(item: $selectedNote) { note in
            EditNoteView(viewModel: viewModel, note: note)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                settingsToggle: $settingsToggle,
                isDarkMode: $isDarkMode,
                useSystemTheme: $useSystemTheme
            )
        }
        .preferredColorScheme(useSystemTheme ? nil : (isDarkMode ? .dark : .light))
    }
}

// MARK: - Notes List View
struct NotesListView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Binding var showingSettings: Bool
    @Binding var showingAddNote: Bool
    @State private var selectedNote: Note?
    @State private var showingCategoryFilter = false
    @Environment(\.colorScheme) private var currentColorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente adaptativo
                LinearGradient(
                    gradient: Gradient(colors: currentColorScheme == .dark ? 
                        [Color.purple.opacity(0.2), Color.blue.opacity(0.2)] :
                        [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header personalizado con título y botones
                    HStack {
                        Text("Mis Notas")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Botón de filtros por categoría
                        Button(action: { showingCategoryFilter.toggle() }) {
                            Image(systemName: viewModel.selectedCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        // Botón de configuraciones
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Barra de búsqueda
                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    
                    // Filtros de categorías (cuando está visible)
                    if showingCategoryFilter {
                        CategoryFilterView(viewModel: viewModel)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                    }
                    
                    // Indicador de filtros activos
                    ActiveFiltersView(viewModel: viewModel)
                        .padding(.horizontal, 20)
                    
                    // Lista de notas o estado vacío
                    if viewModel.filteredNotes.isEmpty {
                        if viewModel.notes.isEmpty {
                            EmptyStateView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            EmptyFilterStateView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredNotes) { note in
                                    NoteCard(note: note) {
                                        selectedNote = note
                                    }
                                }
                                .onDelete { indexSet in
                                    // Convertir índices de filteredNotes a índices de notes
                                    let notesToDelete = indexSet.map { viewModel.filteredNotes[$0] }
                                    for note in notesToDelete {
                                        if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                                            viewModel.deleteNote(at: IndexSet(integer: index))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100) // Espacio para el botón flotante
                        }
                    }
                }
                
                // Botón flotante para agregar nueva nota
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: { showingAddNote = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .sheet(item: $selectedNote) { note in
                EditNoteView(viewModel: viewModel, note: note)
            }
        }
    }
}

// MARK: - Calendar View
struct CompactReminderCard: View {
    let note: Note
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.orange.gradient)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? "Sin título" : note.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let reminderDate = note.reminderDate {
                    Text(reminderDate, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.orange.opacity(0.1))
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HorizontalReminderCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Encabezado con icono y título
            HStack(spacing: 6) {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text(note.title.isEmpty ? "Sin título" : note.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            
            // Contenido de la nota (si existe)
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Información del recordatorio
            if let reminderDate = note.reminderDate {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                        .font(.caption2)
                    
                    Text(reminderDate, style: .time)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(width: 200, height: 100) // Ancho fijo para scroll horizontal
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.orange.opacity(0.1))
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ImprovedReminderCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Encabezado con icono y título
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                Text(note.title.isEmpty ? "Sin título" : note.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // Contenido de la nota (si existe)
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            // Información del recordatorio
            if let reminderDate = note.reminderDate {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reminderDate, style: .time)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(reminderDate, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.orange.opacity(0.1))
                .stroke(.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CalendarView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var selectedDate = Date()
    @Environment(\.colorScheme) private var currentColorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente adaptativo
                LinearGradient(
                    gradient: Gradient(colors: currentColorScheme == .dark ? 
                        [Color.green.opacity(0.2), Color.blue.opacity(0.2)] :
                        [Color.green.opacity(0.1), Color.blue.opacity(0.1)]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Calendario de Recordatorios")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Contenido principal con diseño vertical
                    VStack(spacing: 16) {
                        // Calendario grande arriba (ocupa la mayor parte)
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Calendario")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            // Calendario personalizado con indicadores
                            CustomCalendarView(
                                selectedDate: $selectedDate,
                                datesWithReminders: getDatesWithReminders()
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity) // Ocupa todo el espacio disponible
                        
                        // Lista de recordatorios abajo (sección compacta)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.orange)
                                Text("Recordatorios para \(selectedDate, formatter: dateFormatter)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            let remindersForDate = getRemindersForDate(selectedDate)
                            
                            if remindersForDate.isEmpty {
                                HStack {
                                    Image(systemName: "calendar.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                    Text("No hay recordatorios para esta fecha")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.regularMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(remindersForDate) { note in
                                            HorizontalReminderCard(note: note)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.regularMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 150) // Altura fija para la sección de recordatorios
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
    
    private func getRemindersForDate(_ date: Date) -> [Note] {
        let calendar = Calendar.current
        return viewModel.notes.filter { note in
            guard let reminderDate = note.reminderDate,
                  note.hasReminder && note.reminderEnabled else {
                return false
            }
            return calendar.isDate(reminderDate, inSameDayAs: date)
        }
    }
    
    // Función para verificar si una fecha tiene recordatorios
    private func hasReminders(for date: Date) -> Bool {
        let calendar = Calendar.current
        return viewModel.notes.contains { note in
            guard note.hasReminder,
                  note.reminderEnabled,
                  let reminderDate = note.reminderDate else { return false }
            return calendar.isDate(reminderDate, inSameDayAs: date)
        }
    }
    
    // Obtener todas las fechas con recordatorios
    private func getDatesWithReminders() -> Set<Date> {
        let calendar = Calendar.current
        var dates = Set<Date>()
        
        for note in viewModel.notes {
            if note.hasReminder,
               note.reminderEnabled,
               let reminderDate = note.reminderDate {
                // Normalizar la fecha al inicio del día
                let normalizedDate = calendar.startOfDay(for: reminderDate)
                dates.insert(normalizedDate)
            }
        }
        
        return dates
    }
}

// MARK: - Reminder Card
struct ReminderCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                Text(note.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if let reminderDate = note.reminderDate {
                    Text(reminderDate, style: .time)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.2))
                        )
                        .foregroundColor(.orange)
                }
            }
            
            Text(note.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("¡Tu primer nota te espera!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Toca el botón + para crear tu primera nota")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct NoteCard: View {
    let note: Note
    let onTap: () -> Void
    
    private var cardColors: [Color] {
        let colors = [
            [Color.pink, Color.orange],
            [Color.blue, Color.cyan],
            [Color.green, Color.mint],
            [Color.purple, Color.indigo],
            [Color.orange, Color.yellow],
            [Color.red, Color.pink]
        ]
        return colors[abs(note.id.hashValue) % colors.count]
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Icono colorido
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: cardColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "doc.text.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(note.title)
                        .applyNoteStyle(isBold: note.isBold, isItalic: note.isItalic, fontStyle: note.fontStyle, size: 18)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(note.content)
                        .applyNoteStyle(isBold: note.isBold, isItalic: note.isItalic, fontStyle: note.fontStyle, size: 14)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Categoría y tags
                    HStack(spacing: 8) {
                        // Categoría
                        CategoryBadge(category: note.category)
                        
                        // Tags (máximo 2 visibles)
                        if !note.tags.isEmpty {
                            ForEach(Array(note.tags.prefix(2)), id: \.self) { tag in
                                TagBadge(tag: tag)
                            }
                            
                            if note.tags.count > 2 {
                                Text("+\(note.tags.count - 2)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(note.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Indicador de recordatorio
                        if note.hasReminder && note.reminderEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                if let reminderDate = note.reminderDate {
                                    Text(reminderDate, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.15))
                            )
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NotesViewModel
    @State private var title = ""
    @State private var content = ""
    @State private var isBold = false
    @State private var isItalic = false
    @State private var selectedFont: FontStyle = .system
    @State private var hasReminder = false
    @State private var reminderDate = Date()
    @State private var selectedCategory: NoteCategory = .general
    @State private var tags: [String] = []
    @State private var newTag = ""
    @FocusState private var titleIsFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header con icono
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                        
                        Text("Nueva Nota")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Campo de título
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "textformat.size")
                                    .foregroundColor(.green)
                                Text("Título")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            TextField("Escribe un título genial...", text: $title)
                                .focused($titleIsFocused)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.regularMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        
                        // Campo de contenido
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                Text("Contenido")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            TextField("¿Qué tienes en mente?", text: $content, axis: .vertical)
                                .lineLimit(6, reservesSpace: true)
                                .font(selectedFont.font(size: 16))
                                .fontWeight(isBold ? .bold : .regular)
                                .italic(isItalic)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.regularMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        
                        // Controles de formato
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "textformat")
                                    .foregroundColor(.purple)
                                Text("Formato")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(spacing: 12) {
                                // Botones de formato
                                HStack(spacing: 15) {
                                    Button(action: { isBold.toggle() }) {
                                        HStack {
                                            Image(systemName: "bold")
                                            Text("Negrita")
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isBold ? Color.purple.opacity(0.2) : Color.clear)
                                                .stroke(Color.purple, lineWidth: isBold ? 2 : 1)
                                        )
                                        .foregroundColor(isBold ? .purple : .primary)
                                    }
                                    
                                    Button(action: { isItalic.toggle() }) {
                                        HStack {
                                            Image(systemName: "italic")
                                            Text("Cursiva")
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isItalic ? Color.blue.opacity(0.2) : Color.clear)
                                                .stroke(Color.blue, lineWidth: isItalic ? 2 : 1)
                                        )
                                        .foregroundColor(isItalic ? .blue : .primary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Selector de fuente
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Fuente")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(FontStyle.allCases, id: \.self) { font in
                                                Button(action: { selectedFont = font }) {
                                                    Text(font.displayName)
                                                        .font(font.font(size: 14))
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .fill(selectedFont == font ? Color.green.opacity(0.2) : Color.clear)
                                                                .stroke(Color.green, lineWidth: selectedFont == font ? 2 : 1)
                                                        )
                                                        .foregroundColor(selectedFont == font ? .green : .primary)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                                
                                // Vista previa del texto
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Vista previa:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(content.isEmpty ? "Ejemplo de texto con formato" : content)
                                        .applyNoteStyle(isBold: isBold, isItalic: isItalic, fontStyle: selectedFont)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.1))
                                        )
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Material.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                        
                        // Sección de recordatorio
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.orange)
                                Text("Recordatorio")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            // Sección de categoría
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Categoría")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(NoteCategory.allCases, id: \.self) { category in
                                        CategorySelectionCard(
                                            category: category,
                                            isSelected: selectedCategory == category,
                                            action: { selectedCategory = category }
                                        )
                                    }
                                }
                            }
                            
                            // Sección de tags
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Etiquetas")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                // Tags existentes
                                if !tags.isEmpty {
                                    FlexibleView(data: tags, spacing: 8, alignment: .leading) { tag in
                                        HStack(spacing: 4) {
                                            Text("#\(tag)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                            
                                            Button(action: {
                                                tags.removeAll { $0 == tag }
                                            }) {
                                                Image(systemName: "xmark")
                                                    .font(.caption2)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(.blue.opacity(0.15))
                                                .stroke(.blue.opacity(0.3), lineWidth: 0.5)
                                        )
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                // Agregar nuevo tag
                                HStack {
                                    TextField("Agregar etiqueta...", text: $newTag)
                                        .textFieldStyle(.plain)
                                        .onSubmit {
                                            addTag()
                                        }
                                    
                                    Button("Agregar", action: addTag)
                                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            Toggle(isOn: $hasReminder) {
                                HStack {
                                    Image(systemName: hasReminder ? "bell.badge.fill" : "bell.slash.fill")
                                        .foregroundColor(hasReminder ? .green : .gray)
                                    Text("Programar recordatorio")
                                        .font(.subheadline)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            
                            if hasReminder {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Fecha y hora")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    DatePicker(
                                        "Fecha del recordatorio",
                                        selection: $reminderDate,
                                        in: Date()...,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text("Recibirás una notificación en la fecha seleccionada")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Material.regularMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        }
                    }
                    
                    // Espaciado adicional al final para mejor UX
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                }
            }
            .navigationTitle("🎨 Crear")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        viewModel.addNote(
                            title: title, 
                            content: content,
                            isBold: isBold,
                            isItalic: isItalic,
                            fontStyle: selectedFont,
                            reminderDate: hasReminder ? reminderDate : nil,
                            category: selectedCategory,
                            tags: tags
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                title.isEmpty || content.isEmpty ? 
                                AnyShapeStyle(Color.gray.opacity(0.3)) :
                                AnyShapeStyle(LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            )
                    )
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                titleIsFocused = true
            }
        }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
}

struct EditNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NotesViewModel
    let note: Note
    @State private var title: String
    @State private var content: String
    @State private var isBold: Bool
    @State private var isItalic: Bool
    @State private var selectedFont: FontStyle
    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @State private var selectedCategory: NoteCategory
    @State private var tags: [String]
    @State private var newTag = ""
    
    init(viewModel: NotesViewModel, note: Note) {
        self.viewModel = viewModel
        self.note = note
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        _isBold = State(initialValue: note.isBold)
        _isItalic = State(initialValue: note.isItalic)
        _selectedFont = State(initialValue: note.fontStyle)
        _hasReminder = State(initialValue: note.hasReminder)
        _reminderDate = State(initialValue: note.reminderDate ?? Date())
        _selectedCategory = State(initialValue: note.category)
        _tags = State(initialValue: note.tags)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.pink.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header con icono
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                        
                        Text("Editar Nota")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Campo de título
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "textformat.size")
                                    .foregroundColor(.orange)
                                Text("Título")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            TextField("Título de la nota", text: $title)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.regularMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        
                        // Controles de formato
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "textformat")
                                    .foregroundColor(.purple)
                                Text("Formato del texto")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            // Botones de formato
                            HStack(spacing: 16) {
                                Button(action: { isBold.toggle() }) {
                                    HStack {
                                        Image(systemName: "bold")
                                        Text("Negrita")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isBold ? 
                                                  AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                                                  AnyShapeStyle(Color.gray.opacity(0.2)))
                                    )
                                    .foregroundColor(isBold ? .white : .primary)
                                }
                                
                                Button(action: { isItalic.toggle() }) {
                                    HStack {
                                        Image(systemName: "italic")
                                        Text("Cursiva")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isItalic ? 
                                                  AnyShapeStyle(LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)) :
                                                  AnyShapeStyle(Color.gray.opacity(0.2)))
                                    )
                                    .foregroundColor(isItalic ? .white : .primary)
                                }
                                
                                Spacer()
                            }
                            
                            // Selector de fuente
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Estilo de fuente")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 8) {
                                    ForEach(FontStyle.allCases, id: \.self) { fontStyle in
                                        Button(action: { selectedFont = fontStyle }) {
                                            Text(fontStyle.displayName)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(selectedFont == fontStyle ? 
                                                              AnyShapeStyle(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)) :
                                                              AnyShapeStyle(Color.gray.opacity(0.2)))
                                                )
                                                .foregroundColor(selectedFont == fontStyle ? .white : .primary)
                                        }
                                    }
                                }
                            }
                            
                            // Vista previa del texto
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Vista previa")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(content.isEmpty ? "Tu texto aparecerá aquí..." : content)
                                    .applyStyle(isBold: isBold, isItalic: isItalic, fontStyle: selectedFont)
                                    .lineLimit(2)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Material.regularMaterial)
                                    )
                            }
                        }
                        
                        // Campo de contenido
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.pink)
                                Text("Contenido")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            TextField("Contenido de la nota", text: $content, axis: .vertical)
                                .font(selectedFont.font(size: 16))
                                .fontWeight(isBold ? .bold : .regular)
                                .italic(isItalic)
                                .lineLimit(6, reservesSpace: true)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.regularMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                    
                    // Sección de recordatorio
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Recordatorio")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        // Sección de categoría
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Categoría")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(NoteCategory.allCases, id: \.self) { category in
                                    CategorySelectionCard(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                        }
                        
                        // Sección de tags
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Etiquetas")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            // Tags existentes
                            if !tags.isEmpty {
                                FlexibleView(data: tags, spacing: 8, alignment: .leading) { tag in
                                    HStack(spacing: 4) {
                                        Text("#\(tag)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        
                                        Button(action: {
                                            tags.removeAll { $0 == tag }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.caption2)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(.blue.opacity(0.15))
                                            .stroke(.blue.opacity(0.3), lineWidth: 0.5)
                                    )
                                    .foregroundColor(.blue)
                                }
                            }
                            
                            // Agregar nuevo tag
                            HStack {
                                TextField("Agregar etiqueta...", text: $newTag)
                                    .textFieldStyle(.plain)
                                    .onSubmit {
                                        addTag()
                                    }
                                
                                Button("Agregar", action: addTag)
                                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Toggle(isOn: $hasReminder) {
                            HStack {
                                Image(systemName: hasReminder ? "bell.badge.fill" : "bell.slash.fill")
                                    .foregroundColor(hasReminder ? .green : .gray)
                                Text("Programar recordatorio")
                                    .font(.subheadline)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        
                        if hasReminder {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fecha y hora")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                DatePicker(
                                    "Fecha del recordatorio",
                                    selection: $reminderDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Recibirás una notificación en la fecha seleccionada")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Material.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    
                    // Espaciado adicional al final para mejor UX
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                }
            }
            .navigationTitle("Editar")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        viewModel.updateNote(
                            id: note.id, 
                            newTitle: title, 
                            newContent: content,
                            isBold: isBold,
                            isItalic: isItalic,
                            fontStyle: selectedFont,
                            reminderDate: hasReminder ? reminderDate : nil,
                            reminderEnabled: hasReminder,
                            category: selectedCategory,
                            tags: tags
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                title.isEmpty || content.isEmpty ? 
                                AnyShapeStyle(Color.gray.opacity(0.3)) :
                                AnyShapeStyle(LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            )
                    )
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var systemColorScheme
    @Binding var settingsToggle: Bool
    @Binding var isDarkMode: Bool
    @Binding var useSystemTheme: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.black.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header con icono
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                        
                        Text("Configuraciones")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Sección de configuraciones
                    VStack(spacing: 20) {
                        // Configuración de tema
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.indigo)
                                Text("Configuración de Tema")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(spacing: 12) {
                                // Toggle para usar tema del sistema
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Usar tema del sistema")
                                            .font(.body)
                                        Text("Detecta automáticamente el modo claro/oscuro")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $useSystemTheme)
                                        .tint(.indigo)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.regularMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                                
                                // Toggle para modo oscuro manual (solo si no usa tema del sistema)
                                if !useSystemTheme {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Modo oscuro")
                                                .font(.body)
                                            Text("Activar tema oscuro manualmente")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $isDarkMode)
                                            .tint(.purple)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Material.regularMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                }
                                
                                // Indicador del tema actual
                                HStack {
                                    Image(systemName: useSystemTheme ? 
                                        (systemColorScheme == .dark ? "moon.circle.fill" : "sun.max.circle.fill") :
                                        (isDarkMode ? "moon.circle.fill" : "sun.max.circle.fill")
                                    )
                                    .foregroundColor(useSystemTheme ? 
                                        (systemColorScheme == .dark ? .purple : .orange) :
                                        (isDarkMode ? .purple : .orange)
                                    )
                                    
                                    Text("Tema actual: \(useSystemTheme ? "Sistema (\(systemColorScheme == .dark ? "Oscuro" : "Claro"))" : (isDarkMode ? "Oscuro" : "Claro"))")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // Configuración de prueba original
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                Text("Configuración de Prueba")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Activar función de prueba")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $settingsToggle)
                                    .tint(.orange)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Material.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("⚙️ Configuraciones")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Font Extension
extension FontStyle {
    func font(size: CGFloat = 16) -> Font {
        switch self {
        case .system:
            return .system(size: size)
        case .serif:
            return .custom("Times New Roman", size: size)
        case .monospace:
            return .custom("Courier", size: size)
        case .rounded:
            return .system(size: size, design: .rounded)
        }
    }
}

// MARK: - Text Styling Extensions
extension Text {
    func applyNoteStyle(isBold: Bool, isItalic: Bool, fontStyle: FontStyle, size: CGFloat = 16) -> Text {
        var text = self.font(fontStyle.font(size: size))
        
        if isBold && isItalic {
            text = text.fontWeight(.bold).italic()
        } else if isBold {
            text = text.fontWeight(.bold)
        } else if isItalic {
            text = text.italic()
        }
        
        return text
    }
}

extension View {
    func applyStyle(isBold: Bool, isItalic: Bool, fontStyle: FontStyle, size: CGFloat = 16) -> some View {
        self
            .font(fontStyle.font(size: size))
            .fontWeight(isBold ? .bold : .regular)
            .italic(isItalic)
    }
}

#Preview {
    ContentView()
}

// MARK: - Custom Calendar View
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let datesWithReminders: Set<Date>
    @State private var currentMonth = Date()
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header del mes
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Días de la semana
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Grid de días
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    DayView(
                        date: date,
                        selectedDate: $selectedDate,
                        hasReminder: hasReminder(for: date),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    )
                }
            }
            .padding(.horizontal)
            
            // Leyenda
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                    Text("Con recordatorios")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            currentMonth = selectedDate
        }
    }
    
    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate <= monthLastWeek.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func hasReminder(for date: Date) -> Bool {
        let normalizedDate = calendar.startOfDay(for: date)
        return datesWithReminders.contains(normalizedDate)
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

// MARK: - Day View
struct DayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let hasReminder: Bool
    let isCurrentMonth: Bool
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
    
    var body: some View {
        ZStack {
            // Fondo del día
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? .blue : .clear)
                .frame(height: 40)
            
            VStack(spacing: 2) {
                // Número del día
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday ? .blue :
                        isCurrentMonth ? .primary : .secondary
                    )
                
                // Indicador de recordatorio
                if hasReminder {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .onTapGesture {
            selectedDate = date
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Buscar notas...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Material.regularMaterial)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Category Filter View
struct CategoryFilterView: View {
    @ObservedObject var viewModel: NotesViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Botón "Todas"
                CategoryFilterChip(
                    title: "Todas",
                    icon: "square.grid.2x2",
                    color: "gray",
                    count: viewModel.notes.count,
                    isSelected: viewModel.selectedCategory == nil,
                    action: { viewModel.setSelectedCategory(nil) }
                )
                
                // Botones de categorías
                ForEach(NoteCategory.allCases, id: \.self) { category in
                    let count = viewModel.notesCountByCategory[category] ?? 0
                    CategoryFilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        color: category.color,
                        count: count,
                        isSelected: viewModel.selectedCategory == category,
                        action: { 
                            viewModel.setSelectedCategory(
                                viewModel.selectedCategory == category ? nil : category
                            )
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Category Filter Chip
struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let color: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var chipColor: Color {
        switch color {
        case "gray": return .gray
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "pink": return .pink
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? chipColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .stroke(isSelected ? chipColor : .secondary.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(isSelected ? chipColor : .primary)
        }
    }
}

// MARK: - Active Filters View
struct ActiveFiltersView: View {
    @ObservedObject var viewModel: NotesViewModel
    
    var body: some View {
        if viewModel.selectedCategory != nil || !viewModel.searchText.isEmpty || !viewModel.selectedTags.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Filtros activos:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let category = viewModel.selectedCategory {
                    ActiveFilterTag(text: category.displayName, color: category.color) {
                        viewModel.setSelectedCategory(nil)
                    }
                }
                
                if !viewModel.searchText.isEmpty {
                    ActiveFilterTag(text: "Búsqueda: \(viewModel.searchText)", color: "blue") {
                        viewModel.searchText = ""
                    }
                }
                
                Spacer()
                
                Button("Limpiar", action: viewModel.clearFilters)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Active Filter Tag
struct ActiveFilterTag: View {
    let text: String
    let color: String
    let onRemove: () -> Void
    
    private var tagColor: Color {
        switch color {
        case "gray": return .gray
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "pink": return .pink
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption2)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(tagColor.opacity(0.2))
                .stroke(tagColor.opacity(0.5), lineWidth: 1)
        )
        .foregroundColor(tagColor)
    }
}

// MARK: - Empty Filter State View
struct EmptyFilterStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No se encontraron notas")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Intenta ajustar los filtros o la búsqueda")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: NoteCategory
    
    private var categoryColor: Color {
        switch category.color {
        case "gray": return .gray
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "pink": return .pink
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            Text(category.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(categoryColor.opacity(0.15))
                .stroke(categoryColor.opacity(0.3), lineWidth: 0.5)
        )
        .foregroundColor(categoryColor)
    }
}

// MARK: - Tag Badge
struct TagBadge: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(.blue.opacity(0.15))
                    .stroke(.blue.opacity(0.3), lineWidth: 0.5)
            )
            .foregroundColor(.blue)
    }
}

// MARK: - Category Selection Card
struct CategorySelectionCard: View {
    let category: NoteCategory
    let isSelected: Bool
    let action: () -> Void
    
    private var categoryColor: Color {
        switch category.color {
        case "gray": return .gray
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "pink": return .pink
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : categoryColor)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? categoryColor : categoryColor.opacity(0.1))
                    .stroke(categoryColor, lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Flexible View (for tags layout)
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State private var availableWidth: CGFloat = 0

    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }

            FlexibleViewLayout(
                data: data,
                spacing: spacing,
                availableWidth: availableWidth,
                content: content
            )
        }
    }
}

struct FlexibleViewLayout<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let availableWidth: CGFloat
    let content: (Data.Element) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowData in
                HStack(spacing: spacing) {
                    ForEach(rowData, id: \.self) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = []
        var currentRow: [Data.Element] = []
        var currentRowWidth: CGFloat = 0

        for item in data {
            let itemWidth = estimateItemWidth(item)
            let itemWithSpacing = itemWidth + (currentRow.isEmpty ? 0 : spacing)

            if currentRowWidth + itemWithSpacing <= availableWidth {
                currentRow.append(item)
                currentRowWidth += itemWithSpacing
            } else {
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = [item]
                currentRowWidth = itemWidth
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    func estimateItemWidth(_ item: Data.Element) -> CGFloat {
        return CGFloat(String(describing: item).count * 8 + 20)
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
