import Testing
@testable import MADNCore

@Suite("The changes")
struct Changes {

    @Test("starting the game changes nothing visible")
    func start() throws {
        var state = try State(players: [.one, .two], player: .one)
        let changes = try Rules.execute(.game(.start), on: &state)

        #expect(changes.isEmpty)
    }

    @Test("a roll that allows a move reports the die")
    func rollWithMove() throws {
        var state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one)
        let changes = try Rules.execute(.player(.roll(.three)), on: &state)

        #expect(changes == [.rolled(.three)])
    }

    @Test("a roll without a move but with tries left reports that the player could not move")
    func rollWithTriesLeft() throws {
        var state = try State(pieces: [.one: ["0A"], .two: ["1A"]], player: .one)
        let changes = try Rules.execute(.player(.roll(.three)), on: &state)

        #expect(changes == [.rolled(.three), .couldNotMove])
    }

    @Test("a 6 without a move reports that the player could not move and keeps the turn")
    func sixWithoutMove() throws {
        var state = try State(pieces: [.one: ["0b"], .two: ["1A"]], player: .one)
        let changes = try Rules.execute(.player(.roll(.six)), on: &state)

        #expect(changes == [.rolled(.six), .couldNotMove])
    }

    @Test("a roll without a move and without tries left reports that the player could not move and passes the turn")
    func rollWithoutMove() throws {
        var state = try State(pieces: [.one: ["0b"], .two: ["1A"]], player: .one)
        let changes = try Rules.execute(.player(.roll(.three)), on: &state)

        #expect(changes == [.rolled(.three), .couldNotMove, .turnPassed(to: .two)])
    }

    @Test("a move reports the move and passes the turn")
    func move() throws {
        var state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one, die: .three)
        let changes = try Rules.execute(.player(.move(from: "05", to: "08")), on: &state)

        #expect(changes == [.moved(from: "05", to: "08"), .turnPassed(to: .two)])
    }

    @Test("a move after a 6 reports the move and keeps the turn")
    func moveAfterSix() throws {
        var state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one, die: .six)
        let changes = try Rules.execute(.player(.move(from: "05", to: "11")), on: &state)

        #expect(changes == [.moved(from: "05", to: "11")])
    }

    @Test("a capturing move reports the capture before the move")
    func capture() throws {
        var state = try State(pieces: [.one: ["05"], .two: ["08"]], player: .one, die: .three)
        let changes = try Rules.execute(.player(.move(from: "05", to: "08")), on: &state)

        #expect(changes == [.captured(at: "08", to: "1A"), .moved(from: "05", to: "08"), .turnPassed(to: .two)])
    }

    @Test("a finishing move reports the finish and pauses the game")
    func finish() throws {
        var state = try State(pieces: [.one: ["0b", "0c", "0d", "34"], .two: ["15"], .three: ["25"]], player: .one, die: .six)
        let changes = try Rules.execute(.player(.move(from: "34", to: "0a")), on: &state)

        #expect(changes == [.moved(from: "34", to: "0a"), .finished(.one), .paused])
    }

    @Test("the last finishing move reports the finish and ends the game")
    func lastFinish() throws {
        var state = try State(pieces: [.one: ["0b", "0c", "0d", "39"]], player: .one, die: .one)
        let changes = try Rules.execute(.player(.move(from: "39", to: "0a")), on: &state)

        #expect(changes == [.moved(from: "39", to: "0a"), .finished(.one), .over])
    }

    @Test("resuming passes the turn")
    func resume() throws {
        var state = try State(pieces: [.one: ["0b", "0c", "0d", "34"], .two: ["15"], .three: ["25"]], player: .one)
            .rolled(.six)
            .moved("34")
        let changes = try Rules.execute(.game(.resume), on: &state)

        #expect(changes == [.turnPassed(to: .two)])
    }

    @Test("ending the game reports that it is over")
    func end() throws {
        var state = try State(pieces: [.one: ["05"], .two: ["15"]], player: .one)
        let changes = try Rules.execute(.game(.end), on: &state)

        #expect(changes == [.over])
    }
}
