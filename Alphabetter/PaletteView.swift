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
        view.material = .popover // macOS Tahoe-like liquid glass
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Main View
struct PaletteView: View {
    @AppStorage("lastSelectedTab") private var selectedTab = 0
    @StateObject var hoverState = HoverState()
    @AppStorage("appTheme") private var appTheme = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("appAccentColor") private var appAccentColor = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectBlur().edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    TabButton(title: "Search", tab: 0, selectedTab: $selectedTab)
                    TabButton(title: "Consonants", tab: 1, selectedTab: $selectedTab)
                    TabButton(title: "Vowels", tab: 2, selectedTab: $selectedTab)
                    TabButton(title: "Diacritics", tab: 3, selectedTab: $selectedTab)
                    TabButton(title: "Settings", tab: 4, selectedTab: $selectedTab)
                }
                .id("tabs_\(appAccentColor)_\(appTheme)")
                .padding(.top, 15)
                .padding(.bottom, 10)
                
                ZStack {
                    if selectedTab == 0 { SearchListView() }
                    else if selectedTab == 1 { ConsonantChartView() }
                    else if selectedTab == 2 { VowelChartView() }
                    else if selectedTab == 3 { DiacriticsView() }
                    else if selectedTab == 4 { SettingsView() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                HStack(alignment: .firstTextBaseline) {
                    if hoverState.isHovering {
                        Text(hoverState.info)
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.primary.opacity(0.9)) // Dynamically adapt to light/dark
                    } else {
                        Text("Hover over a symbol for details")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("[ˈæɫ.fəˌbɛ.ɾɚ]")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandAccent)
                        .id("logo_\(appAccentColor)_\(appTheme)")
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.05)) // Softer footer area
            }
            .id("palette_\(appTheme)") // Force overall view interior trait re-evaluation on theme switch
        }
        .frame(minWidth: 500, minHeight: 450)
        .onAppear { updateAppearance(theme: appTheme) }
        .onChange(of: appTheme) { _, newValue in updateAppearance(theme: newValue) }
        .environmentObject(hoverState)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToSettingsTab"))) { _ in
            selectedTab = 4
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToSearchTab"))) { _ in
            selectedTab = 0
        }
        .background(
            ZStack {
                Button("Close") { NSApp.keyWindow?.close() }.keyboardShortcut(.cancelAction)
                Button("Settings") { selectedTab = 4 }.keyboardShortcut(",", modifiers: .command)
                Button("Search") { NotificationCenter.default.post(name: NSNotification.Name("SwitchToSearchTab"), object: nil) }.keyboardShortcut("f", modifiers: .command)
            }
            .opacity(0)
        )
    }

    private func updateAppearance(theme: Int) {
        NSApp.appearance = theme == 1 ? NSAppearance(named: .aqua) : (theme == 2 ? NSAppearance(named: .darkAqua) : nil)
    }
}

// MARK: - Search View
struct SearchListView: View {
    @State private var searchText = ""
    @AppStorage("selectedProfileId") private var selectedProfileId: String = "All"
    @FocusState private var isSearchFocused: Bool
    @ObservedObject var recents = RecentsManager.shared
    @EnvironmentObject var hoverState: HoverState
    @EnvironmentObject var profileManager: ProfileManager
    @AppStorage("appAccentColor") private var appAccentColor = 0
    
    var filteredSymbols: [IPASymbol] {
        var symbols = ipaDatabase
        if selectedProfileId == "English" {
            symbols = symbols.filter { englishIPA.contains($0.char) }
        } else if selectedProfileId != "All", let profile = profileManager.profiles.first(where: { $0.id.uuidString == selectedProfileId }) {
            symbols = symbols.filter { profile.characters.contains($0.char) }
        }
        
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
                
                Menu {
                    Button("All Symbols") { selectedProfileId = "All" }
                    Button("English") { selectedProfileId = "English" }
                    if !profileManager.profiles.isEmpty {
                        Divider()
                        ForEach(profileManager.profiles) { profile in
                            Button(profile.name) { selectedProfileId = profile.id.uuidString }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(selectedProfileId == "All" ? "All" : (selectedProfileId == "English" ? "ENG" : profileManager.profiles.first(where: { $0.id.uuidString == selectedProfileId })?.name ?? "Filter"))
                            .font(.caption).fontWeight(.bold).lineLimit(1)
                    }
                    .padding(8)
                    .background(selectedProfileId == "All" ? Color.primary.opacity(0.1) : Color.brandAccent)
                    .foregroundColor(selectedProfileId == "All" ? .primary : .white)
                    .cornerRadius(8)
                }
                .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
                .fixedSize()
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
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandAccent.opacity(0.4), lineWidth: 1))
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isSearchFocused = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isSearchFocused = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToSearchTab"))) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isSearchFocused = true }
        }
    }
}

// MARK: - Interactive Card
struct SearchResultCard: View {
    let symbol: IPASymbol
    @EnvironmentObject var hoverState: HoverState
    @EnvironmentObject var profileManager: ProfileManager
    @State private var isHovering = false
    @AppStorage("appAccentColor") private var appAccentColor = 0
    
    var body: some View {
        Button(action: {
            EventTapManager.shared.insertFromMenu(symbol.char)
            RecentsManager.shared.add(symbol)
        }) {
            VStack {
                Text(symbol.type == .diacritic ? "◌" + symbol.char : symbol.char)
                    .font(.system(size: 24, weight: .regular, design: .default))
                    .foregroundColor(isHovering ? Color.brandAccent : .primary)
                    .scaleEffect(isHovering ? 1.2 : 1.0)
                    .frame(height: 30) // Fixed height for alignment
                
                Text(symbol.name)
                    .font(.caption2)
                    .foregroundColor(isHovering ? Color.brandAccent : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.primary.opacity(isHovering ? 0.15 : 0.05))
            .cornerRadius(12) // Smoother rounding
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
            hoverState.isHovering = hovering
            if hovering { hoverState.info = symbol.tooltipInfo }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        .contextMenu {
            if let features = symbol.features {
                VStack(alignment: .leading) {
                    Text("Phonological Features").font(.headline)
                    ForEach(features.activeFeatures, id: \.name) { feat in
                        Text("\(feat.value == .plus ? "+" : "-")\(feat.name)")
                    }
                }
            } else {
                Text("No feature data available")
            }
            
            Divider()
            
            Menu("Add to Profile...") {
                if profileManager.profiles.isEmpty {
                    Text("No profiles found")
                } else {
                    ForEach(profileManager.profiles) { profile in
                        Button(action: {
                            profileManager.toggleSymbol(char: symbol.char, in: profile.id)
                        }) {
                            HStack {
                                Text(profile.name)
                                if profile.characters.contains(symbol.char) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}

// MARK: - Components
struct TabButton: View {
    let title: String
    let tab: Int
    @Binding var selectedTab: Int
    @AppStorage("appAccentColor") private var appAccentColor = 0
    
    var isSelected: Bool { selectedTab == tab }
    
    var body: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab } }) {
            Text(title).fontWeight(.semibold).font(.system(size: 13))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.brandAccent.opacity(0.85) : Color.primary.opacity(0.05))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
