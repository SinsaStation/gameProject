import Foundation
import RxSwift
import RxCocoa
import Action

enum GameStatus {
    case new
    case pause
    case resume
}

final class GameViewModel: CommonViewModel {

    private(set) var newGameStatus = BehaviorRelay<GameStatus>(value: .new)
    private var gameUnitManager: GameUnitManagerType
    private var timer: DispatchSourceTimer?
    private(set) var timeProgress = Progress(totalUnitCount: Perspective.startingTime)
    private(set) var currentScore = 0
    private(set) var scoreAdded = BehaviorRelay<Int>(value: 0)
    private(set) var newMemberUnit = BehaviorRelay<StackMemberUnit?>(value: nil)
    private(set) var newDirection = BehaviorRelay<Direction?>(value: nil)
    private(set) var newOnGameUnits = BehaviorRelay<[Unit]?>(value: nil)
    
    private(set) lazy var pauseAction: Action<Void, Void> = Action {
        self.timer?.cancel()
        self.newGameStatus.accept(.pause)
        return self.pause().asObservable().map { _ in }
    }
    
    init(sceneCoordinator: SceneCoordinatorType, storage: ItemStorageType, pauseAction: CocoaAction? = nil, gameUnitManager: GameUnitManagerType, totalTime: Int64 = Perspective.startingTime) {
        self.gameUnitManager = gameUnitManager
        timeProgress.becomeCurrent(withPendingUnitCount: totalTime)
        super.init(sceneCoordinator: sceneCoordinator, storage: storage)
    }
    
    func execute() {
        newGame()
        timerStart()
        
        let newUnits = gameUnitManager.startings()
        newOnGameUnits.accept(newUnits)
    }
    
    private func newGame() {
        gameUnitManager.resetAll()
        sendNewUnitToStack(by: Perspective.startingCount)
        currentScore = .zero
        scoreAdded.accept(0)
        timeProgress.completedUnitCount = Perspective.startingTime
    }
    
    private func sendNewUnitToStack(by count: Int) {
        (0..<count).forEach { _ in
            let newMember = gameUnitManager.newMember()
            newMemberUnit.accept(newMember)
        }
    }
    
    func timerStart() {
        let timeUnit = 1
        timer = DispatchSource.makeTimerSource()
        timer?.schedule(deadline: .now()+1, repeating: .seconds(timeUnit))
        
        timer?.setEventHandler { [weak self] in
            self?.timeMinus(by: timeUnit)
            self?.gameMayOver()
        }
        timer?.activate()
    }
    
    private func timeMinus(by second: Int) {
        timeProgress.completedUnitCount -= Int64(second)
    }
    
    private func gameMayOver() {
        guard timeProgress.completedUnitCount <= 0  else { return }
        
        timer?.cancel()

        DispatchQueue.main.async {
            self.gameOver()
        }
    }
    
    func moveUnitAction(to direction: Direction) {
        guard let currentUnitScore = gameUnitManager.currentHeadUnitScore() else { return }
        let isAnswerCorrect = gameUnitManager.isMoveActionCorrect(to: direction)
        
        isAnswerCorrect ? correctAction(for: direction, currentUnitScore) : wrongAction()
    }
    
    private func correctAction(for direction: Direction, _ scoreGained: Int) {
        newDirection.accept(direction)
        currentScore += scoreGained
        scoreAdded.accept(scoreGained)
        gameUnitManager.raiseAnswerCount()
        
        if gameUnitManager.isTimeToLevelUp() { sendNewUnitToStack(by: 1) }
        
        onGameUnitNeedsChange()
    }
    
    private func onGameUnitNeedsChange() {
        let currentUnits = gameUnitManager.removeAndRefilled()
        newOnGameUnits.accept(currentUnits)
    }
    
    private func wrongAction() {
        timeMinus(by: Perspective.wrongTime)
        gameMayOver()
    }
    
    @discardableResult
    private func gameOver() -> Completable {
        let gameOverViewModel = GameOverViewModel(sceneCoordinator: sceneCoordinator, storage: storage, finalScore: currentScore, newGameStatus: newGameStatus)
        let gameOverScene = Scene.gameOver(gameOverViewModel)
        return self.sceneCoordinator.transition(to: gameOverScene, using: .fullScreen, with: StoryboardType.game, animated: true)
    }
    
    @discardableResult
    private func pause() -> Completable {
        let pauseViewModel = PauseViewModel(sceneCoordinator: sceneCoordinator, storage: storage, currentScore: currentScore, newGameStatus: newGameStatus)
        let pauseScene = Scene.pause(pauseViewModel)
        return self.sceneCoordinator.transition(to: pauseScene, using: .fullScreen, with: StoryboardType.game, animated: false)
    }
}
