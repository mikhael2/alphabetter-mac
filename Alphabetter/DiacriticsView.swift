import SwiftUI

/// Look up a character in ipaDatabase; fall back to the official Unicode scalar name
/// (e.g. "Modifier letter small h with hook" for ʱ) rather than a generic "Unknown".
private func ipaSymbolFallback(_ char: String) -> IPASymbol {
    if let found = ipaDatabase.first(where: { $0.char == char }) { return found }
    // Use Unicode name, title-cased for readability
    let rawName = char.unicodeScalars.first.flatMap { $0.properties.name } ?? ""
    let name = rawName.isEmpty ? char : (rawName.prefix(1).uppercased() + rawName.dropFirst().lowercased())
    return IPASymbol(char: char, name: name, type: .other, tags: "")
}

struct DiacriticsView: View {
    
    func sym(_ char: String) -> IPASymbol { ipaSymbolFallback(char) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 1. DIACRITICS
                section("Diacritics") {
                    row("Voiceless", "\u{0325}", "Breathy voiced", "\u{0324}")
                    row("Voiced", "\u{032C}", "Creaky voiced", "\u{0330}")
                    row("Aspirated", "ʰ", "Breathy-voice asp.", "ʱ")
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
                    row("No aud. release", "\u{031A}", "Linguolabial", "\u{033C}")
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
                    VStack(spacing: 1) {
                        Text("LEVEL")
                            .font(.caption).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                        
                        TonePairRowContainer(text: "Extra high", dChar: "\u{030B}", lChar: "˥")
                        TonePairRowContainer(text: "High", dChar: "\u{0301}", lChar: "˦")
                        TonePairRowContainer(text: "Mid", dChar: "\u{0304}", lChar: "˧")
                        TonePairRowContainer(text: "Low", dChar: "\u{0300}", lChar: "˨")
                        TonePairRowContainer(text: "Extra low", dChar: "\u{030F}", lChar: "˩")
                        
                        ToneSingleRowContainer(text: "Downstep", char: "↓")
                        ToneSingleRowContainer(text: "Upstep", char: "↑")
                    }
                    .background(Color.gray.opacity(0.05))
                    .border(Color.gray.opacity(0.2))
                    
                    // Right Column (Contour Tones)
                    VStack(spacing: 1) {
                        Text("CONTOUR")
                            .font(.caption).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                        
                        ToneSingleRowContainer(text: "Rising", char: "\u{030C}")
                        ToneSingleRowContainer(text: "Falling", char: "\u{0302}")
                        ToneSingleRowContainer(text: "High rising", char: "\u{1DC4}")
                        ToneSingleRowContainer(text: "Low rising", char: "\u{1DC5}")
                        ToneSingleRowContainer(text: "Rising-falling", char: "\u{1DC8}")
                        
                        ToneSingleRowContainer(text: "Global rise", char: "↗")
                        ToneSingleRowContainer(text: "Global fall", char: "↘")
                    }
                    .background(Color.gray.opacity(0.05))
                    .border(Color.gray.opacity(0.2))
                    
                }.padding(.horizontal)
            }.padding(.vertical)
        }
    }
    
    // --- HELPER VIEWS ---
    
    func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 1) {
            Text(title.uppercased())
                .font(.caption).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
            content()
        }
        .background(Color.gray.opacity(0.05))
        .border(Color.gray.opacity(0.2))
        .padding(.horizontal)
    }

    // Standard Diacritic Row — two side-by-side items
    func row(_ t1: String, _ c1: String, _ t2: String? = nil, _ c2: String? = nil) -> some View {
        HStack(spacing: 1) {
            DiacriticRowButton(text: t1, symbol: sym(c1))
                .frame(maxWidth: .infinity)
            if let t2 = t2, let c2 = c2 {
                Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1)
                DiacriticRowButton(text: t2, symbol: sym(c2))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Interactive Component
struct DiacriticRowButton: View {
    let text: String
    let symbol: IPASymbol
    
    @EnvironmentObject var hoverState: HoverState
    @EnvironmentObject var profileManager: ProfileManager
    @State private var isHovering = false
    @AppStorage("appAccentColor") private var appAccentColor = 0
    
    /// Show ◌ for: (1) symbols the database marks as .diacritic, (2) Unicode combining
    /// marks (non-spacing/spacing), and (3) IPA modifier letters U+02B0–U+02DE
    /// (ʰ ʱ ʲ ʷ ˠ ˤ ˞ etc.) — but NOT tone bars U+02E5–U+02E9 (˥˦˧˨˩) or arrows.
    private var showsDottedCircle: Bool {
        if symbol.type == .diacritic { return true }
        guard let scalar = symbol.char.unicodeScalars.first else { return false }
        let cat = scalar.properties.generalCategory
        if cat == .nonspacingMark || cat == .spacingMark { return true }
        if cat == .modifierLetter && scalar.value >= 0x02B0 && scalar.value <= 0x02DE { return true }
        return false
    }
    
    var body: some View {
        Button(action: {
            EventTapManager.shared.insertFromMenu(symbol.char)
            RecentsManager.shared.add(symbol)
        }) {
            HStack {
                Text(text)
                    .font(.caption)
                    .foregroundColor(isHovering ? Color.brandAccent : .primary)
                    .shadow(color: isHovering ? .black.opacity(0.55) : .clear, radius: 1, x: 0, y: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                    .contentShape(Rectangle())
                
                Text(showsDottedCircle ? "◌" + symbol.char : symbol.char)
                    .font(.system(size: 22, weight: .regular, design: .default))
                    .foregroundColor(isHovering ? Color.brandAccent : .primary)
                    .shadow(color: isHovering ? .black.opacity(0.55) : .clear, radius: 1, x: 0, y: 1)
                    .scaleEffect(isHovering ? 1.15 : 1.0)
                    .frame(width: 44, height: 40)
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
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

// MARK: - Tone Row Containers

/// Level tone row: shows the label + diacritic (clickable/hoverable) plus the letter symbol as its own IPAButton.
struct TonePairRowContainer: View {
    let text: String
    let dChar: String
    let lChar: String

    func sym(_ char: String) -> IPASymbol { ipaSymbolFallback(char) }

    var body: some View {
        HStack(spacing: 1) {
            // Left: label + diacritic — full DiacriticRowButton hover/click/tooltip behavior
            DiacriticRowButton(text: text, symbol: sym(dChar))
                .frame(maxWidth: .infinity)

            Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1)

            // Right: the tone letter (˥˦˧˨˩) as its own IPAButton with its own tooltip
            IPAButton(symbol: sym(lChar))
                .frame(width: 45, height: 35)
        }
    }
}

/// Contour / single-char tone row: delegates entirely to DiacriticRowButton.
struct ToneSingleRowContainer: View {
    let text: String
    let char: String

    func sym(_ char: String) -> IPASymbol { ipaSymbolFallback(char) }

    var body: some View {
        DiacriticRowButton(text: text, symbol: sym(char))
    }
}
