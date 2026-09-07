import SwiftUI
import ServiceManagement

// MARK: - Accent Color
extension Color {
    /// Pre-built palette — constructed once as a static let rather than on every render call.
    private static let accentPalette: [Color] = [
        Color(red: 175/255, green: 104/255, blue: 239/255), // 0: Purple
        .blue,    // 1: Blue
        .green,   // 2: Green
        .orange,  // 3: Orange
        .red,     // 4: Red
        Color(hue: 0.92, saturation: 0.6, brightness: 0.97), // 5: Pink
        .gray     // 6: Monochrome/Gray
    ]

    static var brandAccent: Color {
        let index = UserDefaults.standard.integer(forKey: "appAccentColor")
        return accentPalette[min(max(index, 0), accentPalette.count - 1)]
    }
}

// MARK: - Notification Names
extension NSNotification.Name {
    static let switchToSettingsTab = NSNotification.Name("SwitchToSettingsTab")
    static let switchToSearchTab   = NSNotification.Name("SwitchToSearchTab")
}

// MARK: - App Entry Point
@main
struct AlphabetterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appDelegate.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var paletteWindow: NSWindow?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Handle Dock Icon Logic
        let shouldHide = UserDefaults.standard.bool(forKey: "hideDockIcon")
        NSApp.setActivationPolicy(shouldHide ? .accessory : .regular)

        // 2. Setup Menu Bar
        setupStatusBar()
        let showMenuBar = UserDefaults.standard.object(forKey: "showMenuBarIcon") as? Bool ?? true
        updateStatusBarVisibility(show: showMenuBar)

        // 3. Configure Event Tap
        let defaults = UserDefaults.standard
        let manager = EventTapManager.shared
        manager.useRightOptionOnly = !defaults.bool(forKey: "useCustomShortcut")
        let tkIndex = defaults.integer(forKey: "triggerKeyIndex")
        let mappedKeys = EventTapManager.paletteShortcutKeys
        if tkIndex < mappedKeys.count { manager.triggerKey = mappedKeys[tkIndex].1 }
        manager.customTriggerKeyCode = Int64(defaults.object(forKey: "customTriggerKeyCode") as? Int ?? Int(KeyCodes.space))
        manager.customTriggerModifiers = UInt64(defaults.object(forKey: "customTriggerModifiers") as? Int ?? 524288)

        // Connect the trigger to the palette
        manager.onTogglePalette = { [weak self] in
            self?.openPalette()
            NotificationCenter.default.post(name: .switchToSearchTab, object: nil)
        }

        // 4. Start Listening
        manager.start()
    }

    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem.button {
            if let originalImage = NSImage(named: "MenuBarIcon") {
                let image = originalImage.copy() as! NSImage
                let ratio = image.size.width / image.size.height
                image.size = NSSize(width: 18 * ratio, height: 18)
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageOnly
            } else if let fallback = NSImage(systemSymbolName: "character", accessibilityDescription: nil) {
                fallback.isTemplate = true
                button.image = fallback
                button.imagePosition = .imageOnly
            } else {
                button.title = "ð"
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "IPA Input: ON", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let searchItem = NSMenuItem(title: "Open IPA Palette...", action: #selector(openSearch), keyEquivalent: "p")
        searchItem.target = self
        menu.addItem(searchItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // --- QUICK INSERT SUBMENU ---
        let quickInsertItem = NSMenuItem(title: "Quick Insert", action: nil, keyEquivalent: "")
        let quickMenu = NSMenu()

        func addItem(_ title: String, _ shortcut: String, _ char: String) {
            let paddingCount = max(0, 24 - title.count)
            let padding = String(repeating: " ", count: paddingCount)
            let paddedTitle = "  " + title + padding + "\t" + shortcut
            let item = NSMenuItem(title: paddedTitle, action: #selector(insertFromMenu(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = char
            quickMenu.addItem(item)
        }

        // Group 1: Prosody & Structure
        addItem("Primary Stress ( ˈ )", "[⌥Q]", "ˈ")
        addItem("Length ( ː )", "[⌥;]", "ː")
        addItem("Tie Bar ( ͡ )", "[⌥F]", "͡")
        addItem("Syllabic ( ̩ )", "[⇧⌥F]", "\u{0329}")
        quickMenu.addItem(NSMenuItem.separator())

        // Group 2: Articulation Modifiers
        addItem("Aspiration ( ʰ )", "[⇧⌥H]", "ʰ")
        addItem("Palatalized ( ʲ )", "[⇧⌥J]", "ʲ")
        addItem("Labialized ( ʷ )", "[⇧⌥W]", "ʷ")
        addItem("Velarized ( ˠ )", "[⇧⌥Y]", "ˠ")
        addItem("Nasalized ( ̃ )", "[⇧⌥S]", "\u{0303}")
        addItem("Rhoticity ( ˞ )", "[⇧⌥R]", "˞")
        addItem("No Aud. Rel. ( ̚ )", "[⇧⌥L]", "̚")
        quickMenu.addItem(NSMenuItem.separator())

        // Group 3: Tones
        addItem("Low ( ̀ )", "[⇧⌥2]", "\u{0300}")
        addItem("High ( ́ )", "[⇧⌥4]", "\u{0301}")
        addItem("Rising ( ̌ )", "[⇧⌥6]", "\u{030C}")
        addItem("Falling ( ̂ )", "[⇧⌥7]", "\u{0302}")

        menu.setSubmenu(quickMenu, for: quickInsertItem)
        menu.addItem(quickInsertItem)

        menu.addItem(NSMenuItem.separator())
        let restartItem = NSMenuItem(title: "Restart", action: #selector(restartApp), keyEquivalent: "")
        restartItem.target = self
        menu.addItem(restartItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusBarItem.menu = menu
    }

    func updateStatusBarVisibility(show: Bool) {
        if show {
            if statusBarItem == nil { setupStatusBar() }
            statusBarItem.isVisible = true
        } else {
            statusBarItem?.isVisible = false
        }
    }

    @objc func openSettings() {
        openPalette()
        NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
    }

    @objc func openSearch() {
        openPalette()
        NotificationCenter.default.post(name: .switchToSearchTab, object: nil)
    }

    @objc func openPalette() {
        // 1. Force the app to wake up and come to the front
        NSApp.activate(ignoringOtherApps: true)

        // 2. If the window is already open, just bring it to the front
        if let window = paletteWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // 3. Create the floating panel
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 500),
            styleMask: [.titled, .closable, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )

        // 4. Configure: float above everything
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.title = "Alphabetter"
        window.center()

        // 5. Connect the palette view
        window.contentView = NSHostingView(rootView: PaletteView().environmentObject(ProfileManager.shared))

        // 6. Launch it
        window.makeKeyAndOrderFront(nil)
        self.paletteWindow = window
    }

    @objc func insertFromMenu(_ sender: NSMenuItem) {
        if let char = sender.representedObject as? String {
            EventTapManager.shared.insertFromMenu(char)
        }
    }

    @objc func restartApp() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", Bundle.main.bundlePath]
        try? process.run()
        NSApplication.shared.terminate(nil)
    }

    @objc func quitApp() { NSApplication.shared.terminate(nil) }
}
