import SwiftUI

struct VowelChartView: View {
    let heights = IPAHeight.allCases
    let backnesses = IPABackness.allCases
    
    // Get all vowel symbols from database
    var vowels: [IPASymbol] {
        ipaDatabase.filter { $0.type == .vowel }
    }
    
    // Helper to find symbols for a specific cell
    func symbols(for height: IPAHeight, backness: IPABackness) -> (unrounded: IPASymbol?, rounded: IPASymbol?) {
        let cellSymbols = vowels.filter { $0.vowelHeight == height && $0.vowelBackness == backness }
        let unrounded = cellSymbols.first { $0.vowelRoundedness == .unrounded }
        let rounded = cellSymbols.first { $0.vowelRoundedness == .rounded }
        return (unrounded, rounded)
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(alignment: .center, horizontalSpacing: 1, verticalSpacing: 1) {
                // 1. Header Row (Backness)
                GridRow {
                    Color.clear.frame(width: 80, height: 30) // Corner spacer
                    ForEach(backnesses) { backness in
                        Text(backness.rawValue.capitalized)
                            .font(.caption).fontWeight(.bold)
                            .frame(width: 60, height: 30)
                            .background(Color.blue.opacity(0.2)) // Different color for Vowels
                    }
                }
                
                // 2. Data Rows (Heights)
                ForEach(heights) { height in
                    GridRow {
                        // Row Header (Height)
                        Text(height.rawValue.capitalized)
                            .font(.caption).fontWeight(.bold)
                            .frame(width: 80, height: 40, alignment: .trailing)
                            .padding(.trailing, 5)
                            .background(Color.blue.opacity(0.2))
                        
                        // Cells
                        ForEach(backnesses) { backness in
                            let (unrounded, rounded) = symbols(for: height, backness: backness)
                            
                            HStack(spacing: 0) {
                                // Unrounded (Left)
                                if let sym = unrounded {
                                    IPAButton(symbol: sym)
                                } else {
                                    Color.clear
                                }
                                
                                // Rounded (Right)
                                if let sym = rounded {
                                    IPAButton(symbol: sym)
                                } else {
                                    Color.clear
                                }
                            }
                            .frame(width: 60, height: 40)
                            // Shade cell if it has content, otherwise slightly darker to show grid structure
                            .background((unrounded != nil || rounded != nil) ? Color(NSColor.controlBackgroundColor) : Color.gray.opacity(0.05))
                            .border(Color.gray.opacity(0.2))
                        }
                    }
                }
            }
            .padding()
        }
    }
}
