# Emotion Recognition App

A professional Flutter mobile application for multimodal emotion recognition using Speech and Heart Rate data.

## Features

### 1. Speech Emotion Recognition (SER)
- **Real-time voice recording** through mobile microphone
- **MFCC feature extraction** (40 coefficients, 174 frames)
- **26 emotion classes** detection using TensorFlow Lite
- Professional UI with confidence scores and probability distribution

### 2. Heart Rate Emotion Recognition (HER)
- **Google Fit API integration** for heart rate data retrieval
- **Physiological signal processing** with bandpass filtering
- **Binary emotion classification** (Low/High Valence)
- Heart rate statistics display (average, min, max)

### 3. Multimodal Fusion Analysis
- **Combined Speech + Heart Rate** emotion detection
- **Gated fusion architecture** for optimal prediction
- **8 emotion classes**: Angry, Calm, Disgust, Fear, Happy, Neutral, Sad, Surprise
- Step-by-step guided workflow

## Technical Architecture

### Models
- **SER Model**: `ser_cpu_rnn_model.tflite` - RNN-based speech emotion classifier
- **HER Model**: `HER_emotion_model_custom.tflite` - BiLSTM heart rate emotion classifier
- **Fusion Model**: `fusion_model.tflite` - Multimodal gated fusion network

### Audio Processing Pipeline
1. Real-time audio recording at 22,050 Hz sample rate
2. Pre-emphasis filtering (α = 0.97)
3. Frame-based windowing (Hamming window)
4. FFT and power spectrum computation
5. Mel-filterbank application (40 mel bands)
6. DCT transformation to MFCC coefficients
7. Padding/truncation to 174 frames

### Heart Rate Processing
1. Google Fit API data retrieval
2. Signal normalization (Z-score standardization)
3. Padding/truncation to 5000 samples
4. Model inference for valence classification

## Google Fit Integration

### Configuration
The app is configured with:
- **Client ID**: `522512286409-e1msqhisbo1ep47lqvug6b948i528pgp.apps.googleusercontent.com`
- **SHA-1**: `07:6E:8F:B1:3F:CE:E9:B2:79:DC:0F:EF:A8:35:84:F8:BB:EB:7A:9C`

### Required Permissions
- `android.permission.ACTIVITY_RECOGNITION`
- `android.permission.ACCESS_FINE_LOCATION`
- `com.google.android.gms.permission.ACTIVITY_RECOGNITION`

## Installation

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / Xcode
- Android device with Google Fit installed

### Setup Steps

1. **Clone and navigate to the project**
```bash
cd emotion_recognition_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Ensure TFLite models are in place**
The following models should be in `assets/models/`:
- `ser_cpu_rnn_model.tflite`
- `HER_emotion_model_custom.tflite`
- `fusion_model.tflite`

4. **Configure Google Fit**
- Enable Fitness API in Google Cloud Console
- Add SHA-1 fingerprint to your Firebase/Google Cloud project
- Ensure package name matches: `com.emotion.app.emotion_recognition_app`

5. **Run the app**
```bash
flutter run
```

## Usage Guide

### Speech Emotion Recognition
1. Tap "Speech Emotion Recognition" on home screen
2. Tap the microphone button to start recording
3. Speak naturally (3-5 seconds recommended)
4. Tap stop button to end recording
5. View emotion prediction with confidence scores

### Heart Rate Emotion Recognition
1. Tap "Heart Rate Emotion Recognition"
2. Ensure Google Fit has recent heart rate data
3. Tap "Fetch from Google Fit" button
4. Grant permissions if requested
5. View emotional valence prediction

### Multimodal Fusion
1. Tap "Multimodal Fusion Analysis"
2. **Step 1**: Fetch heart rate data from Google Fit
3. **Step 2**: Record your voice (tap mic button)
4. **Step 3**: View combined emotion prediction
5. Tap "Start New Analysis" to reset

## Model Details

### Speech Emotion Model
- **Input**: `[1, 40, 174]` - MFCC features
- **Output**: `[1, 26]` - Probability distribution over 26 emotion classes
- **Architecture**: Bidirectional RNN with attention mechanism

### Heart Rate Model
- **Input**: `[1, 5000]` - Normalized heart rate signal
- **Output**: `[1, 2]` - Binary valence classification
- **Architecture**: CNN + BiLSTM with temporal pooling

### Fusion Model
- **Input 1**: `[1, 40]` - Speech MFCC means
- **Input 2**: `[1, 100, 1]` - Heart rate features
- **Output**: `[1, 8]` - Multimodal emotion classification
- **Architecture**: Gated fusion with residual connections

## Dependencies

### Core
- `flutter: sdk`
- `tflite_flutter: ^0.10.4` - TensorFlow Lite inference
- `tflite_flutter_helper: ^0.3.1` - TFLite utilities

### Audio
- `record: ^5.0.4` - Audio recording
- `permission_handler: ^11.0.1` - Runtime permissions
- `path_provider: ^2.1.1` - File system access

### Health
- `health: ^10.0.0` - Google Fit integration

### UI
- `provider: ^6.1.1` - State management
- `fl_chart: ^0.66.0` - Data visualization

## Permissions

### Android
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

### iOS
Add to `Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for emotion recognition</string>
<key>NSHealthShareUsageDescription</key>
<string>We need access to your heart rate data for emotion analysis</string>
```

## Performance Optimization

- Models are loaded once during initialization
- Audio processing is done in background
- Efficient MFCC computation with FFT
- Minimal memory footprint with streaming data

## Troubleshooting

### Google Fit Connection Issues
1. Ensure Google Fit app is installed and has data
2. Check that Fitness API is enabled in Google Cloud Console
3. Verify SHA-1 fingerprint matches your app signing key
4. Grant all requested permissions

### Audio Recording Issues
1. Check microphone permissions are granted
2. Ensure device has working microphone
3. Try recording in a quiet environment
4. Verify audio sample rate compatibility

### Model Loading Errors
1. Confirm TFLite models are in `assets/models/`
2. Check model file sizes (should not be 20 bytes)
3. Verify models are properly exported from Python training
4. Check TFLite version compatibility

## Project Structure

```
emotion_recognition_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/
│   │   ├── home_screen.dart      # Main navigation screen
│   │   ├── speech_emotion_screen.dart
│   │   ├── heart_rate_screen.dart
│   │   └── fusion_screen.dart
│   ├── services/
│   │   ├── speech_emotion_service.dart
│   │   ├── heart_rate_service.dart
│   │   └── fusion_emotion_service.dart
│   └── utils/
│       └── audio_processor.dart  # MFCC computation
├── assets/
│   └── models/
│       ├── ser_cpu_rnn_model.tflite
│       ├── HER_emotion_model_custom.tflite
│       └── fusion_model.tflite
├── android/
│   └── app/
│       ├── build.gradle
│       └── src/main/AndroidManifest.xml
└── pubspec.yaml
```

## Research Background

This app implements the multimodal emotion recognition system described in:
**"Enhanced Emotion Classification via Multimodal Fusion of Physiological and Vocal Signals from Daily-Life Wearables"**

### Key Contributions
- Real-time emotion detection using consumer devices
- Gated fusion architecture for multimodal integration
- Practical deployment on mobile platforms
- Privacy-preserving on-device inference

## Future Enhancements

- [ ] Add facial expression recognition
- [ ] Implement continuous emotion tracking
- [ ] Support offline mode with local data storage
- [ ] Add emotion history and analytics
- [ ] Integrate additional physiological signals (EDA, skin temperature)
- [ ] Personalized model fine-tuning

## License

[Specify your license]

## Contact

For questions or issues, please contact the development team.

---

**Built with ❤️ using Flutter and TensorFlow Lite**
