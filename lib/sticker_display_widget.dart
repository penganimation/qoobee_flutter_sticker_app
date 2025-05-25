import 'package:flutter/material.dart';
import 'sticker_model.dart';
import 'sticker_set.dart';
import 'dart:developer' as developer; // For logging

class StickerDisplayExample extends StatefulWidget {
  const StickerDisplayExample({super.key});

  @override
  State<StickerDisplayExample> createState() => _StickerDisplayExampleState();
}

class _StickerDisplayExampleState extends State<StickerDisplayExample> {
  late Future<List<List<StickerSet>>> _stickerDataFuture;
  late Future<Set<String>> _productIdsFuture;
  final StickerModel _stickerModel = StickerModel();

  // Simplified mapping based on common patterns observed
  // This would need to be more robust in a real application
  final Map<String, String> _setNameToDirectoryMap = {
    "EVERYDAY": "Everyday",
    "HAPPY": "Happy",
    "LOVE": "Love",
    "SAD": "Sad",
    "ANNOYED": "Angry", // As per ls output, ANNOYED maps to Angry directory
    "FESTIVE": "Festive",
    "PHOTO": "Photo",
  };

  @override
  void initState() {
    super.initState();
    _stickerDataFuture = _stickerModel.getAllStickerData();
    _productIdsFuture = _stickerModel.getAllProductIdentifiers();
  }

  String? _getFirstStickerAssetPath(List<List<StickerSet>> categories) {
    for (var category in categories) {
      for (var stickerSet in category) {
        if (stickerSet.stickerNames != null && stickerSet.stickerNames!.isNotEmpty) {
          String? setName = stickerSet.stickerSetName;
          if (setName == null || setName.isEmpty) continue;

          List<String> parts = setName.split(" ");
          String categoryNamePart = parts[0].toUpperCase();
          String? subDirNumber;

          String mappedCategoryDir = _setNameToDirectoryMap[categoryNamePart] ?? categoryNamePart.toLowerCase();
          
          // Try to find a number for sub-directory
          for (int i = 1; i < parts.length; i++) {
            if (RegExp(r'^\d+$').hasMatch(parts[i])) {
              subDirNumber = parts[i];
              break;
            }
          }
          
          String stickerFileName = stickerSet.stickerNames![0];
          // Ensure stickerFileName ends with .png; if not, append it.
          // The names in JSON (e.g., IM_DAY5_0) don't have extensions.
          if (!stickerFileName.toLowerCase().endsWith('.png')) {
            stickerFileName += '.png';
          }

          if (subDirNumber != null) {
            return 'assets/stickers/$mappedCategoryDir/$subDirNumber/$stickerFileName';
          } else {
            // Handle cases like "FESTIVE 1" where files might be directly under "Festive"
            // or "PHOTO 1" under "Photo". The current logic in generate_asset_list.py
            // creates paths like assets/stickers/Festive/Festive0_0.png based on sticker names.
            // We need to align this.
            // If the stickerSetName is "FESTIVE 1" and sticker name is "Festive0_0",
            // path is assets/stickers/Festive/Festive0_0.png
            // The subDirNumber logic above might incorrectly make it /Festive/1/Festive0_0.png
            // Let's refine: if mappedCategoryDir is one of those with flat structure...
             if (["Festive", "Photo", "Sad"].contains(mappedCategoryDir)) {
                return 'assets/stickers/$mappedCategoryDir/$stickerFileName';
            }
            // If there's a number in the set name but it's not a separate subdir in asset path,
            // this might still be an issue. The asset_list.txt generation used a slightly different logic.
            // For now, this is a heuristic.
            return 'assets/stickers/$mappedCategoryDir/$stickerFileName'; // Fallback if no number
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker Display Example'),
      ),
      body: Center(
        child: FutureBuilder<List<List<StickerSet>>>(
          future: _stickerDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              developer.log('Error loading sticker data: ${snapshot.error}', name: 'StickerDisplay');
              return Text('Error loading sticker data: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final String? firstStickerPath = _getFirstStickerAssetPath(snapshot.data!);
              final String webPPath = 'assets/stickers_webp/FestiveWA/WhatsApp_Annoyed1_Static_FD1.webp'; // Hardcoded example

              // Log product IDs for verification
              _productIdsFuture.then((ids) {
                 developer.log('Product IDs: $ids', name: 'StickerDisplay');
              }).catchError((e) {
                 developer.log('Error fetching product IDs: $e', name: 'StickerDisplay');
              });

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (firstStickerPath != null)
                    Column(
                      children: [
                        Text('First PNG Sticker: $firstStickerPath'),
                        Image.asset(
                          firstStickerPath,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            developer.log('Error loading PNG image: $firstStickerPath, Error: $error', name: 'StickerDisplay');
                            return Text('Error loading image: $firstStickerPath');
                          },
                        ),
                      ],
                    )
                  else
                    const Text('No PNG stickers found to display.'),
                  const SizedBox(height: 20),
                  // WebP Bonus
                  // Note: Image.asset might work for WebP if flutter_webp_and_gif is correctly set up
                  // and handles it transparently. Otherwise, a specific widget from the package might be needed.
                  // For this example, we'll try with Image.asset.
                  Column(
                    children: [
                      Text('WebP Sticker Example: $webPPath'),
                      Image.asset(
                        webPPath,
                        width: 100,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          developer.log('Error loading WebP image: $webPPath, Error: $error', name: 'StickerDisplay');
                          return Text('Error loading WebP image. Ensure flutter_webp_and_gif is set up if needed. Path: $webPPath');
                        },
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return const Text('No sticker data found.');
            }
          },
        ),
      ),
    );
  }
}
