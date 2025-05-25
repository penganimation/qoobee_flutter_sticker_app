//
//  ButtonCollectionViewCell.swift
//  QooBee iMessage Stickers MessagesExtension
//
//  Created by lu peng on 19/11/19.
//  Copyright © 2019 www.QooBee.com. All rights reserved.
//

import UIKit

class ButtonCollectionViewCell: UICollectionViewCell {
    
    let allStickerData = StickerModel.shared.getAllStickerData()
    
    @IBOutlet weak var newStickerSign: UIImageView!
    @IBOutlet weak var buttonImageView: UIImageView!
    
    func setupButtons(selectedCategoryIndex:Int, indexPath: IndexPath){
        
        let currentSets = allStickerData[indexPath.row]
        
        let stickerCategories   = StickerModel.shared.getAllStickerCategories()
        
        buttonImageView.image = UIImage.init(named: String(stickerCategories[indexPath.row]))
        
        if selectedCategoryIndex == indexPath.row {
            buttonImageView.alpha = 1
        }else{
            buttonImageView.alpha = 0.2
        }
        
        for set in currentSets {
            if IAPHelper.shared.isProductPurchased(set.purchaseId!) || (set.purchaseId?.contains("FREE"))!{
                self.newStickerSign.isHidden = true
            }else{
                self.newStickerSign.isHidden = false
            }
        }
        
    }
}
