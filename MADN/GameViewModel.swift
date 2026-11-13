import SwiftUI
import MADNCore

@Observable
final class GameViewModel {

    private var model: Game

    private(set) var presented: PresentedState

    init(game model: Game = try! Game()) {
        self.model = model
        presented = PresentedState(game: model)
    }

    // Presented state

    // Decouples model state from presented state: changes to the model happen immediately, while
    // changes to the presented state can be animated and delayed.
    // This way, the model state is always valid when it is serialized, and the
    // presented state does not have to follow the rules of the game.
    // Presented state is always synced with the model after a model change, either immediately or
    // after presenting.

    struct PresentedState {
        var player: Game.Player
        var pieces: [Game.Field: Game.Player]
        var die: Int?
        var movablePieces: Set<Game.Field>

        init(game: Game) {
            player = game.player

            pieces = Game.Field.allCases.reduce(into: [:]) { pieces, field in
                pieces[field] = game.player(at: field)
            }

            die = game.die?.rawValue

            movablePieces = game.die == nil
                ? []
                : Set(try! game.possibleMoves().map(\.from))
        }

        func player(at field: Game.Field) -> Game.Player? {
            pieces[field]
        }
    }

    private var isPresenting = false

    private func presentThenSync(_ change: @escaping () async -> Void) {
        isPresenting = true

        Task {
            defer {
                withAnimation { presented = PresentedState(game: model) }
                isPresenting = false
            }

            await change()
        }
    }

    // Game state

    var isGameOver: Bool { model.isOver }

    var finishedPlayers: Set<Game.Player> { model.finishedPlayers }

    // Game actions

    func start(players: Set<Game.Player>, player: Game.Player) {
        model = try! Game(players: players, player: player)
        presented = PresentedState(game: model)
    }

    func roll() {
        guard !isPresenting else { return }

        do {
            try model.roll()
            presented = PresentedState(game: model)

            if try model.possibleMoves().isEmpty {
                try model.pass()

                presentThenSync { // show the roll before passing
                    try? await Task.sleep(for: .seconds(1.5))
                }
            }
        } catch {
            print(error)
        }
    }

    func move(field: Game.Field) {
        guard !isPresenting else { return }

        do {
            try model.move(field: field)
            presented = PresentedState(game: model)
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
