import SwiftUI
import MADNCore

struct BoardView: View {

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

                            FieldView(
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
            DieView(
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

struct FieldView: View {
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
                    if let color { Circle().fill(color.opacity(0.25)) }
                }
                .scaleEffect(isSmall ? 0.8 : 1)
                .overlay { if let pieceColor { PieceView(color: pieceColor, isHighlighted: isHighlighted) } }
        }
        .buttonStyle(UnstyledButtonStyle())
        .disabled(!isHighlighted)
        .scaleEffect(0.95)
        .padding(5)
    }
}

struct PieceView: View {
    let color: Color
    let isHighlighted: Bool

    var body: some View {
        Circle()
            .fill(color)
            .strokeBorder(isHighlighted ? Color.orange : .black, lineWidth: isHighlighted ? 14 : 4)
            .scaleEffect(0.75)
    }
}

private typealias PiecePositions = [Game.Player: [String]]

#Preview("Mixed board") {
    let labels: PiecePositions = [
        .one:   ["0A", "0a", "00", "09"],
        .two:   ["1A", "1a", "11", "19"],
        .three: ["2A", "2a", "22", "29"],
        .four:  ["3A", "3a", "33", "39"],
    ]
    let pieces = labels.mapValues { Set($0.map { Game.Field($0)! }) }

    BoardView(game: GameViewModel(game: try! Game(pieces: pieces)))
}

#Preview("2 players") {
    let labels: PiecePositions = [
        .one:   ["0A", "0a", "00", "09"],
        .three: ["2A", "2a", "22", "29"],
    ]
    let pieces = labels.mapValues { Set($0.map { Game.Field($0)! }) }

    BoardView(game: GameViewModel(game: try! Game(pieces: pieces)))
}

#Preview("Finished player") {
    let labels: PiecePositions = [
        .one:   ["0A", "0a", "00", "09"],
        .two:   ["1a", "1b", "1c", "1d"],
        .three: ["2A", "2a", "22", "29"],
        .four:  ["3A", "3a", "33", "39"],
    ]
    let pieces = labels.mapValues { Set($0.map { Game.Field($0)! }) }

    BoardView(game: GameViewModel(game: try! Game(pieces: pieces, player: .one)))
}
