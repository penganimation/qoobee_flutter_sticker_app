//
//  HeaderCollectionReusableView.swift
//  QooBee iMessage Stickers MessagesExtension
//
//  Created by lu peng on 21/11/19.
//  Copyright © 2019 www.QooBee.com. All rights reserved.
//

import UIKit
import StoreKit

class HeaderCollectionReusableView: UICollectionReusableView {
        
    @IBOutlet weak var stickerHeader: UILabel!
    @IBOutlet weak var btnBuy: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var bannerView: UIImageView!
    
    let allStickerData       = StickerModel.shared.getAllStickerData()
    
    var currentProductId = ""
    
    func setupHeader (selectedCategoryIndex:Int, indexPath:IndexPath){

        let id = allStickerData[selectedCategoryIndex][indexPath.section].purchaseId!
        let setName = allStickerData[selectedCategoryIndex][indexPath.section].stickerSetName
        
        self.stickerHeader.text = setName
        self.stickerHeader.textColor = .white
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
                
        switch selectedCategoryIndex {
        case 0:
            if indexPath.section == 0 {
                self.bannerView.image = UIImage(named: "Banner0_0")
                self.backgroundColor = UIColor.init(displayP3Red: 255/255, green: 79/255, blue: 149/255, alpha: 1)
            }else{
                self.bannerView.image = UIImage(named: "Banner0_1")
                self.backgroundColor = UIColor.init(displayP3Red: 34/255, green: 209/255, blue: 0/255, alpha: 1)
            }
        case 1:
            self.bannerView.image = UIImage(named: "Banner1")
            self.backgroundColor = UIColor.init(displayP3Red: 34/255, green: 209/255, blue: 0/255, alpha: 1)
        case 2:
            self.bannerView.image = UIImage(named: "Banner2")
            self.backgroundColor = UIColor.init(displayP3Red: 255/255, green: 96/255, blue: 0/255, alpha: 1)
        case 3:
            self.bannerView.image = UIImage(named: "Banner3")
            self.backgroundColor = UIColor.init(displayP3Red: 225/255, green: 0/255, blue: 6/255, alpha: 1)
        case 4:
            self.bannerView.image = UIImage(named: "Banner4")
            self.backgroundColor = UIColor.init(displayP3Red: 0/255, green: 135/255, blue: 221/255, alpha: 1)
        case 5:
            self.bannerView.image = UIImage(named: "Banner5")
            self.backgroundColor = UIColor.init(displayP3Red: 152/255, green: 0/255, blue: 217/255, alpha: 1)
        case 6:
            self.bannerView.image = UIImage(named: "Banner6")
            self.backgroundColor = UIColor.init(displayP3Red: 226/255, green: 0/255, blue: 5/255, alpha: 1)
        case 7:
            self.bannerView.image = UIImage(named: "Banner7")
            self.backgroundColor = UIColor.init(displayP3Red: 226/255, green: 0/255, blue: 5/255, alpha: 1)
        case 8:
            self.bannerView.image = UIImage(named: "Banner8")
            self.backgroundColor = UIColor.init(displayP3Red: 172/255, green: 172/255, blue: 172/255, alpha: 1)
        default:
            self.bannerView.image = UIImage(named: "Banner8")
            self.backgroundColor = .red
        }
        
        if IAPHelper.shared.isProductPurchased(id) || id.contains("FREE"){
           btnBuy.isHidden = true
           restoreButton.isHidden = true
        }else{
            btnBuy.isHidden = false
            restoreButton.isHidden = false
            currentProductId = id
            btnBuy.addTarget(self, action: #selector(HeaderCollectionReusableView.buyButtonTapped(_:)), for: .touchUpInside)
            restoreButton.addTarget(self, action: #selector(HeaderCollectionReusableView.restoreButtonTapped(_:)), for: .touchUpInside)
        }
    }

    //Function to run when buy button is pressed
    @objc func buyButtonTapped(_ sender: AnyObject) {
        IAPHelper.shared.buyProduct(currentProductId)
    }
    
    //Run Restore function
    @objc func restoreButtonTapped(_ sender: AnyObject) {
        IAPHelper.shared.restorePurchases()
    }
    
}
