import SwiftUI

struct IPAButton: View {
    let symbol: IPASymbol
    var size: CGFloat = 24
    
    // Receive the shared state
    @EnvironmentObject var hoverState: HoverState
    
    var body: some View {
        Button(action: {
                    // 1. Insert Text
                    EventTapManager.shared.insertFromMenu(symbol.char)
                    // 2. Add to Recents
                    RecentsManager.shared.add(symbol)
                }) {
            // (Same visual logic as before)
            if symbol.type == .diacritic {
                Text("◌" + symbol.char)
                    .font(.system(size: size, weight: .regular, design: .serif))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            } else {
                Text(symbol.char)
                    .font(.system(size: size, weight: .regular, design: .serif))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(PlainButtonStyle())
        // REPLACEMENT FOR .help()
        .onHover { hovering in
            if hovering {
                hoverState.info = generateTooltip()
                hoverState.isHovering = true
            } else {
                hoverState.isHovering = false
            }
        }
    }
    
    // Generate the text for the status bar
    func generateTooltip() -> String {
        var parts: [String] = []
        
        // 1. Name
        parts.append(symbol.description.capitalized)
        
        // 2. Shortcut
        if let shortcut = EventTapManager.shared.findShortcut(for: symbol.char) {
            parts.append("Key: \(shortcut)")
        }
        
        // 3. Unicode
        if let scalar = symbol.char.unicodeScalars.first {
            let hex = String(format: "U+%04X", scalar.value)
            parts.append(hex)
        }
        
        return parts.joined(separator: "  •  ")
    }
}
