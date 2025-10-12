# Emotion Recognition App - Project Overview

## 🎯 Project Summary

A professional Flutter mobile application implementing multimodal emotion recognition using Speech and Heart Rate signals with TensorFlow Lite models.

## ✨ Key Features

### 1. Speech Emotion Recognition (SER)
- Real-time audio recording through mobile microphone
- Advanced MFCC feature extraction (40 coefficients, 174 frames)
- 26 emotion class detection
- Confidence scores and probability distribution display

### 2. Heart Rate Emotion Recognition (HER)
- Google Fit API integration for seamless data retrieval
- Physiological signal processing with bandpass filtering
- Binary valence classification (Low/High)
- Heart rate statistics visualization

### 3. Multimodal Fusion Analysis
- Combined Speech + Heart Rate emotion detection
- Gated fusion neural network architecture
- 8 emotion classes: Angry, Calm, Disgust, Fear, Happy, Neutral, Sad, Surprise
- Step-by-step guided user workflow

## 🏗️ Technical Architecture

### Technology Stack
- **Framework**: Flutter 3.0+
- **ML Inference**: TensorFlow Lite
- **Audio Processing**: Custom MFCC implementation
- **Health Data**: Google Fit API (health package)
- **State Management**: Provider pattern
- **Platform**: Android (with iOS support ready)

### Model Architecture

#### Speech Emotion Model (SER)
```
Input: [1, 40, 174] Float32
       ↓
Bidirectional RNN + Attention
       ↓
Output: [1, 26] Softmax probabilities
```

#### Heart Rate Model (HER)
```
Input: [1, 5000] Float32
       ↓
Conv1D + BiLSTM + Global Pooling
       ↓
Output: [1, 2] Softmax probabilities
```

#### Fusion Model
```
Input 1: [1, 40] Speech Features
Input 2: [1, 100, 1] HR Features
       ↓
Gated Fusion Network
       ↓
Output: [1, 8] Softmax probabilities
```

## 📁 Project Structure

```
emotion_recognition_app/
│
├── lib/
│   ├── main.dart                          # App entry point
│   │
│   ├── screens/                           # UI Screens
│   │   ├── home_screen.dart               # Main navigation
│   │   ├── speech_emotion_screen.dart     # SER interface
│   │   ├── heart_rate_screen.dart         # HER interface
│   │   └── fusion_screen.dart             # Fusion interface
│   │
│   ├── services/                          # Business Logic
│   │   ├── speech_emotion_service.dart    # SER model inference
│   │   ├── heart_rate_service.dart        # HER model + Google Fit
│   │   └── fusion_emotion_service.dart    # Fusion model inference
│   │
│   └── utils/                             # Utilities
│       └── audio_processor.dart           # MFCC computation
│
├── assets/
│   └── models/                            # TFLite Models
│       ├── ser_cpu_rnn_model.tflite
│       ├── HER_emotion_model_custom.tflite
│       └── fusion_model.tflite
│
├── android/                               # Android Configuration
│   ├── app/
│   │   ├── build.gradle                   # App-level Gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml        # Permissions & config
│   │       └── kotlin/...                 # MainActivity
│   ├── build.gradle                       # Project-level Gradle
│   └── settings.gradle                    # Gradle settings
│
├── pubspec.yaml                           # Dependencies
├── README.md                              # User documentation
├── SETUP_INSTRUCTIONS.md                  # Setup guide
└── PROJECT_OVERVIEW.md                    # This file
```

## 🔬 Signal Processing Pipeline

### Audio Processing (MFCC Extraction)

```
Raw Audio (22050 Hz, Mono WAV)
    ↓
Pre-emphasis Filter (α=0.97)
    ↓
Framing (512 samples, 256 hop)
    ↓
Hamming Windowing
    ↓
FFT (512 bins)
    ↓
Power Spectrum
    ↓
Mel Filterbank (40 bands)
    ↓
Log Transform
    ↓
DCT (40 coefficients)
    ↓
Padding/Truncation (174 frames)
    ↓
Model Input [1, 40, 174]
```

### Heart Rate Processing

```
Google Fit API Data
    ↓
Raw HR Values (BPM)
    ↓
Padding/Truncation (5000 samples)
    ↓
Z-score Normalization
    μ = mean(HR)
    σ = std(HR)
    normalized = (HR - μ) / σ
    ↓
Model Input [1, 5000]
```

## 🔐 Google Fit Integration

### Configuration Details
- **Package Name**: `com.emotion.app.emotion_recognition_app`
- **Client ID**: `522512286409-e1msqhisbo1ep47lqvug6b948i528pgp.apps.googleusercontent.com`
- **SHA-1**: `07:6E:8F:B1:3F:CE:E9:B2:79:DC:0F:EF:A8:35:84:F8:BB:EB:7A:9C`

### Required Permissions
```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="com.google.android.gms.permission.ACTIVITY_RECOGNITION"/>
```

### Data Retrieval
- Fetches heart rate data from last 5 minutes
- Requires Google Fit app installed and synced
- Automatic permission handling

## 📱 User Interface Design

### Color Scheme
- **Speech Module**: Blue gradient (#1976D2)
- **Heart Rate Module**: Red gradient (#D32F2F)
- **Fusion Module**: Green gradient (#388E3C)
- **Home Screen**: Teal gradient (#00897B)

### Design Principles
- Material Design 3 guidelines
- Professional gradient backgrounds
- Card-based layout for content
- Clear visual hierarchy
- Intuitive navigation flow
- Real-time status updates

## 🔄 App Workflow

### Speech Emotion Recognition Flow
```
User opens SER screen
    ↓
Tap microphone button
    ↓
Grant microphone permission
    ↓
Record audio (user controlled)
    ↓
Tap stop button
    ↓
Extract MFCC features
    ↓
Run TFLite inference
    ↓
Display emotion + confidence
```

### Heart Rate Recognition Flow
```
User opens HER screen
    ↓
Tap "Fetch from Google Fit"
    ↓
Grant Fitness API permissions
    ↓
Retrieve HR data (5 min window)
    ↓
Preprocess HR signal
    ↓
Run TFLite inference
    ↓
Display valence + statistics
```

### Fusion Analysis Flow
```
User opens Fusion screen
    ↓
Step 1: Fetch HR data
    ↓
Step 2: Record voice
    ↓
Extract both features
    ↓
Run multimodal inference
    ↓
Display fused prediction
```

## 📊 Model Performance Expectations

### Input Requirements
- **Audio**: 3-5 seconds of clear speech
- **Heart Rate**: Continuous data from wearable device
- **Environment**: Quiet space for audio recording

### Latency
- **MFCC Extraction**: ~100-200ms
- **Model Inference**: ~50-100ms per model
- **Total Processing**: <500ms for complete pipeline

### Memory Usage
- **Model Size**: SER (~500KB), HER (~300KB), Fusion (~800KB)
- **Runtime Memory**: ~50-100MB including audio buffers
- **Peak Usage**: ~150MB during inference

## 🛠️ Development Guidelines

### Code Organization
- **Single Responsibility**: Each file has one clear purpose
- **Separation of Concerns**: UI, business logic, and utilities separated
- **Clean Architecture**: Service layer abstracts model complexity
- **Reusable Components**: Audio processor shared across modules

### Best Practices
- Async/await for all I/O operations
- Proper error handling and user feedback
- Memory-efficient audio processing
- Model loaded once and reused
- State management with setState

## 🔍 Key Implementation Details

### MFCC Computation
- Custom Dart implementation (no external DSP library)
- Cooley-Tukey FFT algorithm (radix-2)
- Mel-scale frequency warping
- DCT-II transformation
- Optimized for mobile performance

### Google Fit Integration
- OAuth 2.0 authentication flow
- Automatic token management
- Graceful permission handling
- Fallback error messages

### TFLite Integration
- Models loaded from assets
- Efficient buffer allocation
- Multi-input model support (fusion)
- Float32 tensor handling

## 🎓 Research Foundation

Based on the paper:
**"Enhanced Emotion Classification via Multimodal Fusion of Physiological and Vocal Signals from Daily-Life Wearables"**

### Scientific Contributions
1. Multimodal fusion architecture
2. Real-world wearable device integration
3. On-device inference for privacy
4. Practical emotion recognition system

### Emotion Classes

**SER Model (26 classes)**:
- Neutral, Calm, Happy, Sad, Angry, Fearful, Disgust, Surprised
- Each with variations: Strong, Normal, Weak intensity levels

**HER Model (2 classes)**:
- Low Valence (negative emotional state)
- High Valence (positive emotional state)

**Fusion Model (8 classes)**:
- Angry, Calm, Disgust, Fear, Happy, Neutral, Sad, Surprise

## 📈 Future Enhancements

### Planned Features
- [ ] Facial expression recognition module
- [ ] Continuous emotion tracking over time
- [ ] Emotion history and analytics dashboard
- [ ] Export emotion data (CSV/JSON)
- [ ] Personalized model fine-tuning
- [ ] Multiple language support

### Technical Improvements
- [ ] Model quantization for reduced size
- [ ] Real-time streaming inference
- [ ] Background heart rate monitoring
- [ ] Cloud sync for multi-device
- [ ] Advanced visualization (charts, graphs)

## 🔐 Privacy & Security

### Data Handling
- **On-Device Processing**: All inference runs locally
- **No Cloud Upload**: Audio and HR data never leave device
- **Temporary Storage**: Recordings deleted after processing
- **Google Fit**: Only reads data, never writes
- **Permissions**: Requested only when needed

### Security Measures
- Secure model storage in assets
- No external API calls for inference
- Local file system isolation
- Permission-based access control

## 📝 Testing Recommendations

### Unit Testing
- Audio processing functions
- MFCC computation accuracy
- Model input/output shapes
- Feature normalization

### Integration Testing
- Google Fit data retrieval
- Audio recording pipeline
- End-to-end inference flow
- UI state management

### User Testing
- Record various emotion expressions
- Test in different environments
- Verify with multiple users
- Compare with ground truth emotions

## 🎯 Success Metrics

### Technical Metrics
- Model load time < 1 second
- Inference latency < 500ms
- App startup time < 2 seconds
- Memory usage < 200MB

### User Experience Metrics
- Clear emotion predictions
- Intuitive navigation flow
- Responsive UI interactions
- Helpful error messages

## 📚 Documentation

### Available Guides
1. **README.md** - User-facing documentation
2. **SETUP_INSTRUCTIONS.md** - Detailed setup guide
3. **PROJECT_OVERVIEW.md** - This technical overview

### Code Documentation
- Inline comments for complex logic
- Function-level documentation
- Clear variable naming
- Structured file organization

## 🤝 Contributing

### Code Style
- Follow Dart style guide
- Use meaningful variable names
- Add comments for complex algorithms
- Keep functions focused and small

### Git Workflow
1. Create feature branch
2. Implement changes
3. Test thoroughly
4. Submit pull request
5. Code review process

## 📞 Support & Contact

For technical issues:
1. Check SETUP_INSTRUCTIONS.md
2. Review error messages carefully
3. Verify all prerequisites
4. Check model files are valid

## 🏆 Acknowledgments

- TensorFlow Lite team for mobile inference
- Flutter team for cross-platform framework
- Google Fit API for health data access
- Research paper authors for scientific foundation

---

**Built with passion for emotion AI and mobile development** 🚀

*Version: 1.0.0*
*Last Updated: October 2025*
