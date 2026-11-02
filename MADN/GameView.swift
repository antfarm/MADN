import SwiftUI
import Playgrounds

struct GameView: View {

    static let boardMap = """
        1A 1B .. .. 18 19 20 .. .. 2B 2A
        1C 1D .. .. 17 2a 21 .. .. 2D 2C
        .. .. .. .. 16 2b 22 .. .. .. ..
        .. .. .. .. 15 2c 23 .. .. .. ..
        10 11 12 13 14 2d 24 25 26 27 28
        09 1a 1b 1c 1d .. 3d 3c 3b 3a 29
        08 07 06 05 04 0d 34 33 32 31 30
        .. .. .. .. 03 0c 35 .. .. .. ..
        .. .. .. .. 02 0b 36 .. .. .. ..
        0C 0D .. .. 01 0a 37 .. .. 3D 3C
        0A 0B .. .. 00 39 38 .. .. 3B 3A
        """
        .split(separator: "\n")
        .map { $0.split(separator: " ") }


    let colors = [Color.yellow, .blue, .red, .green]

    @State var game = Game()

    @State var dieRotation = 0.0

    @State var rolling = false

    var showIDs = false

    init() {
        Self.validateBoardMap()
    }

    static func validateBoardMap() {
        let fields = boardMap.flatMap { $0 }.map { String($0) }.filter { $0 != ".." }

        assert(Set(fields).count == fields.count, "Duplicate fields in board map")
        assert(Game.isValid(fields: Set(fields)), "Board map does not match the game's fields")
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            board
                .frame(width: 1100, height: 1100)
                .scaleEffect(side / 1100)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    var board: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(Self.boardMap.indices, id: \.self) { row in
                GridRow {
                    ForEach(Self.boardMap[row].indices, id: \.self) { column in
                        let field = String(Self.boardMap[row][column])
                        let owner = field.first!.wholeNumberValue
                        let fill = field.last == "0" || field.last!.isLetter ? owner.map { colors[$0].opacity(0.4) } : nil
                        if field == ".." {
                            Color.clear
                        } else {
                            Circle()
                                .strokeBorder(.primary, lineWidth: 4)
                                .background {
                                    Circle().fill(Color(.systemBackground))
                                    Circle().fill(fill ?? .clear)
                                }
                                .scaleEffect(field.last!.isLetter && game.piece(at: field) == nil ? 0.8 : 1)
                                .overlay { if let player = game.piece(at: field) { Piece(color: colors[player], isMovable: game.movablePieces.contains(field)) } }
                                .overlay { if showIDs { Text(field) } }
                                .anchorPreference(key: CellCenters.self, value: .center) { center in
                                    [field: center]
                                }
                                .scaleEffect(0.95)
                                .padding(5)
                                .onTapGesture { game.move(field: field) }
                                .allowsHitTesting(game.movablePieces.contains(field))
                        }
                    }
                }
            }
        }
        .backgroundPreferenceValue(CellCenters.self) { centers in
            GeometryReader { proxy in
                Path { path in
                    path.addLines((0..<40).compactMap { centers[String(format: "%02d", $0)].map { proxy[$0] } })
                    path.closeSubpath()
                }
                .stroke(.primary, lineWidth: 4)
            }
        }
        .overlayPreferenceValue(CellCenters.self) { centers in
            GeometryReader { proxy in
                if let anchor = centers["\(game.player)4"].map({ proxy[$0] }) {
                    let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    let step = 1.75 * proxy.size.width / 11

                    Button {
                        rolling = true
                        withAnimation(.easeInOut(duration: 1)) {
                            dieRotation += 360
                            game.roll()
                        } completion: {
                            rolling = false
                        }
                    } label: {
                        Die(value: game.die, color: colors[game.player])
                            .scaleEffect(0.9)
                    }
                    .buttonStyle(DieButtonStyle())
                    .disabled(game.die != nil || rolling)
                    .rotationEffect(.degrees(dieRotation + Double(game.player) * 90))
                    .frame(width: proxy.size.width / 11, height: proxy.size.width / 11)
                    .position(x: anchor.x + (anchor.x < center.x ? -step : step),
                              y: anchor.y + (anchor.y < center.y ? -step : step))
                }
            }
        }
        .font(.system(.body, design: .monospaced))
        .scaleEffect(0.9)
    }
}

struct CellCenters: PreferenceKey {
    static let defaultValue: [String: Anchor<CGPoint>] = [:]

    static func reduce(value: inout [String: Anchor<CGPoint>], nextValue: () -> [String: Anchor<CGPoint>]) {
        value.merge(nextValue()) { $1 }
    }
}

struct Piece: View {
    let color: Color
    let isMovable: Bool

    var body: some View {
        Circle()
            .fill(color)
            .strokeBorder(isMovable ? .orange : .black, lineWidth: isMovable ? 14 : 4)
            .scaleEffect(0.75)
    }
}

struct Die: View {
    let value: Int?
    let color: Color

    static let eyes = [
        1: "... .X. ...",
        2: "X.. ... ..X",
        3: "X.. .X. ..X",
        4: "X.X ... X.X",
        5: "X.X .X. X.X",
        6: "X.X X.X X.X",
    ]

    var body: some View {
        RoundedRectangle(cornerRadius: 11)
            .fill(Color(red: 1, green: 0.97, blue: 0.86).opacity(0.85))
            .strokeBorder(.primary, lineWidth: 4)
            .overlay {
                if let value {
                    let rows = Self.eyes[value]!.split(separator: " ").map(Array.init)
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
                    .transition(.opacity)
                } else {
                    Circle()
                        .fill(color)
                        .strokeBorder(.orange, lineWidth: 14)
                        .scaleEffect(0.7)
                        .transition(.opacity)
                }
            }
    }
}

struct DieButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label // no pressed or disabled styling
    }
}

#Preview {
    GameView()
}

#Playground {
    let cells = GameView.boardMap.flatMap { $0 }
}
