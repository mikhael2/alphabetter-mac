import SwiftUI

struct DiacriticsView: View {
    
    func sym(_ char: String) -> IPASymbol {
        ipaDatabase.first { $0.char == char } ?? IPASymbol(char: char, name: "Unknown", type: .other, tags: "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 1. DIACRITICS
                section("Diacritics") {
                    row("Voiceless", "\u{0325}", "Breathy voiced", "\u{0324}")
                    row("Voiced", "\u{032C}", "Creaky voiced", "\u{0330}")
                    row("Aspirated", "ʰ", "Linguolabial", "\u{033C}")
                    row("More rounded", "\u{0339}", "Labialized", "ʷ")
                    row("Less rounded", "\u{031C}", "Palatalized", "ʲ")
                    row("Advanced", "\u{031F}", "Velarized", "ˠ")
                    row("Retracted", "\u{0320}", "Pharyngealized", "ˤ")
                    row("Centralized", "\u{0308}", "Velarized or Phar.", "\u{0334}")
                    row("Mid-centralized", "\u{033D}", "Raised", "\u{031D}")
                    row("Syllabic", "\u{0329}", "Lowered", "\u{031E}")
                    row("Non-syllabic", "\u{032F}", "Adv. Tongue Root", "\u{0318}")
                    row("Rhoticity", "˞", "Ret. Tongue Root", "\u{0319}")
                    row("Nasalized", "\u{0303}", "Dental", "\u{032A}")
                    row("Nasal release", "ⁿ", "Apical", "\u{033A}")
                    row("Lateral release", "ˡ", "Laminal", "\u{033B}")
                    row("No aud. release", "\u{031A}")
                }
                
                // 2. SUPRASEGMENTALS
                section("Suprasegmentals") {
                    row("Primary stress", "ˈ", "Minor (foot) group", "|")
                    row("Secondary stress", "ˌ", "Major (intonation)", "‖")
                    row("Long", "ː", "Syllable break", ".")
                    row("Half-long", "ˑ", "Linking", "‿")
                    row("Extra-short", "\u{0306}")
                }
                
                // 3. TONES
                Text("Tones & Word Accents").font(.headline).padding(.leading)
                HStack(alignment: .top, spacing: 20) {
                    
                    // Left Column (Level Tones)
                    Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 1) {
                        GridRow { Text("LEVEL").font(.caption).bold().padding(5); Color.clear; Color.clear }
                        toneRow("Extra high", "\u{030B}", "˥")
                        toneRow("High", "\u{0301}", "˦")
                        toneRow("Mid", "\u{0304}", "˧")
                        toneRow("Low", "\u{0300}", "˨")
                        toneRow("Extra low", "\u{030F}", "˩")
                        
                        // Interactive Downstep/Upstep (Spanning 2 cols, empty 3rd)
                        levelToneRowSimple("Downstep", "↓")
                        levelToneRowSimple("Upstep", "↑")
                    }
                    .background(Color.gray.opacity(0.1)).border(Color.gray.opacity(0.2))
                    
                    // Right Column (Contour Tones)
                    Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 1) {
                        GridRow { Text("CONTOUR").font(.caption).bold().padding(5); Color.clear }
                        contourRow("Rising", "\u{030C}")
                        contourRow("Falling", "\u{0302}")
                        contourRow("High rising", "\u{1DC4}")
                        contourRow("Low rising", "\u{1DC5}")
                        contourRow("Rising-falling", "\u{1DC8}")
                        
                        // Interactive Global Rise/Fall
                        contourRow("Global rise", "↗")
                        contourRow("Global fall", "↘")
                    }
                    .background(Color.gray.opacity(0.1)).border(Color.gray.opacity(0.2))
                    
                }.padding(.horizontal)
            }.padding(.vertical)
        }
    }
    
    // --- HELPER VIEWS ---
    
    func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline).padding(.leading)
            Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 1) {
                content()
            }
            .background(Color.gray.opacity(0.1))
            .border(Color.gray.opacity(0.2))
            .padding(.horizontal)
        }
    }

    // 1. Standard Diacritic Row
    func row(_ t1: String, _ c1: String, _ t2: String? = nil, _ c2: String? = nil) -> some View {
        GridRow {
            DiacriticRowButton(text: t1, symbol: sym(c1)).gridCellColumns(1)
            Color.clear.frame(width: 30, height: 1)
            if let t2 = t2, let c2 = c2 {
                DiacriticRowButton(text: t2, symbol: sym(c2)).gridCellColumns(1)
            } else {
                Color.clear; Color.clear
            }
        }
    }
    
    // 2. Tone Row (3 Columns: Label | Diacritic | Letter)
    func toneRow(_ t: String, _ d: String, _ l: String) -> some View {
        GridRow {
            Text(t).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 5)
            IPAButton(symbol: sym(d)).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
            IPAButton(symbol: sym(l)).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    // 3. Level Tone Simple Row (For Downstep/Upstep in Left Grid)
    // Structure: [Interactive Button (Spans 2)] [Empty Slot]
    func levelToneRowSimple(_ t: String, _ c: String) -> some View {
        GridRow {
            DiacriticRowButton(text: t, symbol: sym(c))
                .gridCellColumns(2)
            Color.clear // 3rd column spacer
        }
    }

    // 4. Contour Tone Row (For Right Grid)
    // Structure: [Interactive Button (Spans 2)]
    func contourRow(_ t: String, _ c: String) -> some View {
        GridRow {
            DiacriticRowButton(text: t, symbol: sym(c))
                .gridCellColumns(2)
        }
    }
}

// MARK: - Interactive Component
struct DiacriticRowButton: View {
    let text: String
    let symbol: IPASymbol
    
    @EnvironmentObject var hoverState: HoverState
    @State private var isHovering = false
    let purple = Color(red: 175/255, green: 104/255, blue: 239/255)
    
    var body: some View {
        Button(action: {
            EventTapManager.shared.insertFromMenu(symbol.char)
            RecentsManager.shared.add(symbol)
        }) {
            HStack {
                Text(text)
                    .font(.caption)
                    .foregroundColor(isHovering ? purple : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                    .contentShape(Rectangle())
                
                Text(symbol.type == .diacritic ? "◌" + symbol.char : symbol.char)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundColor(isHovering ? purple : .primary)
                    .scaleEffect(isHovering ? 1.2 : 1.0)
                    .frame(width: 40, height: 30)
                    .contentShape(Rectangle())
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(isHovering ? 0.6 : 0.3))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
            hoverState.isHovering = hovering
            if hovering { hoverState.info = symbol.tooltipInfo }
        }
    }
}
