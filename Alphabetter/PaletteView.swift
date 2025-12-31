import SwiftUI
import AppKit
import Combine

// MARK: - State Managers
class RecentsManager: ObservableObject {
    static let shared = RecentsManager()
    @Published var recents: [IPASymbol] = []
    
    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: "RecentSymbols") {
            self.recents = saved.compactMap { char in ipaDatabase.first { $0.char == char } }
        }
    }
    
    func add(_ symbol: IPASymbol) {
        recents.removeAll { $0.char == symbol.char }
        recents.insert(symbol, at: 0)
        if recents.count > 11 { recents = Array(recents.prefix(11)) }
        UserDefaults.standard.set(recents.map { $0.char }, forKey: "RecentSymbols")
    }
}

class HoverState: ObservableObject {
    @Published var info: String = ""
    @Published var isHovering: Bool = false
}

// MARK: - Visual Helpers
struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Main View
struct PaletteView: View {
    @State private var selectedTab = 0
    @StateObject var hoverState = HoverState()
    let brandPurple = Color(red: 175/255, green: 104/255, blue: 239/255)
    
    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectBlur().edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    SearchListView().tabItem { Label("Search", systemImage: "magnifyingglass") }.tag(0)
                    ConsonantChartView().tabItem { Label("Consonants", systemImage: "mouth") }.tag(1)
                    VowelChartView().tabItem { Label("Vowels", systemImage: "waveform.path.ecg") }.tag(2)
                    DiacriticsView().tabItem { Label("Diacritics", systemImage: "text.format.superscript") }.tag(3)
                }
                .padding(.top, 10)
                
                HStack(alignment: .firstTextBaseline) {
                    if hoverState.isHovering {
                        Text(hoverState.info)
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    } else {
                        Text("Hover over a symbol for details")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("[ˈæɫ.fəˌbɛ.ɾɚ]")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(brandPurple)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.2))
            }
        }
        .frame(minWidth: 550, minHeight: 450)
        .environmentObject(hoverState)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in selectedTab = 0 }
        .background(Button("Close") { NSApp.keyWindow?.close() }.keyboardShortcut(.cancelAction).opacity(0))
    }
}

// MARK: - Search View
struct SearchListView: View {
    @State private var searchText = ""
    @State private var showEnglishOnly = false
    @FocusState private var isSearchFocused: Bool
    @ObservedObject var recents = RecentsManager.shared
    @EnvironmentObject var hoverState: HoverState
    let purple = Color(red: 175/255, green: 104/255, blue: 239/255)
    
    var filteredSymbols: [IPASymbol] {
        var symbols = ipaDatabase
        if showEnglishOnly { symbols = symbols.filter { englishIPA.contains($0.char) } }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            symbols = symbols.filter { $0.searchKeywords.contains { k in k.hasPrefix(query) } }
        }
        return symbols
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Search Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search...", text: $searchText).textFieldStyle(PlainTextFieldStyle()).focused($isSearchFocused)
                }
                .padding(8).background(Color.primary.opacity(0.1)).cornerRadius(8)
                
                Button(action: { withAnimation(.spring()) { showEnglishOnly.toggle() } }) {
                    Text("ENG").font(.caption).fontWeight(.bold).padding(8)
                        .background(showEnglishOnly ? purple : Color.primary.opacity(0.1))
                        .foregroundColor(showEnglishOnly ? .white : .secondary).cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle()).help("Show English Phonemes Only")
            }
            .padding(10).padding(.top, 10)
            
            // Recents Section
            if !recents.recents.isEmpty && searchText.isEmpty {
                VStack(spacing: 5) {
                    Text("Recently Used").font(.caption).fontWeight(.semibold).foregroundColor(.secondary).padding(.top, 5)
                    HStack(spacing: 5) {
                        ForEach(recents.recents) { symbol in
                            IPAButton(symbol: symbol)
                                .frame(width: 40, height: 40)
                                .background(Color.primary.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(purple.opacity(0.4), lineWidth: 1))
                        }
                    }.padding(.horizontal, 8).padding(.bottom, 5)
                }
            }
            
            Divider()
            
            // Grid Results
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                    ForEach(filteredSymbols) { symbol in
                        SearchResultCard(symbol: symbol)
                    }
                }.padding()
                if filteredSymbols.isEmpty { Spacer(); Text("No symbols found").foregroundColor(.secondary); Spacer() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isSearchFocused = true }
        }
    }
}

// MARK: - Interactive Card
struct SearchResultCard: View {
    let symbol: IPASymbol
    @EnvironmentObject var hoverState: HoverState
    @State private var isHovering = false
    
    let purple = Color(red: 175/255, green: 104/255, blue: 239/255)
    
    var body: some View {
        Button(action: {
            EventTapManager.shared.insertFromMenu(symbol.char)
            RecentsManager.shared.add(symbol)
        }) {
            VStack {
                Text(symbol.type == .diacritic ? "◌" + symbol.char : symbol.char)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundColor(isHovering ? purple : .primary)
                    .scaleEffect(isHovering ? 1.2 : 1.0)
                    .frame(height: 30) // Fixed height for alignment
                
                Text(symbol.name)
                    .font(.caption2)
                    .foregroundColor(isHovering ? purple : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.primary.opacity(isHovering ? 0.1 : 0.05))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
            hoverState.isHovering = hovering
            if hovering { hoverState.info = symbol.tooltipInfo }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
    }
}
