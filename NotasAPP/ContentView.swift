//
//  ContentView.swift
//  NotasAPP
//
//  Created by Angel Santana on 19/08/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingAddNote = false
    @State private var selectedNote: Note?
    @State private var showingSettings = false
    @State private var settingsToggle = false
    @State private var isDarkMode = false
    @State private var useSystemTheme = true
    @Environment(\.colorScheme) var systemColorScheme
    
    private var currentColorScheme: ColorScheme {
        if useSystemTheme {
            return systemColorScheme
        } else {
            return isDarkMode ? .dark : .light
        }
    }
    
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
                    // Header personalizado con título y botón de configuraciones
                    HStack {
                        Text("Mis Notas")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Solo botón de configuraciones
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
                    .padding(.bottom, 20)
                    
                    // Contenido scrolleable
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if viewModel.notes.isEmpty {
                                EmptyStateView()
                                    .padding(.top, 50)
                            } else {
                                ForEach(viewModel.notes) { note in
                                    NoteCard(note: note) {
                                        selectedNote = note
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                                                viewModel.deleteNote(at: IndexSet(integer: index))
                                            }
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .overlay(
                // Botón flotante para agregar nota
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
                                                colors: [.purple, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }
            )
#if os(iOS)
            .navigationBarHidden(true)
#else
            .navigationTitle("")
#endif
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
        }
        .preferredColorScheme(useSystemTheme ? nil : (isDarkMode ? .dark : .light))
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
                    .fill(.regularMaterial)
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
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
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
                                .applyStyle(isBold: isBold, isItalic: isItalic, fontStyle: selectedFont)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
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
                                    .fill(.regularMaterial)
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
                                .fill(.regularMaterial)
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
                            reminderDate: hasReminder ? reminderDate : nil
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
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
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
                                            .fill(.regularMaterial)
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
                                .applyStyle(isBold: isBold, isItalic: isItalic, fontStyle: selectedFont)
                                .lineLimit(6, reservesSpace: true)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
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
                            .fill(.regularMaterial)
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
                            reminderEnabled: hasReminder
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
                                        .fill(.regularMaterial)
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
                                            .fill(.regularMaterial)
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
                                    .fill(.regularMaterial)
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
