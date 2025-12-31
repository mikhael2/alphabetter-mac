import Foundation

// MARK: - English IPA Set
let englishIPA: Set<String> = [
    "p", "b", "t", "d", "k", "ɡ", "ʔ", "m", "n", "ŋ", "f", "v", "θ", "ð", "s", "z", "ʃ", "ʒ", "h",
    "t͡ʃ", "d͡ʒ", "ɹ", "j", "w", "l", "ɫ", "ʰ", "ɾ", "ʔ", "̚", "i", "ɪ", "u", "ʊ", "e", "ɛ", "æ", "ɑ",
    "ɔ", "ʌ", "ə", "a", "o", "ɚ", "ɝ", "ˈ", "ˌ", "ː", ".", "̩", "̃", "̯"
]

// MARK: - Enums
enum IPAType: String, CaseIterable { case consonant, vowel, diacritic, suprasegmental, tone, other }
enum IPAManner: String, CaseIterable, Identifiable {
    case plosive, nasal, trill, tapOrFlap = "tap or flap", fricative, lateralFricative = "lateral fricative", approximant, lateralApproximant = "lateral approximant"
    var id: String { rawValue }
}
enum IPAPlace: String, CaseIterable, Identifiable {
    case bilabial, labiodental, dental, alveolar, postalveolar, retroflex, palatal, velar, uvular, pharyngeal, glottal
    var id: String { rawValue }
}
enum IPAVoicing: String { case voiceless, voiced }
enum IPAHeight: String, CaseIterable, Identifiable {
    case close, nearClose = "near-close", closeMid = "close-mid", mid, openMid = "open-mid", nearOpen = "near-open", open
    var id: String { rawValue }
    var verticalPosition: Double {
        switch self {
        case .close: return 0.0; case .nearClose: return 1.0/6.0; case .closeMid: return 2.0/6.0; case .mid: return 3.0/6.0
        case .openMid: return 4.0/6.0; case .nearOpen: return 5.0/6.0; case .open: return 1.0
        }
    }
}
enum IPABackness: String, CaseIterable, Identifiable {
    case front, central, back
    var id: String { rawValue }
}
enum IPARoundedness: String { case unrounded, rounded }

// MARK: - Symbol Model
struct IPASymbol: Identifiable, Equatable {
    let id = UUID()
    let char: String
    let name: String
    let type: IPAType
    let tags: String
    
    var consonantManner: IPAManner? = nil
    var consonantPlace: IPAPlace? = nil
    var consonantVoicing: IPAVoicing? = nil
    var vowelHeight: IPAHeight? = nil
    var vowelBackness: IPABackness? = nil
    var vowelRoundedness: IPARoundedness? = nil
    
    var searchKeywords: [String] {
        var terms = [name, char, type.rawValue] + tags.components(separatedBy: " ")
        if let v = consonantVoicing { terms.append(v.rawValue) }
        if let m = consonantManner { terms.append(m.rawValue); if m == .plosive || m == .nasal { terms.append("stop") } }
        if let p = consonantPlace {
            terms.append(p.rawValue)
            if [.bilabial, .labiodental].contains(p) { terms.append(contentsOf: ["round", "labial"]) }
            if [.bilabial, .labiodental, .dental, .alveolar].contains(p) { terms.append(contentsOf: ["front", "anterior"]) }
            if [.velar, .uvular, .pharyngeal, .glottal].contains(p) { terms.append(contentsOf: ["back", "dorsal", "posterior"]) }
            if [.dental, .alveolar, .postalveolar, .retroflex].contains(p) { terms.append("coronal") }
        }
        if let h = vowelHeight {
            terms.append(h.rawValue)
            if h == .close { terms.append("high") }; if h == .open { terms.append("low") }
            if [.closeMid, .mid, .openMid].contains(h) { terms.append("mid") }
        }
        if let b = vowelBackness { terms.append(b.rawValue) }
        if let r = vowelRoundedness { terms.append(r.rawValue); if r == .rounded { terms.append("round") } }
        return terms.filter { !$0.isEmpty }.map { $0.lowercased() }
    }
    
    var description: String {
        var parts: [String] = []
        if let v = consonantVoicing { parts.append(v.rawValue) }
        if let p = consonantPlace { parts.append(p.rawValue) }
        if let m = consonantManner { parts.append(m.rawValue) }
        if let r = vowelRoundedness { parts.append(r.rawValue) }
        if let h = vowelHeight { parts.append(h.rawValue) }
        if let b = vowelBackness { parts.append(b.rawValue) }
        return parts.isEmpty ? (tags.isEmpty ? name : tags) : parts.joined(separator: " ")
    }
    
    var tooltipInfo: String {
        var parts = [description.capitalized]
        if let shortcut = EventTapManager.shared.findShortcut(for: char) { parts.append("Key: \(shortcut)") }
        if let scalar = char.unicodeScalars.first { parts.append(String(format: "U+%04X", scalar.value)) }
        return parts.joined(separator: "  •  ")
    }
}

// MARK: - Database
let ipaDatabase: [IPASymbol] = [
    // Pulmonic Consonants
    IPASymbol(char: "p", name: "lowercase p", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .bilabial, consonantVoicing: .voiceless),
    IPASymbol(char: "b", name: "lowercase b", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .bilabial, consonantVoicing: .voiced),
    IPASymbol(char: "t", name: "lowercase t", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .alveolar, consonantVoicing: .voiceless),
    IPASymbol(char: "d", name: "lowercase d", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .alveolar, consonantVoicing: .voiced),
    IPASymbol(char: "ʈ", name: "retroflex t", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .retroflex, consonantVoicing: .voiceless),
    IPASymbol(char: "ɖ", name: "retroflex d", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .retroflex, consonantVoicing: .voiced),
    IPASymbol(char: "c", name: "lowercase c", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .palatal, consonantVoicing: .voiceless),
    IPASymbol(char: "ɟ", name: "dotless j with stroke", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .palatal, consonantVoicing: .voiced),
    IPASymbol(char: "k", name: "lowercase k", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .velar, consonantVoicing: .voiceless),
    IPASymbol(char: "ɡ", name: "lowercase g", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .velar, consonantVoicing: .voiced),
    IPASymbol(char: "q", name: "lowercase q", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .uvular, consonantVoicing: .voiceless),
    IPASymbol(char: "ɢ", name: "small capital g", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .uvular, consonantVoicing: .voiced),
    IPASymbol(char: "ʔ", name: "glottal stop", type: .consonant, tags: "plosive uh-oh", consonantManner: .plosive, consonantPlace: .glottal, consonantVoicing: .voiceless),
    
    IPASymbol(char: "m", name: "lowercase m", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .bilabial, consonantVoicing: .voiced),
    IPASymbol(char: "ɱ", name: "eng with hook", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .labiodental, consonantVoicing: .voiced),
    IPASymbol(char: "n", name: "lowercase n", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .alveolar, consonantVoicing: .voiced),
    IPASymbol(char: "ɳ", name: "retroflex n", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .retroflex, consonantVoicing: .voiced),
    IPASymbol(char: "ɲ", name: "left-tail n at left", type: .consonant, tags: "nasal gn", consonantManner: .nasal, consonantPlace: .palatal, consonantVoicing: .voiced),
    IPASymbol(char: "ŋ", name: "engma", type: .consonant, tags: "nasal ng", consonantManner: .nasal, consonantPlace: .velar, consonantVoicing: .voiced),
    IPASymbol(char: "ɴ", name: "small capital n", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .uvular, consonantVoicing: .voiced),
    
    IPASymbol(char: "ʙ", name: "small capital b", type: .consonant, tags: "trill", consonantManner: .trill, consonantPlace: .bilabial, consonantVoicing: .voiced),
    IPASymbol(char: "r", name: "lowercase r", type: .consonant, tags: "trill", consonantManner: .trill, consonantPlace: .alveolar, consonantVoicing: .voiced),
    IPASymbol(char: "ʀ", name: "small capital r", type: .consonant, tags: "trill", consonantManner: .trill, consonantPlace: .uvular, consonantVoicing: .voiced),
    
    IPASymbol(char: "ⱱ", name: "v with right hook", type: .consonant, tags: "tap flap", consonantManner: .tapOrFlap, consonantPlace: .labiodental, consonantVoicing: .voiced),
    IPASymbol(char: "ɾ", name: "fishhook r", type: .consonant, tags: "tap flap", consonantManner: .tapOrFlap, consonantPlace: .alveolar, consonantVoicing: .voiced),
    IPASymbol(char: "ɽ", name: "retroflex flap", type: .consonant, tags: "tap flap", consonantManner: .tapOrFlap, consonantPlace: .retroflex, consonantVoicing: .voiced),
    
    IPASymbol(char: "ɸ", name: "phi", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .bilabial, consonantVoicing: .voiceless),
    IPASymbol(char: "β", name: "beta", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .bilabial, consonantVoicing: .voiced),
    IPASymbol(char: "f", name: "lowercase f", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .labiodental, consonantVoicing: .voiceless),
    IPASymbol(char: "v", name: "lowercase v", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .labiodental, consonantVoicing: .voiced),
    IPASymbol(char: "θ", name: "theta", type: .consonant, tags: "fricative th", consonantManner: .fricative, consonantPlace: .dental, consonantVoicing: .voiceless),
    IPASymbol(char: "ð", name: "eth", type: .consonant, tags: "fricative th", consonantManner: .fricative, consonantPlace: .dental, consonantVoicing: .voiced),
    IPASymbol(char: "s", name: "lowercase s", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .alveolar, consonantVoicing: .voiceless),
    IPASymbol(char: "z", name: "lowercase z", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .alveolar, consonantVoicing: .voiced),
    IPASymbol(char: "ʃ", name: "esh", type: .consonant, tags: "fricative sh", consonantManner: .fricative, consonantPlace: .postalveolar, consonantVoicing: .voiceless),
    IPASymbol(char: "ʒ", name: "ezh", type: .consonant, tags: "fricative zh", consonantManner: .fricative, consonantPlace: .postalveolar, consonantVoicing: .voiced),
    IPASymbol(char: "ʂ", name: "retroflex s", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .retroflex, consonantVoicing: .voiceless),
    IPASymbol(char: "ʐ", name: "retroflex z", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .retroflex, consonantVoicing: .voiced),
    IPASymbol(char: "ç", name: "c with cedilla", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .palatal, consonantVoicing: .voiceless),
    IPASymbol(char: "ʝ", name: "j with crossed-tail", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .palatal, consonantVoicing: .voiced),
    IPASymbol(char: "x", name: "lowercase x", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .velar, consonantVoicing: .voiceless),
    IPASymbol(char: "ɣ", name: "gamma", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .velar, consonantVoicing: .voiced),
    IPASymbol(char: "χ", name: "chi", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .uvular, consonantVoicing: .voiceless),
    IPASymbol(char: "ʁ", name: "inverted small capital r", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .uvular, consonantVoicing: .voiced),
    IPASymbol(char: "ħ", name: "h with stroke", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .pharyngeal, consonantVoicing: .voiceless),
    IPASymbol(char: "ʕ", name: "reversed glottal stop", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .pharyngeal, consonantVoicing: .voiced),
    IPASymbol(char: "h", name: "lowercase h", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .glottal, consonantVoicing: .voiceless),
    IPASymbol(char: "ɦ", name: "h with hook", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .glottal, consonantVoicing: .voiced),

    IPASymbol(char: "ɬ", name: "l with belt", type: .consonant, tags: "lateral fricative", consonantManner: .lateralFricative, consonantPlace: .alveolar, consonantVoicing: .voiceless),
    IPASymbol(char: "ɮ", name: "lezh", type: .consonant, tags: "lateral fricative", consonantManner: .lateralFricative, consonantPlace: .alveolar, consonantVoicing: .voiced),

    IPASymbol(char: "ʋ", name: "v with hook", type: .consonant, tags: "approximant", consonantManner: .approximant, consonantPlace: .labiodental, consonantVoicing: .voiced),
    IPASymbol(char: "ɹ", name: "turned r", type: .consonant, tags: "approximant", consonantManner: .approximant, consonantPlace: .alveolar, consonantVoicing: .voiced),
    IPASymbol(char: "ɻ", name: "retroflex approximant", type: .consonant, tags: "approximant", consonantManner: .approximant, consonantPlace: .retroflex, consonantVoicing: .voiced),
    IPASymbol(char: "j", name: "lowercase j", type: .consonant, tags: "approximant y", consonantManner: .approximant, consonantPlace: .palatal, consonantVoicing: .voiced),
    IPASymbol(char: "ɯ", name: "turned m", type: .consonant, tags: "approximant", consonantManner: .approximant, consonantPlace: .velar, consonantVoicing: .voiced),

    IPASymbol(char: "l", name: "lowercase l", type: .consonant, tags: "lateral approximant", consonantManner: .lateralApproximant, consonantPlace: .alveolar, consonantVoicing: .voiced),
    IPASymbol(char: "ɭ", name: "retroflex l", type: .consonant, tags: "lateral approximant", consonantManner: .lateralApproximant, consonantPlace: .retroflex, consonantVoicing: .voiced),
    IPASymbol(char: "ʎ", name: "turned y", type: .consonant, tags: "lateral approximant", consonantManner: .lateralApproximant, consonantPlace: .palatal, consonantVoicing: .voiced),
    IPASymbol(char: "ʟ", name: "small capital l", type: .consonant, tags: "lateral approximant", consonantManner: .lateralApproximant, consonantPlace: .velar, consonantVoicing: .voiced),

    // Other Symbols
    IPASymbol(char: "ʍ", name: "turned w", type: .consonant, tags: "voiceless labial-velar fricative"),
    IPASymbol(char: "w", name: "lowercase w", type: .consonant, tags: "voiced labial-velar approximant"),
    IPASymbol(char: "ɥ", name: "turned h", type: .consonant, tags: "voiced labial-palatal approximant"),
    IPASymbol(char: "ʜ", name: "small capital h", type: .consonant, tags: "voiceless epiglottal fricative"),
    IPASymbol(char: "ʢ", name: "reversed glottal stop with stroke", type: .consonant, tags: "voiced epiglottal fricative"),
    IPASymbol(char: "ʡ", name: "epiglottal plosive", type: .consonant, tags: "epiglottal plosive"),
    IPASymbol(char: "ɕ", name: "c with curl", type: .consonant, tags: "voiceless alveolo-palatal fricative"),
    IPASymbol(char: "ʑ", name: "z with curl", type: .consonant, tags: "voiced alveolo-palatal fricative"),
    IPASymbol(char: "ɺ", name: "turned long leg r", type: .consonant, tags: "alveolar lateral flap tap"),
    IPASymbol(char: "ɧ", name: "hooktop heng", type: .consonant, tags: "simultaneous esh and x"),

    // Affricates
    IPASymbol(char: "t͡s", name: "ts tie bar", type: .consonant, tags: "voiceless alveolar affricate"),
    IPASymbol(char: "t͡ʃ", name: "tesh tie bar", type: .consonant, tags: "voiceless palato-alveolar affricate"),
    IPASymbol(char: "t͡ɕ", name: "tc curl tie bar", type: .consonant, tags: "voiceless alveolo-palatal affricate"),
    IPASymbol(char: "ʈ͡ʂ", name: "retroflex ts tie bar", type: .consonant, tags: "voiceless retroflex affricate"),
    IPASymbol(char: "d͡z", name: "dz tie bar", type: .consonant, tags: "voiced alveolar affricate"),
    IPASymbol(char: "d͡ʒ", name: "dezh tie bar", type: .consonant, tags: "voiced post-alveolar affricate"),
    IPASymbol(char: "d͡ʑ", name: "dz curl tie bar", type: .consonant, tags: "voiced alveolo-palatal affricate"),
    IPASymbol(char: "ɖ͡ʐ", name: "retroflex dz tie bar", type: .consonant, tags: "voiced retroflex affricate"),

    // Implosives
    IPASymbol(char: "ɓ", name: "b with hook", type: .consonant, tags: "implosive voiced bilabial"),
    IPASymbol(char: "ɗ", name: "d with hook", type: .consonant, tags: "implosive voiced dental alveolar"),
    IPASymbol(char: "ʄ", name: "dotless j with stroke and hook", type: .consonant, tags: "implosive voiced palatal"),
    IPASymbol(char: "ɠ", name: "g with hook", type: .consonant, tags: "implosive voiced velar"),
    IPASymbol(char: "ʛ", name: "small capital g with hook", type: .consonant, tags: "implosive voiced uvular"),

    // Vowels
    IPASymbol(char: "i", name: "lowercase i", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .front, vowelRoundedness: .unrounded),
    IPASymbol(char: "y", name: "lowercase y", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .front, vowelRoundedness: .rounded),
    IPASymbol(char: "ɨ", name: "i with stroke", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .central, vowelRoundedness: .unrounded),
    IPASymbol(char: "ʉ", name: "u with bar", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .central, vowelRoundedness: .rounded),
    IPASymbol(char: "ɯ", name: "turned m", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .back, vowelRoundedness: .unrounded),
    IPASymbol(char: "u", name: "lowercase u", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .back, vowelRoundedness: .rounded),
    IPASymbol(char: "ɪ", name: "small capital i", type: .vowel, tags: "vowel kit", vowelHeight: .nearClose, vowelBackness: .front, vowelRoundedness: .unrounded),
    IPASymbol(char: "ʏ", name: "small capital y", type: .vowel, tags: "vowel", vowelHeight: .nearClose, vowelBackness: .front, vowelRoundedness: .rounded),
    IPASymbol(char: "ʊ", name: "horseshoe u", type: .vowel, tags: "vowel foot", vowelHeight: .nearClose, vowelBackness: .back, vowelRoundedness: .rounded),
    IPASymbol(char: "e", name: "lowercase e", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .front, vowelRoundedness: .unrounded),
    IPASymbol(char: "ø", name: "o with stroke", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .front, vowelRoundedness: .rounded),
    IPASymbol(char: "ɘ", name: "reversed e", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .central, vowelRoundedness: .unrounded),
    IPASymbol(char: "ɵ", name: "barred o", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .central, vowelRoundedness: .rounded),
    IPASymbol(char: "ɤ", name: "rams horn", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .back, vowelRoundedness: .unrounded),
    IPASymbol(char: "o", name: "lowercase o", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .back, vowelRoundedness: .rounded),
    IPASymbol(char: "ə", name: "schwa", type: .vowel, tags: "vowel", vowelHeight: .mid, vowelBackness: .central, vowelRoundedness: .unrounded),
    IPASymbol(char: "ɛ", name: "epsilon", type: .vowel, tags: "vowel dress", vowelHeight: .openMid, vowelBackness: .front, vowelRoundedness: .unrounded),
    IPASymbol(char: "œ", name: "ligature oe", type: .vowel, tags: "vowel", vowelHeight: .openMid, vowelBackness: .front, vowelRoundedness: .rounded),
    IPASymbol(char: "ɜ", name: "reversed epsilon", type: .vowel, tags: "vowel", vowelHeight: .openMid, vowelBackness: .central, vowelRoundedness: .unrounded),
    IPASymbol(char: "ɞ", name: "closed reversed epsilon", type: .vowel, tags: "vowel", vowelHeight: .openMid, vowelBackness: .central, vowelRoundedness: .rounded),
    IPASymbol(char: "ʌ", name: "wedge", type: .vowel, tags: "vowel strut", vowelHeight: .openMid, vowelBackness: .back, vowelRoundedness: .unrounded),
    IPASymbol(char: "ɔ", name: "open o", type: .vowel, tags: "vowel thought", vowelHeight: .openMid, vowelBackness: .back, vowelRoundedness: .rounded),
    IPASymbol(char: "æ", name: "ash", type: .vowel, tags: "vowel cat", vowelHeight: .nearOpen, vowelBackness: .front, vowelRoundedness: .unrounded),
    IPASymbol(char: "ɐ", name: "turned a", type: .vowel, tags: "vowel", vowelHeight: .nearOpen, vowelBackness: .central, vowelRoundedness: .unrounded),
    IPASymbol(char: "a", name: "lowercase a", type: .vowel, tags: "vowel", vowelHeight: .open, vowelBackness: .front, vowelRoundedness: .unrounded),
    IPASymbol(char: "ɶ", name: "small capital oe", type: .vowel, tags: "vowel", vowelHeight: .open, vowelBackness: .front, vowelRoundedness: .rounded),
    IPASymbol(char: "ɑ", name: "script a", type: .vowel, tags: "vowel father", vowelHeight: .open, vowelBackness: .back, vowelRoundedness: .unrounded),
    IPASymbol(char: "ɒ", name: "turned alpha", type: .vowel, tags: "vowel", vowelHeight: .open, vowelBackness: .back, vowelRoundedness: .rounded),

    // Diacritics
    IPASymbol(char: "\u{0325}", name: "Voiceless", type: .diacritic, tags: "ring below"),
    IPASymbol(char: "\u{032C}", name: "Voiced", type: .diacritic, tags: "wedge caron below"),
    IPASymbol(char: "ʰ", name: "Aspirated", type: .diacritic, tags: "superscript h puff"),
    IPASymbol(char: "\u{0339}", name: "More rounded", type: .diacritic, tags: "right half ring below"),
    IPASymbol(char: "\u{031C}", name: "Less rounded", type: .diacritic, tags: "left half ring below"),
    IPASymbol(char: "\u{031F}", name: "Advanced", type: .diacritic, tags: "plus sign below"),
    IPASymbol(char: "\u{0320}", name: "Retracted", type: .diacritic, tags: "minus sign below"),
    IPASymbol(char: "\u{0308}", name: "Centralized", type: .diacritic, tags: "diaeresis umlaut above"),
    IPASymbol(char: "\u{033D}", name: "Mid-centralized", type: .diacritic, tags: "x above"),
    IPASymbol(char: "\u{0329}", name: "Syllabic", type: .diacritic, tags: "vertical line below"),
    IPASymbol(char: "\u{032F}", name: "Non-syllabic", type: .diacritic, tags: "inverted breve below"),
    IPASymbol(char: "˞", name: "Rhoticity", type: .diacritic, tags: "r-colored hook"),
    IPASymbol(char: "\u{0324}", name: "Breathy voiced", type: .diacritic, tags: "diaeresis umlaut below"),
    IPASymbol(char: "\u{0330}", name: "Creaky voiced", type: .diacritic, tags: "tilde below"),
    IPASymbol(char: "\u{033C}", name: "Linguolabial", type: .diacritic, tags: "seagull below"),
    IPASymbol(char: "ʷ", name: "Labialized", type: .diacritic, tags: "superscript w"),
    IPASymbol(char: "ʲ", name: "Palatalized", type: .diacritic, tags: "superscript j"),
    IPASymbol(char: "ˠ", name: "Velarized", type: .diacritic, tags: "superscript gamma"),
    IPASymbol(char: "ˤ", name: "Pharyngealized", type: .diacritic, tags: "superscript reversed glottal"),
    IPASymbol(char: "\u{0334}", name: "Velarized or Pharyngealized", type: .diacritic, tags: "tilde through middle"),
    IPASymbol(char: "\u{031D}", name: "Raised", type: .diacritic, tags: "up tack below"),
    IPASymbol(char: "\u{031E}", name: "Lowered", type: .diacritic, tags: "down tack below"),
    IPASymbol(char: "\u{0318}", name: "Advanced Tongue Root", type: .diacritic, tags: "ATR left tack below"),
    IPASymbol(char: "\u{0319}", name: "Retracted Tongue Root", type: .diacritic, tags: "RTR right tack below"),
    IPASymbol(char: "\u{032A}", name: "Dental", type: .diacritic, tags: "bridge below"),
    IPASymbol(char: "\u{033A}", name: "Apical", type: .diacritic, tags: "inverted bridge below"),
    IPASymbol(char: "\u{033B}", name: "Laminal", type: .diacritic, tags: "square below"),
    IPASymbol(char: "\u{0303}", name: "Nasalized", type: .diacritic, tags: "tilde above"),
    IPASymbol(char: "ⁿ", name: "Nasal release", type: .diacritic, tags: "superscript n"),
    IPASymbol(char: "ˡ", name: "Lateral release", type: .diacritic, tags: "superscript l"),
    IPASymbol(char: "\u{031A}", name: "No audible release", type: .diacritic, tags: "corner above"),
    IPASymbol(char: "͡", name: "Tie Bar (Ligature)", type: .diacritic, tags: "tie bar ligature"),

    // Suprasegmentals
    IPASymbol(char: "ˈ", name: "Primary stress", type: .suprasegmental, tags: "stress mark high"),
    IPASymbol(char: "ˌ", name: "Secondary stress", type: .suprasegmental, tags: "stress mark low"),
    IPASymbol(char: "ː", name: "Long", type: .suprasegmental, tags: "length mark colon"),
    IPASymbol(char: "ˑ", name: "Half-long", type: .suprasegmental, tags: "half length"),
    IPASymbol(char: "\u{0306}", name: "Extra-short", type: .suprasegmental, tags: "breve above"),
    IPASymbol(char: "|", name: "Minor (foot) group", type: .suprasegmental, tags: "pipe"),
    IPASymbol(char: "‖", name: "Major (intonation) group", type: .suprasegmental, tags: "double pipe"),
    IPASymbol(char: ".", name: "Syllable break", type: .suprasegmental, tags: "period dot"),
    IPASymbol(char: "‿", name: "Linking (no break)", type: .suprasegmental, tags: "undertie link"),

    // Tones
    IPASymbol(char: "\u{030B}", name: "Extra high (diacritic)", type: .diacritic, tags: "tone double acute"),
    IPASymbol(char: "\u{0301}", name: "High (diacritic)", type: .diacritic, tags: "tone acute"),
    IPASymbol(char: "\u{0304}", name: "Mid (diacritic)", type: .diacritic, tags: "tone macron"),
    IPASymbol(char: "\u{0300}", name: "Low (diacritic)", type: .diacritic, tags: "tone grave"),
    IPASymbol(char: "\u{030F}", name: "Extra low (diacritic)", type: .diacritic, tags: "tone double grave"),
    IPASymbol(char: "˥", name: "Extra high (letter)", type: .tone, tags: "tone bar 5"),
    IPASymbol(char: "˦", name: "High (letter)", type: .tone, tags: "tone bar 4"),
    IPASymbol(char: "˧", name: "Mid (letter)", type: .tone, tags: "tone bar 3"),
    IPASymbol(char: "˨", name: "Low (letter)", type: .tone, tags: "tone bar 2"),
    IPASymbol(char: "˩", name: "Extra low (letter)", type: .tone, tags: "tone bar 1"),
    IPASymbol(char: "\u{030C}", name: "Rising", type: .diacritic, tags: "tone caron"),
    IPASymbol(char: "\u{0302}", name: "Falling", type: .diacritic, tags: "tone circumflex"),
    IPASymbol(char: "\u{1DC4}", name: "High rising", type: .diacritic, tags: "tone macron acute"),
    IPASymbol(char: "\u{1DC5}", name: "Low rising", type: .diacritic, tags: "tone grave acute"),
    IPASymbol(char: "\u{1DC8}", name: "Rising-falling", type: .diacritic, tags: "tone peaking"),
    IPASymbol(char: "↓", name: "Downstep", type: .tone, tags: "arrow down"),
    IPASymbol(char: "↑", name: "Upstep", type: .tone, tags: "arrow up"),
    IPASymbol(char: "↗", name: "Global rise", type: .tone, tags: "arrow diagonal up"),
    IPASymbol(char: "↘", name: "Global fall", type: .tone, tags: "arrow diagonal down"),

    // Clicks
    IPASymbol(char: "ǀ", name: "Dental click", type: .other, tags: "click pipe tsk"),
    IPASymbol(char: "ǁ", name: "Lateral click", type: .other, tags: "click double pipe"),
    IPASymbol(char: "ǂ", name: "Palatal click", type: .other, tags: "click double dagger"),
    IPASymbol(char: "ǃ", name: "Alveolar click", type: .other, tags: "click exclamation"),
    IPASymbol(char: "ʘ", name: "Bilabial click", type: .other, tags: "click bullseye")
]
