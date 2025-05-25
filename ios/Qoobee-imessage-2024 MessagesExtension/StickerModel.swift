//
//  StickerModel.swift
//  QooBee iMessage Stickers MessagesExtension
//
//  Created by lu peng on 28/11/19.
//  Copyright © 2019 www.QooBee.com. All rights reserved.
//

import Foundation
import Messages

/// Singleton model class for managing stickers
class StickerModel {
    
    // Shared instance of StickerModel
    static let shared = StickerModel()

    /// Retrieves all local product identifiers for stickers that require purchase.
    /// - Returns: A set of unique product identifiers.
    public func getLocalProductIdentifiers() -> Set<ProductIdentifier> {
        var localProductIdentifiers: Set<ProductIdentifier> = []
        
        // Retrieve all sticker data
        let allStickerData = getAllStickerData()
        for section in allStickerData {
            for set in section {
                // Safely unwrap `purchaseId` before adding it to the set
                if let id = set.purchaseId, !id.isEmpty {
                    localProductIdentifiers.insert(id)
                } else {
                    print("Warning: Missing or empty purchaseId in StickerSet")
                }
            }
        }
        
        return localProductIdentifiers
    }


    /// Loads all sticker data from the local plist file.
    /// - Returns: A two-dimensional array of `StickerSet` objects representing sticker sections and their sets.
    public func getAllStickerData() -> [[StickerSet]] {
        // Array to store all sticker data
        var allStickerData = [[StickerSet]]()
        
        // Attempt to retrieve the plist file's URL from the bundle
        guard let url = Bundle.main.url(forResource: "AllStickersData", withExtension: "plist") else {
            print("Error: Unable to find AllStickersData.plist.")
            return allStickerData
        }
        
        do {
            // Decode the plist data into a nested array of `StickerSet` objects
            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: url)
            allStickerData = try decoder.decode([[StickerSet]].self, from: data)
        } catch {
            print("Error decoding AllStickersData.plist: \(error.localizedDescription)")
        }
        
        return allStickerData
    }
    
    /// Calculates the total number of stickers across all sticker sets.
    /// - Returns: Total count of stickers.
    public func getTotalNumOfStickers() -> Int {
        var totalStickers = 0
        
        // Iterate through all sticker sets and count each sticker's names
        let allStickerData = getAllStickerData()
        for stickerSets in allStickerData {
            for stickerSet in stickerSets {
                totalStickers += stickerSet.stickerNames?.count ?? 0
            }
        }
        
        return totalStickers
    }
    
    /// Retrieves the list of all sticker categories based on the first sticker set in each section.
    /// - Returns: An array of category names as strings.
    public func getAllStickerCategories() -> [String] {
        var stickerCategories: [String] = []
        
        // Retrieve category names from the first sticker set in each section
        let allStickerData = getAllStickerData()
        for stickerSets in allStickerData {
            if let categoryName = stickerSets.first?.stickerSetName {
                stickerCategories.append(categoryName)
            }
        }
        return stickerCategories
    }
    
}

