import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'sticker_set.dart';
import 'dart:developer' as developer;

// A simple class to hold identifying details for a sticker, useful for lookups.
class StickerIdentifierDetails {
  final String stickerSetName; // Original name of the set, e.g., "EVERYDAY 5"
  final String stickerFileName; // Base name, e.g., "IM_DAY5_0" (without extension)
  // Add any other details needed to reconstruct the path or display info
  // For example, the main category key like "EVERYDAY" or "HAPPY"
  final String mainCategoryKey; // e.g. "EVERYDAY"
  final String? setNumber; // e.g. "5" from "EVERYDAY 5"

  StickerIdentifierDetails({
    required this.stickerSetName,
    required this.stickerFileName,
    required this.mainCategoryKey,
    this.setNumber,
  });
}

class StickerModel {
  List<List<StickerSet>> _allStickerDataCache = [];
  Map<String, StickerIdentifierDetails> _stickerDetailsCache = {};
  bool _isDataLoaded = false;

  Future<void> _ensureDataLoaded() async {
    if (!_isDataLoaded) {
      await getAllStickerData(); // This will load and populate caches
    }
  }

  Future<List<List<StickerSet>>> getAllStickerData() async {
    if (_isDataLoaded) {
      // developer.log("Returning cached sticker data", name: "StickerModel");
      return _allStickerDataCache;
    }

    developer.log("Loading sticker data from JSON", name: "StickerModel");
    try {
      final String jsonString = await rootBundle.loadString('assets/all_stickers_data.json');
      final List<dynamic> parsedOuterList = json.decode(jsonString);
      
      List<List<StickerSet>> stickerData = [];
      Map<String, StickerIdentifierDetails> tempDetailsCache = {};

      for (var categoryListDynamic in parsedOuterList) {
        if (categoryListDynamic is List) {
          List<StickerSet> categorySets = [];
          for (var stickerPackJson in categoryListDynamic) {
            if (stickerPackJson is Map<String, dynamic>) {
              try {
                StickerSet set = StickerSet.fromJson(stickerPackJson);
                categorySets.add(set);

                if (set.stickerSetName != null && set.stickerNames != null) {
                  String setName = set.stickerSetName!;
                  List<String> nameParts = setName.split(" ");
                  String mainCategoryKey = nameParts[0].toUpperCase();
                  String? setNumber;
                  if (nameParts.length > 1 && RegExp(r'^\d+$').hasMatch(nameParts[1])) {
                    setNumber = nameParts[1];
                  } else if (nameParts.length > 2 && RegExp(r'^\d+$').hasMatch(nameParts[1]) && nameParts[2].startsWith('(')) {
                    setNumber = nameParts[1];
                  }

                  for (String stickerName in set.stickerNames!) {
                    // Key for cache should be the base name (without .png)
                    tempDetailsCache[stickerName] = StickerIdentifierDetails(
                      stickerSetName: setName,
                      stickerFileName: stickerName,
                      mainCategoryKey: mainCategoryKey,
                      setNumber: setNumber,
                    );
                  }
                }
              } catch (e) {
                developer.log('Error parsing a sticker pack: $stickerPackJson Error: $e', name: "StickerModel");
              }
            }
          }
          stickerData.add(categorySets);
        }
      }
      _allStickerDataCache = stickerData;
      _stickerDetailsCache = tempDetailsCache;
      _isDataLoaded = true;
      developer.log("Sticker data and details cache populated. ${_stickerDetailsCache.length} individual stickers cached.", name: "StickerModel");
      return stickerData;
    } catch (e, stackTrace) {
      developer.log('Error loading or parsing all_stickers_data.json: $e', name: "StickerModel", error: e, stackTrace: stackTrace);
      _isDataLoaded = false; // Ensure we attempt to load again if it fails
      return []; 
    }
  }

  Future<StickerIdentifierDetails?> getStickerDetails(String stickerName) async {
    await _ensureDataLoaded();
    if (_stickerDetailsCache.containsKey(stickerName)) {
      return _stickerDetailsCache[stickerName];
    }
    developer.log("Sticker details not found for: $stickerName", name: "StickerModel");
    return null;
  }


  Future<Set<String>> getAllProductIdentifiers() async {
    await _ensureDataLoaded(); // Ensures _allStickerDataCache is populated
    final Set<String> productIdentifiers = {};

    for (List<StickerSet> category in _allStickerDataCache) {
      for (StickerSet pack in category) {
        if (pack.purchaseId != null && 
            pack.purchaseId!.isNotEmpty &&
            pack.purchaseId != "FREE") {
          productIdentifiers.add(pack.purchaseId!);
        }
      }
    }
    return productIdentifiers;
  }
}
