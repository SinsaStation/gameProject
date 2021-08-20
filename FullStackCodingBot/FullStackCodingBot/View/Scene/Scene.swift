import UIKit
import GameKit
import Firebase

enum Scene {
    case main(MainViewModel)
    case setting(MainViewModel)
    case howToPlay(HowToPlayViewModel)
    case story(StoryViewModel)
    case shop(ShopViewModel)
    case rank(RankViewModel)
    case item(ItemViewModel)
    case game(GameViewModel)
    case pause(PauseViewModel)
    case gameOver(GameOverViewModel)
    case alert(AlertMessage)
}

extension Scene {
    
    // swiftlint:disable:next cyclomatic_complexity
    func instantiate(from identifier: String) -> UIViewController {
        let storyboard = UIStoryboard(name: identifier, bundle: nil)
        switch self {
        
        case .main(let viewModel):
            guard var mainVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.main) as? MainViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            mainVC.bind(viewModel: viewModel)
            return mainVC
            
        case .shop(let viewModel):
            guard var shopVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.shop) as? ShopViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            shopVC.bind(viewModel: viewModel)
            return shopVC
            
        case .rank(let viewModel):
            guard var rankVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.rank) as? RankViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            rankVC.gameCenterDelegate = viewModel
            rankVC.leaderboardIdentifier = IdentifierGC.leaderboard
            rankVC.viewState = .leaderboards
            rankVC.bind(viewModel: viewModel)
            return rankVC
            
        case .item(let viewModel):
            guard var itemVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.item) as? ItemViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            itemVC.bind(viewModel: viewModel)
            return itemVC
            
        case .game(let viewModel):
            guard var gameVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.game) as? GameViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            gameVC.bind(viewModel: viewModel)
            return gameVC
            
        case .pause(let viewModel):
            guard var pauseVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.pause) as? PauseViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            pauseVC.bind(viewModel: viewModel)
            return pauseVC
            
        case .gameOver(let viewModel):
            guard var gameOverVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.gameOver) as? GameOverViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            gameOverVC.bind(viewModel: viewModel)
            return gameOverVC
            
        case .alert(let message):
            let alerMessage = message.content.message
            let alertScene = UIAlertController(title: alerMessage.title, message: alerMessage.content, preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: message.content.confirm, style: .cancel)
            alertScene.addAction(confirmAction)
            return alertScene
            
        case .setting(let viewModel):
            guard var settingVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.setting) as? SettingViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            settingVC.bind(viewModel: viewModel)
            return settingVC
            
        case .story(let viewModel):
            guard var storyVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.story) as? StoryViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            storyVC.bind(viewModel: viewModel)
            return storyVC
            
        case .howToPlay(let viewModel):
            guard var howToVC = storyboard.instantiateViewController(withIdentifier: IdentifierVC.howTo) as? HowToPlayViewController else {
                Firebase.Analytics.logEvent("ViewControllerError", parameters: nil)
                fatalError()
            }
            howToVC.bind(viewModel: viewModel)
            return howToVC
        }
    }
}
