import Foundation
import SwiftUI
import Combine

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
    var abbreviation: String {
        switch self {
        case .plosive: return "Plos."
        case .nasal: return "Nasal"
        case .trill: return "Trill"
        case .tapOrFlap: return "Tap"
        case .fricative: return "Fric."
        case .lateralFricative: return "L. Fric."
        case .approximant: return "Approx."
        case .lateralApproximant: return "L. Appr."
        }
    }
}
enum IPAPlace: String, CaseIterable, Identifiable {
    case bilabial, labiodental, dental, alveolar, postalveolar, retroflex, palatal, velar, uvular, pharyngeal, glottal
    var id: String { rawValue }
    var abbreviation: String {
        switch self {
        case .bilabial: return "Bilab."
        case .labiodental: return "Lab-d."
        case .dental: return "Dent."
        case .alveolar: return "Alv."
        case .postalveolar: return "P-alv."
        case .retroflex: return "Retr."
        case .palatal: return "Pal."
        case .velar: return "Velar"
        case .uvular: return "Uvul."
        case .pharyngeal: return "Phar."
        case .glottal: return "Glot."
        }
    }
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

// MARK: - Features

enum FeatureValue: String {
    case plus = "+"
    case minus = "-"
    case zero = "0"
}

struct PhonologicalFeatures: Equatable {
    var syllabic: FeatureValue = .zero
    var consonantal: FeatureValue = .zero
    var sonorant: FeatureValue = .zero
    var continuant: FeatureValue = .zero
    var delayedRelease: FeatureValue = .zero
    var nasal: FeatureValue = .zero
    var lateral: FeatureValue = .zero
    var spreadGlottis: FeatureValue = .zero
    var constrictedGlottis: FeatureValue = .zero
    var voice: FeatureValue = .zero
    var labial: FeatureValue = .zero
    var round: FeatureValue = .zero
    var coronal: FeatureValue = .zero
    var anterior: FeatureValue = .zero
    var distributed: FeatureValue = .zero
    var dorsal: FeatureValue = .zero
    var high: FeatureValue = .zero
    var low: FeatureValue = .zero
    var back: FeatureValue = .zero
    var tense: FeatureValue = .zero
    var advancedTongueRoot: FeatureValue = .zero

    var activeFeatures: [(name: String, value: FeatureValue)] {
        return [
            ("syllabic", syllabic), ("consonantal", consonantal), ("sonorant", sonorant),
            ("continuant", continuant), ("delayedRelease", delayedRelease), ("nasal", nasal),
            ("lateral", lateral), ("spreadGlottis", spreadGlottis), ("constrictedGlottis", constrictedGlottis),
            ("voice", voice), ("labial", labial), ("round", round),
            ("coronal", coronal), ("anterior", anterior), ("distributed", distributed),
            ("dorsal", dorsal), ("high", high), ("low", low), ("back", back),
            ("tense", tense), ("advancedTongueRoot", advancedTongueRoot)
        ].filter { $0.value != .zero }
    }
}

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
    var features: PhonologicalFeatures? = nil
    
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
        
        if let feats = features {
            for feat in feats.activeFeatures {
                if feat.value == .plus {
                    terms.append(feat.name) // Allow implicit search e.g. "coronal"
                    terms.append("+\(feat.name)")
                } else if feat.value == .minus {
                    terms.append("-\(feat.name)")
                }
            }
        }
        
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
    IPASymbol(char: "p", name: "lowercase p", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .bilabial, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .minus, labial: .plus, anterior: .plus)),
    IPASymbol(char: "b", name: "lowercase b", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .bilabial, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .plus, labial: .plus, anterior: .plus)),
    IPASymbol(char: "t", name: "lowercase t", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .alveolar, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .minus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "d", name: "lowercase d", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .alveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ʈ", name: "retroflex t", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .retroflex, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .minus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "ɖ", name: "retroflex d", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .retroflex, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .plus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "c", name: "lowercase c", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .palatal, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .minus, coronal: .plus, anterior: .minus, distributed: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ɟ", name: "dotless j with stroke", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .palatal, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "k", name: "lowercase k", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .velar, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .minus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "ɡ", name: "lowercase g", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .velar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .plus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "q", name: "lowercase q", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .uvular, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .minus, dorsal: .plus, high: .minus, low: .minus, back: .plus)),
    IPASymbol(char: "ɢ", name: "small capital g", type: .consonant, tags: "plosive", consonantManner: .plosive, consonantPlace: .uvular, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .plus, dorsal: .plus, high: .minus, low: .minus, back: .plus)),
    IPASymbol(char: "ʔ", name: "glottal stop", type: .consonant, tags: "plosive uh-oh", consonantManner: .plosive, consonantPlace: .glottal, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .minus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, constrictedGlottis: .plus, voice: .minus)),
    
    IPASymbol(char: "m", name: "lowercase m", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .bilabial, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, nasal: .plus, voice: .plus, labial: .plus)),
    IPASymbol(char: "ɱ", name: "eng with hook", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .labiodental, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, nasal: .plus, voice: .plus, labial: .plus)),
    IPASymbol(char: "n", name: "lowercase n", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .alveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, nasal: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ɳ", name: "retroflex n", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .retroflex, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, nasal: .plus, voice: .plus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "ɲ", name: "left-tail n at left", type: .consonant, tags: "nasal gn", consonantManner: .nasal, consonantPlace: .palatal, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, nasal: .plus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus)),
    IPASymbol(char: "ŋ", name: "engma", type: .consonant, tags: "nasal ng", consonantManner: .nasal, consonantPlace: .velar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, nasal: .plus, voice: .plus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "ɴ", name: "small capital n", type: .consonant, tags: "nasal", consonantManner: .nasal, consonantPlace: .uvular, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, nasal: .plus, voice: .plus, dorsal: .plus, high: .minus, low: .minus, back: .plus)),
    
    IPASymbol(char: "ʙ", name: "small capital b", type: .consonant, tags: "trill", consonantManner: .trill, consonantPlace: .bilabial, consonantVoicing: .voiced),
    IPASymbol(char: "r", name: "lowercase r", type: .consonant, tags: "trill", consonantManner: .trill, consonantPlace: .alveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ʀ", name: "small capital r", type: .consonant, tags: "trill", consonantManner: .trill, consonantPlace: .uvular, consonantVoicing: .voiced),
    
    IPASymbol(char: "ⱱ", name: "v with right hook", type: .consonant, tags: "tap flap", consonantManner: .tapOrFlap, consonantPlace: .labiodental, consonantVoicing: .voiced),
    IPASymbol(char: "ɾ", name: "fishhook r", type: .consonant, tags: "tap flap", consonantManner: .tapOrFlap, consonantPlace: .alveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, delayedRelease: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ɽ", name: "retroflex flap", type: .consonant, tags: "tap flap", consonantManner: .tapOrFlap, consonantPlace: .retroflex, consonantVoicing: .voiced),
    
    IPASymbol(char: "ɸ", name: "phi", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .bilabial, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, labial: .plus)),
    IPASymbol(char: "β", name: "beta", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .bilabial, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, labial: .plus)),
    IPASymbol(char: "f", name: "lowercase f", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .labiodental, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, labial: .plus)),
    IPASymbol(char: "v", name: "lowercase v", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .labiodental, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, labial: .plus)),
    IPASymbol(char: "θ", name: "theta", type: .consonant, tags: "fricative th", consonantManner: .fricative, consonantPlace: .dental, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ð", name: "eth", type: .consonant, tags: "fricative th", consonantManner: .fricative, consonantPlace: .dental, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "s", name: "lowercase s", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .alveolar, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "z", name: "lowercase z", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .alveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ʃ", name: "esh", type: .consonant, tags: "fricative sh", consonantManner: .fricative, consonantPlace: .postalveolar, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "ʒ", name: "ezh", type: .consonant, tags: "fricative zh", consonantManner: .fricative, consonantPlace: .postalveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "ʂ", name: "retroflex s", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .retroflex, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, coronal: .plus, anterior: .minus, distributed: .minus)),
    IPASymbol(char: "ʐ", name: "retroflex z", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .retroflex, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .minus)),
    IPASymbol(char: "ç", name: "c with cedilla", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .palatal, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "ʝ", name: "j with crossed-tail", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .palatal, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "x", name: "lowercase x", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .velar, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "ɣ", name: "gamma", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .velar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "χ", name: "chi", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .uvular, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, dorsal: .plus, high: .minus, low: .minus, back: .plus)),
    IPASymbol(char: "ʁ", name: "inverted small capital r", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .uvular, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, dorsal: .plus, high: .minus, low: .minus, back: .plus)),
    IPASymbol(char: "ħ", name: "h with stroke", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .pharyngeal, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, dorsal: .plus, low: .plus, back: .plus)),
    IPASymbol(char: "ʕ", name: "reversed glottal stop", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .pharyngeal, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, dorsal: .plus, low: .plus, back: .plus)),
    IPASymbol(char: "h", name: "lowercase h", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .glottal, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .minus, sonorant: .minus, continuant: .plus, spreadGlottis: .plus, voice: .minus)),
    IPASymbol(char: "ɦ", name: "h with hook", type: .consonant, tags: "fricative", consonantManner: .fricative, consonantPlace: .glottal, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .minus, sonorant: .minus, continuant: .plus, spreadGlottis: .plus, voice: .plus)),

    IPASymbol(char: "ɬ", name: "l with belt", type: .consonant, tags: "lateral fricative", consonantManner: .lateralFricative, consonantPlace: .alveolar, consonantVoicing: .voiceless, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, lateral: .plus, voice: .minus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ɮ", name: "lezh", type: .consonant, tags: "lateral fricative", consonantManner: .lateralFricative, consonantPlace: .alveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, lateral: .plus, voice: .plus, coronal: .plus, anterior: .plus)),

    IPASymbol(char: "ʋ", name: "v with hook", type: .consonant, tags: "approximant", consonantManner: .approximant, consonantPlace: .labiodental, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus)),
    IPASymbol(char: "ɹ", name: "turned r", type: .consonant, tags: "approximant", consonantManner: .approximant, consonantPlace: .alveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ɻ", name: "retroflex approximant", type: .consonant, tags: "approximant", consonantManner: .approximant, consonantPlace: .retroflex, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "j", name: "lowercase j", type: .consonant, tags: "approximant y", consonantManner: .approximant, consonantPlace: .palatal, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, coronal: .plus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ɯ", name: "turned m", type: .consonant, tags: "approximant", consonantManner: .approximant, consonantPlace: .velar, consonantVoicing: .voiced, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .plus, low: .minus, back: .plus, tense: .plus)),

    IPASymbol(char: "l", name: "lowercase l", type: .consonant, tags: "lateral approximant", consonantManner: .lateralApproximant, consonantPlace: .alveolar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .plus, lateral: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ɭ", name: "retroflex l", type: .consonant, tags: "lateral approximant", consonantManner: .lateralApproximant, consonantPlace: .retroflex, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .plus, lateral: .plus, voice: .plus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "ʎ", name: "turned y", type: .consonant, tags: "lateral approximant", consonantManner: .lateralApproximant, consonantPlace: .palatal, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .plus, lateral: .plus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ʟ", name: "small capital l", type: .consonant, tags: "lateral approximant", consonantManner: .lateralApproximant, consonantPlace: .velar, consonantVoicing: .voiced, features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .plus, lateral: .plus, voice: .plus, dorsal: .plus, high: .plus, back: .plus)),

    // Other Symbols
    IPASymbol(char: "ʍ", name: "turned w", type: .consonant, tags: "voiceless labial-velar fricative", features: PhonologicalFeatures(consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .minus, labial: .plus, round: .plus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "w", name: "lowercase w", type: .consonant, tags: "voiced labial-velar approximant", features: PhonologicalFeatures(consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "ɥ", name: "turned h", type: .consonant, tags: "voiced labial-palatal approximant", features: PhonologicalFeatures(consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, coronal: .plus, anterior: .minus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ʜ", name: "small capital h", type: .consonant, tags: "voiceless epiglottal fricative", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, dorsal: .plus, low: .plus, back: .plus)),
    IPASymbol(char: "ʢ", name: "reversed glottal stop with stroke", type: .consonant, tags: "voiced epiglottal fricative", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, dorsal: .plus, low: .plus, back: .plus)),
    IPASymbol(char: "ʡ", name: "epiglottal plosive", type: .consonant, tags: "epiglottal plosive", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, voice: .minus, dorsal: .plus, low: .plus, back: .plus)),
    IPASymbol(char: "ɕ", name: "c with curl", type: .consonant, tags: "voiceless alveolo-palatal fricative", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ʑ", name: "z with curl", type: .consonant, tags: "voiced alveolo-palatal fricative", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ɺ", name: "turned long leg r", type: .consonant, tags: "alveolar lateral flap tap", features: PhonologicalFeatures(consonantal: .plus, sonorant: .plus, continuant: .minus, lateral: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ɧ", name: "hooktop heng", type: .consonant, tags: "voiceless postalveolo-velar fricative", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .plus, voice: .minus, labial: .plus, round: .plus, coronal: .plus, anterior: .minus, dorsal: .plus, high: .plus, back: .plus)),

    // Affricates
    IPASymbol(char: "t͡s", name: "ts tie bar", type: .consonant, tags: "voiceless alveolar affricate", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .minus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "t͡ʃ", name: "tesh tie bar", type: .consonant, tags: "voiceless palato-alveolar affricate", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .minus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "t͡ɕ", name: "tc curl tie bar", type: .consonant, tags: "voiceless alveolo-palatal affricate", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .minus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ʈ͡ʂ", name: "retroflex ts tie bar", type: .consonant, tags: "voiceless retroflex affricate", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .minus, coronal: .plus, anterior: .minus, distributed: .minus)),
    IPASymbol(char: "d͡z", name: "dz tie bar", type: .consonant, tags: "voiced alveolar affricate", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "d͡ʒ", name: "dezh tie bar", type: .consonant, tags: "voiced post-alveolar affricate", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .plus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "d͡ʑ", name: "dz curl tie bar", type: .consonant, tags: "voiced alveolo-palatal affricate", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ɖ͡ʐ", name: "retroflex dz tie bar", type: .consonant, tags: "voiced retroflex affricate", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .minus)),

    // Implosives
    IPASymbol(char: "ɓ", name: "b with hook", type: .consonant, tags: "implosive voiced bilabial", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, constrictedGlottis: .plus, voice: .plus, labial: .plus)),
    IPASymbol(char: "ɗ", name: "d with hook", type: .consonant, tags: "implosive voiced dental alveolar", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, constrictedGlottis: .plus, voice: .plus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ʄ", name: "dotless j with stroke and hook", type: .consonant, tags: "implosive voiced palatal", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, constrictedGlottis: .plus, voice: .plus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ɠ", name: "g with hook", type: .consonant, tags: "implosive voiced velar", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, constrictedGlottis: .plus, voice: .plus, dorsal: .plus, high: .plus, back: .plus)),
    IPASymbol(char: "ʛ", name: "small capital g with hook", type: .consonant, tags: "implosive voiced uvular", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .minus, constrictedGlottis: .plus, voice: .plus, dorsal: .plus, high: .minus, low: .minus, back: .plus)),

    // Vowels
    IPASymbol(char: "i", name: "lowercase i", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .front, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, coronal: .plus, dorsal: .plus, high: .plus, low: .minus, back: .minus, tense: .plus)),
    IPASymbol(char: "y", name: "lowercase y", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .front, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, coronal: .plus, dorsal: .plus, high: .plus, low: .minus, back: .minus, tense: .plus)),
    IPASymbol(char: "ɨ", name: "i with stroke", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .central, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .plus, low: .minus, back: .minus, tense: .plus)),
    IPASymbol(char: "ʉ", name: "u with bar", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .central, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .plus, low: .minus, back: .minus, tense: .plus)),
    IPASymbol(char: "ɯ", name: "turned m", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .back, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .plus, low: .minus, back: .plus, tense: .plus)),
    IPASymbol(char: "u", name: "lowercase u", type: .vowel, tags: "vowel", vowelHeight: .close, vowelBackness: .back, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .plus, low: .minus, back: .plus, tense: .plus)),
    IPASymbol(char: "ɪ", name: "small capital i", type: .vowel, tags: "vowel kit", vowelHeight: .nearClose, vowelBackness: .front, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, coronal: .plus, dorsal: .plus, high: .plus, low: .minus, back: .minus, tense: .minus)),
    IPASymbol(char: "ʏ", name: "small capital y", type: .vowel, tags: "vowel", vowelHeight: .nearClose, vowelBackness: .front, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, coronal: .plus, dorsal: .plus, high: .plus, low: .minus, back: .minus, tense: .minus)),
    IPASymbol(char: "ʊ", name: "horseshoe u", type: .vowel, tags: "vowel foot", vowelHeight: .nearClose, vowelBackness: .back, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .plus, low: .minus, back: .plus, tense: .minus)),
    IPASymbol(char: "e", name: "lowercase e", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .front, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, coronal: .plus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .plus)),
    IPASymbol(char: "ø", name: "o with stroke", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .front, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, coronal: .plus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .plus)),
    IPASymbol(char: "ɘ", name: "reversed e", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .central, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .plus)),
    IPASymbol(char: "ɵ", name: "barred o", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .central, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .plus)),
    IPASymbol(char: "ɤ", name: "rams horn", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .back, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .minus, low: .minus, back: .plus, tense: .plus)),
    IPASymbol(char: "o", name: "lowercase o", type: .vowel, tags: "vowel", vowelHeight: .closeMid, vowelBackness: .back, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .minus, low: .minus, back: .plus, tense: .plus)),
    IPASymbol(char: "ə", name: "schwa", type: .vowel, tags: "vowel", vowelHeight: .mid, vowelBackness: .central, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .minus)),
    IPASymbol(char: "ɛ", name: "epsilon", type: .vowel, tags: "vowel dress", vowelHeight: .openMid, vowelBackness: .front, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, coronal: .plus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .minus)),
    IPASymbol(char: "œ", name: "ligature oe", type: .vowel, tags: "vowel", vowelHeight: .openMid, vowelBackness: .front, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, coronal: .plus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .minus)),
    IPASymbol(char: "ɜ", name: "reversed epsilon", type: .vowel, tags: "vowel", vowelHeight: .openMid, vowelBackness: .central, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .minus)),
    IPASymbol(char: "ɞ", name: "closed reversed epsilon", type: .vowel, tags: "vowel", vowelHeight: .openMid, vowelBackness: .central, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .minus, low: .minus, back: .minus, tense: .minus)),
    IPASymbol(char: "ʌ", name: "wedge", type: .vowel, tags: "vowel strut", vowelHeight: .openMid, vowelBackness: .back, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .minus, low: .minus, back: .plus, tense: .minus)),
    IPASymbol(char: "ɔ", name: "open o", type: .vowel, tags: "vowel thought", vowelHeight: .openMid, vowelBackness: .back, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .minus, low: .minus, back: .plus, tense: .minus)),
    IPASymbol(char: "æ", name: "ash", type: .vowel, tags: "vowel cat", vowelHeight: .nearOpen, vowelBackness: .front, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, coronal: .plus, dorsal: .plus, high: .minus, low: .plus, back: .minus, tense: .minus)),
    IPASymbol(char: "ɐ", name: "turned a", type: .vowel, tags: "vowel", vowelHeight: .nearOpen, vowelBackness: .central, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .minus, low: .plus, back: .minus, tense: .minus)),
    IPASymbol(char: "a", name: "lowercase a", type: .vowel, tags: "vowel", vowelHeight: .open, vowelBackness: .front, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .minus, low: .plus, back: .minus, tense: .plus)),
    IPASymbol(char: "ɶ", name: "small capital oe", type: .vowel, tags: "vowel", vowelHeight: .open, vowelBackness: .front, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, coronal: .plus, dorsal: .plus, high: .minus, low: .plus, back: .minus, tense: .plus)),
    IPASymbol(char: "ɑ", name: "script a", type: .vowel, tags: "vowel father", vowelHeight: .open, vowelBackness: .back, vowelRoundedness: .unrounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, round: .minus, dorsal: .plus, high: .minus, low: .plus, back: .plus, tense: .plus)),
    IPASymbol(char: "ɒ", name: "turned alpha", type: .vowel, tags: "vowel", vowelHeight: .open, vowelBackness: .back, vowelRoundedness: .rounded, features: PhonologicalFeatures(syllabic: .plus, consonantal: .minus, sonorant: .plus, continuant: .plus, voice: .plus, labial: .plus, round: .plus, dorsal: .plus, high: .minus, low: .plus, back: .plus, tense: .plus)),

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
    IPASymbol(char: "ǀ", name: "Dental click", type: .other, tags: "click pipe tsk", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .minus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ǁ", name: "Lateral click", type: .other, tags: "click double pipe", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, lateral: .plus, voice: .minus, coronal: .plus, anterior: .plus)),
    IPASymbol(char: "ǂ", name: "Palatal click", type: .other, tags: "click double dagger", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .minus, coronal: .plus, anterior: .minus, distributed: .plus, dorsal: .plus, high: .plus, back: .minus)),
    IPASymbol(char: "ǃ", name: "Alveolar click", type: .other, tags: "click exclamation", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .minus, coronal: .plus, anterior: .minus)),
    IPASymbol(char: "ʘ", name: "Bilabial click", type: .other, tags: "click bullseye", features: PhonologicalFeatures(consonantal: .plus, sonorant: .minus, continuant: .minus, delayedRelease: .plus, voice: .minus, labial: .plus))
]

struct IPAProfile: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var characters: Set<String>
}

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profiles: [IPAProfile] = []
    
    private let profilesKey = "CustomIPAProfiles"
    
    init() {
        loadProfiles()
    }
    
    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([IPAProfile].self, from: data) {
            self.profiles = decoded
        }
        
        // Seed a demo profile if none exist (so users can see the beautiful cards right away)
        if self.profiles.isEmpty {
            let demoSet = ["p", "b", "t", "d", "k", "ɡ", "m", "n", "ɲ", "f", "θ", "s", "x", "t͡ʃ", "l", "ʎ", "ɾ", "r", "i", "e", "a", "o", "u"]
            self.profiles.append(IPAProfile(name: "Spanish (Demo)", characters: Set(demoSet)))
            saveProfiles()
        }
    }
    
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
        }
    }
    
    func addProfile(name: String, characterString: String = "") {
        let charSet = parseCharacterSet(from: characterString)
        profiles.append(IPAProfile(name: name, characters: charSet))
        saveProfiles()
    }
    
    func updateProfile(id: UUID, newName: String, newCharacterString: String) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            profiles[index].name = newName
            profiles[index].characters = parseCharacterSet(from: newCharacterString)
            saveProfiles()
        }
    }
    
    func deleteProfile(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        saveProfiles()
    }
    
    func toggleSymbol(char: String, in profileID: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == profileID }) {
            if profiles[index].characters.contains(char) {
                profiles[index].characters.remove(char)
            } else {
                profiles[index].characters.insert(char)
            }
            saveProfiles()
        }
    }
    
    private func parseCharacterSet(from string: String) -> Set<String> {
        // Strip out non-IPA characters and whitespace. Assumes space-separated or just continuous characters.
        // Easiest robust parsing: If it matches characters in the database, keep it.
        var validChars = Set<String>()
        
        // Strategy A: split by whitespace
        let tokens = string.components(separatedBy: .whitespacesAndNewlines)
        for token in tokens {
            if ipaDatabase.contains(where: { $0.char == token }) {
                validChars.insert(token)
            } else {
                // Strategy B: it might be unseparated string (e.g. "pbtk")
                for c in token {
                    let s = String(c)
                    if ipaDatabase.contains(where: { $0.char == s }) {
                        validChars.insert(s)
                    }
                }
            }
        }
        
        // Handle common affricates and diacritics tied together, fallback: just check substring against database
        for symbol in ipaDatabase {
            if string.contains(symbol.char) {
                validChars.insert(symbol.char)
            }
        }
        
        return validChars
    }
}
