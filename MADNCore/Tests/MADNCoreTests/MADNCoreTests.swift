import Testing
@testable import MADNCore

@Suite("A piece on an out field")
struct OutField {

    let game = try! Game(pieces: ["0A": .one])

    @Test("can only move with a 6", arguments: 1...6)
    func onlyWithSix(die: Int) {
        let game = game.rolled(die)

        #expect(game.movablePieces().contains("0A") == (die == 6))
    }

    @Test("cannot move with a 6 when an own piece is on the start field")
    func startFieldBlocked() {
        let game = game
            .adding(["00": .one])
            .rolled(6)

        #expect(!game.movablePieces().contains("0A"))
    }
}

@Suite("A piece on a track field")
struct TrackField {

    @Test("enters its own home row after its last track field")
    func entersHomeRow() throws {
        let game = try Game(pieces: ["18": .three]).rolled(3)

        #expect(try game.target(from: "18") == "2b")
    }
}