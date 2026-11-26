import Testing
@testable import MADNCore

@Suite("The turn")
struct Turn {

    @Test("moving after a 6 lets the player roll again")
    func moveAfterSix() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["1A"]], player: .one, die: .six)
        let next = try state.moved("05")

        #expect(next.player == .one)
        #expect(next.die == nil)
    }

    @Test("moving advances the turn after anything but a 6", arguments: [.one, .two, .three, .four, .five] as [DieValue])
    func moveAdvancesTurn(die: DieValue) throws {
        let state = try State(pieces: [.one: ["05"], .two: ["1A"]], player: .one, die: die)
        let next = try state.moved("05")

        #expect(next.player == .two)
        #expect(next.die == nil)
    }

    @Test("players are derived from the initial pieces")
    func playersFromPieces() throws {
        let state = try State(pieces: [.one: ["05"], .three: ["15"]], player: .one)

        #expect(state.players == [.one, .three])
    }

    @Test("the turn advances to the next player")
    func advancesToNextPlayer() throws {
        let state = try State(pieces: [.one: ["05"], .three: ["15"]], player: .one)
            .rolled(.one)
            .moved("05")

        #expect(state.player == .three)
    }

    @Test("a single player keeps the turn")
    func singlePlayerKeepsTurn() throws {
        let state = try State(pieces: [.one: ["05"]], player: .one)
            .rolled(.one)
            .moved("05")

        #expect(state.player == .one)
    }

    @Test("a player with all 4 pieces in their home row no longer gets the turn")
    func finishedPlayerGetsNoTurn() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["1a", "1b", "1c", "1d"], .three: ["25"]], player: .one)
            .rolled(.one)
            .moved("05")

        #expect(state.player == .three)
    }

    @Test("a finished player is no longer among the active players")
    func activePlayers() throws {
        let state = try State(pieces: [.one: ["0a", "0b", "0c", "0d"], .two: ["05"]], player: .one)

        #expect(Rules.activePlayers(in: state) == [.two])
    }

    @Test("a player with all 4 pieces in their home row is among the finished players")
    func finishedPlayers() throws {
        let state = try State(pieces: [.one: ["0a", "0b", "0c", "0d"], .two: ["05"]], player: .one)

        #expect(Rules.finishedPlayers(in: state) == [.one])
    }

    @Test("a player who finishes with a 6 does not roll again")
    func finishWithSix() throws {
        let state = try State(pieces: [.one: ["0b", "0c", "0d", "34"], .two: ["15"], .three: ["25"]], player: .one)
            .rolled(.six)
            .moved("34")
            .resumed()

        #expect(state.player == .two)
    }

    @Test("players take turns in clockwise order")
    func clockwise() {
        #expect(Player.allCases.map(\.next) == [.two, .three, .four, .one])
    }

    @Test("passing advances the turn when no move is possible")
    func passWithoutMove() throws {
        let state = try State(pieces: [.one: ["0b"], .two: ["1A"]], player: .one)
            .rolled(.three)

        #expect(state.player == .two)
    }

    @Test("a 6 that cannot be used still lets the player roll again")
    func passAfterSix() throws {
        let state = try State(pieces: [.one: ["0b"], .two: ["1A"]], player: .one)
            .rolled(.six)

        #expect(state.player == .one)
        #expect(state.die == nil)
    }

    @Test("passing lets the player roll again when bringing in is the only possible move")
    func passOnlyBringIn() throws {
        let state = try State(pieces: [.one: ["0A"], .two: ["1A"]], player: .one)
            .rolled(.three)

        #expect(state.player == .one)
        #expect(state.die == nil)
    }

    @Test("passing advances the turn when a piece could move with another roll")
    func passWithBlockedPiece() throws {
        let state = try State(pieces: [.one: ["0A", "39"], .two: ["1A"]], player: .one)
            .rolled(.five)

        #expect(state.player == .two)
    }

    @Test("passing lets the player roll again when home pieces are packed at the end of the home row")
    func passWithPackedHomePiece() throws {
        let state = try State(pieces: [.one: ["0A", "0d"], .two: ["1A"]], player: .one)
            .rolled(.three)

        #expect(state.player == .one)
        #expect(state.die == nil)
    }

    @Test("passing advances the turn when a home piece could move with another roll")
    func passWithBlockedHomePiece() throws {
        let state = try State(pieces: [.one: ["0A", "0a"], .two: ["1A"]], player: .one)
            .rolled(.five)

        #expect(state.player == .two)
    }

    @Test("passing advances the turn after three tries without a 6")
    func passAfterThreeTries() throws {
        let state = try State(pieces: [.one: ["0A"], .two: ["1A"]], player: .one)
            .rolled(.one)
            .rolled(.two)
            .rolled(.three)

        #expect(state.player == .two)
    }
}

@Suite("A piece on an out field")
struct OutField {

    let state = try! State(pieces: [.one: ["0A"]], player: .one)

    @Test("can only move with a 6", arguments: DieValue.allCases)
    func onlyWithSix(die: DieValue) throws {
        let state = try State(pieces: [.one: ["0A"]], player: .one, die: die)

        #expect((state.target(from: "0A") != nil) == (die == .six))
    }

    @Test("cannot move with a 6 when an own piece is on the start field")
    func startFieldBlocked() throws {
        let state = try state
            .adding([.one: ["00"]])
            .rolled(.six)

        #expect(state.target(from: "0A") == nil)
    }

    @Test("must move in with a 6")
    func mustMoveIn() throws {
        let state = try State(pieces: [.one: ["0A", "05"]], player: .one).rolled(.six)

        #expect(Rules.actions(in: state) == [.move(from: "0A", to: "00")])
    }
}

@Suite("A piece on a track field")
struct TrackField {

    @Test("moves to its target field")
    func movesToTarget() throws {
        let state = try State(pieces: [.one: ["05"]], player: .one, die: .three)
        let next = try state.moved("05")

        #expect(next.board.player(at: "05") == nil)
        #expect(next.board.player(at: "08") == .one)
    }

    @Test("continues from the last sector into the first")
    func crossesSectors() throws {
        let state = try State(pieces: [.two: ["38"]], player: .two).rolled(.three)

        #expect(state.target(from: "38") == "01")
    }

    @Test("enters its own home row after its last track field")
    func entersHomeRow() throws {
        let state = try State(pieces: [.three: ["18"]], player: .three).rolled(.three)

        #expect(state.target(from: "18") == "2b")
    }

    @Test("can move to a field occupied by an opponent's piece")
    func targetOpponent() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["08"]], player: .one).rolled(.three)

        #expect(state.target(from: "05") == "08")
    }

    @Test("captures an opponent's piece when landing on it")
    func captures() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["08"]], player: .one)
            .rolled(.three)
            .moved("05")

        #expect(state.board.player(at: "08") == .one)
    }

    @Test("moves to its player's out area when captured")
    func captured() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["08"]], player: .one)
            .rolled(.three)
            .moved("05")

        #expect(Player.two.outFields.contains { state.board.player(at: $0) == .two })
    }

    @Test("cannot move to a field occupied by an own piece")
    func targetOwn() throws {
        let state = try State(pieces: [.one: ["05", "08"]], player: .one).rolled(.three)

        #expect(state.target(from: "05") == nil)
    }

    @Test("cannot move past the end of its home row")
    func pastHomeRow() throws {
        let state = try State(pieces: [.one: ["39"]], player: .one, die: .six)

        #expect(state.target(from: "39") == nil)
    }

    @Test("cannot pass a piece in the home row")
    func passInHomeRow() throws {
        let state = try State(pieces: [.one: ["38", "0a"]], player: .one, die: .five)

        #expect(state.target(from: "38") == nil)
    }

    @Test("must leave its start field while pieces are staged")
    func mustLeaveStart() throws {
        let state = try State(pieces: [.one: ["0A", "00", "05"]], player: .one).rolled(.three)

        #expect(Rules.actions(in: state) == [.move(from: "00", to: "03")])
    }

    @Test("must capture an opponent's piece when possible")
    func mustCapture() throws {
        let state = try State(pieces: [.one: ["05", "15"], .two: ["08"]], player: .one).rolled(.three)

        #expect(Rules.actions(in: state) == [.move(from: "05", to: "08")])
    }
}

@Suite("A piece on a home field")
struct HomeField {

    @Test("moves to its target field")
    func movesToTarget() throws {
        let state = try State(pieces: [.one: ["0a"]], player: .one).rolled(.two)

        #expect(state.target(from: "0a") == "0c")
    }

    @Test("cannot pass a piece in the home row")
    func passInHomeRow() throws {
        let state = try State(pieces: [.one: ["0a", "0b"]], player: .one).rolled(.two)

        #expect(state.target(from: "0a") == nil)
    }
}

@Suite("The end of the game")
struct EndOfGame {

    @Test("the game is over when all players have finished")
    func gameOver() throws {
        let state = try State(pieces: [.one: ["0a", "0b", "0c", "0d"]], player: .one)

        #expect(Rules.isGameOver(in: state))
    }

    @Test("the game goes on while a player has not finished")
    func notOver() throws {
        let state = try State(pieces: [.one: ["0a", "0b", "0c", "05"]], player: .one)

        #expect(!Rules.isGameOver(in: state))
    }

    @Test("rolling after the game is over is rejected")
    func rollAfterGameOver() throws {
        var state = try State(pieces: [.one: ["0a", "0b", "0c", "0d"]], player: .one)

        #expect(throws: GameError.actionNotOffered) {
            try Rules.apply(.roll(.three), to: &state)
        }
    }

    @Test("ending the game leaves no actions")
    func endGame() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one)

        #expect(Rules.actions(in: Rules.end(in: state)).isEmpty)
    }

    @Test("resuming without a finished player is rejected")
    func resumeNotOffered() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one)

        #expect(throws: GameError.notPaused) {
            try Rules.resume(in: state)
        }
    }

    @Test("the finished players are listed in the order they finished")
    func finishingOrder() throws {
        let state = try State(pieces: [.one: ["0b", "0c", "0d", "39"], .two: ["1b", "1c", "1d", "09"], .three: ["25"]], player: .one)
            .rolled(.one)
            .moved("39")
            .resumed()
            .rolled(.one)
            .moved("09")

        #expect(state.finishedPlayers == [.one, .two])
    }
}

@Suite("The actions")
struct Actions {

    @Test("before rolling, the actions are rolling each die value")
    func beforeRoll() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one)

        #expect(Rules.actions(in: state) == DieValue.allCases.map(Game.Action.roll))
    }

    @Test("after rolling, the actions are the possible moves")
    func afterRoll() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one, die: .three)

        #expect(Rules.actions(in: state) == [.move(from: "05", to: "08")])
    }

    @Test("after a player finishes, no actions are offered")
    func afterFinish() throws {
        let state = try State(pieces: [.one: ["0b", "0c", "0d", "34"], .two: ["15"], .three: ["25"]], player: .one)
            .rolled(.six)
            .moved("34")

        #expect(Rules.actions(in: state).isEmpty)
    }

    @Test("when the game is over, there are no actions")
    func gameOver() throws {
        let state = try State(pieces: [.one: ["0a", "0b", "0c", "0d"]], player: .one)

        #expect(Rules.actions(in: state).isEmpty)
    }

    @Test("a movable piece has a target")
    func target() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one, die: .three)

        #expect(state.target(from: "05") == "08")
    }

    @Test("lists no moves for another player's pieces")
    func otherPlayer() throws {
        let state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one).rolled(.three)

        #expect(state.target(from: "15") == nil)
    }

    @Test("a move that is not offered is rejected")
    func moveNotOffered() throws {
        var state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one, die: .three)

        #expect(throws: GameError.actionNotOffered) {
            try Rules.apply(.move(from: "05", to: "09"), to: &state)
        }
    }
}
