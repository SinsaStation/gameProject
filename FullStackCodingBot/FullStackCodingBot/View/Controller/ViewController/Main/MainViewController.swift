import UIKit
import GhostTypewriter
import GameKit

final class MainViewController: UIViewController, ViewModelBindableType {
    
    var viewModel: MainViewModel!
    @IBOutlet var buttonController: MainButtonController!
    @IBOutlet weak var titleLabel: TypewriterLabel!
    @IBOutlet weak var skyView: SkyView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleLabel.restartTypewritingAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        skyView.startCloudAnimation()
    }

    
    func bindViewModel() {
        buttonController.setupButton()
        buttonController.bind { [unowned self] viewController in
            self.viewModel.makeMoveAction(to: viewController)
        }
    }
}

private extension MainViewController {
    
    private func setup() {
        setupAppleGameCenterLogin()
        setupTitleLabel()
        titleLabel.startTypewritingAnimation()
    }
    
    
    private func setupTitleLabel() {
        titleLabel.font = .systemFont(ofSize: view.bounds.width * 0.04)
        titleLabel.text = Text.title
    }
    
    private func setupAppleGameCenterLogin() {
        GKLocalPlayer.local.authenticateHandler = { gcViewController , error in
            if GKLocalPlayer.local.isAuthenticated {
                print("FireBase")
            }
        }
    }
}

extension MainViewController: GKGameCenterControllerDelegate {
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        print("GCVC DID FINISHED")
    }
}
