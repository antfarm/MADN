import SwiftUI
import MADNCore

@Observable
final class GameViewModel {

    // definition/construction

    private static let boardMap: [[Game.Field?]] = """
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
        .map { $0.split(separator: " ").map { Game.Field(String($0)) } }

    var cellsPerSide: Int { Self.boardMap.count }

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

    private var game: Game

    init(game: Game = try! Game()) {
        self.game = game

        let fields = Self.boardMap.flatMap { $0 }.compactMap { $0 }

        assert(Set(fields).count == fields.count, "Duplicate fields in board map")
        assert(Set(fields) == Set(Game.Field.allCases), "Board map does not match the game's fields")
    }

    // state

    var player: Game.Player { game.player }

    var die: Int? { game.die?.rawValue }

    func player(at field: Game.Field) -> Game.Player? {
        game.player(at: field)
    }

    var movablePieces: Set<Game.Field> {
        guard game.die != nil else { return [] }

        return Set(try! game.possibleMoves().map(\.from))
    }

    // actions

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
        do { try game.move(field: field) } catch { print(error) }
    }

    // board layout

    var trackCells: [(row: Int, column: Int)] { Self.trackCells }

    private static let trackCells: [(row: Int, column: Int)] = {
        func cell(of field: Game.Field) -> (row: Int, column: Int)? {
            for (row, columns) in boardMap.enumerated() {
                if let column = columns.firstIndex(of: field) { return (row, column) }
            }
            return nil
        }

        return Game.Field.trackFields.compactMap(cell(of:))
    }()

    func field(row: Int, column: Int) -> Game.Field? {
        Self.boardMap[row][column]
    }

    // board topology

    func isTrackField(_ field: Game.Field) -> Bool {
        field.isTrack
    }

    func fieldOwner(of field: Game.Field) -> Game.Player? {
        field.owner
    }
}
