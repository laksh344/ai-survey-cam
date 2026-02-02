# 📸 Surveyor Cam

**A specialized photography app for surveyors featuring nested folder organization, AI OCR capabilities, and professional field tools.**

![Surveyor Cam Screenshots](cam.png)
> *From left to right: Main Camera UI with Level Gauge, Creating a Nested Folder, Breadcrumb Navigation (Project > Line), and Folder Details View.*

## 🚀 Features

- **📂 Nested Folder Structure** Create unlimited nested folders (e.g., `Project` > `Building` > `Room`) to keep site photos organized instantly.

- **⚡ Fast Mode** Zero shutter lag camera optimized for rapid field work.

- **🤖 AI Mode (OCR)** Real-time text detection using Google ML Kit. Tap to select specific text on machinery or signs and save it directly to an asset log.

- **📐 Level Gauge** Integrated visual crosshair indicator showing device tilt and horizontal alignment for perfect shots.

- **🏷️ Quick Tags** One-tap tagging system (`[BAD]`, `[GOOD]`, `[FIX]`) to categorize photos as you take them.

- **nav Breadcrumb Navigation** Interactive top bar to easily navigate back through your folder hierarchy.

- **🌑 Dark Glass UI** Modern, high-contrast dark theme designed for outdoor visibility and battery efficiency.

---

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **Vision:** Camera Package & Google ML Kit (OCR)
* **Sensors:** Sensors Plus (Accelerometer/Level Gauge)
* **Storage:** Path Provider (Local File System)

---

## ⚙️ Setup

1.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Run the app:**
    ```bash
    flutter run
    ```

### Permissions
The app requires the following permissions to function:
* **Camera:** For viewfinder and image capture.
* **Storage:** For creating folder structures and saving images locally.
* **Microphone:** (Optional) Reserved for future voice note features.

---

## 📱 Usage

1.  **Create Folders:** Tap the grid icon (top-right) to create a new folder context.
2.  **Navigate:** Use the breadcrumb bar at the top (e.g., `Home > Site A`) to move between folders.
3.  **Take Photos:** Tap the white shutter button. Photos are automatically saved to the currently open folder.
4.  **Quick Tags:** Tap `[BAD]`, `[GOOD]`, or `[FIX]` overlays to tag the *next* photo taken.
5.  **AI OCR Mode:** * Toggle the `AI` switch near the shutter.
    * Tap the shutter to freeze the frame.
    * Tap highlighted text boxes to extract data.
    * Data is appended to `Asset_Data.txt` located in the current folder.

---

## 📂 Project Structure

```text
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


