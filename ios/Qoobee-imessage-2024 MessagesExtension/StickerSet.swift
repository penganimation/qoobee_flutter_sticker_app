//
//  StickerSets.swift
//  QooBee iMessage Stickers MessagesExtension
//
//  Created by lu peng on 28/11/19.
//  Copyright © 2019 www.QooBee.com. All rights reserved.
//

import Foundation

struct StickerSet: Codable {
    
    var purchaseId: String?
    var isLocked: Bool?
    var stickerSetName: String?
    var stickerNames: [String]?
    
}
