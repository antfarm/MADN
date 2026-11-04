import Foundation
import Testing
@testable import MADNCore

@Suite("The board")
struct Board {

    @Test("trackFields lists the fields from 00 to 39, in that order")
    func trackFieldOrder() {
        let labels = (0...39).map { String(format: "%02d", $0) }

        #expect(Game.Field.trackFields.map(\.description) == labels)
    }

    @Test("starts with each player's pieces on their out fields", arguments: Game.Player.allCases)
    func initialPieces(player: Game.Player) throws {
        let board = try Game.Board()
        let outFields = Game.Out.Field.allCases.map { Game.Field.out(player, $0) }

        #expect(board.pieces(for: player) == Set(outFields))
    }

    @Test("rejects a piece on another player's home or out field", arguments: ["1a", "1A"] as [Game.Field])
    func wrongPlayer(field: Game.Field) {
        #expect(throws: GameError.self) {
            _ = try Game.Board(pieces: [field: .one])
        }
    }

    @Test("allows 4 pieces per player")
    func fourPieces() throws {
        let board = try Game.Board(pieces: ["00": .one, "01": .one, "02": .one, "03": .one])

        #expect(board.pieces(for: .one).count == 4)
    }

    @Test("rejects more than 4 pieces per player")
    func fivePieces() {
        #expect(throws: GameError.self) {
            _ = try Game.Board(pieces: ["00": .one, "01": .one, "02": .one, "03": .one, "04": .one])
        }
    }

    @Test("adds a piece to an empty field")
    func addPiece() throws {
        var board = try Game.Board(pieces: ["05": .one])

        try board.add(pieceFor: .two, at: "06")

        #expect(board.player(at: "06") == .two)
    }

    @Test("rejects adding a piece to an occupied field")
    func occupiedField() {
        #expect(throws: GameError.self) {
            var board = try Game.Board(pieces: ["05": .one])

            try board.add(pieceFor: .two, at: "05")
        }
    }

    @Test("stays unchanged when adding a piece fails")
    func failedAdd() throws {
        var board = try Game.Board(pieces: ["05": .one])

        try? board.add(pieceFor: .two, at: "05")

        #expect(board.player(at: "05") == .one)
    }

    @Test("every field survives converting to a label and back", arguments: Game.Field.allCases)
    func labelRoundTrip(field: Game.Field) {
        #expect(Game.Field(field.description) == field)
    }

    @Test("rejects invalid labels", arguments: ["", "0", "000", "40", "4A", "0e", "0E", "xx"])
    func invalidLabel(label: String) {
        #expect(Game.Field(label) == nil)
    }

    @Test("a track field only has an owner if it's a start field")
    func trackFieldOwner() {
        #expect(("10" as Game.Field).owner == .two)
        #expect(("11" as Game.Field).owner == nil)
    }

    @Test("a player's path has 44 steps, from the start field to the end of the home row")
    func path() {
        #expect(Game.Player.two.startField == "10")
        #expect(Game.Player.two.field(stepsTravelled: 43) == "1d")
        #expect(Game.Player.two.field(stepsTravelled: 44) == nil)
    }
}
