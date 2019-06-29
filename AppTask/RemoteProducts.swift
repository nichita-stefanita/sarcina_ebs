//
//  RemoteProducts.swift
//  AppTask
//
//  Created by Nichita Stefanita on 6/24/19.
//  Copyright © 2019 mangoBay. All rights reserved.
//


import UIKit
import SDWebImage
import Alamofire
import SystemConfiguration

class RemoteProducts: NSObject {
    
    static var shared = RemoteProducts()
    
    private var products     = [ProductStruct]()
    
    private var product: ProductStruct!
    
    private let productsPath = NSHomeDirectory() + "/Documents/products.plist"
    
    private override init() {
        super.init()
        getAllProducts(limit: 10, offset: 0) { (done) in
            print(self.products.count)
        }
    }

    // get array of products
    func getProducts(limit: Int, offset: Int,_ comp: @escaping ([ProductStruct]?) -> Void){
            getAllProducts(limit: limit, offset: offset) { [weak self] (done) in
                if done{
                    comp(self?.products)
                }else{
                    comp(nil)
                }
            }
    }
    // get detailed info
    func getSingleProductAt(id:Int,_ comp: @escaping (ProductStruct) -> Void){
            getProduct(id: id) { [weak self] (done) in
                if done{
                    if self?.product.id == id{
                        comp(self!.product)
                    }
                }else{
                    return
                }
            }
    }

    
    private func getProduct(id: Int,_ completion: @escaping (Bool) -> Void){
        if !RemoteProducts.isConnectedToNetwork() && loadProductFromCache(){
            completion(true)
            return
        }
        requestSingleProduct([
            "id" : String(id)
            
        ]) { [weak self] (data) in
            guard let data = data else { completion(false); return }
            let decoder = JSONDecoder()
            do{
                let result = try decoder.decode(ProductStruct.self, from: data)
                self?.product = result
                completion(true)
            }catch{
                completion(false)
            }
        }
    }
    
    private func requestSingleProduct(_ params: [String: Any], completion: @escaping (Data?) -> Void) {
        Alamofire.request("http://185.181.231.32:5000/product",
                          method: .get,
                          parameters: params)
        .validate()
            .responseData { (response) in
                completion(response.data)
        }
    }
    
    private func getAllProducts(limit: Int, offset: Int,_ completion: @escaping (Bool) -> Void){
        if !RemoteProducts.isConnectedToNetwork() && loadProductFromCache(){
            completion(true)
            return
        }
        request([
            "limit" : String(limit),
            "offset" : String(offset)
            
        ]) { [weak self] (data) in
            guard let data = data else { completion(false); return }
            let decoder = JSONDecoder()
            do{
                let result = try decoder.decode([ProductStruct].self, from: data)
                self?.products = result
                completion(true)
            }catch{
                completion(false)
            }
        }
    }
    
    private func request(_ params: [String: Any], completion: @escaping (Data?) -> Void) {
        Alamofire.request("http://185.181.231.32:5000/products",
                          method: .get,
                          parameters: params)
            .validate()
            .responseData { (data) in
                completion(data.data)
        }
    }
    
    public static func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
}

//MARK: Cache
extension RemoteProducts{
    
    private func loadProductFromCache() -> Bool{
        guard let tempProducts = loadFromCache(productsPath, prot: ProductStruct.self) else { return false }
        self.products = tempProducts
        return true
    }
    
    private func cacheProductData() -> Bool{
        return cacheData(productsPath, array: products)
    }
    
    private func cacheData<T>(_ path: String, array: T) -> Bool where T : Encodable{
        let encoder = JSONEncoder()
        do{
            let data = try encoder.encode(array)
            try data.write(to: URL.init(fileURLWithPath: path), options: .atomic)
            return true
        }catch let error{
            print(error)
            return false
        }
    }
    
    private func loadFromCache<T>(_ path: String, prot: T.Type) -> [T]? where T : Decodable{
        let decoder = JSONDecoder()
        do{
            let url = URL.init(fileURLWithPath: path)
            let data = try Data.init(contentsOf: url)
            let result = try decoder.decode([T].self, from: data)
            return result
        }catch let error{
            print(error)
            return nil
        }
    }
    
}


struct ProductStruct: Encodable, Decodable {
    var id: Int
    var title: String
    var image: String
    var price: String
    var short_description: String
    
    private enum CodingKeys: String, CodingKey {
        case id, title, price, image, short_description
    }
    
    init(from decoder: Decoder) throws {
        let container     = try decoder.container(keyedBy: CodingKeys.self)
        title             = try container.decode(String.self, forKey: .title)
        image             = try container.decode(String.self, forKey: .image)
        short_description = try container.decode(String.self, forKey: .short_description)
        id                = try container.decode(Int.self, forKey: .id)
        price             = try String(container.decode(Int.self, forKey: .price))
    }
    
    func getImage(_ imageView: UIImageView, _ completion: @escaping (UIImage?) -> Void){
        imageView.sd_setImage(with: URL(string: image)) { (img, error, type, url) in
            completion(img)
        }
    }
  
}


