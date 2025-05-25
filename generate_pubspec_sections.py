import os

def generate_pubspec_sections_from_asset_list(asset_list_file):
    asset_paths = set()
    # pubspec_asset_entries = set() # Not directly used, final_asset_dirs is used

    try:
        with open(asset_list_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                asset_paths.add(line)
                
    except FileNotFoundError:
        print(f"Error: {asset_list_file} not found.")
        return None, None

    final_asset_dirs = set()
    for path_entry in asset_paths:
        dir_path = os.path.dirname(path_entry)
        if dir_path: 
            final_asset_dirs.add(dir_path + "/") 

    flutter_assets_section_str = "flutter:\n"
    flutter_assets_section_str += "  uses-material-design: true\n"
    flutter_assets_section_str += "  assets:\n"
    for entry in sorted(list(final_asset_dirs)):
        flutter_assets_section_str += f"    - {entry}\n"

    dependencies_section_str = "dependencies:\n"
    dependencies_section_str += "  flutter:\n"
    dependencies_section_str += "    sdk: flutter\n"
    dependencies_section_str += "  cupertino_icons: ^1.0.2\n"
    dependencies_section_str += "  in_app_purchase: ^3.1.0 # Or latest compatible\n"
    dependencies_section_str += "  shared_preferences: ^2.2.0 # Or latest compatible\n"
    dependencies_section_str += "  # For WebP/GIF display, consider packages like flutter_webp_and_gif or lottie:\n"
    dependencies_section_str += "  # e.g., flutter_cache_manager for network assets, or a local asset webp viewer\n"
    dependencies_section_str += "  # For WhatsApp integration or opening URLs:\n"
    dependencies_section_str += "  url_launcher: ^6.0.0 # Or latest compatible (check latest version)\n"
    # Added specific package suggestion for webp as per problem context
    dependencies_section_str += "  flutter_webp_and_gif: ^0.0.4 # Example, check for latest and suitability\n"


    return flutter_assets_section_str, dependencies_section_str

if __name__ == "__main__":
    asset_list_filename = "asset_list.txt"
    flutter_section, dependencies_section = generate_pubspec_sections_from_asset_list(asset_list_filename)

    if flutter_section and dependencies_section:
        try:
            with open("pubspec_sections.yaml", "w", encoding="utf-8") as f:
                f.write("# Generated flutter assets section\n")
                f.write(flutter_section)
                f.write("\n# Generated dependencies section\n")
                f.write(dependencies_section)
            print("Successfully generated pubspec_sections.yaml")
        except IOError as e:
            print(f"Error writing pubspec_sections.yaml: {e}")
    else:
        print("Failed to generate pubspec sections.")
