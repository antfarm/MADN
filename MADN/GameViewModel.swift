import SwiftUI
import MADNCore

@Observable
final class GameViewModel {

    // Game state

    private var model: Game

    var isGameOver: Bool { model.isOver }

    var possibleMoves: [(from: Game.Field, to: Game.Field)] {
        guard model.die != nil else { return [] }

        return try! model.possibleMoves()
    }

    // Presented state

    private let presenter: Presenter

    var presented: PresentedState { presenter.state }

    var hasPlayerFinished: Bool { presented.hasPlayerFinished }

    var shouldDisableInput: Bool { presenter.isPresenting }

    func hasPiece(at field: Game.Field) -> Bool {
        presented.piece(at: field) != nil
    }

    // Initialization

    init(game model: Game = try! Game()) {
        self.model = model
        presenter = Presenter(game: model)
    }

    // Game actions

    func start(players: Set<Game.Player>, player: Game.Player) {
        model = try! Game(players: players, player: player)
        presenter.present(game: model)
    }

    func resume() {
        presenter.present(game: model)
    }

    func roll(_ die: Game.DieValue = .random()) {
        let before = model

        do {
            try model.roll(die)
            presenter.present(roll: die, canMove: !possibleMoves.isEmpty, from: before, to: model)
        } catch {
            print(error)
        }
    }

    func move(_ move: (from: Game.Field, to: Game.Field)) {
        let before = model

        do {
            try model.move(field: move.from)

            let hasPlayerFinished = model.finishedPlayers.count > before.finishedPlayers.count
            presenter.present(move: move, hasPlayerFinished: hasPlayerFinished, from: before, to: model)
        } catch {
            print(error)
        }
    }

    // Board topology

    func isTrackField(_ field: Game.Field) -> Bool {
        field.isTrack
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

    func fieldColor(at field: Game.Field) -> Color? {
        guard let owner = field.owner else { return nil }

        return color(for: owner)
    }

    func pieceColor(at field: Game.Field) -> Color? {
        guard let player = presented.piece(at: field) else { return nil }

        return color(for: player)
    }

    private static let playerCorners: [Alignment] = [.bottomLeading, .topLeading, .topTrailing, .bottomTrailing]

    func corner(for player: Game.Player) -> Alignment {
        Self.playerCorners[player.rawValue]
    }

    func rotation(for player: Game.Player) -> Angle {
        .degrees(Double(player.rawValue) * 90)
    }
}
