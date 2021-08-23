import Foundation
import RxSwift
import RxCocoa
import Firebase
import FirebaseAuth
import GameKit

final class MainViewModel: AdViewModel {
    
    private var settingInfo: SettingInformation
    private let userDefaults = UserDefaults.standard
    
    lazy var settingSwitchState = BehaviorRelay<SettingInformation>(value: settingInfo)
    let firebaseDidLoad = BehaviorRelay<Bool>(value: false)
    
    init(sceneCoordinator: SceneCoordinatorType, storage: PersistenceStorageType, adStorage: AdStorageType, database: DatabaseManagerType, settings: SettingInformation) {
        self.settingInfo = settings
        super.init(sceneCoordinator: sceneCoordinator, storage: storage, adStorage: adStorage, database: database)
        
        setupAppleGameCenterLogin()
    }
    
    func makeMoveAction(to viewController: ViewControllerType) {
        guard firebaseDidLoad.value else { return }
        
        switch viewController {
        case .giftVC:
            let shopViewModel = ShopViewModel(sceneCoordinator: self.sceneCoordinator, storage: self.storage, adStorage: adStorage, database: database)
            let shopScene = Scene.shop(shopViewModel)
            self.sceneCoordinator.transition(to: shopScene, using: .fullScreen, with: StoryboardType.main, animated: true)
            
        case .rankVC:
            let rankViewModel = RankViewModel(sceneCoordinator: self.sceneCoordinator, storage: self.storage, database: database)
            let rankScene = Scene.rank(rankViewModel)
            self.sceneCoordinator.transition(to: rankScene, using: .fullScreen, with: StoryboardType.main, animated: true)
            
        case .itemVC:
            let itemViewModel = ItemViewModel(sceneCoordinator: self.sceneCoordinator, storage: self.storage, database: database)
            let itemScene = Scene.item(itemViewModel)
            self.sceneCoordinator.transition(to: itemScene, using: .fullScreen, with: StoryboardType.main, animated: true)
            
        case .gameVC:
            let gameUnitManager = GameUnitManager(allKinds: self.storage.itemList())
            let gameViewModel = GameViewModel(sceneCoordinator: self.sceneCoordinator, storage: self.storage, database: database, gameUnitManager: gameUnitManager)
            let gameScene = Scene.game(gameViewModel)
            self.sceneCoordinator.transition(to: gameScene, using: .fullScreen, with: StoryboardType.game, animated: true)
            
        case .settingVC:
            let settingScene = Scene.setting(self)
            self.sceneCoordinator.transition(to: settingScene, using: .overCurrent, with: StoryboardType.main, animated: true)
            
        case .storyVC:
            let storyViewModel = StoryViewModel(sceneCoordinator: sceneCoordinator, storage: storage, adStorage: adStorage, database: database, settings: settingInfo, isFirstTimePlay: false)
            let storyScene = Scene.story(storyViewModel)
            self.sceneCoordinator.transition(to: storyScene, using: .fullScreen, with: StoryboardType.main, animated: true)
            
        case .howToVC:
            let howToViewModel = HowToPlayViewModel(sceneCoordinator: sceneCoordinator, storage: storage, adStorage: adStorage, database: database)
            let howToScene = Scene.howToPlay(howToViewModel)
            self.sceneCoordinator.transition(to: howToScene, using: .fullScreen, with: StoryboardType.main, animated: true)
        }
    }
    
    func makeCloseAction() {
        sceneCoordinator.close(animated: true)
    }
    
    @discardableResult
    func setupBGMState(_ info: SwithType) -> Completable {
        let subject = PublishSubject<Void>()
        settingInfo.changeState(info)
        settingSwitchState.accept(settingInfo)
        
        do {
            try userDefaults.setStruct(settingInfo, forKey: IdentifierUD.setting)
            if info == .bgm { MusicStation.shared.toggle() }
        } catch {
            subject.onError(UserDefaultsError.cannotSaveSettingData)
        }
        return subject.ignoreElements().asCompletable()
    }
}

// MARK: Login & Load Data
extension MainViewModel: GKGameCenterControllerDelegate {
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    }
    
    private func setupAppleGameCenterLogin() {
        GKLocalPlayer.local.authenticateHandler = { [unowned self] _, error in
            
            guard error == nil else {
                self.loadOffline()
                return
            }
            
            guard GKLocalPlayer.local.isAuthenticated else {
                self.loadOnline()
                return
            }
            
            GameCenterAuthProvider.getCredential { credential, error in
                guard error == nil, let credential = credential else {
                    self.loadOnline()
                    return
                }
                
                Auth.auth().signIn(with: credential) { [unowned self] user, error in
                    guard error == nil, user != nil else {
                        self.loadOnline()
                        return
                    }
                    loadOnline()
                }
            }
        }
    }
    
    private func loadOffline() {
        loadFromCoredata()
        sceneCoordinator.transition(to: .alert(AlertMessage.networkLoad),
                                    using: .alert,
                                    with: .main,
                                    animated: true)
    }
    
    private func loadOnline() {
        if !userDefaults.bool(forKey: IdentifierUD.hasLaunchedOnce) {
            storage.setupInitialData()
        }
        loadFromFirebase()
    }
    
    private func loadFromCoredata() {
        switch userDefaults.bool(forKey: IdentifierUD.hasLaunchedOnce) {
        case true:
            storage.getCoreDataInfo()
        case false:
            storage.setupInitialData()
        }
        userDefaults.setValue(true, forKey: IdentifierUD.hasLaunchedOnce)
        firebaseDidLoad.accept(true)
    }
    
    private func loadFromFirebase() {
        if firebaseDidLoad.value { return }
        getUserInformation()
        userDefaults.setValue(true, forKey: IdentifierUD.hasLaunchedOnce)
    }
    
    private func getUserInformation() {
        database.getFirebaseData()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] data in
                self.updateDatabaseInformation(data)
                self.updateAdInformation(data)
            }, onError: { _ in
                self.loadFromCoredata()
            }, onCompleted: { [unowned self] in
                self.firebaseDidLoad.accept(true)
            }).disposed(by: rx.disposeBag)
    }
    
    private func updateDatabaseInformation(_ info: NetworkDTO) {
        let firebaseUpdate = info.date
        let coredataUpdate = storage.lastUpdated()
        
        guard firebaseUpdate > coredataUpdate else {
            loadFromCoredata()
            return
        }
        
        storage.update(units: info.units)
        storage.raiseMoney(by: info.money)
        storage.updateHighScore(new: info.score)
    }
    
    private func updateAdInformation(_ info: NetworkDTO) {
        adStorage.setNewRewardsIfPossible(with: info.ads)
            .subscribe(onError: { error in
                        Firebase.Analytics.logEvent("RewardsError", parameters: ["ErrorMessage": "\(error)"])})
            .disposed(by: rx.disposeBag)
    }
}
