import SwiftUI

@main
struct AlphabetterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

struct SettingsView: View {
    @ObservedObject var updater = UpdateChecker.shared
    
    @AppStorage("hideDockIcon") private var hideDockIcon = false
    @AppStorage("triggerKeyIndex") private var triggerKeyIndex = 0
    
    let keys = [("Space", KeyCodes.space), ("Return", KeyCodes.returnKey), ("/ ?", KeyCodes.slash)]
    
    var body: some View {
        Form {
            // --- SECTION 1: SHORTCUTS ---
            Section(header: Text("Global Shortcut")) {
                Text("Hold **Right Option** and press:").foregroundColor(.secondary)
                Picker("Trigger Key:", selection: $triggerKeyIndex) {
                    ForEach(0..<keys.count, id: \.self) { i in Text(keys[i].0).tag(i) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: triggerKeyIndex) { _, _ in updateTriggerKey() }
            }
            
            // --- SECTION 2: UPDATES ---
            Section(header: Text("Updates")) {
                HStack {
                    Button("Check for Updates") {
                        updater.checkForUpdates()
                    }
                    .disabled(updater.isChecking)
                    
                    if updater.isChecking {
                        ProgressView().controlSize(.small).padding(.leading, 5)
                    }
                }
                
                // Status Text
                if !updater.updateStatus.isEmpty {
                    Text(updater.updateStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                    
                    // Download Button
                    if updater.newVersionURL != nil {
                        Button("Quit & Download Update") {
                            updater.downloadAndQuit()
                        }
                        .padding(.top, 2)
                    }
                }
            }
            
            // --- SECTION 3: APPEARANCE ---
            Section(header: Text("Appearance")) {
                Toggle("Hide Dock Icon", isOn: $hideDockIcon)
                    .onChange(of: hideDockIcon) { _, isHidden in
                        NSApp.setActivationPolicy(isHidden ? .accessory : .regular)
                        if !isHidden { NSApp.activate(ignoringOtherApps: true) }
                    }
                
                Text(hideDockIcon ? "App will run in menu bar only." : "App will show in Dock and menu bar.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 350, height: 250)
        .padding()
        .onAppear { updateTriggerKey() }
    }
    
    private func updateTriggerKey() {
        if triggerKeyIndex < keys.count { EventTapManager.shared.triggerKey = keys[triggerKeyIndex].1 }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var paletteWindow: NSWindow?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let shouldHide = UserDefaults.standard.bool(forKey: "hideDockIcon")
        NSApp.setActivationPolicy(shouldHide ? .accessory : .regular)
        
        EventTapManager.shared.onTogglePalette = { [weak self] in self?.openPalette() }
        setupStatusBar()
        EventTapManager.shared.start()
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            if let image = NSImage(named: "MenuBarIcon") {
                let ratio = image.size.width / image.size.height
                image.size = NSSize(width: 18 * ratio, height: 18); image.isTemplate = true
                button.image = image; button.toolTip = "Alphabetter [ˈæɫ.fəˌbɛ.ɾɚ]"
            } else { button.title = "ð" }
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "IPA Input: ON", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let searchItem = NSMenuItem(title: "Open IPA Palette...", action: #selector(openPalette), keyEquivalent: "p"); searchItem.target = self
        menu.addItem(searchItem)
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","); settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        
        // --- QUICK INSERT MENU ---
        let quickInsertItem = NSMenuItem(title: "Quick Insert", action: nil, keyEquivalent: "")
        let quickMenu = NSMenu()
        
        func addHeader(_ title: String) {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.isEnabled = false
            quickMenu.addItem(item)
        }
        
        func addItem(_ title: String, _ shortcut: String, _ char: String) {
            let paddingCount = max(0, 24 - title.count)
            let padding = String(repeating: " ", count: paddingCount)
            let paddedTitle = "  " + title + padding + "\t" + shortcut
            let item = NSMenuItem(title: paddedTitle, action: #selector(insertDiacritic(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = char
            quickMenu.addItem(item)
        }
        
        // 1. STRUCTURE
        addItem("Primary Stress ( ˈ )", "[⌥Q]", "ˈ")
        addItem("Length ( ː )", "[⌥;]", "ː")
        addItem("Tie Bar ( ͡ )", "[⌥F]", "͡")
        addItem("Syllabic ( ̩ )", "[⇧⌥F]", "\u{0329}")
        
        quickMenu.addItem(NSMenuItem.separator())
        
        // 2. MODIFIERS
        addItem("Aspiration ( ʰ )", "[⇧⌥H]", "ʰ")
        addItem("Palatalized ( ʲ )", "[⇧⌥J]", "ʲ")
        addItem("Labialized ( ʷ )", "[⇧⌥W]", "ʷ")
        addItem("Velarized ( ˠ )", "[⇧⌥Y]", "ˠ")
        addItem("Nasalized ( ̃ )", "[⇧⌥S]", "\u{0303}")
        addItem("Rhoticity ( ˞ )", "[⇧⌥R]", "˞")
        addItem("No Aud. Rel. ( ̚ )", "[⇧⌥L]", "̚")
        
        quickMenu.addItem(NSMenuItem.separator())
        
        // 4. TONES
        addItem("Low ( ̀ )", "[⇧⌥2]", "\u{0300}")
        addItem("High ( ́ )", "[⇧⌥4]", "\u{0301}")
        
        addItem("Rising ( ̌ )", "[⇧⌥6]", "\u{030C}")
        addItem("Falling ( ̂ )", "[⇧⌥7]", "\u{0302}")
        
        menu.setSubmenu(quickMenu, for: quickInsertItem)
        menu.addItem(quickInsertItem)
        
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"); quitItem.target = self
        menu.addItem(quitItem)
        statusBarItem.menu = menu
    }
    @objc func openSettings() {
            NSApp.activate(ignoringOtherApps: true) // Brings app to front
            if settingsWindow == nil {
                let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 350, height: 250), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
                w.title = "Settings"; w.contentView = NSHostingView(rootView: SettingsView()); w.center(); w.isReleasedWhenClosed = false
                settingsWindow = w
            }
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
        
        @objc func openPalette() {
            if paletteWindow == nil {
                let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 500), styleMask: [.titled, .closable, .resizable, .utilityWindow, .fullSizeContentView], backing: .buffered, defer: false)
                w.isOpaque = false; w.backgroundColor = .clear; w.titlebarAppearsTransparent = true; w.titleVisibility = .visible; w.title = "[ˈæɫ.fəˌbɛ.ɾɚ]"
                w.contentView = NSHostingView(rootView: PaletteView()); w.center(); w.isReleasedWhenClosed = false
                paletteWindow = w
            }
            paletteWindow?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        }
        
        @objc func insertDiacritic(_ sender: NSMenuItem) {
            if let char = sender.representedObject as? String { EventTapManager.shared.insertFromMenu(char) }
        }
        @objc func quitApp() { NSApplication.shared.terminate(nil) }
    }
