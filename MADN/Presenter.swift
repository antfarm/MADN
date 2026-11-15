import SwiftUI
import MADNCore

extension GameViewModel {

    // Decouples model state from presented state: changes to the model happen immediately,
    // while changes to the presented state can be animated and delayed.
    // This way, the model state is always valid when it is serialized, and the
    // presented state does not have to follow the rules of the game.

    struct PresentedState {
        var player: Game.Player
        var die: Int?
        var pieces: [Game.Field: Game.Player]
        var movingPiece: (player: Game.Player, field: Game.Field)?
        var hasPlayerFinished = false

        init(game: Game) {
            player = game.player

            pieces = Game.Field.allCases.reduce(into: [:]) { pieces, field in
                pieces[field] = game.player(at: field)
            }

            die = game.die?.rawValue
        }

        func player(at field: Game.Field) -> Game.Player? {
            if let movingPiece, movingPiece.field == field {
                return movingPiece.player
            }

            return pieces[field]
        }
    }

    @Observable
    final class Presenter {

        typealias Step = (state: PresentedState, duration: Double)

        private(set) var state: PresentedState
        private(set) var isPresenting = false

        init(state: PresentedState) {
            self.state = state
        }

        func present(_ state: PresentedState) {
            self.state = state
        }

        func present(roll die: Game.DieValue, canMove: Bool, from gameBeforeRoll: Game, to gameAfterRoll: Game) {
            var rolled = PresentedState(game: gameBeforeRoll)
            rolled.die = die.rawValue

            let steps: [Step] = if canMove {
                [(state: rolled, duration: 1)]
            }
            else {
                [
                    (state: rolled, duration: 1),
                    (state: rolled, duration: 1.5),
                    (state: PresentedState(game: gameAfterRoll), duration: 0.2),
                ]
            }

            animate(sequence: steps)
        }

        func present(move: (from: Game.Field, to: Game.Field), hasPlayerFinished: Bool, from gameBeforeMove: Game, to gameAfterMove: Game) {
            let player = gameBeforeMove.player

            let fromIndex = player.path.firstIndex(of: move.from)
            let toIndex = player.path.firstIndex(of: move.to)

            func state(withMovingPieceAt target: Game.Field) -> PresentedState {
                var state = PresentedState(game: gameBeforeMove)
                state.pieces[move.from] = nil
                state.movingPiece = (player: player, field: target)
                return state
            }

            let hopSteps = if let fromIndex, let toIndex {
                player.path[(fromIndex + 1)...toIndex].map { target in
                    (state: state(withMovingPieceAt: target), duration: 0.2)
                }
            }
            else {
                [(state: state(withMovingPieceAt: move.to), duration: 0.2)]
            }

            // if this is the player's finishing move, do not advance the turn or change the die

            func stateBeforeAdvancingTurn() -> PresentedState {
                var state = PresentedState(game: gameAfterMove)
                state.player = gameBeforeMove.player
                state.die = gameBeforeMove.die?.rawValue
                state.hasPlayerFinished = true
                return state
            }

            let finalStep = if hasPlayerFinished {
                (state: stateBeforeAdvancingTurn(), duration: 0.2)
            }
            else {
                (state: PresentedState(game: gameAfterMove), duration: 0.2)
            }

            let steps = hopSteps + [finalStep]

            animate(sequence: steps)
        }

        private func animate(sequence steps: [Step]) {
            isPresenting = true

            Task {
                defer { isPresenting = false }

                for step in steps {
                    withAnimation(.linear(duration: step.duration)) { state = step.state }
                    try? await Task.sleep(for: .seconds(step.duration))
                }
            }
        }
    }
}
