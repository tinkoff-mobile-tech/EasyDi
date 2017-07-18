//
//  StripViewController.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation
import UIKit

class StripViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var stripTitle: UILabel?
    @IBOutlet var stripTitleView: UIView?
    
    @IBOutlet var imageViewWidth: NSLayoutConstraint?
    @IBOutlet var imageViewHeight: NSLayoutConstraint?
    
    @IBOutlet var imageViewLeft: NSLayoutConstraint?
    @IBOutlet var imageViewTop: NSLayoutConstraint?
    
    var strip: XKCDStrip?
    @objc var image: UIImage?
    @objc var titleIsVisible: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let image = self.image, let strip = self.strip else {
            return
        }
        
        self.stripTitle?.text = "#\(strip.id) \(strip.title)"
        
        self.imageView?.image = image
        self.imageViewWidth?.constant = image.size.width
        self.imageViewHeight?.constant = image.size.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.scrollView?.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.updateImagePosition()
        UIView.animate(withDuration: 0.25) { 
            self.scrollView?.alpha = 1
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        self.updateImagePosition()
    }
    
    @objc func updateImagePosition() {
        guard let imageView = self.imageView else {
            return
        }
        
        let yOffset = max(0, (self.view.frame.size.height - imageView.frame.height) / 2)
        self.imageViewTop?.constant = yOffset
        
        let xOffset = max(0, (self.view.frame.size.width - imageView.frame.width) / 2)
        self.imageViewLeft?.constant = xOffset
        
        self.view.layoutIfNeeded()
    }
    
    @IBAction func didTap(_ gesture: UITapGestureRecognizer) {
        self.setTitleState(visible: !self.titleIsVisible)
    }
    
    @objc func setTitleState(visible: Bool) {
        UIView.animate(withDuration: 0.5,delay: 0, options: [UIViewAnimationOptions.beginFromCurrentState], animations: {
            self.stripTitleView?.alpha = self.titleIsVisible ? 1 : 0
        }, completion: { _ in
            self.titleIsVisible = visible
        })
    }
}
