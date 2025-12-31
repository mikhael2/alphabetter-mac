import SwiftUI

struct IPAButton: View {
    let symbol: IPASymbol
    var size: CGFloat = 24
    
    @EnvironmentObject var hoverState: HoverState
    @State private var isHovering = false
    
    // Brand Color
    let purple = Color(red: 175/255, green: 104/255, blue: 239/255)
    
    var body: some View {
        Button(action: {
            EventTapManager.shared.insertFromMenu(symbol.char)
            RecentsManager.shared.add(symbol)
        }) {
            Text(symbol.type == .diacritic ? "◌" + symbol.char : symbol.char)
                .font(.system(size: size, weight: .regular, design: .serif))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        
        // --- VISUAL EFFECTS ---
        // 1. Purple Highlight
        .foregroundColor(isHovering ? purple : .primary)
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
    }
}
