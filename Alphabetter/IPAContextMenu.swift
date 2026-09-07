import SwiftUI

// MARK: - Shared IPA Symbol Context Menu
/// Applies the standard IPA symbol context menu (phonological features + profile management)
/// to any view. Replaces the previously duplicated `.contextMenu` blocks across
/// IPAButton, SearchResultCard, SymbolRow, ClickableTableRow, and DiacriticRowButton.
struct IPAContextMenu: ViewModifier {
    let symbol: IPASymbol
    @EnvironmentObject var profileManager: ProfileManager

    func body(content: Content) -> some View {
        content.contextMenu {
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

extension View {
    func ipaContextMenu(for symbol: IPASymbol) -> some View {
        modifier(IPAContextMenu(symbol: symbol))
    }
}
