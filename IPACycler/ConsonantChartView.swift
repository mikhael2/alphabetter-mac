import SwiftUI

struct ConsonantChartView: View {
    let manners = IPAManner.allCases
    let places = IPAPlace.allCases

    // Helper to find symbols for a specific cell (Pulmonic)
    func symbols(for manner: IPAManner, place: IPAPlace) -> (voiceless: IPASymbol?, voiced: IPASymbol?) {
        let cellSymbols = ipaDatabase.filter { $0.consonantManner == manner && $0.consonantPlace == place }
        let voiceless = cellSymbols.first { $0.consonantVoicing == .voiceless }
        let voiced = cellSymbols.first { $0.consonantVoicing == .voiced }
        return (voiceless, voiced)
    }
    
    func isImpossible(manner: IPAManner, place: IPAPlace) -> Bool {
        switch (place, manner) {
        case (.pharyngeal, .plosive), (.pharyngeal, .nasal), (.pharyngeal, .lateralFricative), (.pharyngeal, .lateralApproximant),
             (.glottal, .nasal), (.glottal, .trill), (.glottal, .tapOrFlap), (.glottal, .lateralFricative), (.glottal, .approximant), (.glottal, .lateralApproximant),
             (.labiodental, .plosive), (.labiodental, .lateralFricative), (.labiodental, .lateralApproximant),
             (.dental, .trill), (.dental, .tapOrFlap), (.dental, .lateralFricative), (.dental, .approximant), (.dental, .lateralApproximant),
             (.palatal, .trill), (.palatal, .tapOrFlap),
             (.velar, .trill), (.velar, .tapOrFlap),
             (.retroflex, .trill):
            return true
        default:
            return false
        }
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 30) {
                // --- 1. PULMONIC CHART ---
                VStack(alignment: .leading, spacing: 5) {
                    Text("Pulmonic Consonants").font(.headline)
                    Grid(alignment: .center, horizontalSpacing: 1, verticalSpacing: 1) {
                        GridRow {
                            Color.clear.frame(width: 100, height: 30)
                            ForEach(places) { place in
                                Text(place.rawValue.capitalized)
                                    .font(.caption).fontWeight(.bold)
                                    .frame(width: 60, height: 30)
                                    .background(Color.green.opacity(0.2))
                            }
                        }
                        ForEach(manners) { manner in
                            GridRow {
                                Text(manner.rawValue.capitalized)
                                    .font(.caption).fontWeight(.bold)
                                    .frame(width: 100, height: 40, alignment: .leading)
                                    .padding(.leading, 5)
                                    .background(Color.green.opacity(0.2))
                                
                                ForEach(places) { place in
                                    let (voiceless, voiced) = symbols(for: manner, place: place)
                                    HStack(spacing: 0) {
                                        if let sym = voiceless { IPAButton(symbol: sym) } else { Color.clear }
                                        if let sym = voiced { IPAButton(symbol: sym) } else { Color.clear }
                                    }
                                    .frame(width: 60, height: 40)
                                    .background(isImpossible(manner: manner, place: place) ? Color.gray.opacity(0.3) : Color(NSColor.controlBackgroundColor))
                                    .border(Color.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // --- 2. NON-PULMONIC CHART ---
                VStack(alignment: .leading, spacing: 5) {
                    Text("Non-Pulmonic Consonants").font(.headline)
                    NonPulmonicView()
                }

                Divider()

                // --- 3. OTHER SYMBOLS & AFFRICATES ---
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
            }
            .padding()
        }
    }
}

// --- SUBVIEWS ---

struct NonPulmonicView: View {
    let clicks = [("ʘ", "Bilabial"), ("ǀ", "Dental"), ("ǃ", "(Post)alveolar"), ("ǂ", "Palatoalveolar"), ("ǁ", "Alveolar lateral")]
    let implosives = [("ɓ", "Bilabial"), ("ɗ", "Dental/alveolar"), ("ʄ", "Palatal"), ("ɠ", "Velar"), ("ʛ", "Uvular")]
    
    var body: some View {
        HStack(alignment: .top, spacing: 1) {
            buildTable(title: "Clicks", items: clicks)
            buildTable(title: "Voiced Implosives", items: implosives)
        }
        .frame(maxWidth: 500)
    }
    
    func buildTable(title: String, items: [(String, String)]) -> some View {
        VStack(spacing: 1) {
            Text(title).font(.caption).fontWeight(.bold).frame(maxWidth: .infinity, minHeight: 30).background(Color.gray.opacity(0.2))
            ForEach(items, id: \.0) { item in
                HStack(spacing: 1) {
                    if let sym = ipaDatabase.first(where: { $0.char == item.0 }) {
                        IPAButton(symbol: sym).frame(width: 40, height: 40).background(Color(NSColor.controlBackgroundColor))
                    }
                    Text(item.1).font(.caption).padding(.leading, 5).frame(maxWidth: .infinity, alignment: .leading).frame(height: 40).background(Color(NSColor.controlBackgroundColor))
                }
            }
        }.border(Color.gray.opacity(0.2))
    }
}

struct OtherSymbolsView: View {
    // Explicit list matching the user's image
    let symbols = ["ʍ", "w", "ɥ", "ʜ", "ʢ", "ʡ", "ɕ", "ʑ", "ɺ", "ɧ"]
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(symbols, id: \.self) { char in
                HStack(spacing: 1) {
                    if let sym = ipaDatabase.first(where: { $0.char == char }) {
                        IPAButton(symbol: sym).frame(width: 40, height: 35).background(Color(NSColor.controlBackgroundColor))
                        Text(sym.tags).font(.caption).padding(.leading, 5).frame(width: 200, alignment: .leading).frame(height: 35).background(Color(NSColor.controlBackgroundColor))
                    }
                }
            }
        }
        .border(Color.gray.opacity(0.2))
    }
}

struct AffricatesView: View {
    let symbols = ["t͡s", "t͡ʃ", "t͡ɕ", "ʈ͡ʂ", "d͡z", "d͡ʒ", "d͡ʑ", "ɖ͡ʐ"]
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(symbols, id: \.self) { char in
                HStack(spacing: 1) {
                    if let sym = ipaDatabase.first(where: { $0.char == char }) {
                        IPAButton(symbol: sym).frame(width: 50, height: 35).background(Color(NSColor.controlBackgroundColor))
                        Text(sym.tags).font(.caption).padding(.leading, 5).frame(width: 220, alignment: .leading).frame(height: 35).background(Color(NSColor.controlBackgroundColor))
                    }
                }
            }
        }
        .border(Color.gray.opacity(0.2))
    }
}
