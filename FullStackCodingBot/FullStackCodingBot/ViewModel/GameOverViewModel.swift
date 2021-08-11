import Foundation
import RxSwift
import RxCocoa
import GameKit

final class GameOverViewModel: CommonViewModel {
    
    private(set) var newScript = BehaviorRelay<Script?>(value: nil)
    private let scoreInfo = BehaviorRelay<Int>(value: 0)
    private let moneyInfo = BehaviorRelay<Int>(value: 0)
    private(set) var highScoreStatus = BehaviorRelay<Bool>(value: false)
    private var newGameStatus: BehaviorRelay<GameStatus>
    
    lazy var finalScore: Driver<String> = {
        return scoreInfo.map { String($0) }.asDriver(onErrorJustReturn: "")
    }()
    
    lazy var gainedMoney: Driver<String> = {
        return moneyInfo.map { String($0) }.asDriver(onErrorJustReturn: "")
    }()
    
    lazy var currentMoney: Driver<String> = {
        return storage.availableMoeny().map { String($0) }.asDriver(onErrorJustReturn: "")
    }()
    
    init(sceneCoordinator: SceneCoordinatorType, storage: PersistenceStorageType, database: DatabaseManagerType, finalScore: Int, newGameStatus: BehaviorRelay<GameStatus>) {
        self.scoreInfo.accept(finalScore)
        self.moneyInfo.accept(finalScore/10)
        self.newGameStatus = newGameStatus
        super.init(sceneCoordinator: sceneCoordinator, storage: storage, database: database)
    }
    
    func execute() {
        storeReward()
        updateHighScore()
        storeHightScoreToGameCenter()
        sendScript()
        MusicStation.shared.stop()
    }
    
    private func storeReward() {
        storage.raiseMoney(by: moneyInfo.value)
    }
    
    private func updateHighScore() {
        let newScore = scoreInfo.value
        let isHighScore = storage.updateHighScore(new: newScore)
        highScoreStatus.accept(isHighScore)
    }
    
    private func storeHightScoreToGameCenter() {
        let bestScore = GKScore(leaderboardIdentifier: IdentifierGC.leaderboard)
        bestScore.value = Int64(storage.myHighScore())
        
        GKScore.report([bestScore]) { error in
            if let error = error {
                print(error)
            } else {
            }
        }
    }
    
    private func sendScript() {
        let script = Script(speaker: .ceo, line: Line(text: "쯧쯔 겨우 이건가?\n실망이군.", emotion: .notGood))
        newScript.accept(script)
    }
    
    func makeMoveAction(to viewController: GameOverViewControllerType) {
        switch viewController {
        case .gameVC:
            newGameStatus.accept(.ready)
            sceneCoordinator.close(animated: true)
        case .mainVC:
            sceneCoordinator.toMain(animated: true)
            MusicStation.shared.play(type: .main)
        }
    }
}
