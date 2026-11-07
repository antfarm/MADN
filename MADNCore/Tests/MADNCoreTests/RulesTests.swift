import Testing
@testable import MADNCore

@Suite("The turn")
struct Turn {

    @Test("moving after a 6 lets the player roll again")
    func moveAfterSix() throws {
        let state = try Game.State(pieces: ["05": .one], player: .one, die: .six)
        let next = try Game.Rules.move(field: "05", in: state)

        #expect(next.player == .one)
        #expect(next.die == nil)
    }

    @Test("moving advances the turn after anything but a 6", arguments: [.one, .two, .three, .four, .five] as [Game.DieValue])
    func moveAdvancesTurn(die: Game.DieValue) throws {
        let state = try Game.State(pieces: ["05": .one], player: .one, die: die)
        let next = try Game.Rules.move(field: "05", in: state)

        #expect(next.player == .two)
        #expect(next.die == nil)
    }

    @Test("the chosen player starts")
    func chosenPlayer() throws {
        let game = try Game(player: .three)

        #expect(game.player == .three)
    }

    @Test("players take turns in clockwise order")
    func clockwise() {
        #expect(Game.Player.allCases.map(\.next) == [.two, .three, .four, .one])
    }

    @Test("cannot pass while a move is possible")
    func noPassWithMove() throws {
        let game = try Game(pieces: ["05": .one]).rolled(.three)

        #expect(throws: GameError.self) { try game.passed() }
    }

    @Test("passing advances the turn when no move is possible")
    func passWithoutMove() throws {
        let game = try Game(pieces: ["0d": .one])
            .rolled(.one)
            .passed()

        #expect(game.player == .two)
    }

    @Test("a 6 that cannot be used still lets the player roll again")
    func passAfterSix() throws {
        let game = try Game(pieces: ["0d": .one])
            .rolled(.six)
            .passed()

        #expect(game.player == .one)
        #expect(game.die == nil)
    }

    @Test("rolling shows a value from 1 to 6")
    func roll() throws {
        var game = try Game()
        try game.roll()

        #expect(try (1...6).contains(#require(game.die).rawValue))
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

    @Test("must move in with a 6")
    func mustMoveIn() throws {
        let game = try Game(pieces: ["0A": .one, "05": .one]).rolled(.six)

        #expect(try game.possibleMoves().map(\.from) == ["0A"])
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

    @Test("can move to a field occupied by an opponent's piece")
    func targetOpponent() throws {
        let game = try Game(pieces: ["05": .one, "08": .two]).rolled(.three)

        #expect(try game.possibleMoves().contains { $0.from == "05" && $0.to == "08" })
    }

    @Test("captures an opponent's piece when landing on it")
    func captures() throws {
        let game = try Game(pieces: ["05": .one, "08": .two])
            .rolled(.three)
            .moved("05")

        #expect(game.player(at: "08") == .one)
    }

    @Test("moves to its player's out area when captured")
    func captured() throws {
        let game = try Game(pieces: ["05": .one, "08": .two])
            .rolled(.three)
            .moved("05")

        #expect(Game.Player.two.outFields.contains { game.player(at: $0) == .two })
    }

    @Test("cannot move to a field occupied by an own piece")
    func targetOwn() throws {
        let game = try Game(pieces: ["05": .one, "08": .one]).rolled(.three)

        #expect(try !game.possibleMoves().contains { $0.from == "05" })
    }

    @Test("cannot move past the end of its home row")
    func pastHomeRow() throws {
        let game = try Game(pieces: ["39": .one]).rolled(.six)

        #expect(try !game.possibleMoves().contains { $0.from == "39" })
    }

    @Test("cannot pass a piece in the home row")
    func passInHomeRow() throws {
        let game = try Game(pieces: ["38": .one, "0a": .one]).rolled(.five)

        #expect(try !game.possibleMoves().contains { $0.from == "38" })
    }
}

@Suite("A piece on a home field")
struct HomeField {

    @Test("moves to its target field")
    func movesToTarget() throws {
        let game = try Game(pieces: ["0a": .one]).rolled(.two)

        #expect(try game.possibleMoves().contains { $0.from == "0a" && $0.to == "0c" })
    }

    @Test("cannot pass a piece in the home row")
    func passInHomeRow() throws {
        let game = try Game(pieces: ["0a": .one, "0b": .one]).rolled(.two)

        #expect(try !game.possibleMoves().contains { $0.from == "0a" })
    }
}

@Suite("Possible moves")
struct PossibleMoves {

    @Test("rejects asking before the die is rolled")
    func notRolled() throws {
        let game = try Game(pieces: ["05": .one])

        #expect(throws: GameError.self) { try game.possibleMoves() }
    }

    @Test("lists no moves for another player's pieces")
    func otherPlayer() throws {
        let game = try Game(pieces: ["05": .one, "15": .two]).rolled(.three)

        #expect(try !game.possibleMoves().contains { $0.from == "15" })
    }
}
