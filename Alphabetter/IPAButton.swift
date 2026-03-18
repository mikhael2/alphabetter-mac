import SwiftUI

struct IPAButton: View {
    let symbol: IPASymbol
    var size: CGFloat = 24
    
    @EnvironmentObject var hoverState: HoverState
    @EnvironmentObject var profileManager: ProfileManager
    @State private var isHovering = false
    @AppStorage("appAccentColor") private var appAccentColor = 0
    
    var body: some View {
        Button(action: {
            EventTapManager.shared.insertFromMenu(symbol.char)
            RecentsManager.shared.add(symbol)
        }) {
            Text(symbol.type == .diacritic ? "◌" + symbol.char : symbol.char)
                .font(.system(size: size, weight: .regular, design: .default))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        
        // --- VISUAL EFFECTS ---
        // 1. Highlight
        .foregroundColor(isHovering ? Color.brandAccent : .primary)
        // 2. "Pop" Scale Effect
        .scaleEffect(isHovering ? 1.2 : 1.0)
        // 3. Bring to front (so it overlaps neighbors when scaled)
        .zIndex(isHovering ? 1 : 0)
        // 4. Smooth Animation
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        // --- HOVER LOGIC ---
        .onHover { hovering in
            isHovering = hovering
            
            // Update Global Status Bar
            hoverState.isHovering = hovering
            if hovering {
                hoverState.info = symbol.tooltipInfo
            }
        }
        .contextMenu {
            if let features = symbol.features {
                VStack(alignment: .leading) {
                    Text("Phonological Features").font(.headline)
                    ForEach(features.activeFeatures, id: \.name) { feat in
                        Text("\(feat.value == .plus ? "+" : "-")\(feat.name)")
                    }
                }
            } else {
                Text("No feature data available")
            }
            
            Divider()
            
            Menu("Add to Profile...") {
                if profileManager.profiles.isEmpty {
                    Text("No profiles found")
                } else {
                    ForEach(profileManager.profiles) { profile in
                        Button(action: {
                            profileManager.toggleSymbol(char: symbol.char, in: profile.id)
                        }) {
                            HStack {
                                Text(profile.name)
                                if profile.characters.contains(symbol.char) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
