import SwiftUI

struct VowelChartView: View {
    let heights = IPAHeight.allCases
    let backnesses = IPABackness.allCases
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    Color.clear.frame(width: 80, height: 30)
                    ForEach(backnesses) { back in
                        Text(back.rawValue.capitalized).font(.caption).fontWeight(.bold)
                            .frame(width: 60, height: 30).background(Color.blue.opacity(0.2))
                    }
                }
                ForEach(heights) { height in
                    GridRow {
                        Text(height.rawValue.capitalized).font(.caption).fontWeight(.bold)
                            .frame(width: 80, height: 40, alignment: .trailing).padding(.trailing, 5).background(Color.blue.opacity(0.2))
                        ForEach(backnesses) { back in
                            let (unrounded, rounded) = symbols(for: height, backness: back)
                            HStack(spacing: 0) {
                                if let s = unrounded { IPAButton(symbol: s) } else { Color.clear }
                                if let s = rounded { IPAButton(symbol: s) } else { Color.clear }
                            }
                            .frame(width: 60, height: 40)
                            .background((unrounded != nil || rounded != nil) ? Color(NSColor.controlBackgroundColor) : Color.gray.opacity(0.05))
                            .border(Color.gray.opacity(0.2))
                        }
                    }
                }
            }.padding()
        }
    }
    
    func symbols(for height: IPAHeight, backness: IPABackness) -> (IPASymbol?, IPASymbol?) {
        let syms = ipaDatabase.filter { $0.vowelHeight == height && $0.vowelBackness == backness }
        return (syms.first { $0.vowelRoundedness == .unrounded }, syms.first { $0.vowelRoundedness == .rounded })
    }
}
