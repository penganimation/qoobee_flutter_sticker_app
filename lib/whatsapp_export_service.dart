import 'dart:convert'; // For jsonEncode if needed for logging, though returning Map is primary
import 'sticker_set.dart'; // Assuming sticker_set.dart is in the same directory
import 'dart:developer' as developer;

class WhatsAppExportService {
  // Generates a unique, safe identifier for the sticker pack.
  // Example: com.app.everyday5 -> com_app_everyday5
  // Example: "EVERYDAY 5 (Static)" -> everyday_5_static
  String _generatePackIdentifier(StickerSet stickerSet) {
    String baseId;
    if (stickerSet.purchaseId != null && stickerSet.purchaseId!.isNotEmpty && stickerSet.purchaseId != "FREE") {
      baseId = stickerSet.purchaseId!;
    } else if (stickerSet.stickerSetName != null && stickerSet.stickerSetName!.isNotEmpty) {
      baseId = stickerSet.stickerSetName!;
    } else {
      // Fallback if both are null/empty, though unlikely for valid sets
      baseId = DateTime.now().millisecondsSinceEpoch.toString();
    }
    // Sanitize the baseId: replace non-alphanumeric with underscore, convert to lowercase
    String sanitizedId = baseId
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_{2,}'), '_'); // Replace multiple underscores with one

    // Ensure it doesn't start or end with an underscore
    if (sanitizedId.startsWith('_')) {
        sanitizedId = sanitizedId.substring(1);
    }
    if (sanitizedId.endsWith('_')) {
        sanitizedId = sanitizedId.substring(0, sanitizedId.length -1);
    }
    // WhatsApp identifiers often have a limit, e.g., 128 chars, and need to be unique.
    // For now, this basic sanitization should suffice for generating a Dart-side ID.
    // Actual native requirements might need more specific formatting.
    if (sanitizedId.isEmpty) { // Should not happen with valid inputs
        return "pack_${DateTime.now().millisecondsSinceEpoch}";
    }
    return sanitizedId;
  }

  Map<String, dynamic> generateContentsJson(
      StickerSet stickerSet, String publisherName, String packIdentifier, String trayIconFileName) {
    
    List<Map<String, dynamic>> stickersList = [];
    if (stickerSet.stickerNames != null) {
      for (String stickerName in stickerSet.stickerNames!) {
        // Assume stickerName is like "IM_DAY5_0", needs ".webp"
        String imageFileName = stickerName.endsWith('.webp') ? stickerName : "$stickerName.webp";
        stickersList.add({
          "image_file": imageFileName,
          "emojis": ["😄", "😊"], // Default emojis
        });
      }
    }

    // Basic structure for contents.json
    // WhatsApp has specific requirements for this structure, including mandatory fields.
    // See WhatsApp developer documentation for the exact current specification.
    Map<String, dynamic> contents = {
      "identifier": packIdentifier,
      "name": stickerSet.stickerSetName ?? "Unnamed Pack",
      "publisher": publisherName,
      "tray_image_file": trayIconFileName, // e.g., "tray_icon.webp"
      "publisher_email": "", // Optional, but good to include
      "publisher_website": "", // Optional
      "privacy_policy_website": "", // Optional
      "license_agreement_website": "", // Optional
      "stickers": stickersList,
      // As per WhatsApp sample:
      "android_play_store_link": "", // Optional
      "ios_app_store_link": "", // Optional
      // Some implementations might also include:
      // "image_data_version": "1", // If you update sticker images but not the config
      // "avoid_cache": false, // Whether WhatsApp should cache the stickers
    };
    
    // Add animated_sticker_pack and image_data_version if it's an animated pack (heuristic)
    // This is a placeholder. Actual detection of animated might be more complex
    // (e.g., based on stickerSetName or a property of StickerSet if available).
    // For now, assuming static WebP based on the problem description focusing on WebP filenames.
    // contents["animated_sticker_pack"] = false; // default to false (static)

    developer.log("Generated contents.json structure for pack: $packIdentifier", name: "WhatsAppExportService");
    return contents;
  }

  Map<String, dynamic> prepareStickerPackForExport(StickerSet stickerSet, String publisherName) {
    // 1. Generate a unique pack identifier
    String packIdentifier = _generatePackIdentifier(stickerSet);

    // 2. Define the placeholder tray icon filename
    // This should be a 96x96 WebP file, under 50KB.
    // The actual file needs to be created by the developer and placed in an appropriate asset location
    // for the native WhatsApp export code to pick up.
    String trayIconFileName = "${packIdentifier}_tray.webp"; // Or a generic one like "qoobee_tray_placeholder.webp"
                                                          // Using a pack-specific one for better future-proofing if one generic isn't used.
                                                          // For the problem: "qoobee_tray_placeholder.webp"
    trayIconFileName = "qoobee_tray_placeholder.webp";


    // 3. Generate contents.json data
    Map<String, dynamic> contentsJsonData =
        generateContentsJson(stickerSet, publisherName, packIdentifier, trayIconFileName);

    // 4. Asset Identification: List of WebP sticker filenames
    List<String> stickerWebPFileNames = [];
    if (stickerSet.stickerNames != null) {
      for (String stickerName in stickerSet.stickerNames!) {
        stickerWebPFileNames.add(stickerName.endsWith('.webp') ? stickerName : "$stickerName.webp");
      }
    }

    developer.log("Prepared pack for export: $packIdentifier. Stickers: ${stickerWebPFileNames.length}", name: "WhatsAppExportService");

    return {
      "contentsJsonData": contentsJsonData,
      "stickerFileNames": stickerWebPFileNames,
      "trayIconFileName": trayIconFileName,
      "packIdentifier": packIdentifier,
    };
  }
}
