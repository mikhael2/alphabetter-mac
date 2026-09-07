import SwiftUI
import ServiceManagement

// MARK: - Settings View
struct SettingsView: View {
    @State private var updateStatus: UpdateStatus = .idle
    @State private var latestVersion: String = ""
    private enum UpdateStatus { case idle, checking, upToDate, available, error }

    @AppStorage("hideDockIcon") private var hideDockIcon = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("appTheme") private var appTheme = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("appAccentColor") private var appAccentColor = 0

    @State private var needsMenuBarRestart = false

    @AppStorage("triggerKeyIndex") private var triggerKeyIndex = 0
    @AppStorage("useCustomShortcut") private var useCustomShortcut = false
    @AppStorage("customTriggerKeyCode") private var customTriggerKeyCode = Int(KeyCodes.space)
    @AppStorage("customTriggerModifiers") private var customTriggerModifiers = 524288 // ⌥ Option
    @AppStorage("customTriggerString") private var customTriggerString = "⌥Space"
    private let keys = EventTapManager.paletteShortcutKeys

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
                    HStack {
                        Button(action: checkForUpdates) {
                            Text(updateStatus == .checking ? "Checking..." : "Check for Updates")
                        }
                        .disabled(updateStatus == .checking)

                        Spacer()

                        switch updateStatus {
                        case .upToDate:
                            Label("Up to date", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green).font(.caption)
                        case .available:
                            Button(action: openReleasesPage) {
                                Label("v\(latestVersion) available — Download", systemImage: "arrow.down.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(Color.brandAccent)
                        case .error:
                            Label("Check failed", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange).font(.caption)
                        default:
                            EmptyView()
                        }
                    }
                }

                Section(header: Text("General")) {
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
                                launchAtLogin = SMAppService.mainApp.status == .enabled
                            }
                        }
                        .onAppear {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                }

                Section(header: Text("Appearance")) {
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

                    Toggle("Hide Menu Bar Icon", isOn: Binding(
                        get: { !showMenuBarIcon },
                        set: { hideIt in
                            showMenuBarIcon = !hideIt
                            needsMenuBarRestart = true
                        }
                    ))

                    if needsMenuBarRestart {
                        Button(action: {
                            if let appDelegate = NSApp.delegate as? AppDelegate {
                                appDelegate.restartApp()
                            }
                        }) {
                            Label("Restart to apply changes", systemImage: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.brandAccent)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Text(appearanceDescription)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Alphabetter for macOS")
                        Spacer()
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
            return "⚠️ Both icons hidden — use your shortcut to access the palette."
        } else if hideDockIcon {
            return "App will run in the menu bar only."
        } else if !showMenuBarIcon {
            return "App will show in the Dock only."
        } else {
            return "App will show in the Dock and menu bar."
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

    private func checkForUpdates() {
        updateStatus = .checking
        let url = URL(string: "https://raw.githubusercontent.com/mikhael2/alphabetter-mac/main/appcast.xml")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                guard let data,
                      let xml = String(data: data, encoding: .utf8),
                      let start = xml.range(of: "<sparkle:shortVersionString>"),
                      let end = xml.range(of: "</sparkle:shortVersionString>") else {
                    updateStatus = .error
                    return
                }
                let latest = String(xml[start.upperBound..<end.lowerBound])
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
                if latest == current {
                    updateStatus = .upToDate
                } else {
                    latestVersion = latest
                    updateStatus = .available
                }
            }
        }.resume()
    }

    private func openReleasesPage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/mikhael2/alphabetter-mac/releases/latest")!)
    }
}

// MARK: - Profiles Settings
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

// MARK: - Profile Edit Row
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
