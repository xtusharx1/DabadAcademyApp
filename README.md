# Dabad Academy

## Overview

Dabad Academy is a comprehensive educational management mobile application designed to streamline interaction between students, parents, and academy administration. Built using Flutter, the platform provides a centralized hub for managing day-to-day academic activities, schedules, and administrative records with ease and reliability.

The application enables users to track attendance records, monitor fee payment statuses, view academic test results, and access notices and announcements in real time. It also features student profile management and secure document handling, ensuring all critical academic information is accessible at your fingertips.

By leveraging real-time Firebase Cloud Messaging (FCM) push notifications and interactive data visualisations, Dabad Academy aims to foster transparent communication and improve overall academic tracking for every stakeholder.

## Tech Stack

- **Core Framework:** Flutter & Dart SDK
- **Backend & Notifications:** Firebase Core, Firebase Cloud Messaging (FCM), Flutter Local Notifications
- **Data Visualization & UI:** FL Chart, Table Calendar, Animate Do, Cupertino Icons
- **Storage & Networking:** SharedPreferences, HTTP
- **Media & Hardware Access:** Image Picker, File Picker, URL Launcher

## Prerequisites

Before setting up the project, ensure you have the following installed on your machine:

- **Flutter SDK** (v3.8.0 or higher)
- **Dart SDK** (v3.8.0 or higher)
- **Git**
- **Android Studio** (with Android SDK & Build Tools)
- **Xcode** (v14+ for iOS development, macOS only)
- **CocoaPods** (for iOS dependencies)

## How to Run the Project

Follow these steps to run the app on a connected device or emulator.

### 1. Clone the Repository

```bash
git clone https://github.com/xtusharx1/DabadAcademyApp.git
cd DabadAcademyApp
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Constants

The API base URL and other app-wide constants live in `lib/constants.dart`.

### 4. Run the App

Execute the following command to start the application in debug mode:

```bash
flutter run
```

To run on a specific target device:

```bash
flutter run -d <device-id>
```


## Build Commands

Use the following commands to generate production build artifacts for Android and iOS.

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle (AAB)

```bash
flutter build appbundle --release
```

### iOS App / IPA

```bash
flutter build ios --release
```

To generate an iOS App Store deployment package (`.ipa`):

```bash
flutter build ipa --release
```

## Folder Structure

Below is a brief overview of the project structure:

```text
.
├── android/                  # Android native project files & configuration
├── ios/                      # iOS native project files & Podfile
├── assets/                   # Static assets (images, icons, and graphics)
├── lib/                      # Core Flutter application source code
│   ├── Models/               # Data models and serialisation logic
│   ├── Screens/              # App screens (Home, Attendance, Notice, Profile, etc.)
│   ├── FCM.dart              # Firebase Cloud Messaging integration setup
│   ├── constants.dart        # API base URL, session version & shared colours
│   ├── firebase_options.dart # Firebase environment credentials and setup

│   └── main.dart             # Application entry point
├── pubspec.yaml              # Package dependencies and asset configurations
└── README.md                 # Project documentation
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
