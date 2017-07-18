//
//  ViewController.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation
import UIKit
import Dispatch

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @objc static let stripsCount: Int = 25
    
    var xkcdService: IXKCDService?
    var strips:[XKCDStrip] = []
    
    var imageService: IImageService?
    
    @objc var loadingStrips:Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.loadingStrips {
                    self.infiniteScrollView?.activityIndicator?.startAnimating()
                } else {
                    self.infiniteScrollView?.activityIndicator?.stopAnimating()
                }
            }
        }
    }
    
    @IBOutlet var tableView: UITableView?
    @IBOutlet var infiniteScrollView: XKCDInfiniteScrollFooterView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        FeedViewAssembly.instance().inject(into: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.xkcdService?.fetchCurrentStrip { (result) in
            switch result {
            case .success(let stripId):
                self.loadStrips(before: stripId+1)
            case .fail(let error):
                print("Error: \(error)")
            }
        }
    }
    
    @objc func loadStrips(before stripId: Int) {
        
        self.loadingStrips = true
        let stripsRange = (stripId - FeedViewController.stripsCount)..<stripId
        self.xkcdService?.fetchStrips(from: stripsRange) { (result) in
            switch result {
            case .success(let strips):
                
                DispatchQueue.main.async {
                    self.strips.append(contentsOf: strips)
                    self.tableView?.reloadData()
                }
            case .fail(let error):
                print("Error: \(error)")
            }
            self.loadingStrips = false
        }
    }
    
    /// MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.strips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let stripCell = tableView.dequeueReusableCell(withIdentifier: "XKCDStripCell", for: indexPath) as? XKCDStripCell else {
            fatalError("Invalid cell type")
        }
        
        let strip = self.strips[indexPath.row]
        stripCell.display(strip)
        
        self.imageService?.loadImage(url: strip.imgURL) { [strip](result) in
            
            guard case let .success(image) = result, strip.id == stripCell.lastShownStripId else {
                return
            }
            
            DispatchQueue.main.async {
                stripCell.display(image: image)
            }
        }
        
        return stripCell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 320
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let infiniteScrollView = self.infiniteScrollView else {
            return
        }
        let infiniteScrollRect = self.view.convert(infiniteScrollView.bounds, from: infiniteScrollView)
        let infiniteScrollOffset = self.view.frame.height - infiniteScrollRect.origin.y
        if infiniteScrollOffset > infiniteScrollRect.height * 0.75 {
            self.loadMoreStrips()
        }
    }
    
    @objc func loadMoreStrips() {
        
        guard self.strips.count > 0, !self.loadingStrips, let lastStripId = self.strips.last?.id else {
            return
        }
        
        self.loadStrips(before: lastStripId)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nextViewController = segue.destination as? StripViewController,
            let selectedStripIndexPath = self.tableView?.indexPathForSelectedRow,
            let stripCell = tableView?.cellForRow(at: selectedStripIndexPath) as? XKCDStripCell else {
            return
        }
        
        let strip = self.strips[selectedStripIndexPath.row]
        
        nextViewController.strip = strip
        nextViewController.image = stripCell.stripImage?.image
    }
}

