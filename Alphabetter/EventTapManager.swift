import Cocoa
import Carbon

// MARK: - Key Codes
struct KeyCodes {
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
    static let comma: Int64 = 43
    static let period: Int64 = 47
    static let semicolon: Int64 = 41
    static let slash: Int64 = 44
    static let space: Int64 = 49
    static let returnKey: Int64 = 36
}

// MARK: - Event Tap Manager
class EventTapManager {
    static let shared = EventTapManager()
    static let paletteShortcutKeys: [(String, Int64)] = [
        ("Space", KeyCodes.space),
        ("Return", KeyCodes.returnKey),
        ("/ ?", KeyCodes.slash)
    ]

    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var onTogglePalette: (() -> Void)?
    var triggerKey: Int64 = KeyCodes.space
    
    var useRightOptionOnly: Bool = true
    var customTriggerKeyCode: Int64 = KeyCodes.space
    var customTriggerModifiers: UInt64 = 0
    
    // Internal State
    private var isRightOptionDown = false
    private var isShiftDown = false
    private var activeKey: Int64? = nil
    private var cycleIndex = 0
    private let magicUserData: Int64 = 0xDEADBEEF
    
    // Mappings
    private let ipaMappings: [Int64: [String]] = [
        // Punctuation keys
        KeyCodes.comma: ["\u{031C}", "\u{0339}"],   // ̜ less-rounded, ̹ more-rounded
        KeyCodes.period: ["\u{0306}", "\u{0308}"],   // ̆ extra-short, ̈ centralized
        KeyCodes.semicolon: ["ː", "ˑ"],              // length mark, half-long
        // Letter mappings
        KeyCodes.a: ["ɑ", "æ", "ɐ", "ã"], KeyCodes.b: ["β", "ɓ", "ʙ"],
        KeyCodes.c: ["ç", "ɕ"], KeyCodes.d: ["ð", "ɖ", "ɗ", "d͡ʒ"],
        KeyCodes.e: ["ə", "ɚ", "ɵ", "ɘ"], KeyCodes.f: ["͡", "͜", "‿"],
        KeyCodes.g: ["ɡ", "ɢ", "ɠ", "ʛ"],
        KeyCodes.h: ["ħ", "ɦ", "ɥ", "ɧ", "ʜ"], KeyCodes.i: ["ɪ", "ɨ", "ᵻ"],
        KeyCodes.j: ["ɟ", "ʄ"], KeyCodes.k: ["ǀ", "ǁ", "ǂ", "!", "ʘ"],
        KeyCodes.l: ["ɫ", "ɭ", "ɬ", "ʟ", "ɮ"], KeyCodes.m: ["ɱ"],
        KeyCodes.n: ["ŋ", "ɲ", "ɳ", "ɴ"], KeyCodes.o: ["ɔ", "ø", "œ", "ɶ"],
        KeyCodes.p: ["ɸ"], KeyCodes.q: ["ˈ", "ˌ"], KeyCodes.r: ["ɾ", "ɹ", "ʁ", "ʀ", "ɻ", "ɽ", "ɺ"],
        KeyCodes.s: ["ʃ", "ʂ"], KeyCodes.t: ["θ", "ʈ", "t͡ʃ", "t͡s"],
        KeyCodes.u: ["ʊ", "ʉ"], KeyCodes.v: ["ʌ", "ʋ"],
        KeyCodes.w: ["ɯ", "ʍ", "ɰ"], KeyCodes.x: ["χ"],
        KeyCodes.y: ["ɣ", "ʎ", "ʏ", "ɤ"], KeyCodes.z: ["ʒ", "ʐ", "ʑ"],
        KeyCodes.three: ["ɛ", "ɜ", "ɝ", "ẽ", "ɞ"], KeyCodes.two: ["ʔ", "ʕ", "ʡ", "ʢ"]
    ]
    
    private let ipaShiftMappings: [Int64: [String]] = [
        // Tone diacritics on number keys
        KeyCodes.one: ["\u{030F}"], KeyCodes.two: ["\u{0300}"], KeyCodes.three: ["\u{0304}"],
        KeyCodes.four: ["\u{0301}"], KeyCodes.five: ["\u{030B}"], KeyCodes.six: ["\u{030C}"],
        KeyCodes.seven: ["\u{0302}"], KeyCodes.eight: ["\u{1DC4}"], KeyCodes.nine: ["\u{1DC5}"],
        KeyCodes.zero: ["\u{1DC8}"],
        // Punctuation row diacritics
        KeyCodes.comma: ["\u{031C}", "\u{0339}"],    // ̜ less-rounded → ̹ more-rounded
        KeyCodes.period: ["\u{0308}", "\u{0324}"],   // ̈ centralized → ̤ breathy voiced
        KeyCodes.semicolon: ["\u{0329}"],             // ̩ syllabic
        // Suprasegmentals on F
        KeyCodes.f: ["ː", "˘", "ˑ"],
        // Place of articulation
        KeyCodes.d: ["\u{032A}", "\u{033A}", "\u{033B}"],  // dental → apical → laminal
        KeyCodes.b: ["\u{033C}"],                           // linguolabial
        // Manner/voice diacritics
        KeyCodes.h: ["ʰ", "ʱ"],   // aspirated → breathy-asp.
        KeyCodes.t: ["\u{0324}"],   // breathy voiced
        KeyCodes.v: ["\u{032C}"],   // voiced
        KeyCodes.s: ["\u{0303}", "\u{0334}", "\u{0330}"],  // nasalized → velarized → creaky
        KeyCodes.o: ["\u{0325}", "˚"],  // voiceless → voiceless alt.
        // Suprasegmental letter modifiers
        KeyCodes.j: ["ʲ"],   // palatalized
        KeyCodes.w: ["ʷ"],   // labialized
        KeyCodes.y: ["ˠ"],   // velarized
        KeyCodes.p: ["ˤ"],   // pharyngealized
        KeyCodes.n: ["ⁿ"],   // nasal release
        KeyCodes.l: ["\u{031A}", "ˡ"],  // no-audible-release → lateral release
        KeyCodes.r: ["˞"],   // rhoticity
        KeyCodes.e: ["\u{1D4A}"],  // extra-short
        KeyCodes.c: ["\u{032F}", "\u{0311}"],  // non-syllabic
        // Tongue body / height position
        KeyCodes.a: ["\u{0318}", "\u{0319}"],  // Adv. Tongue Root → Ret. Tongue Root
        KeyCodes.z: ["\u{031F}", "\u{0320}"],  // advanced → retracted
        KeyCodes.k: ["\u{031D}", "\u{031E}"],  // raised → lowered
        KeyCodes.g: ["\u{033D}"],               // mid-centralized
    ]
    
    var isEnabled: Bool = true {
        didSet { if let port = machPort { CGEvent.tapEnable(tap: port, enable: isEnabled) } }
    }
    
    var isRunning: Bool { machPort != nil }
    private var retryTimer: Timer?

    func start() {
        guard machPort == nil else { return }
        
        let isTrusted = AXIsProcessTrusted()
        let canListen = CGPreflightListenEventAccess()
        NSLog("[Alphabetter] EventTapManager.start() called. AXIsProcessTrusted: %d, CGPreflightListenEventAccess: %d", isTrusted ? 1 : 0, canListen ? 1 : 0)
        
        if !isTrusted || !canListen {
            if !isTrusted {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(options)
            }
            if !canListen {
                CGRequestListenEventAccess()
            }
            DispatchQueue.main.async {
                self.showAccessibilityAlertIfNeeded()
            }
            startRetryTimer()
            return
        }

        stopRetryTimer()
        let events = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        guard let tap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(events), callback: eventTapCallback, userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())) else {
            NSLog("[Alphabetter] Failed to create CGEvent tap; retrying...")
            startRetryTimer()
            return
        }
        self.machPort = tap
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else { return }
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        NSLog("[Alphabetter] Event tap successfully created and enabled!")
    }

    private func startRetryTimer() {
        guard retryTimer == nil else { return }
        DispatchQueue.main.async {
            let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] t in
                guard let self = self else { t.invalidate(); return }
                if self.isRunning {
                    self.stopRetryTimer()
                } else if AXIsProcessTrusted() && CGPreflightListenEventAccess() {
                    NSLog("[Alphabetter] Permissions detected via timer! Starting event tap...")
                    self.start()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.retryTimer = timer
        }
    }

    private func stopRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = nil
    }

    private var hasShownAccessibilityAlert = false
    func showAccessibilityAlertIfNeeded() {
        guard !(AXIsProcessTrusted() && CGPreflightListenEventAccess()) else { return }
        guard !hasShownAccessibilityAlert else { return }
        hasShownAccessibilityAlert = true
        
        let alert = NSAlert()
        alert.messageText = "Accessibility & Input Monitoring Required"
        alert.informativeText = "Alphabetter requires two permissions in System Settings → Privacy & Security:\n\n1. Input Monitoring (to detect the Right Option key)\n2. Accessibility (to type IPA characters into other apps)\n\nPlease check both sections and ensure Alphabetter is enabled."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Dismiss")
        
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        self.start()
    }
    
    private let eventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
        guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
        let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
        
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            NSLog("[Alphabetter] Event tap disabled by system (%d). Re-enabling...", type.rawValue)
            if let port = manager.machPort {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        if event.getIntegerValueField(.eventSourceUserData) == manager.magicUserData { return Unmanaged.passUnretained(event) }
        
        if type == .flagsChanged {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            if keyCode == KeyCodes.rightOption {
                if flags.contains(.maskAlternate) {
                    manager.isRightOptionDown = true
                    NSLog("[Alphabetter] Right Option pressed down")
                } else {
                    manager.isRightOptionDown = false; manager.activeKey = nil; manager.cycleIndex = 0
                    NSLog("[Alphabetter] Right Option released")
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
            
            // Palette toggle check
            if manager.useRightOptionOnly {
                if manager.isRightOptionDown && keyCode == manager.triggerKey {
                    NSLog("[Alphabetter] Trigger shortcut detected! Opening palette...")
                    DispatchQueue.main.async { manager.onTogglePalette?() }
                    return nil
                }
            } else {
                let flagsMask = UInt64(CGEventFlags.maskShift.rawValue | CGEventFlags.maskControl.rawValue | CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskCommand.rawValue)
                let flags = event.flags.rawValue & flagsMask
                let targetFlags = manager.customTriggerModifiers & flagsMask
                if flags == targetFlags && keyCode == manager.customTriggerKeyCode {
                    NSLog("[Alphabetter] Custom trigger shortcut detected! Opening palette...")
                    DispatchQueue.main.async { manager.onTogglePalette?() }
                    return nil
                }
            }
            
            if manager.isRightOptionDown {
                if manager.isShiftDown, let symbols = manager.ipaShiftMappings[keyCode] {
                    if manager.activeKey == keyCode {
                        let nextIndex = (manager.cycleIndex + 1) % symbols.count
                        manager.cycleIndex = nextIndex
                        let nextSymbol = symbols[nextIndex]
                        manager.postCleanBackspace()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.002) {
                            manager.postIPAChar(nextSymbol)
                        }
                    } else {
                        manager.activeKey = keyCode; manager.cycleIndex = 0
                        manager.postIPAChar(symbols[0])
                    }
                    return nil
                } else if !manager.isShiftDown, let symbols = manager.ipaMappings[keyCode] {
                    if manager.activeKey == keyCode {
                        let nextIndex = (manager.cycleIndex + 1) % symbols.count
                        manager.cycleIndex = nextIndex
                        let nextSymbol = symbols[nextIndex]
                        manager.postCleanBackspace()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.002) {
                            manager.postIPAChar(nextSymbol)
                        }
                    } else {
                        manager.activeKey = keyCode; manager.cycleIndex = 0
                        manager.postIPAChar(symbols[0])
                    }
                    return nil
                }
            }
        }
        return Unmanaged.passUnretained(event)
    }
    
    // MARK: - Actions
    func insertFromMenu(_ char: String) {
        if UserDefaults.standard.bool(forKey: "copyToClipboardOnInsert") {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(char, forType: .string)
        }

        guard AXIsProcessTrusted() else {
            hasShownAccessibilityAlert = false
            showAccessibilityAlertIfNeeded()
            return
        }
        NSApplication.shared.hide(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSLog("[Alphabetter] Inserting character from palette: %@", char)
            self.postIPAChar(char)
        }
    }
    
    private func postCleanBackspace() {
        postKey(KeyCodes.delete)
    }
    
    private func postKey(_ keyCode: Int64) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false) else { return }
        down.flags = []; up.flags = []
        down.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        up.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        down.post(tap: .cghidEventTap); up.post(tap: .cghidEventTap)
    }
    
    private func postIPAChar(_ char: String) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return }
        var chars = Array(char.utf16)
        down.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: &chars)
        up.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: &chars)
        down.flags = []; down.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        up.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        down.post(tap: .cghidEventTap); up.post(tap: .cghidEventTap)
    }
    
    // MARK: - Helper
    func findShortcut(for symbol: String) -> String? {
        if symbol == "ɸ" { return "⌥P" }
        
        for (code, list) in ipaShiftMappings {
            if let index = list.firstIndex(of: symbol) {
                let key = keyName(for: code)
                return index == 0 ? "⇧⌥\(key)" : "⇧⌥\(key) (×\(index + 1))"
            }
        }
        
        for (code, list) in ipaMappings {
            if let index = list.firstIndex(of: symbol) {
                let key = keyName(for: code)
                return index == 0 ? "⌥\(key)" : "⌥\(key) (×\(index + 1))"
            }
        }
        return nil
    }
    
    private func keyName(for code: Int64) -> String {
        let names: [Int64: String] = [
            KeyCodes.a: "A", KeyCodes.b: "B", KeyCodes.c: "C", KeyCodes.d: "D", KeyCodes.e: "E", KeyCodes.f: "F", KeyCodes.g: "G",
            KeyCodes.h: "H", KeyCodes.i: "I", KeyCodes.j: "J", KeyCodes.k: "K", KeyCodes.l: "L", KeyCodes.m: "M", KeyCodes.n: "N",
            KeyCodes.o: "O", KeyCodes.p: "P", KeyCodes.q: "Q", KeyCodes.r: "R", KeyCodes.s: "S", KeyCodes.t: "T", KeyCodes.u: "U",
            KeyCodes.v: "V", KeyCodes.w: "W", KeyCodes.x: "X", KeyCodes.y: "Y", KeyCodes.z: "Z", KeyCodes.one: "1", KeyCodes.two: "2",
            KeyCodes.three: "3", KeyCodes.four: "4", KeyCodes.five: "5", KeyCodes.six: "6", KeyCodes.seven: "7", KeyCodes.eight: "8",
            KeyCodes.nine: "9", KeyCodes.zero: "0", KeyCodes.space: "Spc", KeyCodes.returnKey: "Ret", KeyCodes.slash: "?",
            KeyCodes.comma: ",", KeyCodes.period: ".", KeyCodes.semicolon: ";"
        ]
        return names[code] ?? "?"
    }
}
