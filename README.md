# Surveyor Cam

A specialized photography app for surveyors with nested folder organization and AI OCR capabilities.

## Features

- **Nested Folder Structure**: Create unlimited nested folders (e.g., Project > Building > Room)
- **Fast Mode**: Zero shutter lag camera with instant photo saving
- **AI Mode**: Real-time text detection with OCR, tap to select and save asset tags
- **Level Gauge**: Visual indicator showing device tilt/horizontal alignment
- **Quick Tags**: Fast tagging system ([BAD], [GOOD], [FIX]) for photos
- **Breadcrumb Navigation**: Easy navigation through folder hierarchy
- **Dark Glass UI**: Modern, professional dark theme interface

## Tech Stack

- Flutter (Dart)
- Camera package for viewfinder
- Google ML Kit for on-device OCR
- Sensors Plus for accelerometer (level gauge)
- Path Provider for local file system management

## Setup

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Permissions

The app requires:
- Camera permission (for taking photos)
- Storage permission (for saving photos and folders)
- Microphone permission (optional, for future features)

## Project Structure

```
lib/
├── main.dart                  # Entry point, theme setup, permission checks
├── core/
│   ├── app_colors.dart        # Dark glass color palette
│   └── constants.dart         # App constants
├── logic/
│   ├── file_manager.dart      # Folder & file operations
│   └── permission_manager.dart # Permission handling
├── screens/
│   ├── camera_screen.dart     # Main camera screen
│   └── smart_review_screen.dart # AI text selection screen
└── widgets/
    ├── breadcrumb_bar.dart    # Top navigation bar
    ├── level_gauge.dart       # Tilt indicator
    ├── quick_tags.dart        # Tag buttons
    └── control_panel.dart     # Bottom controls
```

## Usage

1. **Create Folders**: Tap the grid icon in the top-right to create a new folder
2. **Navigate**: Tap breadcrumb items to navigate to parent folders
3. **Take Photos**: Tap the white shutter button to capture photos
4. **Use Tags**: Tap [BAD], [GOOD], or [FIX] buttons to tag the next photo
5. **AI Mode**: Toggle the green AI button to enable text detection
   - In AI mode, tap the shutter to freeze the frame
   - Tap detected text boxes to select them
   - Selected text is saved to `Asset_Data.txt` in the current folder

## Notes

- Photos are saved locally in the app's documents directory
- Asset data is appended to `Asset_Data.txt` in each folder
- The app is locked to portrait orientation
- All file operations are asynchronous to maintain UI responsiveness

