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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header personalizado con título y botón
                    HStack {
                        Text("✨ Mis Notas")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { showingAddNote = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
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
        }
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
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(note.content)
                        .font(.subheadline)
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
                        viewModel.addNote(title: title, content: content)
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
}

struct EditNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NotesViewModel
    let note: Note
    @State private var title: String
    @State private var content: String
    
    init(viewModel: NotesViewModel, note: Note) {
        self.viewModel = viewModel
        self.note = note
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
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
                                .lineLimit(6, reservesSpace: true)
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
                        viewModel.updateNote(id: note.id, newTitle: title, newContent: content)
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

#Preview {
    ContentView()
}
