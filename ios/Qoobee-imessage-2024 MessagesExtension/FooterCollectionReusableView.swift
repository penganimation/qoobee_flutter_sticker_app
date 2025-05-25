//
//  FooterCollectionReusableView.swift
//  QooBee iMessage MessagesExtension
//
//  Created by lu peng on 20/1/20.
//  Copyright © 2020 www.QooBee.com. All rights reserved.
//

import UIKit
import StoreKit


class FooterCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var sectionFooterLabel: UILabel!
    
    @IBOutlet weak var viewWhatsappButton: UIView!
    @IBOutlet weak var viewParentWhatsappButton: UIView!
    @IBOutlet weak var buyAllButton: UIButton!
    @IBOutlet weak var footerBanner: UIImageView!
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var restoreButton: UIButton!
    var stickerTray: [StickerTray] = []
    let stickerTypes = ["everyday", "happy", "love", "annoyed", "sad", "Festive 2", "info"]
    let allStickerData = StickerModel.shared.getAllStickerData()

//    let whatsappStickerNames: Set = []

    static var purchasingAlertDelegate:PurchasingAlertDelegate?

    func setupSectionFooter (selectedCatIndex: Int, products:[SKProduct], indexPath: IndexPath, unique: [String]){
        
        let currentSection = indexPath.section
        let numOfSections = allStickerData[selectedCatIndex].endIndex
        let id = allStickerData[selectedCatIndex][indexPath.section].purchaseId!

        var bundlePrice = ""
        var showAddToWhatsapp = false
        if let stickerName = allStickerData[selectedCatIndex][currentSection].stickerSetName{
            let identifier = stickerName.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(Static)", with: "").capitalized
           

            if unique.contains(identifier){
                showAddToWhatsapp = true
            }
        }
        
        for pro in products {
            if pro.productIdentifier == "com.qoobee.qoobeestickersanimated.MessageExtension.BUNDLESALE"{
                bundlePrice = pro.localizedPrice
            }
        }
        
        self.layer.cornerRadius = 10
        self.backgroundColor = UIColor.init(displayP3Red: 255/255, green: 79/255, blue: 149/255, alpha: 1)
        footerBanner.image = UIImage(named: "FooterBanner")
        
        //WHAT TO SHOW ON THE BOTTOM BANNER
        if IAPHelper.shared.isProductPurchased("com.qoobee.qoobeestickersanimated.MessageExtension.BUNDLESALE") {
            sectionFooterLabel.text = "Let's Spread the Love!"
            buyAllButton.isHidden = true
            restoreButton.isHidden = true
            
        }else{
            sectionFooterLabel.text = "All \(StickerModel.shared.getTotalNumOfStickers()) Stickers at \(bundlePrice)"
            buyAllButton.isHidden = false
            restoreButton.isHidden = false
        }
        
        sectionFooterLabel.textColor = .white
        
        if currentSection != numOfSections - 1 {
            sectionFooterLabel.text = nil
            footerBanner.image = nil
            buyAllButton.isHidden = true
        }
        
        //WHEN TO SHOW BOTTOM BANNER
        if showAddToWhatsapp{
            if IAPHelper.shared.isProductPurchased(id) || id.contains("FREE"){
                viewWhatsappButton.backgroundColor = UIColor(red: 37/255, green: 211/255, blue: 102/255, alpha: 1.0)
                let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.addToWhatsapp))
                viewWhatsappButton.addGestureRecognizer(gesture)
            }else{
                viewWhatsappButton.backgroundColor = UIColor(red: 37/255, green: 211/255, blue: 102/255, alpha: 0.5)
            }
            
            viewParentWhatsappButton.isHidden = false
            
            viewWhatsappButton.layer.cornerRadius = 8
            viewWhatsappButton.layer.masksToBounds = true
            
           
        }else{
            viewParentWhatsappButton.isHidden = true
        }
        switch selectedCatIndex {
        case 0:
            if indexPath.section == 0 {
                footerLabel.text = ":: Swipe Left to Remove Favourites ::"
            }else{
                footerLabel.text = ":: Recent 20 Stickers Cannot Be Removed ::"
            }
        case 8:
            footerLabel.text = nil
        default:
            footerLabel.text = ":: Swipe Left to Add Favourites ::"
        }

    }
    
    @objc func addToWhatsapp(sender : UITapGestureRecognizer) {
        // Do what you want
        fetchStickerPacks()
    }
    
    @IBAction func buyAllButtonPressed(_ sender: UIButton) {
        FooterCollectionReusableView.purchasingAlertDelegate?.showBuyingAllAlert()
    }
    @IBAction func restoreButtonPressed(_ sender: Any) {
        IAPHelper.shared.restorePurchases()
    }
    
  
    
    private func fetchStickerPacks() {
        do {
      
            try StickerPackManager.fetchStickerPacks(fromJSON: StickerPackManager.stickersJSON(contentsOfFile: "contents"), identifier:"Festive2")  {stickerPacks in
                if let stickerPack = stickerPacks.first{
                    stickerPack.sendToWhatsApp { completed in
    //                    loadingAlert.dismiss(animated: true)
                    }
                    
                }
                
                
            }
        }catch{
            print(error)
        }
    
        
    }
    
    func getStickers(type: String) -> [StickerTray]{
        print(type)
        return self.stickerTray.filter { item in
            print(item.identifier)
            return item.identifier.lowercased().contains(type.lowercased())
        }
    }
}

