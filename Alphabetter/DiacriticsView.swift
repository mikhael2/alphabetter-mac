import SwiftUI

struct DiacriticsView: View {
    
    func sym(_ char: String) -> IPASymbol {
        return ipaDatabase.first { $0.char == char } ??
               IPASymbol(char: char, name: "Unknown", type: .other, tags: "")
    }

    // Standard 2-column row
    func row(_ title: String, _ char: String, _ title2: String? = nil, _ char2: String? = nil) -> some View {
        GridRow {
            Text(title).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 5)
            IPAButton(symbol: sym(char)).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
            
            if let t2 = title2, let c2 = char2 {
                Text(t2).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 5)
                IPAButton(symbol: sym(c2)).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
            } else {
                Color.clear; Color.clear
            }
        }
    }
    
    // Special 3-column row for Tones (Label | Diacritic | Letter)
    func toneRow(_ title: String, _ diacritic: String, _ letter: String) -> some View {
        GridRow {
            Text(title).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 5)
            IPAButton(symbol: sym(diacritic)).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
            IPAButton(symbol: sym(letter)).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // --- TABLE 1: DIACRITICS ---
                Text("Diacritics").font(.headline).padding(.leading)
                Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 1) {
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
                    row("No aud. release", "\u{031A}", nil, nil)
                }
                .background(Color.gray.opacity(0.1))
                .border(Color.gray.opacity(0.2))
                .padding(.horizontal)

                // --- TABLE 2: SUPRASEGMENTALS ---
                Text("Suprasegmentals").font(.headline).padding(.leading)
                Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 1) {
                    row("Primary stress", "ˈ", "Minor (foot) group", "|")
                    row("Secondary stress", "ˌ", "Major (intonation)", "‖")
                    row("Long", "ː", "Syllable break", ".")
                    row("Half-long", "ˑ", "Linking", "‿")
                    row("Extra-short", "\u{0306}", nil, nil)
                }
                .background(Color.gray.opacity(0.1))
                .border(Color.gray.opacity(0.2))
                .padding(.horizontal)
                
                // --- TABLE 3: TONES ---
                Text("Tones & Word Accents").font(.headline).padding(.leading)
                HStack(alignment: .top, spacing: 20) {
                    // Level Tones
                    Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 1) {
                        GridRow {
                            Text("LEVEL").font(.caption).bold().padding(5)
                            Color.clear; Color.clear
                        }
                        toneRow("Extra high", "\u{030B}", "˥")
                        toneRow("High", "\u{0301}", "˦")
                        toneRow("Mid", "\u{0304}", "˧")
                        toneRow("Low", "\u{0300}", "˨")
                        toneRow("Extra low", "\u{030F}", "˩")
                        
                        GridRow {
                            Text("Downstep").font(.caption).padding(.leading, 5)
                            IPAButton(symbol: sym("↓")).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
                            Color.clear
                        }
                        GridRow {
                            Text("Upstep").font(.caption).padding(.leading, 5)
                            IPAButton(symbol: sym("↑")).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
                            Color.clear
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .border(Color.gray.opacity(0.2))
                    
                    // Contour Tones
                    Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 1) {
                        GridRow {
                            Text("CONTOUR").font(.caption).bold().padding(5)
                            Color.clear
                        }
                        row("Rising", "\u{030C}")
                        row("Falling", "\u{0302}")
                        row("High rising", "\u{1DC4}")
                        row("Low rising", "\u{1DC5}")
                        row("Rising-falling", "\u{1DC8}")
                        
                        GridRow {
                            Text("Global rise").font(.caption).padding(.leading, 5)
                            IPAButton(symbol: sym("↗")).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
                        }
                        GridRow {
                            Text("Global fall").font(.caption).padding(.leading, 5)
                            IPAButton(symbol: sym("↘")).frame(width: 40, height: 30).background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .border(Color.gray.opacity(0.2))
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
    }
}
