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
                    Color.clear.frame(width: 100, height: 30)
                    ForEach(places) { place in
                        Text(place.rawValue.capitalized).font(.caption).fontWeight(.bold)
                            .frame(width: 60, height: 30).background(Color.green.opacity(0.2))
                    }
                }
                ForEach(manners) { manner in
                    GridRow {
                        Text(manner.rawValue.capitalized).font(.caption).fontWeight(.bold)
                            .frame(width: 100, height: 40, alignment: .leading).padding(.leading, 5).background(Color.green.opacity(0.2))
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
        .frame(width: 60, height: 40)
        .background(impossible ? Color.gray.opacity(0.3) : Color(NSColor.controlBackgroundColor))
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
    @State private var isHovering = false
    let purple = Color(red: 175/255, green: 104/255, blue: 239/255)
    
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
                        .foregroundColor(isHovering ? purple : .primary)
                        .scaleEffect(isHovering ? 1.2 : 1.0)
                        .frame(width: btnWidth, height: 35)
                        .background(Color(NSColor.controlBackgroundColor))
                        .contentShape(Rectangle())
                    
                    // Description (Right)
                    Text(sym.tags)
                        .font(.caption)
                        .foregroundColor(isHovering ? purple : .primary)
                        .padding(.leading, 5)
                        .frame(width: width, alignment: .leading)
                        .frame(height: 35)
                        .background(Color(NSColor.controlBackgroundColor))
                        .contentShape(Rectangle())
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(isHovering ? 0.6 : 1.0))
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovering = hovering
                hoverState.isHovering = hovering
                if hovering { hoverState.info = sym.tooltipInfo }
            }
        }
    }
}

// 2. For the Non-Pulmonic Tables (Clicks/Implosives)
struct ClickableTableRow: View {
    let symbol: IPASymbol
    @EnvironmentObject var hoverState: HoverState
    @State private var isHovering = false
    let purple = Color(red: 175/255, green: 104/255, blue: 239/255)
    
    var body: some View {
        Button(action: {
            EventTapManager.shared.insertFromMenu(symbol.char)
            RecentsManager.shared.add(symbol)
        }) {
            HStack(spacing: 1) {
                // Symbol (Left)
                Text(symbol.char)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundColor(isHovering ? purple : .primary)
                    .scaleEffect(isHovering ? 1.2 : 1.0)
                    .frame(width: 40, height: 40)
                    .background(Color(NSColor.controlBackgroundColor))
                
                // Description (Right)
                Text(symbol.name.replacingOccurrences(of: "click", with: "").capitalized)
                    .font(.caption)
                    .foregroundColor(isHovering ? purple : .primary)
                    .padding(.leading, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 40)
                    .background(Color(NSColor.controlBackgroundColor))
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(isHovering ? 0.6 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
            hoverState.isHovering = hovering
            if hovering { hoverState.info = symbol.tooltipInfo }
        }
    }
}
