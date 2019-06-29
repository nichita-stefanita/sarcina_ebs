//
//  ViewController.swift
//  AppTask
//
//  Created by Nichita Stefanita on 6/24/19.
//  Copyright © 2019 mangoBay. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var productList: UICollectionView!
    
    var products = [ProductStruct]()
    var selectedProduct: ProductStruct!
    
    let UD = UserDefaults.standard
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productList.dataSource = self
        productList.delegate = self
        productList.prefetchDataSource = self
        productList.isPrefetchingEnabled = true
        
        RemoteProducts.shared.getProducts(limit: 10 , offset: 0) { (result) in
            if let  productResult = result {
                self.products = productResult
                self.productList.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        productList.reloadData()
    }

    //MARK: CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  productList.dequeueReusableCell(withReuseIdentifier: "productCell", for: indexPath) as! ProductListCollectionViewCell
        let product = products[indexPath.row]
        
        product.getImage(cell.productPhoto, { (image) in
            cell.productPhoto.image = image
        })
        
        cell.productTitle.text = product.title
        cell.productPrice.text = "$\(product.price)"
        cell.productShortDescription.text = product.short_description
        cell.favIndicator.isHidden = true
        
        if UD.value(forKey: String(product.id)) != nil {
            if UD.bool(forKey: String(product.id)) {
                cell.favIndicator.image = UIImage(named: "hearttap")
                cell.favIndicator.isHidden = false
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let productPage = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "productPage") as! ProductDetailViewController
        productPage.id = products[indexPath.row].id
        navigationController?.pushViewController(productPage, animated: true)
    }
    //MARK: CollectionView layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 250)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
}

extension ViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        DispatchQueue.global().async {
            if indexPaths.last?.row == self.products.count - 1{
                RemoteProducts.shared.getProducts(limit: 10, offset: self.products.count, { (result) in
                    for item in result! {
                        if item.id > self.products.last!.id {
                            self.products.append(item)
                            DispatchQueue.main.async {
                                self.productList.reloadData()
                            }
                        }
                    }
                })
            }
        }
    }
}


