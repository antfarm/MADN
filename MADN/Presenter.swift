import SwiftUI
import MADNCore

extension GameViewModel {

    // Decouples model state from presented state: changes to the model happen immediately,
    // while changes to the presented state can be animated and delayed.
    // This way, the model state is always valid when it is serialized, and the
    // presented state does not have to follow the rules of the game.

    struct PresentedState {
        private(set) var player: Game.Player
        private(set) var die: Int?
        private var pieces: [Game.Field: Game.Player]
        private(set) var hasPlayerFinished = false

        init(game: Game) {
            player = game.player
            die = game.die?.rawValue

            pieces = Dictionary(uniqueKeysWithValues: Game.Field.allCases.compactMap { field in
                guard let player = game.player(at: field) else { return nil }
                return (field, player)
            })
        }

        func piece(at field: Game.Field) -> Game.Player? {
            pieces[field]
        }

        func withDie(_ die: Game.DieValue?) -> PresentedState {
            var state = self
            state.die = die?.rawValue
            return state
        }

        func withPieceRemoved(at field: Game.Field) -> PresentedState {
            var state = self
            state.pieces[field] = nil
            return state
        }

        func withPieceReplaced(at field: Game.Field, by player: Game.Player) -> PresentedState {
            var state = self
            state.pieces[field] = player
            return state
        }

        func withPlayer(_ player: Game.Player, finished: Bool = false) -> PresentedState {
            var state = self
            state.player = player
            state.hasPlayerFinished = finished
            return state
        }
    }

    @Observable
    final class Presenter {

        typealias Frame = (state: PresentedState, duration: Double)

        private(set) var state: PresentedState
        private(set) var isPresenting = false

        init(game: Game) {
            state = PresentedState(game: game)
        }

        func present(game: Game) {
            state = PresentedState(game: game)
        }

        func present(roll die: Game.DieValue, canMove: Bool, from gameBefore: Game, to gameAfter: Game) {
            let stateAfterRolling = PresentedState(game: gameBefore)
                .withDie(die)

            let frames: [Frame] = if canMove {
                [(state: stateAfterRolling, duration: 1)]
            }
            else {
                [
                    (state: stateAfterRolling, duration: 1),
                    (state: stateAfterRolling, duration: 1),
                    (state: PresentedState(game: gameAfter), duration: 0.2),
                ]
            }

            animate(sequence: frames)
        }

        func present(move: (from: Game.Field, to: Game.Field), hasPlayerFinished: Bool, from gameBefore: Game, to gameAfter: Game) {
            let path = gameBefore.player.path

            let fromIndex = path.firstIndex(of: move.from)
            let toIndex = path.firstIndex(of: move.to)

            func stateAfterStepping(to nextField: Game.Field) -> PresentedState {
                PresentedState(game: gameBefore)
                    .withPieceRemoved(at: move.from)
                    .withPieceReplaced(at: nextField, by: gameBefore.player)
            }

            let statesAfterStepping = if let fromIndex, let toIndex {
                path[(fromIndex + 1)...toIndex].map { nextField in
                    stateAfterStepping(to: nextField)
                }
            }
            else {
                [stateAfterStepping(to: move.to)]
            }

            let stepFrames = statesAfterStepping.map { state in
                (state: state, duration: 0.2)
            }

            // if this is the player's finishing move, do not advance the turn or change the die

            func stateBeforeAdvancingTurn() -> PresentedState {
                PresentedState(game: gameAfter)
                    .withPlayer(gameBefore.player, finished: true)
                    .withDie(gameBefore.die)
            }

            let finalFrame = if hasPlayerFinished {
                (state: stateBeforeAdvancingTurn(), duration: 0.2)
            }
            else {
                (state: PresentedState(game: gameAfter), duration: 0.2)
            }

            let frames = stepFrames + [finalFrame]

            animate(sequence: frames)
        }

        private func animate(sequence frames: [Frame]) {
            isPresenting = true

            Task {
                defer { isPresenting = false }

                for frame in frames {
                    withAnimation(.linear(duration: frame.duration)) { state = frame.state }
                    try? await Task.sleep(for: .seconds(frame.duration))
                }
            }
        }
    }
}
