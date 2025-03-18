# Installation Instructions

## Download APK
[Download the latest APK from Google Drive]([#](https://drive.google.com/file/d/1jmcobjgIo8tkkgm8b-oyDtPa5BZs-Ydr/view?usp=sharing))

## Prerequisites

Ensure you have the following dependencies installed before running HealthEye:

- **Flutter**: v3.10+
- **Dart**: v3.0+
- **Android Studio** (or **Xcode** for iOS development)

## Installation Steps

### 1. Clone the Repository
```bash
git clone https://github.com/Ace91Ace/HealthEye.git
```

### 2. Navigate to the Project Directory
```bash
cd HealthEye
```

### 3. Install Flutter Dependencies
```bash
flutter pub get
```

### 4. Run the Application
#### For Android:
```bash
flutter run
```
#### For iOS:
```bash
flutter run --no-sound-null-safety
```

### 5. Build APK
To generate an APK for installation, run:
```bash
flutter build apk --release
```

