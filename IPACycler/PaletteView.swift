import SwiftUI
import AppKit
import Combine

// --- 1. DEFINITIONS & MANAGERS ---

// Standard IPA symbols for English (General American + RP)
// Includes common allophones (tap, aspiration, syllabics) for narrow transcription.

class RecentsManager: ObservableObject {
    static let shared = RecentsManager()
    
    @Published var recents: [IPASymbol] = []
    
    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: "RecentSymbols") {
            self.recents = saved.compactMap { char in
                ipaDatabase.first { $0.char == char }
            }
        }
    }
    
    func add(_ symbol: IPASymbol) {
        recents.removeAll { $0.char == symbol.char }
        recents.insert(symbol, at: 0)
        // Keep top 11 items
        if recents.count > 11 {
            recents = Array(recents.prefix(11))
        }
        
        let charArray = recents.map { $0.char }
        UserDefaults.standard.set(charArray, forKey: "RecentSymbols")
    }
}

class HoverState: ObservableObject {
    @Published var info: String = ""
    @Published var isHovering: Bool = false
}

// --- 2. VISUAL HELPERS ---

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView(frame: .zero)
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// --- 3. MAIN PALETTE VIEW ---

struct PaletteView: View {
    @State private var selectedTab = 0
    @StateObject var hoverState = HoverState()
    let brandPurple = Color(red: 175/255, green: 104/255, blue: 239/255)
    var body: some View {
            ZStack(alignment: .top) {
                
                // 1. Background Blur
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                    .edgesIgnoringSafeArea(.all)
                
                // 2. Grey Header
                Color(NSColor.windowBackgroundColor).opacity(0.6)
                    .frame(height: 40)
                    .edgesIgnoringSafeArea(.top)
                
                // 3. Main Content
                VStack(spacing: 0) {
                    TabView(selection: $selectedTab) {
                        SearchListView()
                            .tabItem { Label("Search", systemImage: "magnifyingglass") }
                            .tag(0)
                        
                        ConsonantChartView()
                            .tabItem { Label("Consonants", systemImage: "mouth") }
                            .tag(1)
                        
                        VowelChartView()
                            .tabItem { Label("Vowels", systemImage: "waveform.path.ecg") }
                            .tag(2)
                        
                        DiacriticsView()
                            .tabItem { Label("Diacritics", systemImage: "text.format.superscript") }
                            .tag(3)
                    }
                    .padding(.top, 10)
                    
                    // --- STATUS BAR ---
                    HStack {
                        // LEFT: Tooltip
                        if hoverState.isHovering {
                            Text(hoverState.info)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            Text("Hover over a symbol for details")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // RIGHT: Branding
                        Text("[ˈæɫ.fəˌbɛ.ɾɚ]")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(brandPurple)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    
                } // <--- END OF VSTACK
                
            } // <--- END OF ZSTACK (Main Container)
            
            // 👇 THESE MODIFIERS MUST BE HERE (Attached to ZStack) 👇
            .frame(minWidth: 550, minHeight: 450)
            .environmentObject(hoverState)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                selectedTab = 0
            }
            .background(
                Button("Close") { NSApp.keyWindow?.close() }
                    .keyboardShortcut(.cancelAction)
                    .opacity(0)
            )
        
        }
    }


// --- 4. SEARCH LIST VIEW ---
struct SearchListView: View {
    @State private var searchText = ""
    @State private var showEnglishOnly = false
    @FocusState private var isSearchFocused: Bool
    
    // NEW: Track exactly which item is being hovered
    @State private var hoveredID: UUID?
    
    @ObservedObject var recents = RecentsManager.shared
    @EnvironmentObject var hoverState: HoverState
    
    let columns = [GridItem(.adaptive(minimum: 50))]
    let purple = Color(red: 175/255, green: 104/255, blue: 239/255)
    
    var filteredSymbols: [IPASymbol] {
        var symbols = ipaDatabase
        
        // 1. English Filter
        if showEnglishOnly {
            // Assumes englishIPA is now globally available from IPAData.swift
            symbols = symbols.filter { englishIPA.contains($0.char) }
        }
        
        // 2. Search Text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            symbols = symbols.filter { symbol in
                symbol.searchKeywords.contains { keyword in
                    keyword.hasPrefix(query)
                }
            }
        }
        
        return symbols
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- SEARCH BAR & TOGGLE ---
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isSearchFocused)
                }
                .padding(8)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(8)
                
                Button(action: {
                    withAnimation(.spring()) {
                        showEnglishOnly.toggle()
                    }
                }) {
                    Text("ENG")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(showEnglishOnly ? purple : Color.primary.opacity(0.1))
                        .foregroundColor(showEnglishOnly ? .white : .secondary)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Show English Phonemes Only")
            }
            .padding(10)
            .padding(.top, 10)
            
            // --- RECENTLY USED ---
            if !recents.recents.isEmpty && searchText.isEmpty {
                VStack(spacing: 5) {
                    Text("Recently Used")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                    
                    HStack(spacing: 5) {
                        ForEach(recents.recents) { symbol in
                            IPAButton(symbol: symbol)
                                .frame(width: 40, height: 40)
                                .background(purple.opacity(0.8))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .onHover { hovering in
                                    if hovering {
                                        hoverState.info = symbol.tooltipInfo
                                        hoverState.isHovering = true
                                    } else {
                                        hoverState.isHovering = false
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 5)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider()
            
            // --- RESULTS GRID ---
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredSymbols) { symbol in
                        VStack {
                            IPAButton(symbol: symbol)
                                .allowsHitTesting(false)
                                // NEW: Change color if this specific ID is hovered
                                .foregroundColor(hoveredID == symbol.id ? purple : .primary)
                                .scaleEffect(hoveredID == symbol.id ? 1.1 : 1.0) // Optional: Tiny pop effect
                                .animation(.easeOut(duration: 0.1), value: hoveredID)
                            
                            Text(symbol.name)
                                .font(.caption2)
                                // Also color the text purple if hovered, or keep it secondary
                                .foregroundColor(hoveredID == symbol.id ? purple : .secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(6)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(6)
                        .onTapGesture {
                            EventTapManager.shared.insertFromMenu(symbol.char)
                            RecentsManager.shared.add(symbol)
                        }
                        .onHover { hovering in
                            if hovering {
                                hoveredID = symbol.id // 1. Set Local ID (Color)
                                hoverState.info = symbol.tooltipInfo // 2. Set Global Info (Bottom Bar)
                                hoverState.isHovering = true
                            } else if hoveredID == symbol.id {
                                hoveredID = nil
                                hoverState.isHovering = false
                            }
                        }
                    }
                }
                .padding()
                
                if filteredSymbols.isEmpty {
                    VStack {
                        Spacer()
                        Text("No symbols found").foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(height: 100)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
        .animation(.spring(), value: recents.recents)
    }
}

