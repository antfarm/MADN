import Testing
@testable import MADNCore

@Suite("The turn")
struct Turn {

    @Test("a 6 lets the player roll again, anything else passes the turn", arguments: Game.DieValue.allCases)
    func turnOrder(die: Game.DieValue) throws {
        let state = try Game.State(pieces: ["05": .one], player: .one, die: die)
        let next = try Game.Rules.move(field: "05", in: state)

        #expect(next.player == (die == .six ? .one : .two))
        #expect(next.die == nil)
    }
}

@Suite("A piece on an out field")
struct OutField {

    let game = try! Game(pieces: ["0A": .one])

    @Test("can only move with a 6", arguments: Game.DieValue.allCases)
    func onlyWithSix(die: Game.DieValue) throws {
        let game = game.rolled(die)

        #expect(try game.possibleMoves().contains { $0.from == "0A" } == (die == .six))
    }

    @Test("cannot move with a 6 when an own piece is on the start field")
    func startFieldBlocked() throws {
        let game = try game
            .adding(["00": .one])
            .rolled(.six)

        #expect(try !game.possibleMoves().contains { $0.from == "0A" })
    }
}

@Suite("A piece on a track field")
struct TrackField {

    @Test("moves to its target field")
    func movesToTarget() throws {
        let state = try Game.State(pieces: ["05": .one], player: .one, die: .three)
        let next = try Game.Rules.move(field: "05", in: state)

        #expect(next.board.player(at: "05") == nil)
        #expect(next.board.player(at: "08") == .one)
    }

    @Test("continues from the last sector into the first")
    func crossesSectors() throws {
        let game = try Game(pieces: ["38": .two], player: .two).rolled(.three)

        #expect(try game.possibleMoves().contains { $0.from == "38" && $0.to == "01" })
    }

    @Test("enters its own home row after its last track field")
    func entersHomeRow() throws {
        let game = try Game(pieces: ["18": .three], player: .three).rolled(.three)

        #expect(try game.possibleMoves().contains { $0.from == "18" && $0.to == "2b" })
    }
}

@Suite("Possible moves")
struct PossibleMoves {

    @Test("rejects asking before the die is rolled")
    func notRolled() throws {
        let game = try Game(pieces: ["05": .one])

        #expect(throws: GameError.self) { try game.possibleMoves() }
    }
}
