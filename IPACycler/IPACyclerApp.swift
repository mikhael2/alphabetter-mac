import SwiftUI

@main
struct IPACyclerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// --- SETTINGS VIEW ---
struct SettingsView: View {
    @AppStorage("triggerKeyIndex") private var triggerKeyIndex = 0
    
    // The available options for the hotkey
    let keys = [
        ("Space", KeyCodes.space),
        ("Return", KeyCodes.returnKey),
        ("/ ?", KeyCodes.slash) // <--- Updated Option
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Global Shortcut")) {
                Text("Hold **Right Option** and press:")
                    .foregroundColor(.secondary)
                
                Picker("Trigger Key:", selection: $triggerKeyIndex) {
                    ForEach(0..<keys.count, id: \.self) { index in
                        Text(keys[index].0).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: triggerKeyIndex) {
                    EventTapManager.shared.triggerKey = keys[triggerKeyIndex].1
                }
            }
            .padding()
        }
        .frame(width: 300, height: 120)
        .padding()
        .onAppear {
            // Sync on load
            if triggerKeyIndex < keys.count {
                EventTapManager.shared.triggerKey = keys[triggerKeyIndex].1
            }
        }
    }
}

// --- APP DELEGATE ---
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var paletteWindow: NSWindow?
    var settingsWindow: NSWindow?
    
    let menuDiacritics: [(String, String)] = [
        ("Rhoticity ( ˞ ) \t[⇧⌥R]", "˞"),
        ("Breathy Voice ( ̤ ) \t[⇧⌥T]", "\u{0324}"),
        ("Dental Bridge ( ̪ ) \t[⇧⌥D]", "\u{032A}"),
        ("Nasalized ( ̃ ) \t[⇧⌥S]", "\u{0303}"),
        ("Voiceless Ring ( ̥ ) \t[⇧⌥O]", "\u{0325}"),
        ("Voiced Caron ( ̬ ) \t[⇧⌥V]", "\u{032C}"),
        ("Long ( ː ) \t[⇧⌥F]", "ː"),
        ("Superscript Schwa ( ᵊ ) \t[⇧⌥E]", "\u{1D4A}"),
        ("Aspiration ( ʰ ) \t[⇧⌥H]", "ʰ"),
        ("Palatalization ( ʲ ) \t[⇧⌥J]", "ʲ"),
        ("Labialization ( ʷ ) \t[⇧⌥W]", "ʷ"),
        ("Velarization ( ˠ ) \t[⇧⌥Y]", "ˠ"),
        ("Nasal Release ( ⁿ ) \t[⇧⌥N]", "ⁿ"),
        ("No Audible Release ( ̚ ) \t[⇧⌥L]", "̚"),
        ("Cedilla ( ç ) \t[⇧⌥C]", "\u{0327}")
    ]
    func applicationDidFinishLaunching(_ notification: Notification) {
        EventTapManager.shared.onTogglePalette = { [weak self] in
            self?.openPalette()
        }
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            if let image = NSImage(named: "MenuBarIcon") {
                let ratio = image.size.width / image.size.height
                image.size = NSSize(width: 18 * ratio, height: 18)
                image.isTemplate = true
                button.image = image
                
                // --- NEW: Branding Tooltip ---
                button.toolTip = "Alphabetter [ˈæɫ.fəˌbɛ.ɾɚ]"
                
            } else {
                button.title = "ð"
            }
        }
        
        let menu = NSMenu()
        // Optional: You could rename this item to "Alphabetter: ON" if you want
        menu.addItem(NSMenuItem(title: "IPA Input: ON", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let searchItem = NSMenuItem(title: "Open IPA Palette...", action: #selector(openPalette), keyEquivalent: "p")
        searchItem.target = self
        menu.addItem(searchItem)
        
        // ... (Rest of your menu code stays exactly the same) ...
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // (Keep your cheat sheet logic exactly as is—it's great!)
        let diacriticItem = NSMenuItem(title: "Cheat Sheet / Quick Insert", action: nil, keyEquivalent: "")
        let diacriticMenu = NSMenu()
        
        let tones = [
            ("Extra Low ( ̏ ) \t[⇧⌥1]", "\u{030F}"), ("Low ( ̀ ) \t[⇧⌥2]", "\u{0300}"),
            ("Mid ( ̄ ) \t[⇧⌥3]", "\u{0304}"), ("High ( ́ ) \t[⇧⌥4]", "\u{0301}"),
            ("Extra High ( ̋ ) \t[⇧⌥5]", "\u{030B}"), ("Rising ( ̌ ) \t[⇧⌥6]", "\u{030C}"),
            ("Falling ( ̂ ) \t[⇧⌥7]", "\u{0302}")
        ]
        
        for (name, char) in tones + menuDiacritics {
            let item = NSMenuItem(title: name, action: #selector(insertDiacritic(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = char
            diacriticMenu.addItem(item)
        }
        menu.setSubmenu(diacriticMenu, for: diacriticItem)
        menu.addItem(diacriticItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusBarItem.menu = menu
        
        EventTapManager.shared.start()
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 200),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered, defer: false)
            
            window.title = "Settings"
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openPalette() {
            if paletteWindow == nil {
                let contentView = PaletteView()
                
                // 1. ADD '.fullSizeContentView' to the styleMask
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                    styleMask: [.titled, .closable, .resizable, .utilityWindow, .fullSizeContentView],
                    backing: .buffered, defer: false)
                
                // 2. MAKE THE WINDOW TRANSPARENT
                window.isOpaque = false
                window.backgroundColor = .clear
                
                // 3. TITLE BAR SETTINGS
                // Keep the bar transparent...
                window.titlebarAppearsTransparent = true
                
                // ...BUT make the text visible so we can see the IPA!
                // (Changed from .hidden to .visible)
                window.titleVisibility = .visible
                
                // 4. SET THE FUN IPA TITLE
                window.title = "[ˈæɫ.fəˌbɛ.ɾɚ]"
                
                window.contentView = NSHostingView(rootView: contentView)
                window.center()
                window.isReleasedWhenClosed = false
                paletteWindow = window
            }
            
            paletteWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    @objc func insertDiacritic(_ sender: NSMenuItem) {
        if let char = sender.representedObject as? String {
            EventTapManager.shared.insertFromMenu(char)
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
