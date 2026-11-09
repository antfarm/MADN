import SwiftUI

struct DieView: View {
    let value: Int?
    let color: Color
    let onRoll: () -> Void

    @State var rotation = 0.0
    @State var isRolling = false

    var body: some View {
        Button {
            isRolling = true
            withAnimation(.easeInOut(duration: 1)) {
                rotation += 360
                onRoll()
            } completion: {
                isRolling = false
            }
        } label: {
            face.scaleEffect(0.9)
        }
        .buttonStyle(UnstyledButtonStyle())
        .disabled(value != nil || isRolling)
        .rotationEffect(.degrees(rotation))
    }

    private var face: some View {
        RoundedRectangle(cornerRadius: 11)
            .fill(Color(red: 1, green: 0.97, blue: 0.86).opacity(0.85))
            .strokeBorder(.primary, lineWidth: 4)
            .overlay {
                if let value {
                    Eyes(value: value)
                        .transition(.opacity)
                } else {
                    Circle()
                        .fill(color)
                        .strokeBorder(Color.orange, lineWidth: 14)
                        .scaleEffect(0.7)
                        .transition(.opacity)
                }
            }
    }

    private struct Eyes: View {
        private static let patterns = [
            1: "... .X. ...",
            2: "X.. ... ..X",
            3: "X.. .X. ..X",
            4: "X.X ... X.X",
            5: "X.X .X. X.X",
            6: "X.X X.X X.X",
        ]

        let value: Int

        var body: some View {
            let rows = Self.patterns[value]!.split(separator: " ").map(Array.init)

            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                ForEach(0..<3) { row in
                    GridRow {
                        ForEach(0..<3) { column in
                            Circle().fill(rows[row][column] == "X" ? Color.black : .clear)
                                .scaleEffect(0.8)
                        }
                    }
                }
            }
            .scaleEffect(0.7)
        }
    }
}

#Preview("Faces") {
    HStack {
        ForEach(1...6, id: \.self) { value in
            DieView(value: value, color: .yellow, onRoll: {})
                .frame(width: 100, height: 100)
        }

        DieView(value: nil, color: .yellow, onRoll: {})
            .frame(width: 100, height: 100)
    }
}
