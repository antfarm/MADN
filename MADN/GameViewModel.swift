import SwiftUI
import MADNCore

@Observable
final class GameViewModel {

    // Game state

    private var model: Game {
        didSet {
            if model.isOver { Game.deleteSaved() }
            else { model.save() }
        }
    }

    var players: Set<Game.Player> { model.players }

    var canRoll: Bool {
        model.actions.contains { action in
            if case .roll = action { true } else { false }
        }
    }

    func canMove(from field: Game.Field) -> Bool {
        model.target(from: field) != nil
    }

    var canResume: Bool {
        model.actions.contains(.resume)
    }

    // Presented state

    private let presenter: Presenter

    var presented: PresentedState { presenter.state }

    var isPresenting: Bool { presenter.isPresenting }

    var shouldDisableInput: Bool { isPresenting }

    var dieRotation: Double { presenter.dieRotation }

    var hasPlayerFinished: Bool { presented.hasPlayerFinished }

    func hasPiece(at field: Game.Field) -> Bool {
        presented.piece(at: field) != nil
    }

    // Initialization

    init(game model: Game = try! Game()) {
        self.model = model
        presenter = Presenter(game: model)
    }

    convenience init(players: Set<Game.Player>, player: Game.Player? = nil) {
        self.init(game: try! Game(players: players, player: player))
    }

    // Game actions

    func roll(_ die: Game.DieValue = .random()) {
        let before = model

        do {
            try model.apply(.roll(die))

            let hasMoves = model.actions.contains { action in
                if case .move = action { true } else { false }
            }

            presenter.present(roll: die, canMove: hasMoves, from: before, to: model)
        } catch {
            print(error)
        }
    }

    func move(from field: Game.Field) {
        let move = (from: field, to: model.target(from: field)!)

        let before = model

        do {
            try model.apply(.move(from: move.from, to: move.to))
            presenter.present(move: move, from: before, to: model)
        } catch {
            print(error)
        }
    }

    func resume() {
        try! model.apply(.resume)
        presenter.present(game: model)
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

    // Player colors

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

    // Die placement

    private static let playerCorners: [Alignment] = [.bottomLeading, .topLeading, .topTrailing, .bottomTrailing]

    func corner(for player: Game.Player) -> Alignment {
        Self.playerCorners[player.rawValue]
    }

    func rotation(for player: Game.Player) -> Angle {
        .degrees(Double(player.rawValue) * 90)
    }
}
