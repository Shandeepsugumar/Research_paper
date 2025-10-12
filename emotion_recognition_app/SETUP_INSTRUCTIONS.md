# Emotion Recognition App - Setup Instructions

## Important: Model Files

⚠️ **CRITICAL**: The TFLite model files in `assets/models/` are currently placeholder files (20 bytes each). You MUST replace them with your actual trained models before running the app.

### Required Models

Copy your trained model files to `assets/models/`:

1. **ser_cpu_rnn_model.tflite** - Your trained Speech Emotion Recognition model
2. **HER_emotion_model_custom.tflite** - Your trained Heart Rate Emotion model
3. **fusion_model.tflite** - Your trained Fusion model

```bash
# Copy your actual model files
cp /path/to/your/ser_cpu_rnn_model.tflite emotion_recognition_app/assets/models/
cp /path/to/your/HER_emotion_model_custom.tflite emotion_recognition_app/assets/models/
cp /path/to/your/fusion_model.tflite emotion_recognition_app/assets/models/
```

## Prerequisites

### 1. Install Flutter
Download and install Flutter SDK from: https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Android Development Setup
- Install Android Studio
- Install Android SDK (API level 24+)
- Set up an Android device or emulator

### 3. Google Fit Configuration

#### Enable Fitness API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable "Fitness API"
4. Go to "Credentials" section

#### Configure OAuth Consent Screen
1. Navigate to "OAuth consent screen"
2. Fill in required information
3. Add test users if in development mode

#### Get SHA-1 Fingerprint
For debug build:
```bash
cd emotion_recognition_app/android
./gradlew signingReport
```

Copy the SHA-1 fingerprint for debug keystore.

#### Add OAuth 2.0 Client
1. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
2. Select "Android" as application type
3. Add your package name: `com.emotion.app.emotion_recognition_app`
4. Add your SHA-1 fingerprint
5. Click "Create"

The Client ID is already configured in the app:
- **Client ID**: `522512286409-e1msqhisbo1ep47lqvug6b948i528pgp.apps.googleusercontent.com`

If you need to use your own Client ID, update it in:
- `android/app/src/main/res/values/strings.xml`

## Installation Steps

### 1. Navigate to Project
```bash
cd emotion_recognition_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Verify Models
Check that your model files are in place:
```bash
ls -lh assets/models/
```

All three `.tflite` files should be present and have substantial file sizes (not just 20 bytes).

### 4. Connect Device
Connect your Android device via USB with USB debugging enabled, or start an Android emulator.

Verify device connection:
```bash
flutter devices
```

### 5. Run the App
```bash
flutter run
```

Or for release build:
```bash
flutter run --release
```

## Permissions Setup

### First Run
On the first run, the app will request the following permissions:
1. **Microphone Access** - For voice recording
2. **Google Fit Access** - For heart rate data
3. **Activity Recognition** - For Google Fit integration

**Important**: Grant ALL permissions for full functionality.

### Google Fit Data
Ensure Google Fit app is installed and has heart rate data:
1. Install Google Fit from Play Store
2. Open Google Fit and grant necessary permissions
3. Add a heart rate source (smartwatch, manual entry, or compatible device)
4. Verify data is syncing

## Testing the App

### Test Speech Emotion Recognition
1. Open the app
2. Tap "Speech Emotion Recognition"
3. Tap the microphone button
4. Speak clearly for 3-5 seconds
5. Tap stop and wait for prediction

### Test Heart Rate Recognition
1. Ensure Google Fit has heart rate data from the last 5 minutes
2. Tap "Heart Rate Emotion Recognition"
3. Tap "Fetch from Google Fit"
4. Grant permissions if prompted
5. View emotion prediction

### Test Fusion Analysis
1. Tap "Multimodal Fusion Analysis"
2. Follow Step 1: Fetch heart rate data
3. Follow Step 2: Record voice
4. View combined prediction

## Troubleshooting

### Model Loading Errors
**Problem**: "Error loading model" or "Model not found"

**Solution**:
- Verify model files are in `assets/models/`
- Check file sizes are correct (not 20 bytes)
- Ensure `pubspec.yaml` includes assets section
- Run `flutter clean && flutter pub get`

### Google Fit Connection Issues
**Problem**: "No heart rate data found"

**Solution**:
- Check Google Fit app has data
- Verify Fitness API is enabled
- Ensure OAuth consent screen is configured
- Check SHA-1 fingerprint matches
- Grant all requested permissions

### Audio Recording Issues
**Problem**: Recording fails or no audio captured

**Solution**:
- Grant microphone permission
- Test microphone with other apps
- Check device compatibility
- Ensure quiet environment for better results

### Build Errors
**Problem**: Gradle build fails

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Permission Denied
**Problem**: App crashes on permission request

**Solution**:
- Check `AndroidManifest.xml` has all permissions
- Manually grant permissions in device settings
- Reinstall app after permission updates

## Model Input/Output Specifications

### SER Model
- **Input Shape**: `[1, 40, 174]` (batch, mfcc_coefficients, time_frames)
- **Output Shape**: `[1, 26]` (batch, emotion_classes)
- **Expected Format**: Float32 normalized MFCC features

### HER Model
- **Input Shape**: `[1, 5000]` (batch, samples)
- **Output Shape**: `[1, 2]` (batch, valence_classes)
- **Expected Format**: Float32 normalized heart rate signal

### Fusion Model
- **Input 1 Shape**: `[1, 40]` (batch, speech_features)
- **Input 2 Shape**: `[1, 100, 1]` (batch, hr_features, channels)
- **Output Shape**: `[1, 8]` (batch, emotion_classes)
- **Expected Format**: Float32 normalized features

## Building Release APK

### Generate Release APK
```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Generate App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

The bundle will be at: `build/app/outputs/bundle/release/app-release.aab`

### Signing Configuration
For production release, configure signing:

1. Generate keystore:
```bash
keytool -genkey -v -keystore ~/emotion-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias emotion-app
```

2. Create `android/key.properties`:
```
storePassword=<password>
keyPassword=<password>
keyAlias=emotion-app
storeFile=<path-to-keystore>
```

3. Update `android/app/build.gradle` to use signing config

## Performance Tips

1. **Model Optimization**: Use quantized models for faster inference
2. **Audio Quality**: Record in quiet environment for best results
3. **Heart Rate Data**: Ensure continuous data from wearable for accuracy
4. **Memory**: Close unused apps when running emotion recognition

## Development Mode

For development with hot reload:
```bash
flutter run --debug
```

View logs:
```bash
flutter logs
```

## Support

If you encounter issues:
1. Check this setup guide carefully
2. Review error messages in console
3. Verify all prerequisites are met
4. Ensure model files are valid TFLite models

---

**Note**: This app uses on-device inference with TensorFlow Lite. All processing happens locally on your device, ensuring privacy and low latency.
