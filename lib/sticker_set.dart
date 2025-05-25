// Defines the StickerSet class and its JSON parsing logic.

class StickerSet {
  final String? purchaseId;
  final bool isLocked;
  final String? stickerSetName;
  final List<String>? stickerNames;

  StickerSet({
    this.purchaseId,
    this.isLocked = false, // Default to false
    this.stickerSetName,
    this.stickerNames,
  });

  factory StickerSet.fromJson(Map<String, dynamic> json) {
    var stickerNamesFromJson = json['stickerNames'];
    List<String>? stickerNamesList;
    if (stickerNamesFromJson is List) {
      stickerNamesList = List<String>.from(stickerNamesFromJson.map((item) => item.toString()));
    }

    // Default isLocked to false if json['isLocked'] is null.
    // If json['isLocked'] has a value (true or false), use that value.
    bool lockedStatus = false; // Default if not present or null
    if (json['isLocked'] != null) {
        lockedStatus = json['isLocked'] as bool;
    }
    // The problem statement also said: "Set to true if purchaseId is not "FREE". 
    // Set to false if purchaseId is "FREE" or for special categories"
    // This logic should be handled by the script that *generates* all_stickers_data.json.
    // The StickerSet.fromJson factory should primarily reflect the direct data from the JSON.
    // The isLocked value in the JSON is the one pre-calculated by the Python script.

    return StickerSet(
      purchaseId: json['purchaseId'] as String?,
      isLocked: lockedStatus,
      stickerSetName: json['stickerSetName'] as String?,
      stickerNames: stickerNamesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'isLocked': isLocked,
      'stickerSetName': stickerSetName,
      'stickerNames': stickerNames,
    };
  }
}
