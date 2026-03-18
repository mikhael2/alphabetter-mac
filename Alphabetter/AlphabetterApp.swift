import SwiftUI
import Sparkle
import ServiceManagement

extension Color {
    static var brandAccent: Color {
        let index = UserDefaults.standard.integer(forKey: "appAccentColor")
        let colors: [Color] = [
            Color(red: 175/255, green: 104/255, blue: 239/255), // 0: Purple
            Color.blue,                                         // 1: Blue
            Color.green,                                        // 2: Green
            Color.orange,                                       // 3: Orange
            Color.red,                                          // 4: Red
            Color(hue: 0.92, saturation: 0.6, brightness: 0.97),  // 5: Pink
            Color.gray                                          // 6: Monochrome/Gray
        ]
        return colors[min(max(index, 0), colors.count - 1)]
    }
}

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

struct SettingsView: View {
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    @AppStorage("hideDockIcon") private var hideDockIcon = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("appTheme") private var appTheme = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("appAccentColor") private var appAccentColor = 0
    
    @AppStorage("triggerKeyIndex") private var triggerKeyIndex = 0
    @AppStorage("useCustomShortcut") private var useCustomShortcut = false
    @AppStorage("customTriggerKeyCode") private var customTriggerKeyCode = Int(KeyCodes.space)
    @AppStorage("customTriggerModifiers") private var customTriggerModifiers = 524288 // ⌥ Option
    @AppStorage("customTriggerString") private var customTriggerString = "⌥Space"
    let keys = [("Space", KeyCodes.space), ("Return", KeyCodes.returnKey), ("/ ?", KeyCodes.slash)]

    var body: some View {
        ScrollView {
            Form {
                Section(header: Text("Global Shortcut")) {
                Picker("Shortcut Type", selection: $useCustomShortcut) {
                    Text("Right Option +").tag(false)
                    Text("Custom").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: useCustomShortcut) { _, _ in updateTriggerKey() }

                if !useCustomShortcut {
                    Picker("Trigger Key:", selection: $triggerKeyIndex) {
                        ForEach(0..<keys.count, id: \.self) { i in Text(keys[i].0).tag(i) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: triggerKeyIndex) { _, _ in updateTriggerKey() }
                } else {
                    ShortcutRecorder(
                        customKeyCode: $customTriggerKeyCode,
                        customModifiers: $customTriggerModifiers,
                        customString: $customTriggerString,
                        onChange: { updateTriggerKey() }
                    )
                }
            }

            Section(header: Text("Custom Profiles")) {
                ProfilesSettingsView()
            }

            Section(header: Text("Updates")) {
                Button("Check for Updates...") {
                    updaterController.updater.checkForUpdates()
                }
            }

            Section(header: Text("Appearance")) {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update SMAppService: \(error)")
                            // Revert on failure
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                    .onAppear {
                        // Sync initial state
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())

                Picker("Accent Color", selection: $appAccentColor) {
                    Text("Purple").tag(0)
                    Text("Blue").tag(1)
                    Text("Green").tag(2)
                    Text("Orange").tag(3)
                    Text("Red").tag(4)
                    Text("Pink").tag(5)
                    Text("Gray").tag(6)
                }
                
                Toggle("Hide Dock Icon", isOn: $hideDockIcon)
                    .onChange(of: hideDockIcon) { _, isHidden in
                        NSApp.setActivationPolicy(isHidden ? .accessory : .regular)
                        if !isHidden { NSApp.activate(ignoringOtherApps: true) }
                    }
                    
                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                    .onChange(of: showMenuBarIcon) { _, newValue in
                        if let appDelegate = NSApp.delegate as? AppDelegate {
                            appDelegate.updateStatusBarVisibility(show: newValue)
                        }
                    }
                    
                Text(appearanceDescription)
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
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var appearanceDescription: String {
        if hideDockIcon && !showMenuBarIcon {
            return "WARNING: Both icons hidden! Use shortcut to access."
        } else if hideDockIcon {
            return "App will run in menu bar only."
        } else if !showMenuBarIcon {
            return "App will show in Dock only."
        } else {
            return "App will show in Dock and menu bar."
        }
    }

    private func updateTriggerKey() {
        let manager = EventTapManager.shared
        manager.useRightOptionOnly = !useCustomShortcut
        if triggerKeyIndex < keys.count {
            manager.triggerKey = keys[triggerKeyIndex].1
        }
        manager.customTriggerKeyCode = Int64(customTriggerKeyCode)
        manager.customTriggerModifiers = UInt64(customTriggerModifiers)
    }
}

struct ProfilesSettingsView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var newProfileName = ""
    @State private var newProfileChars = ""
    @State private var isAddingNew = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if profileManager.profiles.isEmpty && !isAddingNew {
                Text("No custom profiles yet. Click below to add one!")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 8) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileEditRow(profile: profile)
                    }
                }
            }
            
            if isAddingNew {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Profile Name", text: $newProfileName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Paste IPA Chars (e.g. p b t d k g)", text: $newProfileChars)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Button("Cancel") {
                            withAnimation {
                                isAddingNew = false
                                newProfileName = ""
                                newProfileChars = ""
                            }
                        }
                        
                        Button("Save Profile") {
                            if !newProfileName.isEmpty {
                                profileManager.addProfile(name: newProfileName, characterString: newProfileChars)
                                withAnimation {
                                    isAddingNew = false
                                    newProfileName = ""
                                    newProfileChars = ""
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newProfileName.isEmpty)
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            } else {
                Button(action: {
                    withAnimation { isAddingNew = true }
                }) {
                    Label("Add New Profile", systemImage: "plus.circle.fill")
                        .foregroundColor(Color.brandAccent)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
            }
        }
    }
}

struct ProfileEditRow: View {
    let profile: IPAProfile
    @EnvironmentObject var profileManager: ProfileManager
    
    @State private var isEditing = false
    @State private var editName = ""
    @State private var editChars = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("Profile Name", text: $editName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Characters (space separated)", text: $editChars)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Button("Cancel") {
                        withAnimation { isEditing = false }
                    }
                    
                    Button("Save") {
                        profileManager.updateProfile(id: profile.id, newName: editName, newCharacterString: editChars)
                        withAnimation { isEditing = false }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(editName.isEmpty)
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(profile.characters.sorted().joined(separator: " "))
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        editName = profile.name
                        editChars = profile.characters.sorted().joined(separator: " ")
                        withAnimation { isEditing = true }
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        if let idx = profileManager.profiles.firstIndex(where: { $0.id == profile.id }) {
                            profileManager.deleteProfile(at: IndexSet(integer: idx))
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}

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
            
            // 3. --- THIS IS THE MISSING PIECE ---
            let defaults = UserDefaults.standard
            let manager = EventTapManager.shared
            manager.useRightOptionOnly = !defaults.bool(forKey: "useCustomShortcut")
            let tkIndex = defaults.integer(forKey: "triggerKeyIndex")
            let mappedKeys = [("Space", KeyCodes.space), ("Return", KeyCodes.returnKey), ("/ ?", KeyCodes.slash)]
            if tkIndex < mappedKeys.count { manager.triggerKey = mappedKeys[tkIndex].1 }
            manager.customTriggerKeyCode = Int64(defaults.object(forKey: "customTriggerKeyCode") as? Int ?? Int(KeyCodes.space))
            manager.customTriggerModifiers = UInt64(defaults.object(forKey: "customTriggerModifiers") as? Int ?? 524288)

            // Connect the trigger to your openPalette function
            manager.onTogglePalette = { [weak self] in
                self?.openPalette()
                NotificationCenter.default.post(name: NSNotification.Name("SwitchToSearchTab"), object: nil)
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

    // Add this variable at the top of your AppDelegate class if it's missing
    
        @objc func openSettings() {
            openPalette()
            NotificationCenter.default.post(name: NSNotification.Name("SwitchToSettingsTab"), object: nil)
        }

        @objc func openSearch() {
            openPalette()
            NotificationCenter.default.post(name: NSNotification.Name("SwitchToSearchTab"), object: nil)
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
                contentRect: NSRect(x: 0, y: 0, width: 750, height: 500), // Height 500 fits the charts better
                styleMask: [.titled, .closable, .nonactivatingPanel, .resizable],
                backing: .buffered,
                defer: false
            )
            
            // 4. Configure: Make it float above everything (Level 9)
            window.level = .floating
            window.isReleasedWhenClosed = false
            window.title = "Alphabetter"
            window.center()

            // 5. Connect your View
            // This connects to your PaletteView.swift file
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

    @objc func quitApp() { NSApplication.shared.terminate(nil) }
}

struct ShortcutRecorder: View {
    @Binding var customKeyCode: Int
    @Binding var customModifiers: Int // NSEvent.ModifierFlags.rawValue
    @Binding var customString: String
    var onChange: () -> Void
    
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: {
            isRecording.toggle()
            if isRecording { startRecording() }
            else { stopRecording() }
        }) {
            Text(isRecording ? "Listening... (Press combination)" : (customString.isEmpty ? "Click to record" : customString))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.isEmpty { 
                NSSound.beep()
                return event 
            }
            
            self.customKeyCode = Int(event.keyCode)
            self.customModifiers = Int(flags.rawValue)
            self.customString = Self.string(for: event)
            
            self.stopRecording()
            self.onChange()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    static func string(for event: NSEvent) -> String {
        var str = ""
        let flags = event.modifierFlags
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.shift) { str += "⇧" }
        if flags.contains(.command) { str += "⌘" }
        
        switch event.keyCode {
        case 36: str += "Return"
        case 49: str += "Space"
        case 48: str += "Tab"
        case 51: str += "Delete"
        case 53: str += "Esc"
        case 123: str += "←"
        case 124: str += "→"
        case 125: str += "↓"
        case 126: str += "↑"
        default:
            if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
                str += chars
            } else {
                str += "Key \(event.keyCode)"
            }
        }
        return str
    }
}
