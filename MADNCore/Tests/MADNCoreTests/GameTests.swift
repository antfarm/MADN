import Foundation
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
        #expect(throws: GameError.tooFewPlayers) {
            _ = try Game(players: players)
        }
    }

    @Test("the starting player must be in the game")
    func startingPlayerNotInGame() {
        #expect(throws: GameError.startingPlayerNotInGame) {
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

    @Test("without a chosen player, the first player in seating order starts")
    func defaultStartingPlayer() throws {
        let game = try Game(players: [.two, .four])

        #expect(game.player == .two)
    }

    @Test("rolling shows the rolled value")
    func roll() throws {
        var game = try Game(pieces: [.one: ["05"], .two: ["1A"]], player: .one) // any roll can move
        try game.apply(.roll(.three))

        #expect(game.die == .three)
    }
}

@Suite("A serialized game")
struct SerializedGame {

    @Test("keeps its pieces, players and remaining tries")
    func keepsPiecesPlayersAndTries() throws {
        var game = try Game(pieces: [.one: ["05"], .three: ["2A"]], player: .three)
        game.state = game.state.rolled(.three)

        let serializedGame = try JSONEncoder().encode(game)
        let deserializedGame = try JSONDecoder().decode(Game.self, from: serializedGame)

        #expect(Field.allCases.map(deserializedGame.player(at:)) == Field.allCases.map(game.player(at:)))
        #expect(deserializedGame.state.players == [.one, .three])
        #expect(deserializedGame.player == .three)
        #expect(deserializedGame.die == nil)

        let afterThirdTry = deserializedGame.state
            .rolled(.one)
            .rolled(.two)

        #expect(afterThirdTry.player == .one)
    }

    @Test("keeps the rolled die")
    func keepsDie() throws {
        let game = try Game(pieces: [.one: ["05"], .three: ["2A"]], player: .one, die: .six)

        let serializedGame = try JSONEncoder().encode(game)
        let deserializedGame = try JSONDecoder().decode(Game.self, from: serializedGame)

        #expect(deserializedGame.die == .six)
    }
}
