import UIKit

final class FullImageStoryView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scriptLabel: UILabel!

    func show(with script: Script) {
        reset()
        
        let imageName = script.imageName ?? ""
        let image = UIImage(named: imageName)
        imageView.image = image
        scriptLabel.text = script.line
        startAnimation(of: script.animation)
    }
    
    private func reset() {
        imageView.layer.removeAllAnimations()
        imageView.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
    
    private func startAnimation(of animationType: Script.Animation) {
        switch animationType {
        case .fadeIn: fadeIn(view: imageView, duration: 0.5)
        case .zoom: zoom(duration: 4.0)
        case .shake: shake()
        }
    }
    
    private func fadeIn(view: UIView, duration: Double) {
        view.alpha = 0.0
        
        UIView.animate(withDuration: duration) {
            view.alpha = 1.0
        }
    }
    
    private func zoom(duration: Double) {
        UIView.animate(withDuration: duration) {
            self.imageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }
    
    private func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.repeatCount = .infinity
        animation.values = [-20, 20, -10, 10, -20, 20, -10, 10, -10]
        imageView.layer.add(animation, forKey: "shake")
    }
}
