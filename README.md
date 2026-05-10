# gscanner

GScanner is a high-performance scanning utility built with Flutter, leveraging **Google’s ML Kit** to provide on-device intelligence. It is designed to be a versatile tool for document digitization, barcode processing, and text extraction, all while maintaining user privacy by performing processing locally.

---

### 🚀 Key Features

* **Document Scanner:** Features a high-quality UI flow for digitizing physical documents with automatic edge detection and perspective correction.
* **Smart Editing:** Built-in capabilities to crop images, apply grayscale/color filters, and remove shadows or stains.
* **Text Recognition (OCR):** Extracts text from images in real-time, supporting multiple languages and structured data.
* **Barcode & QR Scanning:** Fast, omnidirectional scanning of most standard 1D and 2D formats (QR, Aztec, Data Matrix, etc.).
* **Multi-Format Export:** Save and share scanned documents as high-quality PDFs or JPEG images.
* **No Permissions Required:** Utilizes Google Play Services for the document scanner flow, meaning the app doesn't require direct camera permissions for the core scanning UI.

### 🛠 Tech Stack

* Framework: Flutter
* Machine Learning: [Google ML Kit](https://developers.google.com/ml-kit)
* State Management: BLoC (Business Logic Component)
* Image Processing: Specialized ML Kit Vision APIs for document and text analysis.

### 📁 Project Architecture

The application is structured to handle heavy image processing while keeping the UI responsive:

* Presentation Layer: Intuitive interface for the scanner trigger and result gallery using BLoC for state handling.
* Domain Layer: Logic for handling scanned results, file naming conventions, and PDF generation.
* Data Layer: Integration with `google_mlkit_document_scanner` and `google_mlkit_text_recognition` plugins.

### 🏁 Getting Started

#### Prerequisites

* Flutter SDK (Latest stable version)
* Android API Level 21+ (Document Scanner requires Google Play Services)

#### Setup

1. Clone the repository:
git clone [https://github.com/SGBhowmick/gscanner.git]()
2. Install dependencies:
flutter pub get
3. Run the app:
flutter run

### 📝 Roadmap

* [ ] Multi-page document merging and reordering.
* [ ] Cloud sync for scanned documents.
* [ ] Integrated "Smart Reply" based on scanned text entities.

---

*Transforming physical data into digital intelligence.*
