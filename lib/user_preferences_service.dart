import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class UserPreferencesService {
  static const String _favoritesKey = 'favorite_stickers';
  static const String _recentsKey = 'recent_stickers';
  static const String _purchasedProductsKey = 'purchased_product_ids'; // New key for IAP
  static const int _maxRecents = 30;

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  // Favorites Methods
  Future<List<String>> getFavoriteStickers() async {
    final SharedPreferences prefs = await _getPrefs();
    try {
      return prefs.getStringList(_favoritesKey) ?? [];
    } catch (e) {
      developer.log("Error getting favorite stickers: $e", name: "UserPreferencesService");
      return [];
    }
  }

  Future<void> addFavoriteSticker(String stickerName) async {
    final SharedPreferences prefs = await _getPrefs();
    try {
      List<String> favorites = await getFavoriteStickers();
      if (!favorites.contains(stickerName)) {
        favorites.add(stickerName);
        await prefs.setStringList(_favoritesKey, favorites);
        developer.log("Added $stickerName to favorites", name: "UserPreferencesService");
      }
    } catch (e) {
      developer.log("Error adding favorite sticker $stickerName: $e", name: "UserPreferencesService");
    }
  }

  Future<void> removeFavoriteSticker(String stickerName) async {
    final SharedPreferences prefs = await _getPrefs();
    try {
      List<String> favorites = await getFavoriteStickers();
      if (favorites.contains(stickerName)) {
        favorites.remove(stickerName);
        await prefs.setStringList(_favoritesKey, favorites);
        developer.log("Removed $stickerName from favorites", name: "UserPreferencesService");
      }
    } catch (e) {
      developer.log("Error removing favorite sticker $stickerName: $e", name: "UserPreferencesService");
    }
  }

  Future<bool> isFavorite(String stickerName) async {
    try {
      List<String> favorites = await getFavoriteStickers();
      return favorites.contains(stickerName);
    } catch (e) {
      developer.log("Error checking if $stickerName is favorite: $e", name: "UserPreferencesService");
      return false;
    }
  }

  // Recents Methods
  Future<List<String>> getRecentStickers() async {
    final SharedPreferences prefs = await _getPrefs();
    try {
      return prefs.getStringList(_recentsKey) ?? [];
    } catch (e) {
      developer.log("Error getting recent stickers: $e", name: "UserPreferencesService");
      return [];
    }
  }

  Future<void> addRecentSticker(String stickerName) async {
    final SharedPreferences prefs = await _getPrefs();
    try {
      List<String> recents = await getRecentStickers();
      recents.remove(stickerName);
      recents.insert(0, stickerName); 

      if (recents.length > _maxRecents) {
        recents = recents.sublist(0, _maxRecents);
      }
      await prefs.setStringList(_recentsKey, recents);
      developer.log("Added $stickerName to recents", name: "UserPreferencesService");
    } catch (e) {
      developer.log("Error adding recent sticker $stickerName: $e", name: "UserPreferencesService");
    }
  }

  // IAP Purchase Methods
  Future<void> savePurchasedProduct(String purchaseId) async {
    final SharedPreferences prefs = await _getPrefs();
    try {
      List<String> purchasedIds = prefs.getStringList(_purchasedProductsKey) ?? [];
      if (!purchasedIds.contains(purchaseId)) {
        purchasedIds.add(purchaseId);
        await prefs.setStringList(_purchasedProductsKey, purchasedIds);
        developer.log("Saved purchased product: $purchaseId", name: "UserPreferencesService");
      }
    } catch (e) {
      developer.log("Error saving purchased product $purchaseId: $e", name: "UserPreferencesService");
    }
  }

  Future<bool> isProductPurchased(String purchaseId) async {
    final SharedPreferences prefs = await _getPrefs();
    try {
      List<String> purchasedIds = prefs.getStringList(_purchasedProductsKey) ?? [];
      return purchasedIds.contains(purchaseId);
    } catch (e) {
      developer.log("Error checking if product $purchaseId is purchased: $e", name: "UserPreferencesService");
      return false; // Default to not purchased on error
    }
  }

  Future<Set<String>> getAllPurchasedProductIds() async {
    final SharedPreferences prefs = await _getPrefs();
    try {
      List<String> purchasedIdsList = prefs.getStringList(_purchasedProductsKey) ?? [];
      return purchasedIdsList.toSet();
    } catch (e) {
      developer.log("Error getting all purchased product IDs: $e", name: "UserPreferencesService");
      return {};
    }
  }
}
