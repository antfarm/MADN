import Testing
@testable import MADNCore

@Suite("The turn")
struct Turn {

    @Test("moving after a 6 lets the player roll again")
    func moveAfterSix() throws {
        let state = try State(pieces: [.one: ["05"]], player: .one, die: .six)
        let next = try Rules.move(field: "05", in: state)

        #expect(next.player == .one)
        #expect(next.die == nil)
    }

    @Test("moving advances the turn after anything but a 6", arguments: [.one, .two, .three, .four, .five] as [DieValue])
    func moveAdvancesTurn(die: DieValue) throws {
        let state = try State(pieces: [.one: ["05"], .two: []], player: .one, die: die)
        let next = try Rules.move(field: "05", in: state)

        #expect(next.player == .two)
        #expect(next.die == nil)
    }

    @Test("players are derived from the initial pieces")
    func playersFromPieces() throws {
        let state = try State(pieces: [.one: ["05"], .three: ["15"]])

        #expect(state.players == [.one, .three])
    }

    @Test("the turn advances to the next player")
    func advancesToNextPlayer() throws {
        let state = try State(pieces: [.one: ["05"], .three: ["15"]])
            .rolled(.one)
            .moved("05")

        #expect(state.player == .three)
    }

    @Test("a single player keeps the turn")
    func singlePlayerKeepsTurn() throws {
        let state = try State(pieces: [.one: ["05"]])
            .rolled(.one)
            .moved("05")

        #expect(state.player == .one)
    }

    @Test("a player with all 4 pieces in their home row no longer gets the turn")
    func finishedPlayerGetsNoTurn() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["1a", "1b", "1c", "1d"], .three: ["25"]])
            .rolled(.one)
            .moved("05")

        #expect(state.player == .three)
    }

    @Test("a finished player is no longer among the active players")
    func activePlayers() throws {
        let state = try State(pieces: [.one: ["0a", "0b", "0c", "0d"], .two: ["05"]])

        #expect(Rules.activePlayers(in: state) == [.two])
    }

    @Test("a player who finishes with a 6 does not roll again")
    func finishWithSix() throws {
        let state = try State(pieces: [.one: ["0b", "0c", "0d", "34"], .two: ["15"], .three: ["25"]])
            .rolled(.six)
            .moved("34")

        #expect(state.player == .two)
    }

    @Test("players take turns in clockwise order")
    func clockwise() {
        #expect(Player.allCases.map(\.next) == [.two, .three, .four, .one])
    }

    @Test("cannot pass while a move is possible")
    func noPassWithMove() throws {
        let state = try State(pieces: [.one: ["05"]]).rolled(.three)

        #expect(throws: GameError.self) { try state.passed() }
    }

    @Test("passing advances the turn when no move is possible")
    func passWithoutMove() throws {
        let state = try State(pieces: [.one: ["0d"], .two: []])
            .rolled(.one)
            .passed()

        #expect(state.player == .two)
    }

    @Test("a 6 that cannot be used still lets the player roll again")
    func passAfterSix() throws {
        let state = try State(pieces: [.one: ["0d"]])
            .rolled(.six)
            .passed()

        #expect(state.player == .one)
        #expect(state.die == nil)
    }

    @Test("passing lets the player roll again when bringing in is the only possible move")
    func passOnlyBringIn() throws {
        let state = try State(pieces: [.one: ["0A"]])
            .rolled(.three)
            .passed()

        #expect(state.player == .one)
        #expect(state.die == nil)
    }

    @Test("passing advances the turn when a piece could move with another roll")
    func passWithBlockedPiece() throws {
        let state = try State(pieces: [.one: ["0A", "39"], .two: []])
            .rolled(.five)
            .passed()

        #expect(state.player == .two)
    }

    @Test("passing advances the turn after three tries without a 6")
    func passAfterThreeTries() throws {
        let state = try State(pieces: [.one: ["0A"], .two: []])
            .rolled(.one).passed()
            .rolled(.two).passed()
            .rolled(.three).passed()

        #expect(state.player == .two)
    }
}

@Suite("A piece on an out field")
struct OutField {

    let state = try! State(pieces: [.one: ["0A"]])

    @Test("can only move with a 6", arguments: DieValue.allCases)
    func onlyWithSix(die: DieValue) throws {
        let state = state.rolled(die)

        #expect(try Rules.possibleMoves(in: state).contains { $0.from == "0A" } == (die == .six))
    }

    @Test("cannot move with a 6 when an own piece is on the start field")
    func startFieldBlocked() throws {
        let state = try state
            .adding([.one: ["00"]])
            .rolled(.six)

        #expect(try !Rules.possibleMoves(in: state).contains { $0.from == "0A" })
    }

    @Test("must move in with a 6")
    func mustMoveIn() throws {
        let state = try State(pieces: [.one: ["0A", "05"]]).rolled(.six)

        #expect(try Rules.possibleMoves(in: state).map(\.from) == ["0A"])
    }
}

@Suite("A piece on a track field")
struct TrackField {

    @Test("moves to its target field")
    func movesToTarget() throws {
        let state = try State(pieces: [.one: ["05"]], player: .one, die: .three)
        let next = try Rules.move(field: "05", in: state)

        #expect(next.board.player(at: "05") == nil)
        #expect(next.board.player(at: "08") == .one)
    }

    @Test("continues from the last sector into the first")
    func crossesSectors() throws {
        let state = try State(pieces: [.two: ["38"]], player: .two).rolled(.three)

        #expect(try Rules.possibleMoves(in: state).contains { $0.from == "38" && $0.to == "01" })
    }

    @Test("enters its own home row after its last track field")
    func entersHomeRow() throws {
        let state = try State(pieces: [.three: ["18"]], player: .three).rolled(.three)

        #expect(try Rules.possibleMoves(in: state).contains { $0.from == "18" && $0.to == "2b" })
    }

    @Test("can move to a field occupied by an opponent's piece")
    func targetOpponent() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["08"]]).rolled(.three)

        #expect(try Rules.possibleMoves(in: state).contains { $0.from == "05" && $0.to == "08" })
    }

    @Test("captures an opponent's piece when landing on it")
    func captures() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["08"]])
            .rolled(.three)
            .moved("05")

        #expect(state.board.player(at: "08") == .one)
    }

    @Test("moves to its player's out area when captured")
    func captured() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["08"]])
            .rolled(.three)
            .moved("05")

        #expect(Player.two.outFields.contains { state.board.player(at: $0) == .two })
    }

    @Test("cannot move to a field occupied by an own piece")
    func targetOwn() throws {
        let state = try State(pieces: [.one: ["05", "08"]]).rolled(.three)

        #expect(try !Rules.possibleMoves(in: state).contains { $0.from == "05" })
    }

    @Test("cannot move past the end of its home row")
    func pastHomeRow() throws {
        let state = try State(pieces: [.one: ["39"]]).rolled(.six)

        #expect(try !Rules.possibleMoves(in: state).contains { $0.from == "39" })
    }

    @Test("cannot pass a piece in the home row")
    func passInHomeRow() throws {
        let state = try State(pieces: [.one: ["38", "0a"]]).rolled(.five)

        #expect(try !Rules.possibleMoves(in: state).contains { $0.from == "38" })
    }

    @Test("must leave its start field while pieces are staged")
    func mustLeaveStart() throws {
        let state = try State(pieces: [.one: ["0A", "00", "05"]]).rolled(.three)

        #expect(try Rules.possibleMoves(in: state).map(\.from) == ["00"])
    }

    @Test("must capture an opponent's piece when possible")
    func mustCapture() throws {
        let state = try State(pieces: [.one: ["05", "15"], .two: ["08"]]).rolled(.three)

        #expect(try Rules.possibleMoves(in: state).map(\.from) == ["05"])
    }
}

@Suite("A piece on a home field")
struct HomeField {

    @Test("moves to its target field")
    func movesToTarget() throws {
        let state = try State(pieces: [.one: ["0a"]]).rolled(.two)

        #expect(try Rules.possibleMoves(in: state).contains { $0.from == "0a" && $0.to == "0c" })
    }

    @Test("cannot pass a piece in the home row")
    func passInHomeRow() throws {
        let state = try State(pieces: [.one: ["0a", "0b"]]).rolled(.two)

        #expect(try !Rules.possibleMoves(in: state).contains { $0.from == "0a" })
    }
}

@Suite("Possible moves")
struct PossibleMoves {

    @Test("rejects asking before the die is rolled")
    func notRolled() throws {
        let state = try State(pieces: [.one: ["05"]])

        #expect(throws: GameError.self) { try Rules.possibleMoves(in: state) }
    }

    @Test("lists no moves for another player's pieces")
    func otherPlayer() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["15"]]).rolled(.three)

        #expect(try !Rules.possibleMoves(in: state).contains { $0.from == "15" })
    }
}
