import UIKit
import RxSwift
import RxCocoa
import GhostTypewriter
import GoogleMobileAds

final class ShopViewController: UIViewController, ViewModelBindableType {
    
    var viewModel: ShopViewModel!
    
    @IBOutlet weak var backgroundView: ReplicateAnimationView!
    @IBOutlet weak var totalCoinLabel: UILabel!
    @IBOutlet weak var rewardInfoLabel: TypewriterLabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var shopCollectionView: UICollectionView!
    
    private lazy var itemWidth = shopCollectionView.frame.width * 0.3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backgroundView.draw(withImage: .paused, countPerLine: 3.2)
    }
    
    func bindViewModel() {
        viewModel.itemStorage
            .drive(shopCollectionView.rx.items(cellIdentifier: ShopCell.identifier, cellType: ShopCell.self)) { _, item, cell in
                cell.configure(item: item)
            }.disposed(by: rx.disposeBag)

        viewModel.selectedItem
            .subscribe(onNext: { [unowned self] item in
                guard let item = item else { return }
                self.action(for: item)
            }).disposed(by: rx.disposeBag)
        
        viewModel.currentMoney
            .drive(totalCoinLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.reward
            .subscribe(onNext: { [unowned self] reward in
                guard let reward = reward else { return }
                self.setupInfoLabel(text: Text.reward(amount: reward))
            }).disposed(by: rx.disposeBag)

        cancelButton.rx.action = viewModel.cancelAction
    }
    
    private func action(for item: ShopItem) {
        switch item {
        case .adMob(let adMob):
            self.show(adMob)
        case .gift(let number):
            self.giftTaken(number)
        case .taken:
            print("이미 없어진 기프트!")
        }
    }
}

// MARK: Setup
private extension ShopViewController {
    private func setup() {
        setupDelegate()
        setupInfoLabel(text: Text.shopReset)
    }
    
    private func setupDelegate() {
        shopCollectionView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        
        shopCollectionView.rx.modelSelected(ShopItem.self)
            .subscribe(onNext: { [unowned self] item in
                self.viewModel.selectedItem.accept(item)
            }).disposed(by: rx.disposeBag)
    }
    
    private func setupInfoLabel(text: String) {
        let font = UIFont(name: Font.joystix, size: view.bounds.width * 0.04) ?? UIFont()
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.font, value: font, range: .init(location: 0, length: text.count))
        rewardInfoLabel.attributedText = attributedString
        rewardInfoLabel.restartTypewritingAnimation()
    }
}

// MARK: Setup CellSize
extension ShopViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = itemWidth
        let height = width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let xInset = (shopCollectionView.frame.width - itemWidth * 3) / 2.5
        let yInset: CGFloat = 0 // (shopCollectionView.frame.height - (itemWidth * 2)) / 2
        return UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
    }
}

// MARK: Google Ads
extension ShopViewController: GADFullScreenContentDelegate {
    private func giftTaken(_ takenGift: Int) {
        viewModel.giftTaken(takenGift)
    }
    
    private func show(_ adMob: GADRewardedAd) {
        adMob.fullScreenContentDelegate = self
        
        adMob.present(fromRootViewController: self) { [unowned self] in
            self.viewModel.adDidFinished(adMob)
        }
    }
}
