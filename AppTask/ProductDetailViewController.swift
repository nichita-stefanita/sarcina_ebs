//
//  ProductDetailViewController.swift
//  AppTask
//
//  Created by Nichita Stefanita on 6/24/19.
//  Copyright © 2019 mangoBay. All rights reserved.
//

import UIKit
import SDWebImage

class ProductDetailViewController: UIViewController {
    
    @IBOutlet weak var productPhoto: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var favButton: UIButton!
    
    var id: Int!
    var isFav: Bool!
    let UD = UserDefaults.standard
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if id == nil {
            let alert = UIAlertController(title: "Error loading this product", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
        } else {
            RemoteProducts.shared.getSingleProductAt(id: id) { [weak self] (result) in
                if result.id == self!.id{
                    print("result id: \(result.id), id:\(self?.id ?? -1)")
                    self!.getImage(url: result.image, self!.productPhoto) { (image) in
                        self!.productPhoto.image = image
                    }
                    self!.titleLabel.text = result.title
                    self!.priceLabel.text = "$\(result.price)"
                    self!.descriptionTextView.text = result.short_description
                }
            }
            isFav = UD.bool(forKey: String(id))
            
            if isFav {
                favButton.setImage(UIImage(named: "hearttap"), for: .normal)
            } else {
                favButton.setImage(UIImage(named: "heart"), for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
        id = nil
    }
    
    @IBAction func favButtonAction(_ sender: UIButton) {
        if isFav {
            isFav = false
            sender.setImage(UIImage(named: "heart"), for: .normal)
        } else {
            isFav = true
            sender.setImage(UIImage(named: "hearttap"), for: .normal)
        }
        
        UD.set(isFav, forKey: String(id))
    }
    
    func getImage(url: String,_ imageView: UIImageView, _ completion: @escaping (UIImage?) -> Void){
        imageView.sd_setImage(with: URL(string: url)) { (img, error, type, url) in
            completion(img)
        }
    }
}
