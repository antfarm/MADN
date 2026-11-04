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
}

@Suite("A piece on an out field")
struct OutField {

    let game = try! Game(pieces: ["0A": .one])

    @Test("can only move with a 6", arguments: Game.DieValue.allCases)
    func onlyWithSix(die: Game.DieValue) {
        let game = game.rolled(die)

        #expect(game.movablePieces().contains("0A") == (die == .six))
    }

    @Test("cannot move with a 6 when an own piece is on the start field")
    func startFieldBlocked() {
        let game = game
            .adding(["00": .one])
            .rolled(.six)

        #expect(!game.movablePieces().contains("0A"))
    }
}

@Suite("A piece on a track field")
struct TrackField {

    @Test("continues from the last sector into the first")
    func crossesSectors() throws {
        let game = try Game(pieces: ["38": .two]).rolled(.three)

        #expect(try game.target(from: "38") == "01")
    }

    @Test("enters its own home row after its last track field")
    func entersHomeRow() throws {
        let game = try Game(pieces: ["18": .three]).rolled(.three)

        #expect(try game.target(from: "18") == "2b")
    }
}