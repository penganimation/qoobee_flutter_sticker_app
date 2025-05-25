import json
import os
import re

# Hardcoded ls() output relevant for asset path generation
LS_OUTPUT_STRUCTURE = {
    "Qoobee-imessage-2024 MessagesExtension": {
        "Angry": {"1": {}, "2": {}},
        "Everyday": {"1": {}, "2": {}, "3": {}, "4": {}, "5": {}},
        "Festive": {}, # Direct files, no subfolders like 1, 2
        "Happy": {"1": {}, "2": {}, "3": {}, "4": {}, "5": {}},
        "Love": {"1": {}, "2": {}, "3": {}, "4": {}}, # ls shows Love3_x.png directly under Love/4, not Love/Love3/
        "Photo": {}, # Direct files
        "Sad": {}    # Direct files
    }
}

# Mapping from stickerSetName prefix to directory name if different
STICKER_SET_NAME_TO_DIR_MAP = {
    "ANNOYED": "Angry",
    "EVERYDAY": "Everyday",
    "FESTIVE": "Festive",
    "HAPPY": "Happy",
    "LOVE": "Love",
    "PHOTO": "Photo",
    "SAD": "Sad"
}

def get_sticker_file_path(sticker_set_name, sticker_name):
    """
    Generates the expected original file path for a sticker
    based on stickerSetName and stickerName.
    Example: stickerSetName "EVERYDAY 1", stickerName "Everyday0_0"
    -> "Qoobee-imessage-2024 MessagesExtension/Everyday/1/Everyday0_0.png"
    """
    parts = sticker_set_name.split(" ")
    category_prefix = parts[0].upper()
    
    dir_category = STICKER_SET_NAME_TO_DIR_MAP.get(category_prefix, category_prefix.capitalize())

    sub_category_number = None
    if len(parts) > 1 and parts[1].isdigit():
        sub_category_number = parts[1]
    
    # Handle cases like "EVERYDAY 5" or "LOVE 4" where sticker files are directly in a numbered subfolder
    # Handle "FESTIVE 1", "FESTIVE 2" where files are directly under "Festive"
    # Handle "SAD 1", "ANNOYED 1", "PHOTO 1" where files are directly under category dir.

    base_path = "Qoobee-imessage-2024 MessagesExtension"

    if dir_category == "Festive":
        # Festive stickers like Festive0_0.png, Festive1_1.png are directly under Festive/
        return f"{base_path}/{dir_category}/{sticker_name}.png"
    elif dir_category in ["Photo", "Sad"]:
         # Photo/Camera0_0.png, Sad/Sad0_0.png
        return f"{base_path}/{dir_category}/{sticker_name}.png"
    elif dir_category == "Angry" and sub_category_number == "1": # ANNOYED 1 -> Angry/1/Angry0_0.png
        return f"{base_path}/{dir_category}/1/{sticker_name}.png"
    elif dir_category == "Angry" and sub_category_number == "2": # ANNOYED 2 -> Angry/2/Angry1_0.png
        return f"{base_path}/{dir_category}/2/{sticker_name}.png"

    if sub_category_number:
        # Check if this path structure exists in LS_OUTPUT_STRUCTURE
        if dir_category in LS_OUTPUT_STRUCTURE[base_path] and \
           sub_category_number in LS_OUTPUT_STRUCTURE[base_path][dir_category]:
            return f"{base_path}/{dir_category}/{sub_category_number}/{sticker_name}.png"
    
    # Fallback for simple category/sticker_name.png if specific subfolder logic doesn't match
    # This might be needed for sets like "LOVE 4" where sticker names are "Love3_0"
    # and ls output shows them under Qoobee-imessage-2024 MessagesExtension/Love/4/Love3_0.png
    # The stickerSetName "LOVE 4" maps to category "Love", sub_category "4".
    # The stickerName is "Love3_0". This seems consistent.

    # Default if no specific sub_category number is identified or structure is simpler
    # This case should ideally be covered by the specific dir_category checks above.
    # If still here, it means the stickerSetName didn't clearly map to a known path structure.
    # For "LOVE 4", sticker names "Love3_0", path is Love/4/Love3_0.png.
    # The `sub_category_number` from "LOVE 4" is "4".
    if sub_category_number:
         return f"{base_path}/{dir_category}/{sub_category_number}/{sticker_name}.png"

    # If no sub_category_number, assume direct under category e.g. Placeholder/sticker.png
    # This should not happen with current data.
    print(f"Warning: Could not determine path for {sticker_set_name} - {sticker_name}")
    return f"{base_path}/{dir_category}/{sticker_name}.png"


def generate_flutter_asset_paths():
    all_asset_paths = set()

    # 1. Process Stickers
    try:
        with open("all_stickers_data.json", "r", encoding="utf-8") as f:
            sticker_data_categories = json.load(f)
    except FileNotFoundError:
        print("Error: all_stickers_data.json not found.")
        return []
    except json.JSONDecodeError:
        print("Error: Could not decode all_stickers_data.json.")
        return []

    for category_array in sticker_data_categories:
        for sticker_pack in category_array:
            sticker_set_name = sticker_pack.get("stickerSetName", "")
            sticker_names = sticker_pack.get("stickerNames", [])

            if not sticker_set_name or not sticker_names: # Skip packs like FAVOURITES/RECENT if they have no names
                if sticker_set_name.upper() not in ["FAVOURITES", "RECENT", "INFO"]: # Don't warn for these known empty packs
                    # print(f"Skipping pack with no name or stickers: {sticker_set_name}")
                    pass
                continue
            
            set_name_parts = sticker_set_name.split(" ")
            main_category_name_original = set_name_parts[0]
            main_category_name_for_path = STICKER_SET_NAME_TO_DIR_MAP.get(
                main_category_name_original.upper(), 
                main_category_name_original.capitalize()
            )

            sub_folder_number = ""
            # Try to find a number in the sticker set name parts, e.g. "EVERYDAY 5" -> 5
            for part in set_name_parts:
                if part.isdigit():
                    sub_folder_number = part
                    break
            
            flutter_asset_base = f"assets/stickers/{main_category_name_for_path}"
            if sub_folder_number:
                # Ensure this sub_folder_number actually corresponds to a directory from ls
                # e.g. "LOVE 4" -> Love/4/
                # e.g. "ANNOYED 2 (Static)" -> Angry/2/
                # This check is implicitly handled by how source paths would be formed later,
                # but for Flutter asset paths, we construct them predictively.
                flutter_asset_base += f"/{sub_folder_number}"
            # For sets like "FESTIVE 1", "SAD 1", the sub_folder_number might be "1"
            # but the files are directly under "Festive/" or "Sad/".
            # The get_sticker_file_path has more nuanced logic for original paths.
            # For Flutter paths, we simplify: if "FESTIVE 1", path is assets/stickers/Festive/1/
            # This means we need to ensure our copy logic later can find original files from these Flutter paths.
            # Or, adjust Flutter path generation to match original structure more closely where subfolders aren't numeric.
            # The current problem asks for CATEGORY/SUB_CATEGORY, implying numeric if SUB_CATEGORY exists.

            if main_category_name_for_path in ["Festive", "Photo", "Sad"]:
                 # These categories do not have numeric subfolders in the source structure for all their sets.
                 # Example: Festive1_1.png is under "Festive/", not "Festive/1/" or "Festive/2/"
                 # "FESTIVE 1" and "FESTIVE 2" are set names, not direct folder structures.
                 # We will place them under assets/stickers/Festive/ (without a sub_folder_number from set name)
                 # This means sticker names must be unique across all "Festive" sets.
                 flutter_asset_base = f"assets/stickers/{main_category_name_for_path}"


            for s_name in sticker_names:
                flutter_asset_path = f"{flutter_asset_base}/{s_name}.png"
                all_asset_paths.add(flutter_asset_path)

    # 2. Process UI Assets
    ui_assets_mappings = {
        "Assets.xcassets/New Sticker Indicator.imageset/New Sticker Indicator.png": "assets/ui_elements/New Sticker Indicator.png",
        "Assets.xcassets/RestoreIcon.imageset/RestoreIcon.png": "assets/ui_elements/RestoreIcon.png",
        "Assets.xcassets/ShoppingBagWhite.imageset/ShoppingBagWhite.png": "assets/ui_elements/ShoppingBagWhite.png",
        "Assets.xcassets/whatsapp.imageset/whatsapp-3.png": "assets/ui_elements/whatsapp.png",
        "Qoobee-imessage-2024 MessagesExtension/Backgrounds/AddBanner.png": "assets/ui_elements/AddBanner.png",
        "Qoobee-imessage-2024 MessagesExtension/Backgrounds/Background.png": "assets/ui_elements/Background.png",
        "Qoobee-imessage-2024 MessagesExtension/Backgrounds/QooBeeInfo.png": "assets/ui_elements/QooBeeInfo.png",
        "Qoobee-imessage-2024 MessagesExtension/Backgrounds/RemoveBanner.png": "assets/ui_elements/RemoveBanner.png",
        "Qoobee-imessage-2024 MessagesExtension/Backgrounds/UnlockBanner.png": "assets/ui_elements/UnlockBanner.png",
        "Assets.xcassets/iMessage App Icon.stickersiconset/marketing-1024x1024.png": "assets/ui_elements/app_logo_large.png",
        "Assets.xcassets/iMessage App Icon.stickersiconset/marketing-1024x768.png": "assets/ui_elements/app_logo_wide.png"
    }

    for i in range(9): # Banner0.png to Banner8.png
        ui_assets_mappings[f"Qoobee-imessage-2024 MessagesExtension/Banners/Banner{i}.png"] = f"assets/ui_elements/Banner{i}.png"
    ui_assets_mappings["Qoobee-imessage-2024 MessagesExtension/Banners/FooterBanner.png"] = "assets/ui_elements/FooterBanner.png"

    for original_path, flutter_path in ui_assets_mappings.items():
        all_asset_paths.add(flutter_path)
        
    # Add .webp files from FestiveWA as they are, under a specific webp asset path
    # These are not stickers in the traditional png sense for this script's main logic.
    # The problem mentions "flutter_webp_and_gif" for these.
    # Based on ls: Qoobee-imessage-2024 MessagesExtension/FestiveWA/
    festive_wa_path = "Qoobee-imessage-2024 MessagesExtension/FestiveWA/"
    festive_wa_files = [
        "WhatsApp_Annoyed1_Static_FD1.webp",
        "wa_day_festive_fd491.webp",
        "wa_day_festive_fd492.webp",
        "wa_day_festive_fd493.webp",
        "wa_day_festive_fd494.webp",
        "wa_day_festive_fd495.webp",
        "wa_day_festive_fd496.webp",
        "wa_day_festive_tray.webp"
    ]
    for f_name in festive_wa_files:
        all_asset_paths.add(f"assets/stickers_webp/FestiveWA/{f_name}")


    return sorted(list(all_asset_paths))

if __name__ == "__main__":
    asset_paths = generate_flutter_asset_paths()
    if asset_paths:
        try:
            with open("asset_list.txt", "w", encoding="utf-8") as f:
                for path in asset_paths:
                    f.write(path + "\n")
            print(f"Successfully generated asset_list.txt with {len(asset_paths)} asset paths.")
        except IOError as e:
            print(f"Error writing asset_list.txt: {e}")
    else:
        print("No asset paths were generated.")
