import Testing
@testable import MADNCore

@Suite("A new game")
struct NewGame {

    @Test("has only the chosen players' pieces, on their out fields")
    func chosenPlayers() throws {
        let game = try Game(players: [.one, .three])

        #expect(Player.one.outFields.allSatisfy { game.player(at: $0) == .one })
        #expect(Player.two.outFields.allSatisfy { game.player(at: $0) == nil })
        #expect(Player.three.outFields.allSatisfy { game.player(at: $0) == .three })
        #expect(Player.four.outFields.allSatisfy { game.player(at: $0) == nil })
    }

    @Test("needs at least 2 players", arguments: [[], [.one]] as [Set<Player>])
    func tooFewPlayers(players: Set<Player>) {
        #expect(throws: GameError.self) {
            _ = try Game(players: players)
        }
    }

    @Test("the starting player must be in the game")
    func startingPlayerNotInGame() {
        #expect(throws: GameError.self) {
            _ = try Game(players: [.one, .two], player: .three)
        }
    }

    @Test("starts with each player's pieces on their out fields", arguments: Player.allCases)
    func initialPieces(player: Player) throws {
        let game = try Game()

        #expect(player.outFields.allSatisfy { game.player(at: $0) == player })
    }

    @Test("the chosen player starts")
    func chosenPlayer() throws {
        let game = try Game(player: .three)

        #expect(game.player == .three)
    }

    @Test("rolling shows a value from 1 to 6")
    func roll() throws {
        var game = try Game()
        try game.roll()

        #expect(try (1...6).contains(#require(game.die).rawValue))
    }
}
