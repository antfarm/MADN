import SwiftUI

private let highlightColor = Color.orange

struct GameView: View {

    @State private var game = GameViewModel()

    var body: some View {
        Board(game: game)
    }
}

struct Board: View {

    private static let cellSize: CGFloat = 100

    let game: GameViewModel

    var body: some View {
        GeometryReader { proxy in
            let boardSize = CGFloat(game.cellsPerSide) * Self.cellSize

            grid
                .frame(width: boardSize, height: boardSize)
                .scaleEffect(min(proxy.size.width, proxy.size.height) / boardSize)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var grid: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<game.cellsPerSide, id: \.self) { row in
                GridRow {
                    ForEach(0..<game.cellsPerSide, id: \.self) { column in
                        if let field = game.field(row: row, column: column) {
                            let hasMovablePiece = game.movablePieces.contains(field)
                            let player = game.player(at: field)

                            Field(
                                color: game.color(for: game.fieldOwner(of: field)),
                                pieceColor: game.color(for: player),
                                isHighlighted: hasMovablePiece,
                                isSmall: !game.isTrackField(field) && player == nil,
                                onTap: { withAnimation { game.move(field: field) } }
                            )
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
        .background {
            let fieldCenters = game.trackCells.map {
                CGPoint(x: (CGFloat($0.column) + 0.5) * Self.cellSize,
                        y: (CGFloat($0.row) + 0.5) * Self.cellSize)
            }

            TrackLine(fieldCenters: fieldCenters)
        }
        .overlay(alignment: game.corner(for: game.player)) {
            Die(
                value: game.die,
                color: game.color(for: game.player),
                onRoll: { game.roll() }
            )
            .rotationEffect(game.rotation(for: game.player))
            .frame(width: Self.cellSize, height: Self.cellSize)
            .padding(2.25 * Self.cellSize)
        }
        .scaleEffect(0.9)
    }
}

struct TrackLine: View {
    let fieldCenters: [CGPoint]

    var body: some View {
        Path { path in
            path.addLines(fieldCenters)
            path.closeSubpath()
        }
        .stroke(.primary, lineWidth: 4)
    }
}

struct Field: View {
    let color: Color?
    let pieceColor: Color?
    let isHighlighted: Bool
    let isSmall: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Circle()
                .strokeBorder(.primary, lineWidth: 4)
                .background {
                    Circle().fill(Color(.systemBackground))
                    if let color { Circle().fill(color.opacity(0.4)) }
                }
                .scaleEffect(isSmall ? 0.8 : 1)
                .overlay { if let pieceColor { Piece(color: pieceColor, isHighlighted: isHighlighted) } }
        }
        .buttonStyle(UnstyledButtonStyle())
        .disabled(!isHighlighted)
        .scaleEffect(0.95)
        .padding(5)
    }
}

struct Piece: View {
    let color: Color
    let isHighlighted: Bool

    var body: some View {
        Circle()
            .fill(color)
            .strokeBorder(isHighlighted ? highlightColor : .black, lineWidth: isHighlighted ? 14 : 4)
            .scaleEffect(0.75)
    }
}

struct Die: View {
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
                        .strokeBorder(highlightColor, lineWidth: 14)
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

struct UnstyledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label // no pressed or disabled styling
    }
}

import MADNCore

#Preview {
    GameView()
}

#Preview("Mixed board") {
    let pieces: [Game.Field: Game.Player] = Dictionary(uniqueKeysWithValues:
        zip(Game.Player.allCases, [
            ["0A", "0a", "00", "09"],
            ["1A", "1a", "11", "19"],
            ["2A", "2a", "22", "29"],
            ["3A", "3a", "33", "39"],
        ]).flatMap { player, labels in
            labels.map { (Game.Field($0)!, player) }
        }
    )

    Board(game: GameViewModel(game: try! Game(pieces: pieces)))
}

#Preview("Finished player") {
    let pieces: [Game.Field: Game.Player] = Dictionary(uniqueKeysWithValues:
        zip(Game.Player.allCases, [
            ["0A", "0a", "00", "09"],
            ["1a", "1b", "1c", "1d"],
            ["2A", "2a", "22", "29"],
            ["3A", "3a", "33", "39"],
        ]).flatMap { player, labels in
            labels.map { (Game.Field($0)!, player) }
        }
    )

    Board(game: GameViewModel(game: try! Game(pieces: pieces, player: .two)))
}
