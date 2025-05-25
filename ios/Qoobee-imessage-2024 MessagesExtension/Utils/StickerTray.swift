//
//  StickerTray.swift
//  QooBeeAgapiWAStickerApp
//
//  Created by Utsav Shrestha on 14/10/2021.
//

import Foundation
struct StickerTray{
    let identifier: String
    let image: ImageData?
    let name: String
    
    init(identifier: String, url: String, name: String) throws {
        let trayCompliantImageData: ImageData = try ImageData.imageDataIfCompliant(contentsOfFile: url, isTray: true)
        self.image = trayCompliantImageData
        self.identifier = identifier
        self.name = name
    }
}
