import SwiftUI
import AppKit

// MARK: - Shortcut Recorder
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
        if flags.contains(.option)  { str += "⌥" }
        if flags.contains(.shift)   { str += "⇧" }
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
