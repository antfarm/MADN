import Foundation
import Testing
@testable import MADNCore

@Suite("A new board")
struct NewBoard {

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
}

@Suite("Adding a piece")
struct AddingPiece {

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
}

@Suite("Moving a piece")
struct MovingPiece {

    @Test("moves a piece to an empty field")
    func movePiece() throws {
        var board = try Game.Board(pieces: ["05": .one])

        try board.move(from: "05", to: "08")

        #expect(board.player(at: "05") == nil)
        #expect(board.player(at: "08") == .one)
    }

    @Test("rejects moving from an empty field")
    func emptyField() {
        #expect(throws: GameError.self) {
            var board = try Game.Board(pieces: ["05": .one])

            try board.move(from: "06", to: "08")
        }
    }

    @Test("rejects moving to an occupied field")
    func occupiedField() {
        #expect(throws: GameError.self) {
            var board = try Game.Board(pieces: ["05": .one, "08": .two])

            try board.move(from: "05", to: "08")
        }
    }
}

@Suite("The fields")
struct Fields {

    @Test("trackFields lists the fields from 00 to 39, in that order")
    func trackFieldOrder() {
        let labels = (0...39).map { String(format: "%02d", $0) }

        #expect(Game.Field.trackFields.map(\.description) == labels)
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

    @Test("the start fields are 10 fields apart")
    func startFields() {
        #expect(Game.Player.allCases.map(\.startField) == ["00", "10", "20", "30"])
    }

    @Test("there are 72 fields, without duplicates")
    func allFields() {
        #expect(Game.Field.allCases.count == 72)
        #expect(Set(Game.Field.allCases).count == 72)
    }

    @Test("home and out fields are owned by their player", arguments: ["1a", "1A"] as [Game.Field])
    func homeAndOutFieldOwner(field: Game.Field) {
        #expect(field.owner == .two)
    }
}

@Suite("A player's path")
struct Path {

    @Test("has 44 steps, from the start field to the end of the home row")
    func path() {
        #expect(Game.Player.two.startField == "10")
        #expect(Game.Player.two.field(stepsTravelled: 43) == "1d")
        #expect(Game.Player.two.field(stepsTravelled: 44) == nil)
    }

    @Test("does not contain another player's home row")
    func fieldNotOnPath() {
        #expect(throws: GameError.self) {
            _ = try Game.Player.one.stepsTravelled(to: "1a")
        }
    }

    @Test("has no field before its start")
    func negativeSteps() {
        #expect(Game.Player.two.field(stepsTravelled: -1) == nil)
    }
}
