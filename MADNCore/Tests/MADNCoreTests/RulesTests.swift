import Testing
@testable import MADNCore

@Suite("A new game")
struct NewGame {

    @Test("has only the chosen players' pieces, on their out fields")
    func chosenPlayers() throws {
        let game = try Game(players: [.one, .three])

        #expect(Game.Player.one.outFields.allSatisfy { game.player(at: $0) == .one })
        #expect(Game.Player.two.outFields.allSatisfy { game.player(at: $0) == nil })
        #expect(Game.Player.three.outFields.allSatisfy { game.player(at: $0) == .three })
        #expect(Game.Player.four.outFields.allSatisfy { game.player(at: $0) == nil })
    }

    @Test("needs at least 2 players", arguments: [[], [.one]] as [Set<Game.Player>])
    func tooFewPlayers(players: Set<Game.Player>) {
        #expect(throws: GameError.self) {
            _ = try Game(players: players)
        }
    }

    @Test("starts with each player's pieces on their out fields", arguments: Game.Player.allCases)
    func initialPieces(player: Game.Player) throws {
        let game = try Game()

        #expect(player.outFields.allSatisfy { game.player(at: $0) == player })
    }
}

@Suite("The turn")
struct Turn {

    @Test("moving after a 6 lets the player roll again")
    func moveAfterSix() throws {
        let state = try Game.State(pieces: [.one: ["05"]], player: .one, die: .six)
        let next = try Game.Rules.move(field: "05", in: state)

        #expect(next.player == .one)
        #expect(next.die == nil)
    }

    @Test("moving advances the turn after anything but a 6", arguments: [.one, .two, .three, .four, .five] as [Game.DieValue])
    func moveAdvancesTurn(die: Game.DieValue) throws {
        let state = try Game.State(pieces: [.one: ["05"]], player: .one, die: die)
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
        let game = try Game(pieces: [.one: ["05"]]).rolled(.three)

        #expect(throws: GameError.self) { try game.passed() }
    }

    @Test("passing advances the turn when no move is possible")
    func passWithoutMove() throws {
        let game = try Game(pieces: [.one: ["0d"]])
            .rolled(.one)
            .passed()

        #expect(game.player == .two)
    }

    @Test("a 6 that cannot be used still lets the player roll again")
    func passAfterSix() throws {
        let game = try Game(pieces: [.one: ["0d"]])
            .rolled(.six)
            .passed()

        #expect(game.player == .one)
        #expect(game.die == nil)
    }

    @Test("passing lets the player roll again when bringing in is the only possible move")
    func passOnlyBringIn() throws {
        let game = try Game(pieces: [.one: ["0A"]])
            .rolled(.three)
            .passed()

        #expect(game.player == .one)
        #expect(game.die == nil)
    }

    @Test("passing advances the turn when a piece could move with another roll")
    func passWithBlockedPiece() throws {
        let game = try Game(pieces: [.one: ["0A", "39"]])
            .rolled(.five)
            .passed()

        #expect(game.player == .two)
    }

    @Test("passing advances the turn after three tries without a 6")
    func passAfterThreeTries() throws {
        let game = try Game(pieces: [.one: ["0A"]])
            .rolled(.one).passed()
            .rolled(.two).passed()
            .rolled(.three).passed()

        #expect(game.player == .two)
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

    let game = try! Game(pieces: [.one: ["0A"]])

    @Test("can only move with a 6", arguments: Game.DieValue.allCases)
    func onlyWithSix(die: Game.DieValue) throws {
        let game = game.rolled(die)

        #expect(try game.possibleMoves().contains { $0.from == "0A" } == (die == .six))
    }

    @Test("cannot move with a 6 when an own piece is on the start field")
    func startFieldBlocked() throws {
        let game = try game
            .adding([.one: ["00"]])
            .rolled(.six)

        #expect(try !game.possibleMoves().contains { $0.from == "0A" })
    }

    @Test("must move in with a 6")
    func mustMoveIn() throws {
        let game = try Game(pieces: [.one: ["0A", "05"]]).rolled(.six)

        #expect(try game.possibleMoves().map(\.from) == ["0A"])
    }
}

@Suite("A piece on a track field")
struct TrackField {

    @Test("moves to its target field")
    func movesToTarget() throws {
        let state = try Game.State(pieces: [.one: ["05"]], player: .one, die: .three)
        let next = try Game.Rules.move(field: "05", in: state)

        #expect(next.board.player(at: "05") == nil)
        #expect(next.board.player(at: "08") == .one)
    }

    @Test("continues from the last sector into the first")
    func crossesSectors() throws {
        let game = try Game(pieces: [.two: ["38"]], player: .two).rolled(.three)

        #expect(try game.possibleMoves().contains { $0.from == "38" && $0.to == "01" })
    }

    @Test("enters its own home row after its last track field")
    func entersHomeRow() throws {
        let game = try Game(pieces: [.three: ["18"]], player: .three).rolled(.three)

        #expect(try game.possibleMoves().contains { $0.from == "18" && $0.to == "2b" })
    }

    @Test("can move to a field occupied by an opponent's piece")
    func targetOpponent() throws {
        let game = try Game(pieces: [.one: ["05"], .two: ["08"]]).rolled(.three)

        #expect(try game.possibleMoves().contains { $0.from == "05" && $0.to == "08" })
    }

    @Test("captures an opponent's piece when landing on it")
    func captures() throws {
        let game = try Game(pieces: [.one: ["05"], .two: ["08"]])
            .rolled(.three)
            .moved("05")

        #expect(game.player(at: "08") == .one)
    }

    @Test("moves to its player's out area when captured")
    func captured() throws {
        let game = try Game(pieces: [.one: ["05"], .two: ["08"]])
            .rolled(.three)
            .moved("05")

        #expect(Game.Player.two.outFields.contains { game.player(at: $0) == .two })
    }

    @Test("cannot move to a field occupied by an own piece")
    func targetOwn() throws {
        let game = try Game(pieces: [.one: ["05", "08"]]).rolled(.three)

        #expect(try !game.possibleMoves().contains { $0.from == "05" })
    }

    @Test("cannot move past the end of its home row")
    func pastHomeRow() throws {
        let game = try Game(pieces: [.one: ["39"]]).rolled(.six)

        #expect(try !game.possibleMoves().contains { $0.from == "39" })
    }

    @Test("cannot pass a piece in the home row")
    func passInHomeRow() throws {
        let game = try Game(pieces: [.one: ["38", "0a"]]).rolled(.five)

        #expect(try !game.possibleMoves().contains { $0.from == "38" })
    }

    @Test("must leave its start field while pieces are staged")
    func mustLeaveStart() throws {
        let game = try Game(pieces: [.one: ["0A", "00", "05"]]).rolled(.three)

        #expect(try game.possibleMoves().map(\.from) == ["00"])
    }

    @Test("must capture an opponent's piece when possible")
    func mustCapture() throws {
        let game = try Game(pieces: [.one: ["05", "15"], .two: ["08"]]).rolled(.three)

        #expect(try game.possibleMoves().map(\.from) == ["05"])
    }
}

@Suite("A piece on a home field")
struct HomeField {

    @Test("moves to its target field")
    func movesToTarget() throws {
        let game = try Game(pieces: [.one: ["0a"]]).rolled(.two)

        #expect(try game.possibleMoves().contains { $0.from == "0a" && $0.to == "0c" })
    }

    @Test("cannot pass a piece in the home row")
    func passInHomeRow() throws {
        let game = try Game(pieces: [.one: ["0a", "0b"]]).rolled(.two)

        #expect(try !game.possibleMoves().contains { $0.from == "0a" })
    }
}

@Suite("Possible moves")
struct PossibleMoves {

    @Test("rejects asking before the die is rolled")
    func notRolled() throws {
        let game = try Game(pieces: [.one: ["05"]])

        #expect(throws: GameError.self) { try game.possibleMoves() }
    }

    @Test("lists no moves for another player's pieces")
    func otherPlayer() throws {
        let game = try Game(pieces: [.one: ["05"], .two: ["15"]]).rolled(.three)

        #expect(try !game.possibleMoves().contains { $0.from == "15" })
    }
}
