import SwiftUI
import MADNCore

@Observable
final class GameViewModel {

    // definition/construction

    private static let boardMap = """
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

    var cellsPerSide: Int { Self.boardMap.count }

    private static let playerColors = [Color.yellow, .blue, .red, .green]

    func color(for player: Int) -> Color {
        Self.playerColors[player]
    }

    func color(for player: Int?) -> Color? {
        guard let player else { return nil }

        return Self.playerColors[player]
    }

    private static let playerCorners: [Alignment] = [.bottomLeading, .topLeading, .topTrailing, .bottomTrailing]

    func corner(for player: Int) -> Alignment {
        Self.playerCorners[player]
    }

    private static let initialPieces: [Set<String>] = [
        ["0A", "0a", "00", "09"],
        ["1A", "1a", "11", "19"],
        ["2A", "2a", "22", "29"],
        ["3A", "3a", "33", "39"],
    ]

    private var game = try! Game(pieces: initialPieces)

    init() {
        let fields = Self.boardMap.flatMap { $0 }.map { String($0) }.filter { $0 != ".." }

        assert(Set(fields).count == fields.count, "Duplicate fields in board map")
        assert(Set(fields) == Game.allFields, "Board map does not match the game's fields")
    }

    // state

    var player: Int { game.player }

    var die: Int? { game.die }

    func player(at field: String) -> Int? {
        try! game.player(at: field)
    }

    var movablePieces: Set<String> { game.movablePieces() }

    // actions

    func roll() {
        game.roll(.random(in: 1...6))
    }

    func move(field: String) {
        do { try game.move(field: field) } catch { print(error) }
    }

    // board layout

    var trackCells: [(row: Int, column: Int)] { Self.trackCells }

    private static let trackCells: [(row: Int, column: Int)] = {
        func cell(of field: String) -> (row: Int, column: Int)? {
            for (row, columns) in boardMap.enumerated() {
                if let column = columns.firstIndex(of: Substring(field)) { return (row, column) }
            }
            return nil
        }

        return (0..<40)
            .map { String(format: "%02d", $0) } // TODO: ask the model
            .compactMap(cell(of:))
    }()

    func field(row: Int, column: Int) -> String? {
        let field = String(Self.boardMap[row][column])

        return field == ".." ? nil : field
    }

    // board topology

    func isTrackField(_ field: String) -> Bool {
        field.last!.isNumber
    }

    func fieldOwner(of field: String) -> Int? {
        guard !isTrackField(field) || field.last == "0" else { return nil }

        return field.first!.wholeNumberValue
    }
}
