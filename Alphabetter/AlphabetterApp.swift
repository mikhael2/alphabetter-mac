import SwiftUI
import Sparkle

@main
struct AlphabetterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    @AppStorage("hideDockIcon") private var hideDockIcon = false
    @AppStorage("triggerKeyIndex") private var triggerKeyIndex = 0
    let keys = [("Space", KeyCodes.space), ("Return", KeyCodes.returnKey), ("/ ?", KeyCodes.slash)]

    var body: some View {
        Form {
            Section(header: Text("Global Shortcut")) {
                Text("Hold **Right Option** and press:").foregroundColor(.secondary)
                Picker("Trigger Key:", selection: $triggerKeyIndex) {
                    ForEach(0..<keys.count, id: \.self) { i in Text(keys[i].0).tag(i) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: triggerKeyIndex) { _, _ in updateTriggerKey() }
            }

            Section(header: Text("Updates")) {
                Button("Check for Updates...") {
                    updaterController.updater.checkForUpdates()
                }
            }

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
            
            Section(header: Text("About")) {
                HStack {
                    Text("Alphabetter for macOS")
                    Spacer()
                    // Replace the v1.0.0 Text with this:
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 350, height: 280)
        .padding()
    }

    private func updateTriggerKey() {
        if triggerKeyIndex < keys.count {
            EventTapManager.shared.triggerKey = keys[triggerKeyIndex].1
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var paletteWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let shouldHide = UserDefaults.standard.bool(forKey: "hideDockIcon")
        NSApp.setActivationPolicy(shouldHide ? .accessory : .regular)
        setupStatusBar()
        EventTapManager.shared.start()
    }

    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            if let image = NSImage(named: "MenuBarIcon") {
                let ratio = image.size.width / image.size.height
                image.size = NSSize(width: 18 * ratio, height: 18)
                image.isTemplate = true
                button.image = image
            } else { button.title = "ð" }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "IPA Input: ON", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let searchItem = NSMenuItem(title: "Open IPA Palette...", action: #selector(openPalette), keyEquivalent: "p")
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
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusBarItem.menu = menu
    }

    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc func openPalette() {
        // ... (existing palette code) ...
    }

    @objc func insertFromMenu(_ sender: NSMenuItem) {
        if let char = sender.representedObject as? String {
            EventTapManager.shared.insertFromMenu(char)
        }
    }

    @objc func quitApp() { NSApplication.shared.terminate(nil) }
}
