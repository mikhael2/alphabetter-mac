import SwiftUI

struct ConsonantChartView: View {
    private let manners = IPAManner.allCases
    private let places = IPAPlace.allCases
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 30) {
                pulmonicSection
                Divider()
                nonPulmonicSection
                Divider()
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Other Symbols").font(.headline)
                        OtherSymbolsView()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Affricates").font(.headline)
                        AffricatesView()
                    }
                }
            }.padding()
        }
    }
    
    // --- 1. PULMONIC CHART (Grid Layout) ---
    private var pulmonicSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Pulmonic Consonants").font(.headline)
            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    Color.clear.frame(width: 65, height: 30) // Reduced from 100
                    ForEach(places) { place in
                        Text(place.abbreviation).font(.system(size: 10, weight: .bold))
                            .frame(width: 55, height: 30).background(Color.brandAccent.opacity(0.15))
                    }
                }
                ForEach(manners) { manner in
                    GridRow {
                        Text(manner.abbreviation).font(.system(size: 10, weight: .bold))
                            .frame(width: 65, height: 40, alignment: .leading).padding(.leading, 5).background(Color.brandAccent.opacity(0.15))
                        ForEach(places) { place in cell(manner: manner, place: place) }
                    }
                }
            }
        }
    }
    
    private func cell(manner: IPAManner, place: IPAPlace) -> some View {
        let (voiceless, voiced) = getSymbols(manner: manner, place: place)
        let impossible = isImpossible(manner: manner, place: place)
        return HStack(spacing: 0) {
            if let s = voiceless { IPAButton(symbol: s) } else { Color.clear }
            if let s = voiced { IPAButton(symbol: s) } else { Color.clear }
        }
        .frame(width: 55, height: 40)
        .background(impossible ? Color.primary.opacity(0.1) : Color.clear)
        .border(Color.gray.opacity(0.2))
    }
    
    // --- 2. NON-PULMONIC (Clicks & Implosives) ---
    private var nonPulmonicSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Non-Pulmonic Consonants").font(.headline)
            NonPulmonicView()
        }
    }
    
    // --- HELPERS ---
    private func getSymbols(manner: IPAManner, place: IPAPlace) -> (IPASymbol?, IPASymbol?) {
        let syms = ipaDatabase.filter { $0.consonantManner == manner && $0.consonantPlace == place }
        return (syms.first { $0.consonantVoicing == .voiceless }, syms.first { $0.consonantVoicing == .voiced })
    }
    
    private func isImpossible(manner: IPAManner, place: IPAPlace) -> Bool {
        switch (place, manner) {
        case (.pharyngeal, .plosive), (.pharyngeal, .nasal), (.pharyngeal, .lateralFricative), (.pharyngeal, .lateralApproximant): return true
        case (.glottal, .nasal), (.glottal, .trill), (.glottal, .tapOrFlap), (.glottal, .lateralFricative), (.glottal, .approximant), (.glottal, .lateralApproximant): return true
        case (.labiodental, .plosive), (.labiodental, .lateralFricative), (.labiodental, .lateralApproximant): return true
        case (.dental, .trill), (.dental, .tapOrFlap), (.dental, .lateralFricative), (.dental, .approximant), (.dental, .lateralApproximant): return true
        case (.palatal, .trill), (.palatal, .tapOrFlap), (.velar, .trill), (.velar, .tapOrFlap), (.retroflex, .trill): return true
        default: return false
        }
    }
}

// MARK: - Subviews

struct NonPulmonicView: View {
    let clicks = ["ʘ", "ǀ", "ǃ", "ǂ", "ǁ"]
    let implosives = ["ɓ", "ɗ", "ʄ", "ɠ", "ʛ"]
    
    var body: some View {
        HStack(alignment: .top, spacing: 1) {
            buildTable(title: "Clicks", chars: clicks)
            buildTable(title: "Voiced Implosives", chars: implosives)
        }.frame(maxWidth: 500)
    }
    
    func buildTable(title: String, chars: [String]) -> some View {
        VStack(spacing: 1) {
            Text(title).font(.caption).fontWeight(.bold).frame(maxWidth: .infinity, minHeight: 30).background(Color.gray.opacity(0.2))
            ForEach(chars, id: \.self) { char in
                if let sym = ipaDatabase.first(where: { $0.char == char }) {
                    ClickableTableRow(symbol: sym)
                }
            }
        }.border(Color.gray.opacity(0.2))
    }
}

struct OtherSymbolsView: View {
    let symbols = ["ʍ", "w", "ɥ", "ʜ", "ʢ", "ʡ", "ɕ", "ʑ", "ɺ", "ɧ"]
    var body: some View {
        VStack(spacing: 1) {
            ForEach(symbols, id: \.self) { char in
                SymbolRow(char: char, width: 200)
            }
        }.border(Color.gray.opacity(0.2))
    }
}

struct AffricatesView: View {
    let symbols = ["t͡s", "t͡ʃ", "t͡ɕ", "ʈ͡ʂ", "d͡z", "d͡ʒ", "d͡ʑ", "ɖ͡ʐ"]
    var body: some View {
        VStack(spacing: 1) {
            ForEach(symbols, id: \.self) { char in
                SymbolRow(char: char, width: 220, btnWidth: 50)
            }
        }.border(Color.gray.opacity(0.2))
    }
}

// MARK: - Interactive Rows

// 1. For "Other Symbols" & "Affricates" lists
struct SymbolRow: View {
    let char: String
    let width: CGFloat
    var btnWidth: CGFloat = 40
    
    @EnvironmentObject var hoverState: HoverState
    @EnvironmentObject var profileManager: ProfileManager
    @State private var isHovering = false
    @AppStorage("appAccentColor") private var appAccentColor = 0
    
    var body: some View {
        if let sym = ipaDatabase.first(where: { $0.char == char }) {
            Button(action: {
                EventTapManager.shared.insertFromMenu(sym.char)
                RecentsManager.shared.add(sym)
            }) {
                HStack(spacing: 1) {
                    // Symbol (Left)
                    Text(sym.char)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundColor(isHovering ? Color.brandAccent : .primary)
                        .scaleEffect(isHovering ? 1.2 : 1.0)
                        .frame(width: btnWidth, height: 35)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                    
                    // Description (Right)
                    Text(sym.tags)
                        .font(.caption)
                        .foregroundColor(isHovering ? Color.brandAccent : .primary)
                        .padding(.leading, 5)
                        .frame(width: width, alignment: .leading)
                        .frame(height: 35)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                }
                .background(Color.primary.opacity(isHovering ? 0.1 : 0.05))
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovering = hovering
                hoverState.isHovering = hovering
                if hovering { hoverState.info = sym.tooltipInfo }
            }
            .contextMenu {
                if let features = sym.features {
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
                                profileManager.toggleSymbol(char: sym.char, in: profile.id)
                            }) {
                                HStack {
                                    Text(profile.name)
                                    if profile.characters.contains(sym.char) {
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
}

// 2. For the Non-Pulmonic Tables (Clicks/Implosives)
struct ClickableTableRow: View {
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
            HStack(spacing: 1) {
                // Symbol (Left)
                Text(symbol.char)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundColor(isHovering ? Color.brandAccent : .primary)
                    .scaleEffect(isHovering ? 1.2 : 1.0)
                    .frame(width: 40, height: 40)
                    .background(Color.clear)
                
                // Description (Right)
                Text(symbol.name.replacingOccurrences(of: "click", with: "").capitalized)
                    .font(.caption)
                    .foregroundColor(isHovering ? Color.brandAccent : .primary)
                    .padding(.leading, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 40)
                    .background(Color.clear)
            }
            .background(Color.primary.opacity(isHovering ? 0.1 : 0.05))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
            hoverState.isHovering = hovering
            if hovering { hoverState.info = symbol.tooltipInfo }
        }
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
