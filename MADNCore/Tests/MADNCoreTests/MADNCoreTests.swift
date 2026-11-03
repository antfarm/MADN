import Testing
@testable import MADNCore

@Suite("A piece on an out field")
struct OutField {

    let game = try! Game(pieces: [["0A"], [], [], []])

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