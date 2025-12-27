import Cocoa
import Carbon

struct KeyCodes {
    // ... (Your existing letters a-z) ...
    static let a: Int64 = 0; static let s: Int64 = 1; static let d: Int64 = 2; static let f: Int64 = 3
    static let h: Int64 = 4; static let g: Int64 = 5; static let z: Int64 = 6; static let x: Int64 = 7
    static let c: Int64 = 8; static let v: Int64 = 9; static let b: Int64 = 11; static let q: Int64 = 12
    static let w: Int64 = 13; static let e: Int64 = 14; static let r: Int64 = 15; static let y: Int64 = 16
    static let t: Int64 = 17; static let one: Int64 = 18; static let two: Int64 = 19; static let three: Int64 = 20
    static let four: Int64 = 21; static let six: Int64 = 22; static let five: Int64 = 23; static let nine: Int64 = 25
    static let seven: Int64 = 26; static let eight: Int64 = 28; static let zero: Int64 = 29; static let o: Int64 = 31
    static let u: Int64 = 32; static let i: Int64 = 34; static let p: Int64 = 35; static let l: Int64 = 37
    static let j: Int64 = 38; static let k: Int64 = 40; static let n: Int64 = 45; static let m: Int64 = 46
    
    static let rightOption: Int64 = 61
    static let delete: Int64 = 51
    static let shift: Int64 = 56
    static let period: Int64 = 47
        static let semicolon: Int64 = 41
    // TRIGGERS
    static let space: Int64 = 49
    static let returnKey: Int64 = 36
    static let slash: Int64 = 44
}

class EventTapManager {
    static let shared = EventTapManager()
    
    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // CALLBACK: This lets the App Delegate know when to toggle the window
    var onTogglePalette: (() -> Void)?
    
    // SETTINGS: Allow user to change the trigger key (Default = Space)
    var triggerKey: Int64 = KeyCodes.space
    
    // State
    private var isRightOptionDown = false
    private var isShiftDown = false
    private var activeKey: Int64? = nil
    private var cycleIndex = 0
    
    private let magicUserData: Int64 = 0xDEADBEEF
    
    // LAYER 1: Base Cycling
    private let ipaMappings: [Int64: [String]] = [
        KeyCodes.period: ["\u{0306}"],
            KeyCodes.semicolon: ["ː", "ˑ"],
        KeyCodes.a: ["ɑ", "æ", "ɐ", "ã"],
        KeyCodes.b: ["β", "ɓ", "ʙ"],
        KeyCodes.c: ["ç", "ɕ"],
        KeyCodes.d: ["ð", "ɖ", "ɗ", "dʒ"],
        KeyCodes.e: ["ə", "ɚ", "ɵ", "ɘ"],
        // KeyCodes.f: ["ɸ"], // REMOVED: Now handled by direct shortcut below
        KeyCodes.g: ["ɡ", "ɢ", "ɠ", "ʛ"],
        KeyCodes.h: ["ħ", "ɦ", "ɥ", "ɧ", "ʜ"],
        KeyCodes.i: ["ɪ", "ɨ", "ᵻ"],
        KeyCodes.j: ["ɟ", "ʄ"],
        KeyCodes.k: ["ǀ", "ǁ", "ǂ", "!", "ʘ"],
        KeyCodes.l: ["ɫ", "ɬ", "ɭ", "ɮ"],
        KeyCodes.m: ["ɱ"],
        KeyCodes.n: ["ŋ", "ɲ", "ɳ", "ɴ"],
        KeyCodes.o: ["ɔ", "œ", "ɒ", "ɔ̃", "ɶ"],
        // KeyCodes.p: ["ɸ"], // REMOVED: Now handled by direct shortcut below
        KeyCodes.q: ["ˈ", "ˌ"],
        KeyCodes.r: ["ɾ", "ɹ", "ʁ", "ʀ", "ɻ", "ɽ", "ɺ"],
        KeyCodes.s: ["ʃ", "ʂ"],
        KeyCodes.t: ["θ", "ʈ", "tʃ", "ts"],
        KeyCodes.u: ["ʊ", "ʉ"],
        KeyCodes.v: ["ʌ", "ʋ"],
        KeyCodes.w: ["ɯ", "ʍ", "ɰ"],
        KeyCodes.x: ["χ"],
        KeyCodes.y: ["ɣ", "ʎ", "ʏ", "ɤ"],
        KeyCodes.z: ["ʒ", "ʐ", "ʑ"],
        KeyCodes.three: ["ɛ", "ɜ", "ɝ", "ẽ", "ɞ"],
        KeyCodes.two: ["ʔ", "ʕ", "ʡ", "ʢ"]
    ]
    
    // LAYER 2: Primary Diacritics
    private let ipaShiftMappings: [Int64: String] = [
        KeyCodes.one: "\u{030F}", KeyCodes.two: "\u{0300}", KeyCodes.three: "\u{0304}",
        KeyCodes.four: "\u{0301}", KeyCodes.five: "\u{030B}", KeyCodes.six: "\u{030C}",
        KeyCodes.seven: "\u{0302}", KeyCodes.eight: "\u{1DC4}", KeyCodes.nine: "\u{1DC5}",
        KeyCodes.zero: "\u{1DC8}",
        KeyCodes.h: "ʰ", KeyCodes.j: "ʲ", KeyCodes.w: "ʷ", KeyCodes.y: "ˠ",
        KeyCodes.n: "ⁿ", KeyCodes.l: "̚", KeyCodes.f: "\u{0329}", KeyCodes.d: "\u{032A}",
        KeyCodes.o: "\u{0325}", KeyCodes.v: "\u{032C}", KeyCodes.s: "\u{0303}",
        KeyCodes.r: "˞", KeyCodes.e: "\u{1D4A}", KeyCodes.c: "\u{0327}", KeyCodes.t: "\u{0324}"
    ]
    
    var isEnabled: Bool = true {
        didSet { if let port = machPort { CGEvent.tapEnable(tap: port, enable: isEnabled) } }
    }
    
    func start() {
        guard machPort == nil else { return }
        let events = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        guard let tap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(events), callback: eventTapCallback, userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()) ) else { return }
        self.machPort = tap
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else { return }
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    func insertFromMenu(_ char: String) {
        NSApplication.shared.hide(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.postIPAChar(char)
        }
    }
    
    private func postCleanBackspace() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        guard let eventDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(KeyCodes.delete), keyDown: true),
              let eventUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(KeyCodes.delete), keyDown: false) else { return }
        eventDown.flags = []; eventUp.flags = []
        eventDown.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        eventUp.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        eventDown.post(tap: .cghidEventTap); eventUp.post(tap: .cghidEventTap)
    }
    
    private func postIPAChar(_ character: String) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        guard let eventDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let eventUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return }
        var charArray = Array(character.utf16)
        eventDown.keyboardSetUnicodeString(stringLength: charArray.count, unicodeString: &charArray)
        eventUp.keyboardSetUnicodeString(stringLength: charArray.count, unicodeString: &charArray)
        eventDown.flags = []; eventDown.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        eventUp.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        eventDown.post(tap: .cghidEventTap); eventUp.post(tap: .cghidEventTap)
    }
    
    private let eventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
        guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
        let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
        
        if event.getIntegerValueField(.eventSourceUserData) == manager.magicUserData { return Unmanaged.passUnretained(event) }
        
        if type == .flagsChanged {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            if keyCode == KeyCodes.rightOption {
                if flags.contains(.maskAlternate) {
                    manager.isRightOptionDown = true
                } else {
                    manager.isRightOptionDown = false; manager.activeKey = nil; manager.cycleIndex = 0
                }
            }
            if flags.contains(.maskShift) {
                manager.isShiftDown = true
            } else {
                manager.isShiftDown = false
                if manager.isRightOptionDown { manager.activeKey = nil; manager.cycleIndex = 0 }
            }
            return Unmanaged.passUnretained(event)
        }
        
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            if manager.isRightOptionDown {
                
                // 1. Trigger Key (Toggle Palette)
                if keyCode == manager.triggerKey {
                    DispatchQueue.main.async {
                        manager.onTogglePalette?()
                    }
                    return nil
                }
                
                // 2. Direct Shortcuts (Overrides) - NEW!
                if !manager.isShiftDown {
                    switch keyCode {
                    case KeyCodes.p: // Option + P = ɸ (Phi)
                        manager.activeKey = nil
                        manager.postIPAChar("ɸ")
                        return nil
                    case KeyCodes.f: // Option + F = ͡ (Tie Bar)
                        manager.activeKey = nil
                        manager.postIPAChar("͡")
                        return nil
                    default:
                        break
                    }
                }
                
                // 3. Normal Shift Logic
                if manager.isShiftDown, let symbol = manager.ipaShiftMappings[keyCode] {
                    manager.activeKey = nil
                    manager.postIPAChar(symbol)
                    return nil
                }
                // 4. Normal Cycling Logic
                else if !manager.isShiftDown, let symbols = manager.ipaMappings[keyCode] {
                    if manager.activeKey == keyCode {
                        manager.postCleanBackspace()
                        usleep(1000)
                        manager.cycleIndex = (manager.cycleIndex + 1) % symbols.count
                    } else {
                        manager.activeKey = keyCode
                        manager.cycleIndex = 0
                    }
                    manager.postIPAChar(symbols[manager.cycleIndex])
                    return nil
                }
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    // --- Helper to find shortcuts for the UI ---
    func findShortcut(for symbol: String) -> String? {
        
        // 1. Check Hardcoded Shortcuts (NEW)
        if symbol == "ɸ" { return "⌥P" }
        if symbol == "͡" { return "⌥F" }
        
        // 2. Check Shift Layer (Direct mapping)
        for (code, char) in ipaShiftMappings {
            if char == symbol {
                return "⇧⌥" + keyName(for: code)
            }
        }
        
        // 3. Check Standard Layer (Cycling)
        for (code, list) in ipaMappings {
            if let index = list.firstIndex(of: symbol) {
                let key = keyName(for: code)
                // If it's the first item, just show "Option + Key"
                if index == 0 {
                    return "⌥\(key)"
                } else {
                    // If it's deeper in the cycle, tell them
                    return "⌥\(key) (×\(index + 1))"
                }
            }
        }
        return nil
    }
    
    private func keyName(for code: Int64) -> String {
        switch code {
        case KeyCodes.a: return "A"; case KeyCodes.b: return "B"; case KeyCodes.c: return "C"
        case KeyCodes.d: return "D"; case KeyCodes.e: return "E"; case KeyCodes.f: return "F"
        case KeyCodes.g: return "G"; case KeyCodes.h: return "H"; case KeyCodes.i: return "I"
        case KeyCodes.j: return "J"; case KeyCodes.k: return "K"; case KeyCodes.l: return "L"
        case KeyCodes.m: return "M"; case KeyCodes.n: return "N"; case KeyCodes.o: return "O"
        case KeyCodes.p: return "P"; case KeyCodes.q: return "Q"; case KeyCodes.r: return "R"
        case KeyCodes.s: return "S"; case KeyCodes.t: return "T"; case KeyCodes.u: return "U"
        case KeyCodes.v: return "V"; case KeyCodes.w: return "W"; case KeyCodes.x: return "X"
        case KeyCodes.y: return "Y"; case KeyCodes.z: return "Z"
        case KeyCodes.one: return "1"; case KeyCodes.two: return "2"; case KeyCodes.three: return "3"
        case KeyCodes.four: return "4"; case KeyCodes.five: return "5"; case KeyCodes.six: return "6"
        case KeyCodes.seven: return "7"; case KeyCodes.eight: return "8"; case KeyCodes.nine: return "9"
        case KeyCodes.zero: return "0"; case KeyCodes.space: return "Spc"; case KeyCodes.returnKey: return "Ret"
        case KeyCodes.slash: return "?"
        default: return "?"
        }
    }
}
