//
//  StickerCollectionViewCell.swift
//  QooBee iMessage Stickers MessagesExtension
//
//  Created by lu peng on 19/11/19.
//  Copyright © 2019 www.QooBee.com. All rights reserved.
//

import UIKit
import Messages

class StickerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var stickerView: MSStickerView!
    let allStickerData      = StickerModel.shared.getAllStickerData()
    
    //Function to Setup Stickers at Index Path
    func setupStickersAtCategory(selectedCategoryIndex:Int, favStickersNames:[String], recent:[String], indexPath:IndexPath){
        var stickerName = ""
        if selectedCategoryIndex == 0 {
            
            switch indexPath.section {
            case 0:
                stickerName = favStickersNames[indexPath.row]
            default:
                stickerName = recent[indexPath.row]
            }
            
        }else{
            stickerName = allStickerData[selectedCategoryIndex][indexPath.section].stickerNames![indexPath.row]
        }
    
        let currentId = allStickerData[selectedCategoryIndex][indexPath.section].purchaseId!

             if let url = Bundle.main.url(forResource: stickerName, withExtension: "png") {
                do {
                    let sticker = try MSSticker.init(contentsOfFileURL: url, localizedDescription: "")
                    stickerView.sticker = sticker
                    stickerView.startAnimating()
                    
                    if IAPHelper.shared.isProductPurchased(currentId) || indexPath.row < 5 || currentId == "FREE" {
                        stickerView.isUserInteractionEnabled    = true
                        stickerView.alpha                       = 1
                    }else{
                       stickerView.isUserInteractionEnabled     = false
                       stickerView.alpha                        = 0.2
                    }
                }catch {print("cannot make stickers")}
        }
    }
}

