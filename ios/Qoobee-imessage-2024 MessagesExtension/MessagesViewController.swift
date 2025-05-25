//
//  MessagesViewController.swift
//  qoobeestickersanimated MessagesExtension
//
//  Created by Utsav Shrestha on 13/11/2022.
//  test

import UIKit
import Messages
import StoreKit

class MessagesViewController: MSMessagesAppViewController {
    
    // Declare views and buttons
    @IBOutlet weak var stickerCollectionView: UICollectionView!
    @IBOutlet weak var buttonCollectionView: UICollectionView!
    @IBOutlet weak var infoCategoryView: UIImageView!
    
    // WhatsApp URL scheme to open a sticker pack
    private let WhatsAppURL: URL = URL(string: "whatsapp://stickerPack")!
    
    // Define constants for identifiers, keys, and sizes
    private enum Constants {
        static let sectionHeaderCellId = "SectionHeaderCell"     // Identifier for section header cell
        static let buttonCellId = "ButtonCell"                   // Identifier for button cell
        static let stickerCellId = "StickerCell"                 // Identifier for sticker cell
        static let sectionFooterCellId = "SectionFooterCell"     // Identifier for section footer cell
        static let festiveStickers = ["Festive1_1", "Festive1_2", "Festive1_3", "Festive1_4", "Festive1_5", "Festive1_6"]
        static let recentStickersKey = "Recent"                  // Key for saving recent stickers in UserDefaults
        static let festiveStickersAddedKey = "festive_stickered_added_to_recent" // Key to track if festive stickers have been added
        
        // UI element sizes
        static let normalHeaderSize = CGSize(width: 300, height: 30)
        static let bigFooterSize = CGSize(width: 300, height: 50)
        static let stickerCellSize = CGSize(width: 55, height: 55)
        static let buttonCellSize = CGSize(width: 55, height: 40)
    }
    
    // Declare data for stickers and buttons
    private let allStickerData = StickerModel.shared.getAllStickerData() // Fetches all available sticker data
    private var selectedCatIndex = 1 // Index to track the selected sticker category
    private var favStickersNames = StickerModel.shared.getAllStickerData()[0][0].stickerNames // Holds favorite stickers
    private var fetchedProducts: [SKProduct] = [] // Holds in-app purchase products
    private var uniqueWhatsappStickersIdentifiers: [String] = [] // Identifiers for WhatsApp stickers

    // Computed properties for UserDefaults access
    private var recentStickerNames: [String] {
        get {
            return UserDefaults.standard.object(forKey: Constants.recentStickersKey) as? [String] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.recentStickersKey)
        }
    }
    
    private var festiveStickersAdded: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.festiveStickersAddedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.festiveStickersAddedKey)
        }
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadFavStickers()        // Load favorite stickers from UserDefaults
        loadRecentStickers()     // Load recent stickers from UserDefaults
        
        setupNotificationObservers() // Set up notification observer for WhatsApp
        
        // Request products for in-app purchases
        IAPHelper.shared.requestProducts { [weak self] success, products in
            guard let self = self, success, let products = products else {
                print("Cannot get any products")
                return
            }
            
            self.fetchedProducts = products
            for product in products {
                print(product.localizedTitle) // Print each product's title
            }
        }
        
        configureCollectionViewDelegates() // Set delegates and data sources for collection views
        loadUniqueStickerIdentifiers()     // Load unique identifiers for WhatsApp stickers
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("openWhatsapp"), object: nil) // Remove observer on deallocation
    }
    
    // MARK: - Notification Observers
    private func setupNotificationObservers() {
        // Set up an observer for the custom "openWhatsapp" notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleOpenWhatsappNotification(notification:)), name: Notification.Name("openWhatsapp"), object: nil)
    }
    
    @objc private func handleOpenWhatsappNotification(notification: Notification) {
        openURL(url: "")
    }
    
    // MARK: - Load Favorite Stickers
    private func loadFavStickers() {
        // Load favorite stickers from all available sticker data
        for sections in allStickerData {
            for stickerSet in sections {
                for stickerName in stickerSet.stickerNames ?? [] {
                    if UserDefaults.standard.bool(forKey: stickerName) {
                        favStickersNames?.append(stickerName)
                    }
                }
            }
        }
    }
    
    // MARK: - Load Recent Stickers
    private func loadRecentStickers() {
        // Add festive stickers to recent stickers if they haven't been added already
        if !festiveStickersAdded {
            Constants.festiveStickers.forEach { sticker in
                if !recentStickerNames.contains(sticker) {
                    recentStickerNames.insert(sticker, at: 0)
                }
            }
            festiveStickersAdded = true
        }
    }
    
    // MARK: - Load Unique Sticker Identifiers
    private func loadUniqueStickerIdentifiers() {
        do {
            let stickersJson = try StickerPackManager.stickersJSON(contentsOfFile: "contents")
            let packs = stickersJson["sticker_packs"] as? [[String: Any]] ?? []
            uniqueWhatsappStickersIdentifiers = Array(Set(packs.compactMap { $0["identifier"] as? String })) // Extract unique identifiers
        } catch {
            print("Failed to load sticker identifiers: \(error)")
        }
    }
    
    // MARK: - Configure Collection View Delegates and Data Sources
    private func configureCollectionViewDelegates() {
        // Set delegates and data sources for collection views
        stickerCollectionView.delegate = self
        stickerCollectionView.dataSource = self
        buttonCollectionView.delegate = self
        buttonCollectionView.dataSource = self
        IAPHelper.shared.purchasingAlertDelegate = self
        FooterCollectionReusableView.purchasingAlertDelegate = self
    }
    
    // MARK: - Opening URL
    private func openURL(url: String) {
        // Open URL within the app's extension context
        guard let url = URL(string: url) else {
            print("Invalid URL")
            return
        }
        
        self.extensionContext?.open(url, completionHandler: { success in
            print(success ? "URL opened successfully." : "Failed to open URL.")
        })
    }
}

// MARK: - UICollectionView Data Source and Delegate
extension MessagesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // Number of sections in the collection view
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionView == stickerCollectionView ? allStickerData[selectedCatIndex].count : 1
    }
    
    // Number of items in each section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == stickerCollectionView ? stickerCount(for: section) : StickerModel.shared.getAllStickerCategories().count
    }
    
    // Helper to get the count of stickers in each section based on the selected category
    private func stickerCount(for section: Int) -> Int {
        if selectedCatIndex == 0 {
            return section == 0 ? favStickersNames?.count ?? 0 : recentStickerNames.count
        }
        return allStickerData[selectedCatIndex][section].stickerNames?.count ?? 0
    }
    
    // Configure each cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == stickerCollectionView {
            print("allStickerData: \(allStickerData)")
            print("selectedCatIndex: \(selectedCatIndex)")
            guard selectedCatIndex < allStickerData.count,  // Check selectedCatIndex is valid
                  indexPath.section < allStickerData[selectedCatIndex].count,  // Check section is valid
                  let stickerNames = allStickerData[selectedCatIndex][indexPath.section].stickerNames,  // Ensure stickerNames exists
                  indexPath.row < stickerNames.count else {  // Check row is valid
                fatalError("Index out of range in cellForItemAt: selectedCatIndex=\(selectedCatIndex), section=\(indexPath.section), row=\(indexPath.row)")
            }

            let stickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.stickerCellId, for: indexPath) as! StickerCollectionViewCell
            stickerCell.setupStickersAtCategory(selectedCategoryIndex: selectedCatIndex, favStickersNames: favStickersNames ?? [], recent: recentStickerNames, indexPath: indexPath)
            configureGestures(for: stickerCell, at: indexPath)
            return stickerCell
        } else {
            let buttonCell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.buttonCellId, for: indexPath) as! ButtonCollectionViewCell
            buttonCell.setupButtons(selectedCategoryIndex: selectedCatIndex, indexPath: indexPath)
            return buttonCell
        }
    }

    
    // Configures gestures (swipe and tap) for a sticker cell
    private func configureGestures(for stickerCell: StickerCollectionViewCell, at indexPath: IndexPath) {
        guard selectedCatIndex < allStickerData.count,  // Check selectedCatIndex is within bounds
              indexPath.section < allStickerData[selectedCatIndex].count,  // Check section is within bounds
              let stickerNames = allStickerData[selectedCatIndex][indexPath.section].stickerNames,  // Ensure stickerNames exists
              indexPath.row < stickerNames.count else {  // Check row is within bounds
            print("Index out of range: selectedCatIndex=\(selectedCatIndex), section=\(indexPath.section), row=\(indexPath.row)")
            return
        }

        let stickerName = stickerNames[indexPath.row]
        addGestureRecognizers(to: stickerCell, name: stickerName)
    }

    
    // Adds gesture recognizers to a sticker cell for adding/removing favorites and tapping to add recent stickers
    private func addGestureRecognizers(to stickerCell: StickerCollectionViewCell, name: String) {
        let swipeAddFavGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleAddFavSwipe))
        let swipeRemoveFavGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRemoveFavSwipe))
        let stickerTapGesture = UITapGestureRecognizer(target: self, action: #selector(addToRecentStickers))
        
        swipeAddFavGesture.direction = .left
        swipeRemoveFavGesture.direction = .left
        swipeAddFavGesture.name = name
        swipeRemoveFavGesture.name = name
        stickerTapGesture.name = name
        
        stickerCell.gestureRecognizers?.forEach { stickerCell.removeGestureRecognizer($0) }
        stickerCell.addGestureRecognizer(swipeAddFavGesture)
        stickerCell.addGestureRecognizer(swipeRemoveFavGesture)
        stickerCell.addGestureRecognizer(stickerTapGesture)
    }
}

// MARK: - Swipe and Tap Actions for Stickers
extension MessagesViewController {
    
    @objc private func handleAddFavSwipe(sender: UISwipeGestureRecognizer) {
        if let stickerName = sender.name, sender.direction == .left {
            addToFavStickers(stickerName: stickerName)
        }
    }
    
    @objc private func handleRemoveFavSwipe(sender: UISwipeGestureRecognizer) {
        if let stickerName = sender.name, sender.direction == .left {
            removeFavStickers(stickerName: stickerName)
        }
    }
    
    @objc private func addToRecentStickers(sender: UITapGestureRecognizer) {
        guard let stickerName = sender.name else { return }
        
        // Remove and re-insert sticker to keep it at the top of recent stickers
        recentStickerNames.removeAll { $0 == stickerName }
        recentStickerNames.insert(stickerName, at: 0)
    }
    
    // Add sticker to favorites
    private func addToFavStickers(stickerName: String) {
        guard !(favStickersNames?.contains(stickerName) ?? false) else {
            showAlert(title: "Already Added", message: "This sticker is already in favorites.")
            return
        }
        favStickersNames?.append(stickerName)
        UserDefaults.standard.set(true, forKey: stickerName)
        showAlert(title: "Added to Favorites", message: "Sticker added to favorites.")
    }
    
    // Remove sticker from favorites
    private func removeFavStickers(stickerName: String) {
        favStickersNames?.removeAll { $0 == stickerName }
        UserDefaults.standard.set(false, forKey: stickerName)
        showAlert(title: "Removed from Favorites", message: "Sticker removed from favorites.")
    }
    
    // Reusable function to show an alert with a title and message
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Alert Delegate Functions
extension MessagesViewController: PurchasingAlertDelegate {
    
    func showBuyingAllAlert() {
        Alert.showBuyingAllAlert(vc: self)
    }

    func showPurchasingAlert() {
        self.requestPresentationStyle(.expanded)
        Alert.showPurchasingAlert(vc: self)
     }

    func showCompleteAlert() {
        self.stickerCollectionView.reloadData()
        self.buttonCollectionView.reloadData()
        self.dismiss(animated: true, completion: nil)
    }
    
    func showRestoringAlert() {
        Alert.showRestoringAlert(vc: self)
    }
}
