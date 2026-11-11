import SwiftUI
import MADNCore

@Observable
final class GameViewModel {

    private var game: Game

    init(game: Game = try! Game()) {
        self.game = game
    }

    // Game state

    var player: Game.Player { game.player }

    var die: Int? { game.die?.rawValue }

    var isGameOver: Bool { game.isOver }

    var finishedPlayers: Set<Game.Player> { game.finishedPlayers }

    func player(at field: Game.Field) -> Game.Player? {
        game.player(at: field)
    }

    var movablePieces: Set<Game.Field> {
        guard game.die != nil else { return [] }

        return Set(try! game.possibleMoves().map(\.from))
    }

    // Game actions

    func start(players: Set<Game.Player>, player: Game.Player) {
        game = try! Game(players: players, player: player)
    }

    func roll() {
        do {
            try game.roll()

            if try game.possibleMoves().isEmpty {
                Task {
                    try? await Task.sleep(for: .seconds(1.5)) // show the roll before passing
                    withAnimation { try? game.pass() }
                }
            }
        } catch {
            print(error)
        }
    }

    func move(field: Game.Field) {
        do {
            try game.move(field: field)
        } catch {
            print(error)
        }
    }

    // Board topology

    func isTrackField(_ field: Game.Field) -> Bool {
        field.isTrack
    }

    func fieldOwner(of field: Game.Field) -> Game.Player? {
        field.owner
    }

    // Board grid layout

    let cellsPerSide = BoardLayout.cellsPerSide

    func field(row: Int, column: Int) -> Game.Field? {
        BoardLayout.field(row: row, column: column)
    }

    let trackCells = BoardLayout.trackCells

    // Player colors, corners and rotation

    private static let playerColors = [Color.yellow, .blue, .red, .green]

    func color(for player: Game.Player) -> Color {
        Self.playerColors[player.rawValue]
    }

    func color(for player: Game.Player?) -> Color? {
        guard let player else { return nil }

        return Self.playerColors[player.rawValue]
    }

    private static let playerCorners: [Alignment] = [.bottomLeading, .topLeading, .topTrailing, .bottomTrailing]

    func corner(for player: Game.Player) -> Alignment {
        Self.playerCorners[player.rawValue]
    }

    func rotation(for player: Game.Player) -> Angle {
        .degrees(Double(player.rawValue) * 90)
    }
}
