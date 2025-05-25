import 'package:flutter/material.dart';
import 'sticker_model.dart';
import 'sticker_set.dart';
import 'user_preferences_service.dart';
import 'iap_service.dart'; 
import 'whatsapp_export_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:developer' as developer;

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class StickerHomeScreen extends StatefulWidget {
  const StickerHomeScreen({super.key});

  @override
  State<StickerHomeScreen> createState() => _StickerHomeScreenState();
}

class _StickerHomeScreenState extends State<StickerHomeScreen> {
  final StickerModel _stickerModel = StickerModel();
  final UserPreferencesService _prefsService = UserPreferencesService();
  late IAPService _iapService; 
  final WhatsAppExportService _whatsAppExportService = WhatsAppExportService();

  List<List<StickerSet>> _allStickerData = [];
  List<String> _categoryDisplayNames = [];
  List<StickerSet> _currentCategorySetsToDisplay = [];

  Set<String> _favoriteStickerNames = {};
  List<String> _recentStickerNames = [];
  
  List<ProductDetails> _iapProducts = [];
  Set<String> _purchasedProductIds = {};
  bool _isLoading = true; 
  bool _iapProcessing = false; 
  String? _error;

  final Map<String, String> _setNameToDirectoryMap = {
    "FAVOURITES": "Favourites",
    "RECENT": "Recent",
    "EVERYDAY": "Everyday",
    "HAPPY": "Happy",
    "LOVE": "Love",
    "SAD": "Sad",
    "ANNOYED": "Angry",
    "FESTIVE": "Festive",
    "PHOTO": "Photo",
    "INFO": "Info",
  };

  @override
  void initState() {
    super.initState();
    _iapService = IAPService(); 
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _allStickerData = await _stickerModel.getAllStickerData();
      _favoriteStickerNames = (await _prefsService.getFavoriteStickers()).toSet();
      _recentStickerNames = await _prefsService.getRecentStickers();
      _purchasedProductIds = await _prefsService.getAllPurchasedProductIds();
      developer.log("Initially loaded purchased IDs: $_purchasedProductIds", name: "StickerHomeScreen");

      _categoryDisplayNames = _deriveCategoryDisplayNames();

      Set<String> productIdsFromStickerModel = await _stickerModel.getAllProductIdentifiers();
      developer.log("Product IDs for IAP query: $productIdsFromStickerModel", name: "StickerHomeScreen");

      await _iapService.init(
        productIds: productIdsFromStickerModel,
        onPurchaseSuccess: _handlePurchaseSuccess,
        onPurchaseError: _handlePurchaseError,
        onRestoreSuccess: _handleRestoreSuccess,
        onRestoreEmpty: _handleRestoreEmpty,
      );
      
      if (mounted) {
        setState(() {
          _iapProducts = _iapService.getAvailableProducts();
        });
      }

      if (_categoryDisplayNames.isNotEmpty) {
        await _updateCurrentCategorySetsAndDisplay(0, isInitializing: true);
      } else {
        _currentCategorySetsToDisplay = [];
      }

    } catch (e, stackTrace) {
      developer.log('Failed to load initial data: $e', name: "StickerHomeScreen", error: e, stackTrace: stackTrace);
      if (mounted) _error = 'Failed to load data: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    developer.log("Purchase successful: ${purchaseDetails.productID}", name: "StickerHomeScreen");
    await _prefsService.savePurchasedProduct(purchaseDetails.productID);
    if (mounted) {
      _purchasedProductIds = await _prefsService.getAllPurchasedProductIds(); // Refresh purchased IDs
      setState(() {
        _iapProcessing = false;
      });
      await _updateCurrentCategorySetsAndDisplay(_selectedCategoryIndex);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_iapService.getProduct(purchaseDetails.productID)?.title ?? purchaseDetails.productID} purchased!'), backgroundColor: Colors.green),
      );
    }
  }

  void _handlePurchaseError(String errorMessage) {
    developer.log("Purchase error: $errorMessage", name: "StickerHomeScreen");
    if (mounted) {
      setState(() => _iapProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase Error: $errorMessage'), backgroundColor: Colors.red),
      );
    }
  }

 void _handleRestoreSuccess() async {
    developer.log("Restore purchases successful, refreshing purchased items.", name: "StickerHomeScreen");
    _purchasedProductIds = await _prefsService.getAllPurchasedProductIds(); // Refresh the set of purchased IDs
    if (mounted) {
      setState(() {
        _iapProcessing = false; 
      });
      await _updateCurrentCategorySetsAndDisplay(_selectedCategoryIndex); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Previously purchased items restored.'), backgroundColor: Colors.blue),
      );
    }
  }
  
  void _handleRestoreEmpty() {
    developer.log("No purchases found to restore.", name: "StickerHomeScreen");
    if (mounted) {
      setState(() => _iapProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchases found to restore.'), backgroundColor: Colors.orange),
      );
    }
  }

  List<String> _deriveCategoryDisplayNames() {
    // Order based on typical app flow and problem description hints
    return ["Favourites", "Recent", "Everyday", "Happy", "Love", "Sad", "Annoyed", "Festive", "Photo", "Info"];
  }

  Future<void> _updateCurrentCategorySetsAndDisplay(int index, {bool isInitializing = false}) async {
    if (!mounted || index < 0 || index >= _categoryDisplayNames.length) return;
    if(!isInitializing && mounted) setState(() => _isLoading = true);

    _selectedCategoryIndex = index;
    String selectedDisplayName = _categoryDisplayNames[index];
    List<StickerSet> setsForDisplay = [];

    developer.log("Updating to category: $selectedDisplayName", name: "StickerHomeScreen");

    if (selectedDisplayName == "Favourites") {
      _favoriteStickerNames = (await _prefsService.getFavoriteStickers()).toSet(); // Ensure it's fresh
      if (_favoriteStickerNames.isNotEmpty) {
        List<String> favStickerFileNames = [];
         // Iterating to maintain order if UserPreferencesService returns an ordered list (though it's a Set now)
        for (var name in await _prefsService.getFavoriteStickers()) { // get ordered list
            favStickerFileNames.add(name);
        }
        setsForDisplay.add(StickerSet(
            stickerSetName: "Favourites",
            stickerNames: favStickerFileNames,
            isLocked: false 
        ));
      }
    } else if (selectedDisplayName == "Recent") {
      _recentStickerNames = await _prefsService.getRecentStickers(); // Ensure it's fresh
      if (_recentStickerNames.isNotEmpty) {
        setsForDisplay.add(StickerSet(
            stickerSetName: "Recent",
            stickerNames: _recentStickerNames, // Already ordered List<String>
            isLocked: false
        ));
      }
    } else {
      int dataIndex = -1;
      // "Everyday" (index 2) maps to _allStickerData[1], "Happy" (index 3) to _allStickerData[2], etc.
      // "Info" (index 9) maps to _allStickerData[8]
      if (index >= 2 && (index -1) < _allStickerData.length) {
          dataIndex = index - 1; 
      }
      
      if (dataIndex != -1 && dataIndex < _allStickerData.length) {
        setsForDisplay = List<StickerSet>.from(_allStickerData[dataIndex]);
      } else {
        developer.log("Warning: Could not map category $selectedDisplayName to _allStickerData. Index: $index, DataIndex: $dataIndex", name: "StickerHomeScreen");
      }
    }
    
    if (mounted) {
      setState(() {
        _currentCategorySetsToDisplay = setsForDisplay;
        _isLoading = false;
      });
    }
  }

  /// Constructs the asset path for a given sticker.
  ///
  /// [stickerFileName] is the base name of the sticker (e.g., "IM_DAY5_0"), without extension.
  /// [originalSet] should be provided for stickers from static categories loaded from JSON.
  /// Its `stickerSetName` is used to determine the directory structure.
  /// For dynamic categories like "Favourites" or "Recent", [originalSet] will be null or its name will be "Favourites"/"Recent".
  /// In such cases, this method relies on `_stickerModel.getStickerDetails()` to fetch
  /// the necessary path components from the cache.
  Future<String> _getStickerAssetPath(String stickerFileName, {StickerSet? originalSet}) async {
    // Ensure stickerFileName is just the base name, no extension.
    stickerFileName = stickerFileName.replaceAll('.png', '').replaceAll('.webp', '');
    StickerIdentifierDetails? details;

    bool isDynamicCategorySet = originalSet?.stickerSetName == "Favourites" || originalSet?.stickerSetName == "Recent";

    if (originalSet != null && !isDynamicCategorySet) {
        // For static categories, derive details from originalSet's name.
        String setName = originalSet.stickerSetName!;
        List<String> nameParts = setName.split(" ");
        String baseCategoryKey = nameParts[0].toUpperCase(); // e.g., "EVERYDAY"
        String? setNumber;

        // Regex to find a number, possibly followed by " (Static)"
        // Example: "EVERYDAY 5" -> 5; "LOVE 2 (Static)" -> 2
        RegExpMatch? match = RegExp(r'(\d+)(?:\s*\(.*\))?$').firstMatch(setName.substring(baseCategoryKey.length).trim());
        if (match != null && match.groupCount > 0) {
            setNumber = match.group(1);
        } else if (nameParts.length > 1 && RegExp(r'^\d+$').hasMatch(nameParts[1])) {
            setNumber = nameParts[1]; // Fallback for simple "CATEGORY NUMBER"
        }

        details = StickerIdentifierDetails(
            stickerSetName: setName, 
            stickerFileName: stickerFileName, 
            mainCategoryKey: baseCategoryKey, 
            setNumber: setNumber
        );
    } else { 
        // For Favourites, Recents, or if originalSet info is insufficient, fetch from cache.
        details = await _stickerModel.getStickerDetails(stickerFileName);
    }

    if (details == null) {
        developer.log("Critical: No details found for $stickerFileName. Cannot construct path.", name: "StickerHomeScreen._getStickerAssetPath");
        return "assets/images/error_placeholder.png"; // Ensure this placeholder exists or handle differently
    }

    String categoryDir = _setNameToDirectoryMap[details.mainCategoryKey.toUpperCase()] ?? details.mainCategoryKey.capitalizeFirst();
    String? setNumberDir = details.setNumber;
    
    // Specific handling for categories with flat asset structures (no numeric subfolders for sets).
    if (categoryDir == "Festive" || categoryDir == "Photo" || categoryDir == "Sad") {
        return "assets/stickers/$categoryDir/$stickerFileName.png";
    }
    
    // For categories that use numbered subdirectories for sets.
    if (setNumberDir != null && setNumberDir.isNotEmpty) {
        return "assets/stickers/$categoryDir/$setNumberDir/$stickerFileName.png";
    }
    
    // Fallback if setNumberDir is not applicable (e.g. for some sets under a category that usually has numbered sets)
    // This might indicate an issue with stickerSetName format or mapping if reached unexpectedly.
    developer.log("Warning: Fallback path for $stickerFileName in $categoryDir (setNumberDir was null/empty). Original set name: ${details.stickerSetName}", name: "StickerHomeScreen._getStickerAssetPath");
    return "assets/stickers/$categoryDir/$stickerFileName.png";
}


  void _onStickerTap(String stickerName) async {
    developer.log("Sticker $stickerName tapped.", name: "StickerHomeScreen");
    await _prefsService.addRecentSticker(stickerName);
    if(mounted) {
      _recentStickerNames = await _prefsService.getRecentStickers();
      if (_categoryDisplayNames.elementAtOrNull(_selectedCategoryIndex) == "Recent") {
        await _updateCurrentCategorySetsAndDisplay(_selectedCategoryIndex);
      } else {
        // No need to call setState if only data for a non-visible category changed
      }
    }
  }

  void _toggleFavorite(String stickerName) async {
    bool isFav = _favoriteStickerNames.contains(stickerName);
    if (isFav) {
      await _prefsService.removeFavoriteSticker(stickerName);
    } else {
      await _prefsService.addFavoriteSticker(stickerName);
    }
    if(mounted) {
      _favoriteStickerNames = (await _prefsService.getFavoriteStickers()).toSet();
      if (_categoryDisplayNames.elementAtOrNull(_selectedCategoryIndex) == "Favourites") {
        await _updateCurrentCategorySetsAndDisplay(_selectedCategoryIndex);
      } else {
        setState(() {}); // Update icon state if visible on current screen
      }
    }
  }
  
  void _initiatePurchase(String productId) async {
    if (_iapProcessing) return;
    if (mounted) setState(() => _iapProcessing = true);
    ProductDetails? productDetails = _iapService.getProduct(productId);
    if (productDetails != null) {
      await _iapService.buyProduct(productDetails);
    } else {
      _handlePurchaseError("Product details not found for $productId. Try refreshing data.");
      if (mounted) setState(() => _iapProcessing = false);
    }
  }

  void _initiateRestorePurchases() async {
    if (_iapProcessing) return;
    if (mounted) setState(() => _iapProcessing = true );
    await _iapService.restorePurchases();
    // Callbacks handle UI update and _iapProcessing = false.
    // Adding a timeout for cases where the native IAP dialog might not return focus or callback isn't triggered.
     Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _iapProcessing) {
            developer.log("Restore timeout reached, ensuring UI is re-enabled.", name: "StickerHomeScreen");
            setState(() => _iapProcessing = false);
            // Optionally show a generic message if no specific restore callback was hit by then
            // _handleRestoreEmpty(); // Or a more generic "Restore attempt finished"
        }
    });
  }

  void _prepareForWhatsApp(StickerSet stickerSet) {
    final String publisherName = "Qoobee Agapi";
    Map<String, dynamic> exportData = _whatsAppExportService.prepareStickerPackForExport(stickerSet, publisherName);
    
    developer.log("---- WhatsApp Export Data for ${stickerSet.stickerSetName} ----", name: "StickerHomeScreen");
    developer.log("Pack Identifier: ${exportData['packIdentifier']}", name: "StickerHomeScreen");
    developer.log("Tray Icon: ${exportData['trayIconFileName']}", name: "StickerHomeScreen");
    developer.log("Sticker Files: ${exportData['stickerFileNames']}", name: "StickerHomeScreen");
    developer.log("contents.json Data: ${jsonEncode(exportData['contentsJsonData'])}", name: "StickerHomeScreen");
    developer.log("----------------------------------------------------", name: "StickerHomeScreen");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Preparing '${stickerSet.stickerSetName}' for WhatsApp. See console for data. Actual export requires native integration and WebP assets."),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qoobee Stickers'),
        actions: [
          if (_iapProcessing) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isLoading || _iapProcessing) ? null : _loadInitialData,
            tooltip: "Refresh Data & Products",
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'restore') _initiateRestorePurchases();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'restore', child: Text('Restore Purchases')),
            ],
          ),
        ],
      ),
      body: _isLoading && _iapProducts.isEmpty && _currentCategorySetsToDisplay.isEmpty // Show main loader only on initial cold start
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height:10), Text("Loading Stickers & Products...")]))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16))))
              : Column(
                  children: [
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categoryDisplayNames.length,
                        itemBuilder: (context, index) {
                          bool isSelected = _selectedCategoryIndex == index;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
                                foregroundColor: isSelected ? Colors.white : Colors.black,
                              ),
                              onPressed: () => _updateCurrentCategorySetsAndDisplay(index),
                              child: Text(_categoryDisplayNames[index]),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    if (_categoryDisplayNames.isNotEmpty && _selectedCategoryIndex < _categoryDisplayNames.length)
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                _categoryDisplayNames[_selectedCategoryIndex],
                                style: Theme.of(context).textTheme.headlineSmall,
                            ),
                        ),

                    Expanded(
                      child: (_isLoading) 
                        ? const Center(child: CircularProgressIndicator())
                        : (_currentCategorySetsToDisplay.isEmpty)
                            ? Center(
                                child: Text(
                                  _categoryDisplayNames.elementAtOrNull(_selectedCategoryIndex) == "Favourites"
                                    ? "You haven't added any favorite stickers yet!"
                                    : _categoryDisplayNames.elementAtOrNull(_selectedCategoryIndex) == "Recent"
                                      ? "No recently viewed stickers."
                                      : 'No stickers to display in "${_categoryDisplayNames.elementAtOrNull(_selectedCategoryIndex) ?? "this category"}".',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              )
                            : ListView.builder(
                                itemCount: _currentCategorySetsToDisplay.length,
                                itemBuilder: (context, setIndex) {
                                  final stickerSet = _currentCategorySetsToDisplay[setIndex];
                                  if (stickerSet.stickerNames == null || stickerSet.stickerNames!.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  bool isSetLocked = (stickerSet.purchaseId != null && 
                                                      stickerSet.purchaseId != "FREE" && 
                                                      !_purchasedProductIds.contains(stickerSet.purchaseId) &&
                                                      stickerSet.stickerSetName?.toUpperCase() != "FAVOURITES" &&
                                                      stickerSet.stickerSetName?.toUpperCase() != "RECENT" &&
                                                      stickerSet.stickerSetName?.toUpperCase() != "INFO"
                                                      );
                                  
                                  ProductDetails? productDetails;
                                  if(isSetLocked && stickerSet.purchaseId != null) {
                                    productDetails = _iapService.getProduct(stickerSet.purchaseId!);
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                stickerSet.stickerSetName ?? 'Unnamed Set',
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                            ),
                                            if (isSetLocked)
                                              productDetails != null
                                              ? ElevatedButton.icon(
                                                  icon: const Icon(Icons.shopping_cart, size: 16),
                                                  label: Text(productDetails.price),
                                                  onPressed: _iapProcessing ? null : () => _initiatePurchase(productDetails!.id),
                                                )
                                              : (_iapProducts.isEmpty && _isLoading ? const SizedBox.shrink() : const Text(" (Not for sale)", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                                            if (!isSetLocked && stickerSet.stickerSetName?.toUpperCase() != "FAVOURITES" && stickerSet.stickerSetName?.toUpperCase() != "RECENT" && stickerSet.stickerSetName?.toUpperCase() != "INFO")
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.add_circle_outline, size: 16), 
                                                label: const Text("Add to WhatsApp"),
                                                onPressed: () => _prepareForWhatsApp(stickerSet),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
                                              ),
                                          ],
                                        ),
                                      ),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(8.0),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4, crossAxisSpacing: 8.0, mainAxisSpacing: 8.0,
                                        ),
                                        itemCount: stickerSet.stickerNames!.length,
                                        itemBuilder: (context, stickerIndex) {
                                          final stickerName = stickerSet.stickerNames![stickerIndex];
                                          final bool isFav = _favoriteStickerNames.contains(stickerName);

                                          Widget imageWidget;
                                          if (selectedDisplayName == "Favourites" || selectedDisplayName == "Recent") {
                                            imageWidget = FutureBuilder<String>(
                                              future: _getStickerAssetPath(stickerName, originalSet: stickerSet), // Pass the synthetic Fav/Recent set
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1)));
                                                }
                                                if (snapshot.hasError || !snapshot.hasData || snapshot.data == "assets/images/error_placeholder.png") {
                                                  developer.log("Error in FutureBuilder for sticker path: ${snapshot.error}", name: "StickerHomeScreen");
                                                  return const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 24));
                                                }
                                                return Image.asset(snapshot.data!, fit: BoxFit.contain,
                                                  errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 24)),
                                                );
                                              }
                                            );
                                          } else {
                                            // For static categories, path can be constructed more directly if details are already in originalSet
                                            // However, to be safe and consistent, _getStickerAssetPath will handle it
                                            imageWidget = FutureBuilder<String>(
                                                future: _getStickerAssetPath(stickerName, originalSet: stickerSet),
                                                builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                        return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1)));
                                                    }
                                                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == "assets/images/error_placeholder.png") {
                                                        return const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 24));
                                                    }
                                                    return Image.asset(snapshot.data!, fit: BoxFit.contain,
                                                        errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 24)),
                                                    );
                                                }
                                            );
                                          }

                                          return GestureDetector(
                                            onTap: isSetLocked ? null : () => _onStickerTap(stickerName),
                                            child: Card(
                                              elevation: 1.0,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Padding(padding: const EdgeInsets.all(8.0), child: imageWidget),
                                                  if (isSetLocked)
                                                    Container(color: Colors.black.withOpacity(0.4), child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 32))),
                                                  if (!isSetLocked)
                                                    Positioned(
                                                      top: 0, right: 0,
                                                      child: IconButton(
                                                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.grey, size: 20),
                                                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                                        tooltip: isFav ? "Remove from Favourites" : "Add to Favourites",
                                                        onPressed: () => _toggleFavorite(stickerName),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                        ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.blueGrey[50],
                      child: const Center(
                        child: Text('Qoobee Flutter App - Placeholder Banner', style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
                      ),
                    ),
                  ],
                ),
    );
  }

   @override
  void dispose() {
    _iapService.dispose(); 
    super.dispose();
  }
}
